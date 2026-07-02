"""
JARVIS — Risk Governor.

The one piece of philosophy Jarvis owns that TRON doesn't.
TRON reads price. The Governor protects capital. Every trade — tapped or
auto — passes through here, and every refusal is logged and spoken.
Rules are checked in strict priority order, autopsy-style.
"""
from dataclasses import dataclass

from . import config, db


@dataclass
class Verdict:
    allowed: bool
    rule: str = ""
    reason: str = ""


def check(stake: float, origin: str, confidence: int = 0, signal: str = "") -> Verdict:
    env = config.DERIV_ENV

    # 1. Stake ceiling — absolute, no override
    if stake > config.STAKE_MAX:
        v = Verdict(False, "STAKE_CAP",
                    f"Stake ${stake:.2f} exceeds hard cap ${config.STAKE_MAX:.2f}")
        db.log_governor(v.rule, v.reason)
        return v

    # 2. Daily loss cap — realized losses today
    loss = db.today_realized_loss(env)
    if loss >= config.DAILY_LOSS_CAP:
        v = Verdict(False, "DAILY_LOSS_CAP",
                    f"Realized loss today ${loss:.2f} >= cap ${config.DAILY_LOSS_CAP:.2f}. "
                    f"Jarvis stands down until midnight.")
        db.log_governor(v.rule, v.reason)
        return v

    # 3. Concurrency ceiling
    open_n = db.open_trade_count(env)
    if open_n >= config.MAX_CONCURRENT:
        v = Verdict(False, "MAX_CONCURRENT",
                    f"{open_n} contracts already open (max {config.MAX_CONCURRENT})")
        db.log_governor(v.rule, v.reason)
        return v

    # 4. Auto-trade extra gates — humans may tap anything; the machine may not
    if origin == "auto":
        if not config.AUTO_TRADE:
            v = Verdict(False, "AUTO_DISABLED", "Auto-trader is OFF")
            db.log_governor(v.rule, v.reason)
            return v
        if signal not in config.AUTO_SIGNAL_WHITELIST:
            v = Verdict(False, "AUTO_WHITELIST",
                        f"{signal} not in auto whitelist {sorted(config.AUTO_SIGNAL_WHITELIST)}")
            db.log_governor(v.rule, v.reason)
            return v
        if confidence < config.AUTO_MIN_CONFIDENCE:
            v = Verdict(False, "AUTO_CONFIDENCE",
                        f"Confidence {confidence}% < auto floor {config.AUTO_MIN_CONFIDENCE}%")
            db.log_governor(v.rule, v.reason)
            return v

    return Verdict(True)
