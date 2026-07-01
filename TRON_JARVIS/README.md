# TRON × JARVIS — Absolute Dollar Intelligence System

> *"The formula is simple. Analysis + Capital + Execution."*

---

## The Vision

Two entities. One organism.

**TRON** is from Ares — the warrior on the grid. It lives on the price chart, written in Pine Script. It sees everything: trend, structure, momentum, liquidity, confidence. It does not trade. It detects and emits.

**JARVIS** is from Iron Man — the intelligent operator. It lives in Python, connected to Telegram, Deriv API, and the Brain. It analyses, decides, communicates, and executes. Jarvis is Pinescript amplified — if you load TRON on a chart while Jarvis is running, they emit the same signal. That's the glass-box guarantee.

The marriage of both is **Absolute Dollar Intelligence** — a system that sees what institutional traders see, communicates it in plain language, and executes with machine precision on Deriv Vanilla Options.

---

## The Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│  TELEGRAM — Absolute Dollar Intelligence Channel                     │
│  Native formatted alerts — no middleware, direct from TradingView    │
│  Later: Jarvis briefings, tap-to-trade, mini web app                 │
└────────────────────────┬─────────────────────────────────────────────┘
                         │
         ┌───────────────┴────────────────┐
         │                                │
┌────────▼────────┐              ┌────────▼──────────────────────────┐
│  TRON           │              │  JARVIS                           │
│  Pine Script v6 │              │  Python / LLM Brain               │
│                 │              │                                   │
│  Lives on the   │              │  • Market analysis (Deriv API)    │
│  price grid     │              │  • Signal generation (Tron-parity)│
│                 │              │  • Position ledger & risk gate    │
│  Detects:       │              │  • Episodic memory                │
│  • MTF Trend    │◄─ validates ─│  • LLM narrative (2-3 sentences)  │
│  • Structure    │              │  • Telegram dispatch              │
│  • RSI Momentum │              │  • Deriv API execution (future)   │
│  • VWAP Regime  │              │  • MT5 bridge (future)            │
│  • Fib Bands    │              │  • Tap-to-trade mini app (future) │
│  • Volume Prof  │              │                                   │
│  • Confidence   │              │  Human-in-loop: Jarvis recommends,│
│                 │              │  operator approves, Deriv executes│
│  Emits:         │              └───────────────────────────────────┘
│  Formatted      │
│  Telegram alerts│
│  (zero latency) │
└─────────────────┘
```

---

## TRON — The Deterministic Execution Spine

TRON is **100% stateless**. It does not know if you are in a trade. It does not count scale-ins. It does not track P&L. It only ever answers one question per bar:

> *"Given the current market state across all timeframes, what does the architecture see?"*

### The 7 Detection Engines

| Engine | What it computes | Key output |
|--------|-----------------|------------|
| MTF Trail | EMA+ATR trailing stop on Chart/M5/M15/H1/H4 | `ltf_trend`, `h4_trend` (Sovereign layer) |
| Market Structure (SMC) | Pivot HH/LH/HL/LL, BOS confirmation | `bullBOS`, `bearBOS` |
| RSI Momentum | Dual-TF RSI+EMA slope + sustain logic | `newSmartBull`, `newSmartBear` |
| VWAP Regime | Swing-anchored adaptive VWAP | `vwapBullish`, `vwapBearish` |
| Fib Bands | EMA-of-EMA basis + ATR fib multiples | `fibBullish`, `fibBearish` |
| Volume Profile | Session POC/VAH/VAL (8 session types) | `vp_bullish_conf`, `vp_bearish_conf` |
| Confidence Engine | Weighted scoring of all 6 above | `bull_conf_pct`, `bear_conf_pct` |

### Confidence Weights

```
MTF Alignment   1.5 pts  ← most important (H1+M15 agree)
Structure       1.0 pts
RSI Momentum    1.0 pts
VWAP            1.0 pts
Fib             0.5 pts
Volume Profile  0.5 pts
─────────────────────────
Max             5.5 pts → normalized to %
```

### The 4-Layer Fractal Sync (your Sovereign framework)

```
L1 Sovereign (H4)  — macro bias, never fight this
L2 Anchor    (H1)  — intraday direction
L3 Filter   (M15)  — trade-direction confirmation  
L4 Exec    (M5/M1) — entry timing (chart timeframe)
```

All 4 layers must align for maximum conviction. TRON shows sync status live on the dashboard.

### Signal Types

```
⚡ ENTRY            Full confluence met — ATM trigger + confidence gate passed
🔄 CONTINUATION     Momentum re-confirmed in trend direction (Brain decides: new entry or scale-in)
🔀 REGIME SHIFT     Environment just changed (edge-only, single bar, not persistent)
✅ CONFIDENCE PASS  Confidence threshold just crossed — watch for trigger
🏗 BOS              Break of structure confirmed
```

### Vanilla Options Engine

```
Strike Modes:
  ATM      current price rounded to tick
  ITM      deeper strike, higher probability, lower payout
  OTM      aggressive, higher payout, lower probability
  Dynamic  confidence-adaptive: High (≥85%) → OTM | Med (≥70%) → ATM | Low → ITM

