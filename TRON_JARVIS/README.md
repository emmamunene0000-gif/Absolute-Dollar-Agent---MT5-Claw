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
│  • Liquidity    │              │  Human-in-loop: Jarvis recommends,│
│  • Confidence   │              │  operator approves, Deriv executes│
│                 │              └───────────────────────────────────┘
│  Emits:         │
│  Formatted      │
│  Telegram alerts│
│  (zero latency) │
└─────────────────┘
```

---

## TRON — The Deterministic Execution Spine

TRON is **100% stateless**. It does not know if you are in a trade. It does not count scale-ins. It does not track P&L. It only ever answers one question per bar:

> *"Given the current market state across all timeframes, what does the architecture see?"*

### The 8 Detection Engines

| Engine | What it computes | Key output |
|--------|-----------------|------------|
| MTF Trail | EMA+ATR trailing stop on Chart/M5/M15/H1/H4 | `ltf_trend`, `h4_trend` (Sovereign layer) |
| Market Structure (SMC) | Pivot HH/LH/HL/LL, BOS confirmation | `bullBOS`, `bearBOS` |
| RSI Momentum | Dual-TF RSI+EMA slope + sustain logic | `newSmartBull`, `newSmartBear` |
| VWAP Regime | Swing-anchored adaptive VWAP | `vwapBullish`, `vwapBearish` |
| Fib Bands | EMA-of-EMA basis + ATR fib multiples | `fibBullish`, `fibBearish` |
| Volume Profile | Session POC/VAH/VAL (8 session types) | `vp_bullish_conf`, `vp_bearish_conf` |
| **Liquidity Zones** | **Pivot-based S/R zones, break + retest detection** | **`liq_call_entry`, `liq_put_entry` (SNIPER)** |
| Confidence Engine | Weighted scoring of all above | `bull_conf_pct`, `bear_conf_pct` |

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

### The 4-Layer Fractal Sync (Sovereign Framework)

```
L1 Sovereign (H4)  — macro bias, never fight this
L2 Anchor    (H1)  — intraday direction
L3 Filter   (M15)  — trade-direction confirmation
L4 Exec    (M5/M1) — entry timing (chart timeframe)
```

All 4 layers must align for maximum conviction. TRON shows sync status live on the dashboard.

### Signal Hierarchy (most to least conviction)

```
⚡ SNIPER ENTRY       Liquidity zone retest — price returning to broken level
                      Trail + confidence gate BOTH required
                      Highest R:R — institutional zones act as magnets

⚡ ENTRY              Full ATM confluence met — all detection engines aligned
                      Confidence gate + deduplication passed

⚡ BREAK MOMENTUM     Zone structural break with trail confirmation
                      Continuation type — Brain decides: new entry or add

🔄 CONTINUATION       Momentum re-confirmed in trend direction
                      Brain decides: new entry or scale-in

🔀 REGIME SHIFT       Environment just changed (edge-only, single bar, not persistent)
                      Driven by: trail flip, VWAP edge, Fib edge, BOS, zone break

✅ CONFIDENCE PASS    Confidence threshold just crossed — watch for trigger

🏗 BOS               Break of structure confirmed
```

### Liquidity Zone Sniper Engine (detailed)

Zones are drawn at swing pivots (configurable lookback). When price breaks through a zone, the zone changes state from **active** to **broken**. A broken zone that price returns to becomes a **retest** — this is the sniper entry.

```
H-LIQ zone (resistance):
  Break upward  → bull_break_signal  → potential CALL BREAK momentum
  Retest back   → bull_retest_signal → SNIPER CALL (former resistance now support)

L-LIQ zone (support):
  Break downward → bear_break_signal  → potential PUT BREAK momentum + bearish regime flag
  Retest back    → bear_retest_signal → SNIPER PUT (former support now resistance)
```

**Why these are the best entries:**
- Institutional desks defend broken levels on retests
- Stop-loss hunters get shaken out on the initial break; retests offer cleaner fills
- The zone itself acts as natural SL reference — price failing to hold the retest = strong invalidation signal
- Sniper entries require both trail direction AND confidence gate, so they carry full architectural confirmation

**Zone breaks also drive regime exits:**
When support breaks (`bear_break_signal`) the system flags a **bearish regime shift** — any open CALL positions should be exited/defended. Same for `bull_break_signal` → **bullish regime shift** flags exit of PUT positions.

### Vanilla Options Engine

```
Strike Modes:
  ATM      current price (default — tight P/L, fast expiry)
  ITM      deeper strike, higher probability, lower payout
  OTM      aggressive, higher payout, lower probability
  Dynamic  confidence-adaptive: High (≥85%) → OTM | Med (≥70%) → ATM | Low → ITM

Expiry Formula (RR-based, scalp-optimised):
  rec_expiry = bars_to_TP × tf_min × regime_adj
  bars_to_TP = rr_tp_mult (ATR multiples to target, default 1.5)
  regime_adj = 0.75 (3+ layers aligned) | 1.0 (2 layers) | 1.3 (1 layer)
  Capped between min_expiry (2m default) and max_expiry (30m default)
