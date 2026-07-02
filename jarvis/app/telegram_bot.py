"""
JARVIS — Telegram Interface. Tap-to-Trade for Deriv.

EXECUTE-tier signals arrive as cards with inline buttons:
  [⚡ Trade $X]  [⚡ Trade $2X]  [✕ Dismiss]

Only the operator id may tap. Broadcast channel (if set) receives the
signal card without buttons — Beta Operators see the intelligence,
execution stays with you.
"""
import asyncio
import logging

from telegram import Bot, InlineKeyboardButton, InlineKeyboardMarkup, Update
from telegram.ext import Application, CallbackQueryHandler, CommandHandler, ContextTypes

from . import config, db, deriv, governor, voice
from .parser import TronSignal, parse

log = logging.getLogger("jarvis.telegram")

_app: Application | None = None
# In-flight signals awaiting a tap: signal_id → TronSignal
_pending: dict[int, TronSignal] = {}


def _keyboard(signal_id: int) -> InlineKeyboardMarkup:
    s1 = config.STAKE_DEFAULT
    s2 = min(config.STAKE_DEFAULT * 2, config.STAKE_MAX)
    return InlineKeyboardMarkup([[
        InlineKeyboardButton(f"⚡ Trade ${s1:g}", callback_data=f"t|{signal_id}|{s1}"),
        InlineKeyboardButton(f"⚡ Trade ${s2:g}", callback_data=f"t|{signal_id}|{s2}"),
        InlineKeyboardButton("✕", callback_data=f"d|{signal_id}"),
    ]])


async def send_signal_card(sig: TronSignal, signal_id: int):
    """EXECUTE tier → operator card with buttons; broadcast copy without."""
    _pending[signal_id] = sig
    bot = _app.bot
    text = voice.signal_card(sig)
    await bot.send_message(chat_id=config.TELEGRAM_OPERATOR_ID, text=text,
                           reply_markup=_keyboard(signal_id))
    if config.TELEGRAM_BROADCAST_ID:
        await bot.send_message(chat_id=config.TELEGRAM_BROADCAST_ID, text=text)


async def send_context_card(sig: TronSignal):
    bot = _app.bot
    text = voice.context_card(sig)
    await bot.send_message(chat_id=config.TELEGRAM_OPERATOR_ID, text=text)
    if config.TELEGRAM_BROADCAST_ID:
        await bot.send_message(chat_id=config.TELEGRAM_BROADCAST_ID, text=text)


async def send_operator(text: str):
    await _app.bot.send_message(chat_id=config.TELEGRAM_OPERATOR_ID, text=text)


async def execute_signal(sig: TronSignal, signal_id: int, stake: float,
                         origin: str) -> None:
    """The single execution path — tap and auto both land here."""
    verdict = governor.check(stake, origin, sig.confidence, sig.signal)
    if not verdict.allowed:
        await send_operator(voice.governor_refusal(verdict.rule, verdict.reason))
        db.log_trade(signal_id, config.DERIV_ENV, origin, "-", "-", stake,
                     "rejected", detail=f"{verdict.rule}: {verdict.reason}")
        return

    symbol = config.deriv_symbol(sig.symbol_tv)
    if symbol is None:
        msg = f"Unknown symbol map for {sig.symbol_tv}. Add it to SYMBOL_MAP."
        await send_operator(voice.error_note("Symbol resolution", msg))
        db.log_trade(signal_id, config.DERIV_ENV, origin, "-", sig.symbol_tv,
                     stake, "error", detail=msg)
        return

    s = sig.setup
    # Multiplier TP/SL as USD amounts derived from RR on stake:
    tp_amt = stake * float(s.get("rr", 1.5)) if sig.mode == "multiplier" else None
    sl_amt = stake if sig.mode == "multiplier" else None

    try:
        client = deriv.DerivClient()
        receipt = await client.buy(
            mode=sig.mode, bias=sig.bias, symbol=symbol, stake=stake,
            expiry_min=sig.expiry_min, strike=sig.strike,
            tp_amount=tp_amt, sl_amount=sl_amt,
        )
    except deriv.DerivError as e:
        await send_operator(voice.error_note(f"{sig.title} on {symbol}", str(e)))
        db.log_trade(signal_id, config.DERIV_ENV, origin,
                     deriv.CONTRACT_MAP.get((sig.mode, sig.bias), "?"),
                     symbol, stake, "error", detail=str(e))
        return

    db.log_trade(signal_id, receipt["env"], origin,
                 deriv.CONTRACT_MAP[(sig.mode, sig.bias)], symbol, stake,
                 "placed", contract_id=receipt["contract_id"],
                 buy_price=receipt["buy_price"], payout=receipt.get("payout"),
                 detail=receipt.get("longcode"))
    await send_operator(voice.trade_receipt(receipt, sig, stake, origin))
    asyncio.create_task(_watch_contract(receipt["contract_id"], sig))


