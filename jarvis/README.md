# JARVIS — ADI Execution Twin (Phase 1)

TRON detects on the price grid. JARVIS receives, classifies, speaks, and executes on Deriv — with a human tap or (later) on its own, always under the Risk Governor.

## Architecture

TradingView (TRON, Premium) → JSON webhook → JARVIS (FastAPI) → SQLite Ledger → Telegram (Jarvis voice + Tap-to-Trade buttons) → Deriv WS API (vanilla / rise-fall / multipliers, demo or real).

Tier routing: EXECUTE signals get an operator card with ⚡ buttons and a broadcast copy without buttons for the channel. CONTEXT signals get an informational card. NOISE goes to the ledger only — Jarvis holds the trash.

## Setup

1. **Server.** Any small VPS with a public IP. Python 3.11+.
2. `pip install -r requirements.txt`
3. `cp .env.example .env` and fill it in:
   - **Telegram bot**: create via @BotFather, paste token. Run Jarvis once, send `/start` to your bot — it replies with your operator id. Put that in `TELEGRAM_OPERATOR_ID`. Only that id can tap trades.
   - **Deriv tokens**: Deriv → Settings → API Token. Create one on the demo account and one on real, both with `trade` + `read` scopes. `DERIV_ENV=demo` until the demo ledger proves the pipeline.
   - **Deriv app id**: register your own at api.deriv.com — this is also where your affiliate/IB markup attaches later.
   - **WEBHOOK_SECRET**: long random string.
4. Run: `uvicorn app.main:app --host 0.0.0.0 --port 8080`
   (Production: put it behind Caddy/nginx for HTTPS — TradingView requires port 80/443 for webhooks.)
5. **TradingView side**: paste `pine/tron_json_alerts.pine` into TRON (replacing the STEP 17 prose alerts), create ONE alert per chart with "Any alert() function call", Message = `{{alert_message}}`, Webhook URL = `https://your-host/webhook/tron?key=YOUR_SECRET`.

## Commands

- `/status` — account, balance, governor limits, auto-trader state
- `GET /ledger/signals` and `GET /ledger/trades` — glassbox read API (feeds the future Mini App)

## The Governor

Checked in strict priority order on every trade, tap or auto: stake cap → daily loss cap → max concurrent → auto-only gates (flag, signal whitelist, confidence floor). Every veto is spoken and logged.

## Going live checklist

1. Run on demo ≥ 1 week; review `/ledger/trades`.
2. Confirm symbol mapping fired correctly for every asset you alert on (extend `SYMBOL_MAP` in config.py as needed).
3. Flip `DERIV_ENV=real`, restart, confirm boot banner says REAL and the right loginid.
4. Auto-trader stays `false` until the demo auto ledger (run demo with `AUTO_TRADE=true`) earns it.

## Phase 2 hooks already in place

- Ledger read API → Telegram Mini App front-end
- `origin` field on trades separates tap vs auto performance
- Watchlist twin engine (TRON math server-side over Deriv candle streams) plugs in as a new module firing into the same `parse → classify → route` pipeline