```

---

## TRON Alerts — Telegram Native Format

Alerts fire directly from TradingView to Telegram via webhook. No relay server. No parser. The message IS the briefing.

### TradingView Alert Setup (Step-by-Step)

**1. Open TradingView → Alerts panel (clock icon)**

**2. Create Alert on TRON GBX indicator:**
```
Condition:    TRON — GLASSBOX SIGNAL GENERATOR
              Select any alertcondition from dropdown:
              • "Vanilla Call Entry"
              • "Vanilla Put Entry"
              • "Sniper Call Entry"        ← new, highest priority
              • "Sniper Put Entry"         ← new, highest priority
              • "Call Zone Break"
              • "Put Zone Break"
              • "Bullish Regime Shift"
              • "Bearish Regime Shift"
              • "Call Continuation"
              • "Put Continuation"
              • "Call Confidence Pass"
              • "Put Confidence Pass"
              • "Bullish BOS"
              • "Bearish BOS"

Alert Message: {{alert_message}}
Frequency:     Once Per Bar Close
```

**3. OR: Create one alert on ANY condition, set message to `{{alert_message}}`**

The `alert()` calls inside TRON already format the full Telegram briefing. They fire on every signal type automatically when the alert is triggered.

**4. Webhook URL for Telegram:**
```
https://api.telegram.org/bot<YOUR_BOT_TOKEN>/sendMessage?chat_id=<CHAT_ID>&text={{alert_message}}
```

Replace `<YOUR_BOT_TOKEN>` with your bot token from @BotFather and `<CHAT_ID>` with your channel or personal chat ID.

**5. Test it:**
- Force an alert on a test chart (lower timeframe with active signals)
- Confirm message lands in Telegram within seconds of bar close

### What a Signal Looks Like in Telegram

**Regular Entry:**
```
ABSOLUTE DOLLAR INTELLIGENCE
⚡ CALL ENTRY -- R_75 | 1m

FRACTAL 4-LAYER SYNC
L1 Sovereign H4: BULL
L2 Anchor    H1: BULL
L3 Filter   M15: BULL
L4 Exec      M5: BULL

CORE SIGNALS
Confidence: Bull 78% | Bear 32%
Structure:  Bullish BOS
VWAP:       Bullish
Fib:        Bullish

BIAS: CALL -- 78% conf | MTF: ALIGNED | KEY LEVEL

VANILLA OPTIONS SETUP
Strike: 7909.64 (ATM)  Expiry: 3m
Entry:  7912.40
SL:     7908.20  RR: 1:1.5
TP1/2/3: 7915.20 / 7918.00 / 7922.40

REGIME: 65% | ALIGNED | 8 bars
IV: 42%  Delta: 0.52  ATR: 3.2100
```

**Sniper Entry (zone retest):**
```
ABSOLUTE DOLLAR INTELLIGENCE
⚡ SNIPER CALL — Zone Retest -- R_75 | 1m

FRACTAL 4-LAYER SYNC
L1 Sovereign H4: BULL
...