async def _watch_contract(contract_id: int, sig: TronSignal):
    """Poll until the contract settles, then speak the outcome."""
    client = deriv.DerivClient()
    for _ in range(240):  # up to ~2h at 30s
        await asyncio.sleep(30)
        try:
            st = await client.contract_status(contract_id)
        except deriv.DerivError as e:
            log.warning("watch %s: %s", contract_id, e)
            continue
        if st["is_sold"]:
            profit = float(st.get("profit") or 0)
            db.close_trade(contract_id, profit)
            outcome = "WIN" if profit >= 0 else "LOSS"
            await send_operator(
                f"JARVIS — CONTRACT SETTLED\n{voice.DIV}\n"
                f"{sig.title} | {sig.symbol_tv}\n"
                f"Result: {outcome}  P/L: {profit:+.2f} USD\n"
                f"Contract {contract_id} closed. Ledger updated.\n"
            )
            return


# --- Handlers ---

def _is_operator(update: Update) -> bool:
    uid = update.effective_user.id if update.effective_user else 0
    return uid == config.TELEGRAM_OPERATOR_ID


async def on_button(update: Update, context: ContextTypes.DEFAULT_TYPE):
    q = update.callback_query
    await q.answer()
    if not _is_operator(update):
        return
    parts = q.data.split("|")
    if parts[0] == "d":
        await q.edit_message_reply_markup(reply_markup=None)
        return
    if parts[0] == "t":
        signal_id, stake = int(parts[1]), float(parts[2])
        sig = _pending.get(signal_id)
        if sig is None:
            row = db.get_signal(signal_id)
            if row is None:
                await q.edit_message_reply_markup(reply_markup=None)
                return
            import json as _json
            sig = parse(_json.loads(row["raw_json"]))
        await q.edit_message_reply_markup(reply_markup=None)
        await execute_signal(sig, signal_id, stake, origin="tap")


async def cmd_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not _is_operator(update):
        return
    try:
        acct = await deriv.DerivClient().account_info()
        await update.message.reply_text(voice.boot_banner(acct))
    except deriv.DerivError as e:
        await update.message.reply_text(voice.error_note("Status check", str(e)))


async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not _is_operator(update):
        await update.message.reply_text("JARVIS serves one operator.")
        return
    await update.message.reply_text(
        f"JARVIS reporting.\nYour operator id: {update.effective_user.id}\n"
        f"Commands: /status"
    )


async def start_bot() -> Application:
    global _app
    _app = Application.builder().token(config.TELEGRAM_BOT_TOKEN).build()
    _app.add_handler(CommandHandler("start", cmd_start))
    _app.add_handler(CommandHandler("status", cmd_status))
    _app.add_handler(CallbackQueryHandler(on_button))
    await _app.initialize()
    await _app.start()
    await _app.updater.start_polling(drop_pending_updates=True)
    log.info("Telegram polling started")
    return _app


async def stop_bot():
    if _app:
        await _app.updater.stop()
        await _app.stop()
        await _app.shutdown()