Expiry Formula:
  rec_expiry = tf_min × expiry_base × (1 + trend_magnitude×2 + vol_norm)
  Scales automatically with trend strength and volatility.
```

---

## TRON Alerts — Telegram Native Format

Alerts fire directly from TradingView to Telegram via webhook. No relay server. No parser. The message IS the briefing.

### TradingView Alert Setup

```
Alert Message:  {{alert_message}}
Webhook URL:    https://api.telegram.org/botYOUR_BOT_TOKEN/sendMessage
                (add ?chat_id=YOUR_CHAT_ID&text={{alert_message}})
Frequency:      Once Per Bar Close
```

### What a Signal Looks Like in Telegram

```
🚀ABSOLUTE💰DOLLAR💰INTELLIGENCE💯
📊 ⚡ PUT ENTRY — R_75 | 1m

FRACTAL 4-LAYER SYNC
L1 Sovereign (H4): 🔴 BEAR
L2 Anchor   (H1):  🔴 BEAR
L3 Filter  (M15):  🔴 BEAR
L4 Exec    (M5):   🔴 BEAR

CORE SIGNALS
Confidence: Bear 78% | Bull 32%
Structure:  Bearish BOS
VWAP:       Bearish
Fib:        Bearish

BIAS: 📉 PUT — 78% confidence

VANILLA OPTIONS SETUP
Strike:  7909.64 (Dynamic)
Expiry:  8 minutes
Entry:   7912.40

Signal: ⚡ PUT ENTRY | Gate: 60% | MTF: ALIGNED ✅
```

---

## JARVIS — The Cognitive Brain (Next Phase)

Jarvis is Tron amplified. Everything Tron sees on a chart, Jarvis computes independently via the Deriv API — and reaches the same conclusion. This is the glass-box guarantee: **load TRON on a chart while Jarvis is running and they say the same thing**.

### What Jarvis Owns (that Pine never touches)

```python
position_ledger = {
    "is_in_trade": bool,
    "direction": "CALL" | "PUT",
    "entry_price": float,
    "entry_time": datetime,
    "strike": float,
    "expiry": datetime,
    "scale_count": int
}

episodic_memory = [
    {
        "event": "ENTRY",
        "bias": "PUT",
        "confidence": 78,
        "architecture_state": { ... full snapshot ... },
        "outcome": "WIN | LOSS | PENDING"
    }
]
```

### Jarvis Telegram Briefing (scheduled + on-signal)

```
🧠 JARVIS MARKET BRIEF — R_75 | 01:15 UTC

H4 sovereign is bearish. Price has been in a clean distribution 
phase since the London close. M15 BOS at 7920 confirmed. VWAP 
and Fib both bear-aligned. Waiting on M5 continuation for a 
PUT entry at dynamic strike 7890.

