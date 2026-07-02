"""
JARVIS — The Ledger.
Every signal TRON ever fired, every trade Jarvis ever placed, every refusal
by the risk governor. Glassbox means the ledger is the product.
SQLite: zero-ops, lives next to the process, trivially backed up.
"""
import json
import sqlite3
import time
from contextlib import contextmanager

from . import config

SCHEMA = """
CREATE TABLE IF NOT EXISTS signals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ts REAL NOT NULL,
    signal TEXT NOT NULL,
    bias TEXT NOT NULL,
    mode TEXT NOT NULL,
    symbol_tv TEXT NOT NULL,
    tf TEXT,
    spot REAL,
    confidence INTEGER,
    tier TEXT NOT NULL,
    raw_json TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS trades (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ts REAL NOT NULL,
    signal_id INTEGER REFERENCES signals(id),
    env TEXT NOT NULL,               -- demo | real
    origin TEXT NOT NULL,            -- tap | auto
    contract_type TEXT NOT NULL,     -- VANILLALONGCALL, CALL, MULTUP, ...
    deriv_symbol TEXT NOT NULL,
    stake REAL NOT NULL,
    contract_id INTEGER,
    buy_price REAL,
    payout REAL,
    status TEXT NOT NULL,            -- placed | rejected | error | closed
    profit REAL,                     -- filled on close
    detail TEXT
);

CREATE TABLE IF NOT EXISTS governor_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ts REAL NOT NULL,
    rule TEXT NOT NULL,
    detail TEXT
);
"""


@contextmanager
def conn():
    c = sqlite3.connect(config.DB_PATH)
    c.row_factory = sqlite3.Row
    try:
        yield c
        c.commit()
    finally:
        c.close()


def init():
    with conn() as c:
        c.executescript(SCHEMA)


def log_signal(sig) -> int:
    with conn() as c:
        cur = c.execute(
            "INSERT INTO signals (ts, signal, bias, mode, symbol_tv, tf, spot, confidence, tier, raw_json)"
            " VALUES (?,?,?,?,?,?,?,?,?,?)",
            (time.time(), sig.signal, sig.bias, sig.mode, sig.symbol_tv, sig.tf,
             sig.spot, sig.confidence, sig.tier, json.dumps(sig.raw)),
        )
        return cur.lastrowid


def get_signal(signal_id: int) -> dict | None:
    with conn() as c:
        row = c.execute("SELECT * FROM signals WHERE id=?", (signal_id,)).fetchone()
        return dict(row) if row else None


def log_trade(signal_id, env, origin, contract_type, deriv_symbol, stake,
              status, contract_id=None, buy_price=None, payout=None, detail=None) -> int:
    with conn() as c:
        cur = c.execute(
            "INSERT INTO trades (ts, signal_id, env, origin, contract_type, deriv_symbol,"
            " stake, contract_id, buy_price, payout, status, detail)"
            " VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
            (time.time(), signal_id, env, origin, contract_type, deriv_symbol,
             stake, contract_id, buy_price, payout, status, detail),
        )
        return cur.lastrowid


def close_trade(contract_id: int, profit: float):
    with conn() as c:
        c.execute("UPDATE trades SET status='closed', profit=? WHERE contract_id=?",
                  (profit, contract_id))


def log_governor(rule: str, detail: str = ""):
    with conn() as c:
        c.execute("INSERT INTO governor_log (ts, rule, detail) VALUES (?,?,?)",
                  (time.time(), rule, detail))


def today_realized_loss(env: str) -> float:
    """Sum of negative realized profit since local midnight (server time)."""
    midnight = time.time() - (time.time() % 86400)
    with conn() as c:
        row = c.execute(
            "SELECT COALESCE(SUM(profit),0) s FROM trades"
            " WHERE env=? AND status='closed' AND profit<0 AND ts>=?",
            (env, midnight),
        ).fetchone()
        return abs(row["s"])


def open_trade_count(env: str) -> int:
    with conn() as c:
        row = c.execute(
            "SELECT COUNT(*) n FROM trades WHERE env=? AND status='placed'", (env,)
        ).fetchone()
        return row["n"]