BIAS: CALL -- 82% conf | MTF: ALIGNED | KEY LEVEL
...
```

---

## Operating TRON — Masterclass

### Recommended Settings by Trading Mode

**R_75 Scalping (1m/5m chart):**
```
Claw Mode:        Moderate (60%)
Strike Mode:      ATM
Max Expiry:       15m
Spatial Filter:   OFF (ATM breakouts naturally away from trail)
Show Zones:       ON  (activate sniper engine)
Dedup Bars:       3
MTF Trail:        55/14/1.25 (defaults)
```

**XAUUSD Swing (15m/1h chart):**
```
Claw Mode:        Conservative (80%)
Strike Mode:      Dynamic
Max Expiry:       30m
Spatial Filter:   ON (strong zones matter more on XAUUSD)
Show Zones:       ON
Dedup Bars:       5
```

**GBPUSD News-Driven (5m/15m chart):**
```
Claw Mode:        Aggressive (40%) during news, Moderate otherwise
Strike Mode:      ATM
Max Expiry:       20m
Show Zones:       ON
```

### Reading the Cognitive Dashboard

The dashboard has 8 sections:

| Section | What it shows |
|---------|--------------|
| Market Intelligence | Current bias, active signal, waiting condition |
| Fractal H1→M15→Now | H1 intraday truth, M15 tactical alignment, structure |
| CALL breakdown | Per-factor confidence scoring for bullish side |
| PUT breakdown | Per-factor confidence scoring for bearish side |
| Vanilla Options | Live strikes, expiry, continuation status |
| Execution | ATM trigger status, direction gate, confidence gate |
| Regime Intelligence | Strength score, IV proxy, RR ratio, delta |
| Signal P&L | Last entry vs current price (open signal tracker) |
| **Liquidity Zones** | **Sniper status, break status, zone count** |

### The Sniper Trade — Operating Procedure

1. Enable **Show Liquidity Zones** in section 2 inputs
2. Watch for **gold SNIPER CALL/PUT labels** on chart
3. When sniper fires:
   - Verify L1 Sovereign (H4) agrees with direction
   - Check dashboard: SNIPER CALL or SNIPER PUT shows in "I AM" row
   - Strike and Expiry pre-calculated — use them directly
   - SL = zone failure level (if price re-enters broken zone → invalidation)
4. Set TradingView alert on "Sniper Call Entry" / "Sniper Put Entry" in dropdown

### Regime Exit Signals — What to Watch For

TRON emits **regime shift alerts** on these events:

| Trigger | Meaning | Action |
|---------|---------|--------|
| Trail flip | Price crossed and closed past the trail | Flip direction bias |
| VWAP edge | VWAP swing anchor changed direction | Reassess intraday bias |
| Fib edge | Fib trend direction changed | Secondary confirmation of flip |
| BOS (structure) | Price broke key structure level | Strong conviction regime change |
| **Zone break** | **S or R zone structurally broken** | **Strongest exit signal — zones are where institutions set orders** |

**Zone breaks are the most actionable regime exit:** when support breaks below (`bear_break_signal`), the system immediately flags bearish regime shift. Any CALL position held past this point has lost its structural backing.

### Signal Deduplication

TRON tracks the last 3 entry bars per direction. Same-direction entries within `dedup_bars` (default 3) are suppressed. This prevents the system spamming you on ranging markets. Continuation signals are NOT deduplicated — those are intentional momentum confirmations the Brain uses for scale-in decisions.

### Confidence Gate Logic

```
Confidence Gate = (bull_score / bull_max) × 100 ≥ conf_threshold

Conservative  → 80%  (only SOVEREIGN conditions)
Moderate      → 60%  (healthy daily setups)
Aggressive    → 40%  (momentum plays, news)
Custom        → your value
```

A signal can fire ATM trigger without passing confidence — those show as **small unconfirmed dots** (grey circles above/below bar). Watch these when confidence is climbing toward the threshold.

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
    "scale_count": int,
    "entry_type": "SNIPER" | "ENTRY" | "BREAK" | "CONTINUATION"
}

episodic_memory = [
    {
        "event": "ENTRY",
        "bias": "PUT",
        "confidence": 78,
        "entry_type": "SNIPER",
        "architecture_state": { ... full snapshot ... },
        "outcome": "WIN | LOSS | PENDING"
    }
]
```

### Jarvis Telegram Briefing (scheduled + on-signal)

```
JARVIS MARKET BRIEF — R_75 | 01:15 UTC

H4 sovereign is bearish. Price has been in a clean distribution
phase since the London close. M15 BOS at 7920 confirmed. VWAP
and Fib both bear-aligned. L-LIQ zone at 7890 is broken and
price is retesting it now. Waiting on sniper PUT confirmation.

Active position: None
Confidence gate: 60% (Moderate)
Last signal: SNIPER CALL 23:42 UTC (WIN +$12.40)
```

### Execution Flow (Human-in-Loop)

```
1. Jarvis analyses → reaches signal (same as TRON)
2. Jarvis sends Telegram brief with tap-to-trade button
3. Operator reviews, taps EXECUTE
4. Order sent to Deriv API with expiry based on rec_expiry
5. Jarvis monitors position, sends exit alert at expiry or regime shift
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
| XAUUSD | Sniper mode + Conservative | Strong trend days, London/NY session |
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

> "Do we have liquidity trail entries? Those are super entries and they guide the rest especially when it comes to exits and regime shifts, we can with confidence consider exits as well."

---

## Build Sequence

- [x] Phase 0 — Ground truth locked (`TRON_GroundTruth_Locked.pine`)
- [x] Phase 1 — Glassbox signal generator (`TRON_Glassbox_SignalGenerator.pine`)
  - [x] Stateless — all position tracking removed
  - [x] 4-layer fractal sync (H4/H1/M15/M5)
  - [x] Edge-detected regime shifts (no spam)
  - [x] Telegram-native formatted alerts (zero middleware)
  - [x] RR-based expiry formula (ATR velocity model, scalp-capped)
  - [x] Regime strength scoring + quality tiers (SOVEREIGN/ALIGNED/MIXED/OPPOSED)
  - [x] IV proxy + delta approximation
  - [x] PnL tracker (last entry vs current price)
  - [x] Signal deduplication ring buffer
  - [x] Spatial confluence filter (optional)
  - [x] **Liquidity Zone Sniper Engine** — break + retest detection
  - [x] **Sniper entries wired into signal detection + alerts**
  - [x] **Zone breaks wired into regime shift exits**
  - [x] 14 alertcondition() entries (full dropdown in TradingView)
  - [x] Cognitive dashboard (40 rows — full architecture state at a glance)
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