Active position: None
Confidence gate: 60% (Moderate)
Last signal: PUT ENTRY 23:42 UTC (WIN +$12.40)
```

### Execution Flow (Human-in-Loop)

```
1. Jarvis analyses → reaches signal (same as TRON)
2. Jarvis sends Telegram brief with tap-to-trade button
3. Operator reviews, taps EXECUTE
4. Order sent to Deriv API with expiry based on rec_expiry
5. Jarvis monitors position, sends exit alert at expiry
```

### Later: Full Autonomy Mode

```
Jarvis receives signal → risk gate passes → Deriv API executes
Human is notified (not asked). Stop-loss embedded in option structure.
```

---

## Project Files

```
TRON_JARVIS/
├── README.md                          ← you are here — the full vision
│
├── Pine Script (TRON)
│   ├── TRON_Glassbox_SignalGenerator.pine  ← ACTIVE — stateless, Telegram-ready
│   └── TRON_GroundTruth_Locked.pine        ← frozen baseline (never edit)
│
├── Legacy / Reference
│   ├── TronAgent_Spine.pine
│   ├── VanillaAgent_DerivOptions.pine
│   ├── AgentProtocol_LiquiditySuite.mq5
│   ├── Agent - Liquidity Suite.txt
│   ├── Agent V7 Strategy - Tradesgnl.txt
│   └── June TradeSgnl Syntax.txt
│
└── (coming) Jarvis/
    ├── brain.py                       ← position ledger, episodic memory
    ├── signal_engine.py               ← Tron-parity analysis (Deriv API)
    ├── telegram_bot.py                ← briefing dispatch, tap-to-trade
    ├── deriv_client.py                ← execution bridge
    └── config.yaml                    ← pairs, risk params, session filters
```

---

## Pairs & Deployment

| Pair | Mode | Why |
|------|------|-----|
| R_75 (Volatility 75) | All signals — primary | High volatility, clean structure, 24/7 |
| XAUUSD | Sniper mode only | Strong trend days, London/NY session |
| GBPUSD | ATM + Smart | News-driven momentum, predictable BOS |

---

## The Formula

```
Analysis   → TRON sees it. Jarvis confirms it.
Capital    → Deriv Vanilla Options (defined risk, no stop-hunt)
Execution  → Human-in-loop now. Autonomous later.
```

**Vanilla Options are the perfect vehicle**: risk is capped at premium paid (no stop-losses getting hunted), upside is uncapped, expiry aligns with the signal timeframe.

---

## Conversation Lock — The Origin Story

*Captured from the founding session, verbatim:*

> "Tron from Ares. And Jarvis from Iron Man. A Tron-Jarvis for trading vanilla options and perpetual futures. Tron needs to design itself first in Pinescript — that's the Tron version of itself. It lives on the price grid. Jarvis does market analysis, uses the Deriv API to extract data, researches opportunities based on the Tron architecture. Jarvis also executes and makes Tron smarter."

> "The formula is simple. Analysis + Capital + Execution — our intraday momentum trading formula to success with risk management."

> "Jarvis even its analysis is Pinescript amplified. If it sends a signal and you load the Pine agent we get the same thing. This way we have a system that's glass box and makes money."

> "Later we can build a tap-to-trade app... a telegram alert... if you execute, order is sent to Deriv/MT5 with an expiry based on the signal event."

---

## Build Sequence

- [x] Phase 0 — Ground truth locked (`TRON_GroundTruth_Locked.pine`)
- [x] Phase 1 — Glassbox signal generator (`TRON_Glassbox_SignalGenerator.pine`)
  - [x] Stateless — all position tracking removed
  - [x] 4-layer fractal sync (H4/H1/M15/M5)
  - [x] Edge-detected regime shifts (no spam)
  - [x] Telegram-native formatted alerts (zero middleware)
- [ ] Phase 2 — Jarvis Brain (Python)
  - [ ] Deriv API data feed
  - [ ] Tron-parity signal engine
  - [ ] Position ledger + episodic memory
  - [ ] Telegram bot + briefings
  - [ ] LLM narrative generation (Claude API)
- [ ] Phase 3 — Execution
  - [ ] Deriv API order execution
  - [ ] Human-in-loop tap-to-trade
  - [ ] Risk gate (daily limits, session filters)
- [ ] Phase 4 — Mini App
  - [ ] Telegram mini app (tap-to-trade UI)
  - [ ] Live dashboard (positions, P&L, signal history)
  - [ ] Bybit perpetual futures (after Deriv mastery)
