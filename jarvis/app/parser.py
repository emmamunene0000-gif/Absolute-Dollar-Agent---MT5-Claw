"""
JARVIS — Parser & Tier Classifier.

TRON emits everything it sees. Jarvis decides what deserves a human's
attention, what deserves a tap-to-trade card, and what is ambient context.

Tier constitution (mirrors the ADI 3-tier broadcast doctrine):
  TIER_EXECUTE — actionable entries → tap-to-trade card to operator
  TIER_CONTEXT — regime intelligence → informational message, no buttons
  TIER_NOISE   — logged to the ledger, never spoken
"""
from dataclasses import dataclass, field
from typing import Any

TIER_EXECUTE = "EXECUTE"
TIER_CONTEXT = "CONTEXT"
TIER_NOISE = "NOISE"

EXECUTE_SIGNALS = {
    "H4_FLIP_CALL", "H4_FLIP_PUT",
    "SNIPER_CALL", "SNIPER_PUT",
    "MTF_FLIP_CALL", "MTF_FLIP_PUT",
    "TRAIL_FLIP_CALL", "TRAIL_FLIP_PUT",
    "CALL_ENTRY", "PUT_ENTRY",
}

CONTEXT_SIGNALS = {
    "BULL_REGIME_SHIFT", "BEAR_REGIME_SHIFT",
    "CALL_ZONE_BREAK", "PUT_ZONE_BREAK",
    "CALL_CONTINUATION", "PUT_CONTINUATION",
}

NOISE_SIGNALS = {
    "BULL_BOS", "BEAR_BOS",  # ledger-only; structure is context inside entries already
}

# Human-readable signal names in Jarvis's voice
SIGNAL_TITLES = {
    "H4_FLIP_CALL": "H4 SOVEREIGN FLIP — CALL",
    "H4_FLIP_PUT": "H4 SOVEREIGN FLIP — PUT",
    "SNIPER_CALL": "SNIPER CALL — Zone Retest",
    "SNIPER_PUT": "SNIPER PUT — Zone Retest",
    "MTF_FLIP_CALL": "MTF FLIP CALL — M15/H1 Trail",
    "MTF_FLIP_PUT": "MTF FLIP PUT — M15/H1 Trail",
    "TRAIL_FLIP_CALL": "TRAIL FLIP CALL — New Regime",
    "TRAIL_FLIP_PUT": "TRAIL FLIP PUT — New Regime",
    "CALL_ENTRY": "CALL ENTRY — Full Confluence",
    "PUT_ENTRY": "PUT ENTRY — Full Confluence",
    "BULL_REGIME_SHIFT": "BULLISH REGIME SHIFT",
    "BEAR_REGIME_SHIFT": "BEARISH REGIME SHIFT",
    "CALL_ZONE_BREAK": "CALL BREAK — Zone Momentum",
    "PUT_ZONE_BREAK": "PUT BREAK — Zone Momentum",
    "CALL_CONTINUATION": "CALL CONTINUATION",
    "PUT_CONTINUATION": "PUT CONTINUATION",
    "BULL_BOS": "BULLISH BOS",
    "BEAR_BOS": "BEARISH BOS",
}


@dataclass
class TronSignal:
    """Validated TRON payload with Jarvis's classification attached."""
    raw: dict[str, Any]
    signal: str
    bias: str            # CALL | PUT
    mode: str            # vanilla | rise_fall | multiplier
    symbol_tv: str
    tf: str
    spot: float
    confidence: int
    fractal: dict = field(default_factory=dict)
    core: dict = field(default_factory=dict)
    setup: dict = field(default_factory=dict)
    tier: str = TIER_NOISE

    @property
    def title(self) -> str:
        return SIGNAL_TITLES.get(self.signal, self.signal)

    @property
    def expiry_min(self) -> int:
        return int(self.setup.get("expiry_min", 5))

    @property
    def strike(self) -> float:
        return float(self.setup.get("strike", self.spot))


class ParseError(Exception):
    pass


def parse(payload: dict[str, Any]) -> TronSignal:
    """Validate a TRON webhook body. Raise ParseError on anything malformed —
    Jarvis never guesses on money-adjacent data."""
    if not isinstance(payload, dict):
        raise ParseError("payload is not a JSON object")
    if payload.get("engine") != "TRON_GBX_v3":
        raise ParseError(f"unknown engine: {payload.get('engine')!r}")

    try:
        sig = TronSignal(
            raw=payload,
            signal=str(payload["signal"]).upper(),
            bias=str(payload["bias"]).upper(),
            mode=str(payload.get("mode", "vanilla")).lower(),
            symbol_tv=str(payload["symbol"]).upper(),
            tf=str(payload.get("tf", "?")),
            spot=float(payload["spot"]),
            confidence=int(payload.get("confidence", 0)),
            fractal=payload.get("fractal", {}) or {},
            core=payload.get("core", {}) or {},
            setup=payload.get("setup", {}) or {},
        )
    except (KeyError, TypeError, ValueError) as e:
        raise ParseError(f"malformed field: {e}") from e

    if sig.bias not in ("CALL", "PUT"):
        raise ParseError(f"invalid bias {sig.bias!r}")
    if sig.mode not in ("vanilla", "rise_fall", "multiplier"):
        raise ParseError(f"invalid mode {sig.mode!r}")

    sig.tier = classify(sig)
    return sig


def classify(sig: TronSignal) -> str:
    if sig.signal in EXECUTE_SIGNALS:
        return TIER_EXECUTE
    if sig.signal in CONTEXT_SIGNALS:
        return TIER_CONTEXT
    return TIER_NOISE
