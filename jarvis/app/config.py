"""
JARVIS — Configuration.
Everything Jarvis knows that TRON refuses to: accounts, risk, identity.
All secrets live in .env — never in code, never in the repo.
"""
import os
from dotenv import load_dotenv

load_dotenv()

# --- Identity ---
JARVIS_NAME = "JARVIS"
BRAND = "ABSOLUTE DOLLAR INTELLIGENCE"

# --- Webhook ---
WEBHOOK_SECRET = os.getenv("WEBHOOK_SECRET", "change-me")

# --- Telegram ---
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
# Your personal chat id (operator). Jarvis only obeys this id.
TELEGRAM_OPERATOR_ID = int(os.getenv("TELEGRAM_OPERATOR_ID", "0"))
# Optional broadcast channel (@absolutetrademeister or channel numeric id). Blank = off.
TELEGRAM_BROADCAST_ID = os.getenv("TELEGRAM_BROADCAST_ID", "")

# --- Deriv ---
DERIV_APP_ID = os.getenv("DERIV_APP_ID", "1089")  # register your own app id
DERIV_TOKEN_DEMO = os.getenv("DERIV_TOKEN_DEMO", "")
DERIV_TOKEN_REAL = os.getenv("DERIV_TOKEN_REAL", "")
# Hard switch: "demo" or "real". Jarvis announces the active account on boot.
DERIV_ENV = os.getenv("DERIV_ENV", "demo").lower()
DERIV_WS_URL = f"wss://ws.derivws.com/websockets/v3?app_id={DERIV_APP_ID}"

# --- Risk Governor (Jarvis's constitution — TRON knows nothing of this) ---
STAKE_DEFAULT = float(os.getenv("STAKE_DEFAULT", "1.0"))       # USD per tap
STAKE_MAX = float(os.getenv("STAKE_MAX", "10.0"))              # hard per-trade cap
DAILY_LOSS_CAP = float(os.getenv("DAILY_LOSS_CAP", "20.0"))    # USD; hit it → Jarvis refuses
MAX_CONCURRENT = int(os.getenv("MAX_CONCURRENT", "3"))         # open contracts
MULTIPLIER_DEFAULT = int(os.getenv("MULTIPLIER_DEFAULT", "100"))

# --- Auto-trader (present, OFF by default) ---
AUTO_TRADE = os.getenv("AUTO_TRADE", "false").lower() == "true"
AUTO_MIN_CONFIDENCE = int(os.getenv("AUTO_MIN_CONFIDENCE", "80"))
# Only these signal tiers may auto-execute when AUTO_TRADE=true
AUTO_SIGNAL_WHITELIST = {"H4_FLIP_CALL", "H4_FLIP_PUT", "SNIPER_CALL", "SNIPER_PUT"}

# --- Database ---
DB_PATH = os.getenv("DB_PATH", "jarvis.db")

# --- Symbol map: TradingView ticker → Deriv API symbol ---
# Extend as you add assets to the watchlist.
SYMBOL_MAP = {
    "VOLATILITY_75_INDEX": "R_75",
    "VOLATILITY_50_INDEX": "R_50",
    "VOLATILITY_10_INDEX": "R_10",
    "VOLATILITY_75_(1S)_INDEX": "1HZ75V",
    "VOLATILITY_50_(1S)_INDEX": "1HZ50V",
    "VOLATILITY_10_(1S)_INDEX": "1HZ10V",
    "VOLATILITY_100_INDEX": "R_100",
    "VOLATILITY_100_(1S)_INDEX": "1HZ100V",
    "VOLATILITY_25_INDEX": "R_25",
    "STEP_INDEX": "stpRNG",
    "STEP_INDEX_200": "stpRNG2",
    "STEP_INDEX_500": "stpRNG5",
    "BOOM_1000_INDEX": "BOOM1000",
    "CRASH_1000_INDEX": "CRASH1000",
    # Deriv-listed gold (for vanilla/multiplier where offered)
    "XAUUSD": "frxXAUUSD",
    "GBPUSD": "frxGBPUSD",
}


def deriv_symbol(tv_ticker: str) -> str | None:
    """Resolve a TradingView ticker to a Deriv API symbol. None = unknown asset."""
    key = tv_ticker.upper().replace(" ", "_")
    return SYMBOL_MAP.get(key)


def active_token() -> str:
    return DERIV_TOKEN_REAL if DERIV_ENV == "real" else DERIV_TOKEN_DEMO
