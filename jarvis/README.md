# JARVIS — ADI Execution Twin (Phase 1)

TRON detects on the price grid. JARVIS receives, classifies, speaks, and executes on Deriv — with a human tap or (later) on its own, always under the Risk Governor.

## Architecture

TradingView (TRON, Premium) → JSON webhook → JARVIS (FastAPI) → SQLite Ledger → Telegram (Jarvis voice + Tap-to-Trade buttons) → Deriv WS API (vanilla / rise-fall / multipliers, demo or real).

Tier routing: EXECUTE signals get an operator card with ⚡ buttons and a broadcast copy without buttons for the channel. CONTEXT signals get an informational card. NOISE goes to the ledger only — Jarvis holds the trash.

## Setup — Replit (current deployment target)

The repo root has a `.replit` config already pointed at `jarvis/`. Jarvis holds a Telegram polling loop and background "watch this contract" tasks that must stay alive between webhooks, so this must be a **Reserved VM** deployment, not Autoscale — Autoscale spins to zero between requests and would kill both the polling loop and the in-memory `_pending` tap-to-trade queue.

1. **Import**: Replit → Create App → Import from GitHub → this repo.
2. **Secrets** (Replit's lock icon in the sidebar, not `.env` — Replit injects these as real env vars): set every key listed in `jarvis/.env.example` — `WEBHOOK_SECRET`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_OPERATOR_ID`, `TELEGRAM_BROADCAST_ID`, `DERIV_APP_ID`, `DERIV_TOKEN_DEMO`, `DERIV_TOKEN_REAL`, `DERIV_ENV=demo`, `AUTO_TRADE=false`.
   - Telegram bot: create via @BotFather, paste the token, run once, send `/start` — it replies with your operator id, put that in `TELEGRAM_OPERATOR_ID`.
   - Deriv tokens: Deriv → Settings → API Token, one on demo and one on real, both `trade` + `read` scopes.
   - Deriv app id: register your own at api.deriv.com.
3. **Deploy**: the Deploy tab → type **Reserved VM** → it reads the `[deployment]` block in `.replit` (`pip install -r jarvis/requirements.txt` then `uvicorn app.main:app --host 0.0.0.0 --port 8080`) → Deploy. You get a stable `https://<name>.replit.app` URL — that's your webhook host, TLS already handled.
4. **TradingView side**: `TRON_Glassbox_SignalGenerator.pine` (repo root) already emits JSON — STEP 17 was merged. Load it on the chart, create ONE alert with condition "Any alert() function call", Message = `{{alert_message}}`, Webhook URL = `https://<name>.replit.app/webhook/tron?key=YOUR_WEBHOOK_SECRET`.

## Setup — any other VPS

1. `pip install -r requirements.txt`
2. `cp .env.example .env` and fill it in (same fields as the Replit Secrets above).
3. Run: `uvicorn app.main:app --host 0.0.0.0 --port 8080`, behind Caddy/nginx for HTTPS — TradingView requires port 80/443 for webhooks.
4. Same TradingView alert setup as above, pointed at your own host.

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
