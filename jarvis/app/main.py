"""
JARVIS — Main. FastAPI spine.

POST /webhook/tron?key=SECRET  ← TradingView fires here
GET  /health                   ← uptime probe
GET  /ledger/signals           ← last 50 signals (glassbox read API)
GET  /ledger/trades            ← last 50 trades

Run: uvicorn app.main:app --host 0.0.0.0 --port 8080
"""
import asyncio
import json
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Query, Request

from . import config, db, deriv, telegram_bot, voice
from .parser import TIER_CONTEXT, TIER_EXECUTE, ParseError, parse

logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s %(name)s %(levelname)s %(message)s")
log = logging.getLogger("jarvis.main")


@asynccontextmanager
async def lifespan(app: FastAPI):
    db.init()
    await telegram_bot.start_bot()
    try:
        acct = await deriv.DerivClient().account_info()
        await telegram_bot.send_operator(voice.boot_banner(acct))
    except Exception as e:  # boot must not die on a Deriv hiccup
        log.warning("Boot account check failed: %s", e)
        await telegram_bot.send_operator(
            f"JARVIS ONLINE\n{voice.DIV}\nDeriv account check failed: {e}\n"
            f"Webhook listener is live regardless.")
    yield
    await telegram_bot.stop_bot()


app = FastAPI(title="JARVIS — ADI Execution Twin", lifespan=lifespan)


@app.get("/health")
async def health():
    return {"status": "online", "env": config.DERIV_ENV,
            "auto_trade": config.AUTO_TRADE}


@app.post("/webhook/tron")
async def tron_webhook(request: Request, key: str = Query("")):
    if key != config.WEBHOOK_SECRET:
        raise HTTPException(status_code=403, detail="bad key")

    body = await request.body()
    try:
        payload = json.loads(body)
    except json.JSONDecodeError:
        log.warning("Non-JSON webhook body: %r", body[:200])
        raise HTTPException(status_code=400, detail="body must be JSON")

    try:
        sig = parse(payload)
    except ParseError as e:
        log.warning("Rejected payload: %s", e)
        raise HTTPException(status_code=422, detail=str(e))

    signal_id = db.log_signal(sig)
    log.info("Signal #%s %s %s %s tier=%s conf=%s",
             signal_id, sig.signal, sig.bias, sig.symbol_tv, sig.tier,
             sig.confidence)

    # Tier routing — the trash stays in the ledger, never on Telegram
    if sig.tier == TIER_EXECUTE:
        asyncio.create_task(telegram_bot.send_signal_card(sig, signal_id))
        # Auto-trader path — only enters the pipeline when the flag is on;
        # governor still enforces whitelist + confidence floor + caps inside
        if config.AUTO_TRADE:
            asyncio.create_task(
                telegram_bot.execute_signal(sig, signal_id,
                                            config.STAKE_DEFAULT, origin="auto"))
    elif sig.tier == TIER_CONTEXT:
        asyncio.create_task(telegram_bot.send_context_card(sig))
    # TIER_NOISE: ledger only

    return {"ok": True, "signal_id": signal_id, "tier": sig.tier}


@app.get("/ledger/signals")
async def ledger_signals(limit: int = 50):
    with db.conn() as c:
        rows = c.execute(
            "SELECT id, ts, signal, bias, mode, symbol_tv, tf, spot, confidence, tier"
            " FROM signals ORDER BY id DESC LIMIT ?", (min(limit, 200),)).fetchall()
        return [dict(r) for r in rows]


@app.get("/ledger/trades")
async def ledger_trades(limit: int = 50):
    with db.conn() as c:
        rows = c.execute(
            "SELECT * FROM trades ORDER BY id DESC LIMIT ?",
            (min(limit, 200),)).fetchall()
        return [dict(r) for r in rows]
