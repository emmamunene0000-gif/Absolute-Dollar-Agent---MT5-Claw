"""
JARVIS — Deriv Execution Hand.

One WebSocket pipeline, three weapons:
  vanilla    → VANILLALONGCALL / VANILLALONGPUT  (strike + expiry)
  rise_fall  → CALL / PUT                        (direction + expiry)
  multiplier → MULTUP / MULTDOWN                 (+ optional TP/SL limit orders)

Flow per trade: connect → authorize → proposal → buy → report.
Glassbox rule: the proposal (Deriv's own quote) is always surfaced to the
operator before/with execution — no hidden pricing.
"""
import asyncio
import json
import logging

import websockets

from . import config

log = logging.getLogger("jarvis.deriv")

CONTRACT_MAP = {
    ("vanilla", "CALL"): "VANILLALONGCALL",
    ("vanilla", "PUT"): "VANILLALONGPUT",
    ("rise_fall", "CALL"): "CALL",
    ("rise_fall", "PUT"): "PUT",
    ("multiplier", "CALL"): "MULTUP",
    ("multiplier", "PUT"): "MULTDOWN",
}


class DerivError(Exception):
    pass


class DerivClient:
    """Short-lived connection per operation. Simple, stateless, resilient —
    matches the TRON philosophy: no long-lived position state in the pipe."""

    def __init__(self, token: str | None = None):
        self.token = token or config.active_token()
        if not self.token:
            raise DerivError(f"No Deriv token configured for env '{config.DERIV_ENV}'")

    async def _call(self, ws, request: dict) -> dict:
        await ws.send(json.dumps(request))
        while True:
            resp = json.loads(await asyncio.wait_for(ws.recv(), timeout=15))
            if "error" in resp:
                raise DerivError(resp["error"].get("message", str(resp["error"])))
            # skip unrelated subscription pushes
            if resp.get("msg_type") in (request_msg_type(request), "authorize", "proposal",
                                         "buy", "proposal_open_contract", "balance"):
                return resp

    async def _session(self):
        ws = await websockets.connect(config.DERIV_WS_URL, open_timeout=15)
        auth = await self._call(ws, {"authorize": self.token})
        return ws, auth["authorize"]

    async def account_info(self) -> dict:
        ws, auth = await self._session()
        try:
            bal = await self._call(ws, {"balance": 1})
            return {
                "loginid": auth.get("loginid"),
                "currency": auth.get("currency"),
                "is_virtual": bool(auth.get("is_virtual")),
                "balance": bal["balance"]["balance"],
            }
        finally:
            await ws.close()

    def _build_proposal(self, mode: str, bias: str, symbol: str, stake: float,
                        expiry_min: int, strike: float | None,
                        tp: float | None, sl: float | None) -> dict:
        ct = CONTRACT_MAP.get((mode, bias))
        if ct is None:
            raise DerivError(f"No contract mapping for mode={mode} bias={bias}")

        p: dict = {
            "proposal": 1,
            "contract_type": ct,
            "symbol": symbol,
            "currency": "USD",
            "amount": round(stake, 2),
            "basis": "stake",
        }

        if mode in ("vanilla", "rise_fall"):
            p["duration"] = max(1, int(expiry_min))
            p["duration_unit"] = "m"

        if mode == "vanilla":
            # Deriv vanillas take an absolute barrier (the strike TRON computed).
            if strike is None:
                raise DerivError("vanilla mode requires a strike")
            p["barrier"] = str(strike)
        elif mode == "multiplier":
            p["multiplier"] = config.MULTIPLIER_DEFAULT
            limits = {}
            if tp is not None:
                limits["take_profit"] = round(abs(tp), 2)
            if sl is not None:
                limits["stop_loss"] = round(abs(sl), 2)
            if limits:
                p["limit_order"] = limits
        return p

    async def quote(self, **kw) -> dict:
        """Get Deriv's live proposal without buying — the glassbox price check."""
        ws, _ = await self._session()
        try:
            prop = await self._call(ws, self._build_proposal(**kw))
            return prop["proposal"]
        finally:
            await ws.close()

    async def buy(self, mode: str, bias: str, symbol: str, stake: float,
                  expiry_min: int = 5, strike: float | None = None,
                  tp_amount: float | None = None, sl_amount: float | None = None) -> dict:
        """proposal → buy in one session. Returns contract receipt."""
        ws, auth = await self._session()
        try:
            req = self._build_proposal(mode, bias, symbol, stake, expiry_min,
                                       strike, tp_amount, sl_amount)
            prop = (await self._call(ws, req))["proposal"]
            buy = await self._call(ws, {"buy": prop["id"], "price": prop["ask_price"]})
            receipt = buy["buy"]
            return {
                "env": "demo" if auth.get("is_virtual") else "real",
                "loginid": auth.get("loginid"),
                "contract_id": receipt["contract_id"],
                "buy_price": receipt["buy_price"],
                "payout": receipt.get("payout"),
                "longcode": receipt.get("longcode"),
                "ask_quote": prop.get("display_value"),
                "spot_at_buy": prop.get("spot"),
            }
        finally:
            await ws.close()

    async def contract_status(self, contract_id: int) -> dict:
        ws, _ = await self._session()
        try:
            resp = await self._call(ws, {"proposal_open_contract": 1,
                                         "contract_id": contract_id})
            poc = resp["proposal_open_contract"]
            return {
                "is_sold": bool(poc.get("is_sold")),
                "profit": poc.get("profit"),
                "status": poc.get("status"),
                "current_spot": poc.get("current_spot"),
                "longcode": poc.get("longcode"),
            }
        finally:
            await ws.close()


def request_msg_type(request: dict) -> str:
    for k in ("proposal", "buy", "balance", "authorize", "proposal_open_contract"):
        if k in request:
            return k if k != "proposal_open_contract" else "proposal_open_contract"
    return ""
