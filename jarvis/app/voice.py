"""
JARVIS — The Voice.

Plain text in the agent's own chain-logic language. Mobile-native,
zero degradation on repost. No markdown, no HTML. Non-negotiable.
Operator remarks are always left blank.
"""
from . import config
from .parser import TronSignal

DIV = "─" * 24


def _fractal_block(sig: TronSignal) -> str:
    f = sig.fractal
    return (
        "FRACTAL 4-LAYER SYNC\n"
        f"L1 Sovereign H4: {f.get('h4', '—')}\n"
        f"L2 Anchor    H1: {f.get('h1', '—')}\n"
        f"L3 Filter   M15: {f.get('m15', '—')}\n"
        f"L4 Exec      M5: {f.get('m5', '—')}\n"
        f"Sync: {f.get('sync_layers', '?')}/4 | {f.get('quality', '—')}"
    )


def _core_block(sig: TronSignal) -> str:
    c = sig.core
    return (
        "CORE SIGNALS\n"
        f"Structure: {c.get('structure', '—')}\n"
        f"VWAP: {c.get('vwap', '—')}  Fib: {c.get('fib', '—')}\n"
        f"VP: {c.get('vp', '—')}  RSI: {c.get('rsi', '—')}\n"
        f"Location: {c.get('spatial', '—')}"
    )


def _setup_block(sig: TronSignal) -> str:
    s = sig.setup
    if sig.mode == "rise_fall":
        direction = "RISE" if sig.bias == "CALL" else "FALL"
        return (
            "RISE/FALL SETUP\n"
            f"Direction: {direction}  Expiry: {s.get('expiry_min', '?')}m\n"
            f"Spot: {sig.spot}\n"
            f"SL ref: {s.get('sl', '—')}  RR: 1:{s.get('rr', '—')}\n"
            f"TP ref: {s.get('tp1', '—')} / {s.get('tp2', '—')}"
        )
    if sig.mode == "multiplier":
        direction = "UP" if sig.bias == "CALL" else "DOWN"
        return (
            "MULTIPLIER SETUP\n"
            f"Direction: {direction} x{config.MULTIPLIER_DEFAULT}\n"
            f"Spot: {sig.spot}\n"
            f"SL: {s.get('sl', '—')}  RR: 1:{s.get('rr', '—')}\n"
            f"TP1/2/3: {s.get('tp1', '—')} / {s.get('tp2', '—')} / {s.get('tp3', '—')}"
        )
    return (
        "VANILLA OPTIONS SETUP\n"
        f"Strike: {s.get('strike', '—')} ({s.get('strike_mode', '—')})  "
        f"Expiry: {s.get('expiry_min', '?')}m\n"
        f"Entry: {sig.spot}\n"
        f"SL: {s.get('sl', '—')}  RR: 1:{s.get('rr', '—')}\n"
        f"TP1/2/3: {s.get('tp1', '—')} / {s.get('tp2', '—')} / {s.get('tp3', '—')}\n"
        f"IV: {round(float(s.get('iv_proxy', 0)) * 100)}%  Delta: {s.get('delta', '—')}"
    )


def signal_card(sig: TronSignal) -> str:
    s = sig.setup
    return (
        f"{config.BRAND}\n"
        f"{sig.title}\n"
        f"{sig.symbol_tv} | {sig.tf}m\n"
        f"{DIV}\n"
        f"{_fractal_block(sig)}\n"
        f"{DIV}\n"
        f"{_core_block(sig)}\n"
        f"{DIV}\n"
        f"BIAS: {sig.bias} — {sig.confidence}% conf\n"
        f"{DIV}\n"
        f"{_setup_block(sig)}\n"
        f"{DIV}\n"
        f"REGIME: {s.get('regime_strength', '—')}% | {s.get('regime_bars', '—')} bars\n"
        f"\n"
        f"Operator remarks:\n"
    )


def context_card(sig: TronSignal) -> str:
    return (
        f"{config.BRAND}\n"
        f"{sig.title}\n"
        f"{sig.symbol_tv} | {sig.tf}m | Spot {sig.spot}\n"
        f"{DIV}\n"
        f"{_fractal_block(sig)}\n"
        f"{DIV}\n"
        f"Bull {sig.raw.get('conf_bull', '?')}% | Bear {sig.raw.get('conf_bear', '?')}%\n"
        f"No action required. Context logged.\n"
    )


def trade_receipt(receipt: dict, sig: TronSignal, stake: float, origin: str) -> str:
    env_tag = "DEMO" if receipt["env"] == "demo" else "REAL"
    who = "Operator tap" if origin == "tap" else "Auto-trader"
    return (
        f"JARVIS EXECUTION — {env_tag}\n"
        f"{DIV}\n"
        f"{sig.title}\n"
        f"{sig.symbol_tv} → {receipt.get('longcode', '')}\n"
        f"{DIV}\n"
        f"Stake: ${stake:.2f}\n"
        f"Buy price: {receipt.get('buy_price')}\n"
        f"Payout: {receipt.get('payout', '—')}\n"
        f"Spot at buy: {receipt.get('spot_at_buy', '—')}\n"
        f"Contract ID: {receipt.get('contract_id')}\n"
        f"Origin: {who}\n"
        f"Account: {receipt.get('loginid')}\n"
    )


def governor_refusal(rule: str, reason: str) -> str:
    return (
        f"JARVIS — GOVERNOR VETO\n"
        f"{DIV}\n"
        f"Rule: {rule}\n"
        f"{reason}\n"
        f"Trade not placed. Logged to ledger.\n"
    )


def error_note(context: str, err: str) -> str:
    return (
        f"JARVIS — EXECUTION FAULT\n"
        f"{DIV}\n"
        f"{context}\n"
        f"Deriv said: {err}\n"
        f"Nothing was placed. Logged.\n"
    )


def boot_banner(account: dict) -> str:
    env_tag = "DEMO" if account.get("is_virtual") else "REAL"
    auto = "ON" if config.AUTO_TRADE else "OFF"
    return (
        f"JARVIS ONLINE\n"
        f"{DIV}\n"
        f"Account: {account.get('loginid')} ({env_tag})\n"
        f"Balance: {account.get('balance')} {account.get('currency')}\n"
        f"Auto-trader: {auto}\n"
        f"Governor: stake<=${config.STAKE_MAX:.0f} | "
        f"daily loss cap ${config.DAILY_LOSS_CAP:.0f} | "
        f"max {config.MAX_CONCURRENT} open\n"
        f"Listening for TRON.\n"
    )
