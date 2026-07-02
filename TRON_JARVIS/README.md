# TRON × JARVIS — Absolute Dollar Intelligence System

> *"The formula is simple. Analysis + Capital + Execution."*

---

## The Vision

Two entities. One organism.

**TRON** is from Ares — the warrior on the grid. It lives on the price chart, written in Pine Script. It sees everything: trend, structure, momentum, liquidity, confidence. It does not trade. It detects and emits.

**JARVIS** is from Iron Man — the intelligent operator. It lives in Python, connected to Telegram, Deriv API, and the Brain. It analyses, decides, communicates, and executes. Jarvis is Pinescript amplified — if you load TRON on a chart while Jarvis is running, they emit the same signal. That's the glass-box guarantee.

The marriage of both is **Absolute Dollar Intelligence** — a system that sees what institutional traders see, communicates it in plain language, and executes with machine precision on Deriv Vanilla Options and Rise/Fall contracts.

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
│  • Trail Flips  │              │  operator approves, Deriv executes│
│  • Confidence   │              └───────────────────────────────────┘
│                 │
│  Emits:         │
│  Formatted      │
│  Telegram alerts│
│  (zero latency) │
└─────────────────┘
```

---

## Signal Hierarchy — Most to Least Conviction

This is the complete priority order TRON uses. When multiple signals fire on the same bar, the highest-tier one takes the dashboard headline.

```
TIER 1 — SOVEREIGN              (cyan label, largest)
──────────────────────────────────────────────────────
⚡ H4 SOVEREIGN FLIP            H4 trail just flipped direction.
                                This is the macro regime changing.
                                Trade every contract type on this.
                                SL/TP lines drawn automatically.

TIER 2 — MTF SNIPER             (purple label)
──────────────────────────────────────────────────────
⚡ MTF FLIP CALL/PUT            M15 or H1 trail flipped with chart
                                trail agreement + confidence pass.
                                Institutional momentum shift confirmed.

⚡ SNIPER CALL/PUT              Zone retest: price returning to a
  (zone retest)                 broken level. Trail + conf required.
                                Institutions defend broken levels.

TIER 3 — ENTRY                  (green/red label)
──────────────────────────────────────────────────────
⚡ TRAIL FLIP CALL/PUT          Chart trail flipped with MTF partial
                                support + confidence pass.
                                Good entry, cleaner than ATM.

⚡ CALL/PUT ENTRY               Full ATM confluence: all 7 engines
                                aligned, confidence gate passed,
                                deduplication cleared.

TIER 4 — MOMENTUM               (teal/maroon label)
──────────────────────────────────────────────────────
⚡ BREAK CALL/PUT               Zone structural break with trail
                                alignment. Momentum continuation.

🔄 CALL/PUT CONTINUATION        RSI momentum re-confirmed in trend
                                direction. Scale or new entry.

TIER 5 — CONTEXT                (orange label)
──────────────────────────────────────────────────────
🔀 REGIME SHIFT                 Environment changed. Driven by:
                                trail flip, VWAP edge, Fib edge,
                                BOS, or zone break.

✅ CONFIDENCE PASS              Threshold just crossed. Watch for
                                trigger on next bar.

🏗 BOS                          Break of structure confirmed.
```

---

## The 8 Detection Engines

| Engine | What it computes | Key output |
|--------|-----------------|------------|
| MTF Trail | EMA+ATR trailing stop on Chart/M5/M15/H1/H4 | `ltf_trend`, flip signals per TF |
| Market Structure (SMC) | Pivot HH/LH/HL/LL, BOS confirmation | `bullBOS`, `bearBOS` |
| RSI Momentum | Dual-TF RSI+EMA slope + sustain logic | `newSmartBull`, `newSmartBear` |
| VWAP Regime | Swing-anchored adaptive VWAP | `vwapBullish`, `vwapBearish` |
| Fib Bands | EMA-of-EMA basis + ATR fib multiples | `fibBullish`, `fibBearish` |
| Volume Profile | Session POC/VAH/VAL (8 session types) | `vp_bullish_conf`, `vp_bearish_conf` |
| Liquidity Zones | Pivot S/R zones, break + retest detection | `liq_call_entry`, `liq_put_entry` |
| Confidence Engine | Weighted scoring of all above | `bull_conf_pct`, `bear_conf_pct` |

### The 4-Layer Fractal Sync

```
L1 Sovereign (H4)  — macro bias, never fight this
L2 Anchor    (H1)  — intraday direction
L3 Filter   (M15)  — trade-direction confirmation
L4 Exec    (M5/M1) — entry timing (chart timeframe)
```

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

---

## Trail Flip Snipers — The Masterclass

The **trail flip** is the cleanest entry in the system. The diamond marker you see on the chart — when the EMA+ATR trail changes direction — IS the institutional momentum shift. Every other signal is confirming what the trail already knows.

### Why Trail Flips Are the Best Entries

1. **They mark the exact bar the regime changed** — not the 3rd or 5th bar after
2. **The trail IS the trend** — it's not a lagging indicator, it's the structural definition
3. **They compound with timeframes** — an H4 flip changes the entire macro picture; an M15 flip changes the intraday picture; a chart flip is your execution bar
4. **They give natural SL placement** — if price comes back through the trail after a flip, the setup is invalidated. That IS the stop-loss.

### How to Read the Flip Signals

**H4 Sovereign Flip (cyan, LARGE label):**
```
What happened: The H4 EMA+ATR trail changed direction
What it means: Macro regime changed — institutions are repositioning
What to do:    Enter on chart timeframe, hold through retracements
               Use rec_expiry × 2 for Vanilla (regime needs time to develop)
               For Rise/Fall: use 15-30m expiry minimum
               SL = trail level (drawn on chart automatically)
               TP1/2/3 = ATR-based levels (drawn on chart automatically)
```

**MTF Flip — M15 or H1 (purple label):**
```
What happened: M15 or H1 trail flipped with chart trail agreement
What it means: Intraday regime confirmed at two timeframes
What to do:    Strong entry, momentum is fresh
               Standard expiry applies (rec_expiry)
               Trail flip = new regime, not a retest — enter immediately
```

**Chart Trail Flip (fuchsia label):**
```
What happened: Chart timeframe trail flipped with partial MTF support
What it means: Execution-level momentum confirmed
What to do:    Good entry, slightly less conviction than MTF flip
               Watch that H1/M15 doesn't contradict
```

### SL/TP Lines — Reading Them

When any entry fires (flip, sniper, standard), TRON draws:
- **Red dashed line** = Stop Loss level (price crossing back here = invalidation)
- **Dotted green/red lines** = TP1, TP2, TP3 (scale out targets)
- **Small labels** at each line: SL / TP1 / TP2 / TP3

For **Vanilla Options** — the SL line is your reference for sizing the premium (if SL is far, the option premium should be small / use ATM). For **Rise/Fall** — these are profit reference levels, the contract expires at rec_expiry regardless.

**SL/TP formula:**
```
SL   = entry ± (ATR × rr_sl_mult)    default: 1.0× ATR
TP1  = entry ± (ATR × rr_tp_mult)    default: 1.5× ATR
TP2  = entry ± (ATR × rr_tp_mult×2)  default: 3.0× ATR
TP3  = entry ± (ATR × rr_tp_mult×3.5) default: 5.25× ATR
```

For **Rise/Fall contracts**, TP1 = your minimum target, TP2 = comfortable win, TP3 = if momentum is strong.

---

## Deriv Products — Vanilla Options vs Rise/Fall

Both are supported by TRON. Switch in **section 0 inputs** → Trading Mode.

### Vanilla Options (default)

```
You buy a contract with:
  Strike:  ATM = current price (or ITM/OTM/Dynamic)
  Expiry:  rec_expiry minutes
  Risk:    premium paid only (no stop-hunt, risk capped)
  Upside:  unlimited — payout = max(spot - strike, 0) for CALL
           payout = max(strike - spot, 0) for PUT

Best for:  High-conviction setups. Sovereign flips, sniper entries.
           Momentum that needs room to develop.
```

### Rise/Fall (binary direction)

```
You predict: will price be higher (RISE) or lower (FALL) at expiry?
  Direction: RISE = CALL side, FALL = PUT side
  Expiry:    rec_expiry minutes (same formula)
  Strike:    NOT needed — contract is purely directional
  Risk:      stake only — fixed payout if correct, lose stake if wrong

Alert format: "Direction: RISE  Expiry: 3m  Spot: 48,366.61"

Best for:  Scalp flips. Trail flip snipers on 1m/5m chart.
           Fast momentum signals where direction is cleaner than magnitude.
           News-driven moves. Short expiries (1m-5m).
```

### When to Use Which

| Signal Type | Best Contract |
|------------|--------------|
| H4 Sovereign Flip | Vanilla Options (magnitude expected) |
| MTF Flip | Either — Vanilla for high conf, Rise/Fall for speed |
| Chart Trail Flip | Rise/Fall (quick directional scalp) |
| Zone Retest (Sniper) | Vanilla Options (price should hold and rally) |
| Zone Break | Rise/Fall (momentum continuation) |
| Continuation | Rise/Fall (momentum already running) |

**Deriv API Reference:** https://developers.deriv.com/docs/

---

## TradingView Alert Setup — Complete Walkthrough

### Step 1: Load TRON on a Chart
Add `TRON — GLASSBOX SIGNAL GENERATOR` as an indicator on your chart. Recommended timeframes: 1m, 5m, 15m.

### Step 2: Create Your Telegram Bot
1. Message @BotFather on Telegram → `/newbot`
2. Save your bot token: `123456789:ABCdefGHI...`
3. Get your chat ID: message @userinfobot or use `https://api.telegram.org/bot<TOKEN>/getUpdates` after sending a test message

### Step 3: Create the Alert in TradingView

**Option A — Catch all signals with one alert:**
```
Alert on:  TRON — GLASSBOX SIGNAL GENERATOR → any()
Message:   {{alert_message}}
Frequency: Once Per Bar Close
Webhook:   https://api.telegram.org/bot<TOKEN>/sendMessage?chat_id=<CHAT_ID>&text={{alert_message}}
```

**Option B — Priority alerts only (recommended for live trading):**
Create separate alerts for each high-tier signal:

| Alert Name | alertcondition | Priority |
|-----------|----------------|----------|
| H4 Sovereign Flip Call | "H4 Sovereign Flip Call" | TIER 1 |
| H4 Sovereign Flip Put | "H4 Sovereign Flip Put" | TIER 1 |
| MTF Flip Call | "MTF Flip Call (M15/H1)" | TIER 2 |
| MTF Flip Put | "MTF Flip Put (M15/H1)" | TIER 2 |
| Sniper Call | "Sniper Call Entry" | TIER 2 |
| Sniper Put | "Sniper Put Entry" | TIER 2 |
| Call Entry | "Vanilla Call Entry" | TIER 3 |
| Put Entry | "Vanilla Put Entry" | TIER 3 |
| Regime Shift | "Bullish/Bearish Regime Shift" | CONTEXT |

### Step 4: Verify

Send a test. The Telegram message should appear within 2 seconds of bar close. If it doesn't arrive:
- Check bot token and chat ID
- Ensure alert frequency = "Once Per Bar Close" not "Once"
- Confirm webhook URL has no spaces

---

## How to Act on Every Alert Type

This is the operator protocol. Read this before going live.

### ⚡ H4 SOVEREIGN FLIP — CALL / PUT

**What fired:** H4 trail changed direction. Macro regime is new.

**Action:**
1. Check dashboard — `I AM` row shows `H4 FLIP CALL` or `H4 FLIP PUT`
2. Check that L1 Sovereign in Fractal Sync now matches the new direction
3. Look at current bar — SL line is drawn at the trail level
4. Execute on the NEXT candle open (sovereign flips are fresh, don't chase)
5. Vanilla Options: use the provided Strike + Expiry. Consider extending expiry to `rec_expiry × 2` for sovereign moves
6. Rise/Fall: direction is the signal, expiry = rec_expiry minimum 15m

**Do NOT enter if:** L2 (H1) is still strongly opposing — wait for H1 to confirm. A sovereign flip alone without H1 alignment is a watch signal, not an entry.

---

### ⚡ MTF FLIP CALL/PUT — M15/H1 Trail

**What fired:** M15 or H1 trail flipped, chart trail agrees, confidence passed.

**Action:**
1. This IS the intraday regime change. Enter now.
2. Strike = as shown in alert. Expiry = rec_expiry (typically 3-10m on 1m chart)
3. SL line drawn on chart — if price closes back through trail, exit
4. Ride to TP1 minimum. TP2 if regime quality = ALIGNED or SOVEREIGN

**Rise/Fall version:** Enter RISE or FALL per the alert direction, expiry = rec_expiry.

---

### ⚡ SNIPER CALL/PUT — Zone Retest

**What fired:** Price returned to a previously broken S/R zone with trail + confidence aligned.

**Action:**
1. The zone itself acts as SL reference — if price fails to hold the zone (re-enters it), exit
2. Enter at current price (ATM) — the zone retest IS the entry
3. TP targets: TP1 = first clear air, TP2 = next zone above/below
4. Highest RR setup in the system — zone provides natural stop distance

---

### ⚡ TRAIL FLIP CALL/PUT

**What fired:** Chart trail flipped with partial MTF support + confidence.

**Action:**
1. Enter in flip direction. Quicker expiry (rec_expiry or less)
2. Lower conviction than MTF flip — size accordingly
3. If H1 opposes: use Rise/Fall (short expiry) rather than Vanilla

---

### 🔄 CALL/PUT CONTINUATION

**What fired:** RSI momentum re-confirmed in existing trend direction.

**Action:** If in a trade already → this is your scale-in confirmation. If not in trade → enter with reduced size (trend is not fresh). Don't enter against existing opposite position.

---

### 🔀 REGIME SHIFT

**What fired:** VWAP, Fib, trail, or zone changed direction.

**Action:** This is an EXIT signal, not an entry. If holding a CALL when BEARISH REGIME SHIFT fires → consider exit. If holding PUT when BULLISH REGIME SHIFT fires → consider exit. Brain processes these for position management.

---

### ✅ CONFIDENCE PASS

**What fired:** Confidence just crossed the threshold. No trigger yet.

**Action:** Watch. Next ATM crossover in the same direction = entry. Set a manual alert or watch the chart.

---

## Operating Modes

### Vanilla Options Mode

Dashboard shows: Strike (ATM/ITM/OTM/Dynamic), Expiry in minutes, Delta, IV proxy.
Alerts include: Strike level, Entry price, SL/TP levels.

```
Recommended: ATM strike for most setups
             Dynamic strike for high-confidence sovereign flips (goes OTM for max payout)
             ITM when you want higher probability lower payout
```

### Rise/Fall Mode

Dashboard shows: Direction (RISE/FALL), Expiry in minutes.
Alerts include: Direction, Spot price at signal, SL/TP as reference levels (not contract parameters).

```
Set in inputs → Section 0 → Trading Mode → "Rise/Fall"

Alert format changes to:
  Direction: RISE  Expiry: 3m  Spot: 48,366.61
  SL ref: 48,340.00  RR: 1:1.5
  TP ref: 48,391.00 / 48,415.00
```

**API endpoint (Deriv):** `buy` with `contract_type: "CALL"` (Rise) or `"PUT"` (Fall), `duration: rec_expiry`, `duration_unit: "m"`.

---

## Dashboard Reference

| Section | Rows | What it shows |
|---------|------|--------------|
| Market Intelligence | 0-4 | Current bias, active signal, waiting condition, flip trigger |
| Fractal H1→M15→Now | 5-8 | 4-layer sync status with OK/WARN per layer |
| CALL breakdown | 9-15 | Per-factor confidence scoring for bull side |
| PUT breakdown | 16-22 | Per-factor confidence scoring for bear side |
| Vanilla Options | 23-26 | Live strikes, expiry, continuation status |
| Execution | 27-29 | ATM trigger status, direction gate, confidence gate |
| Regime Intelligence | 30-33 | Strength%, quality tier, IV proxy, delta |
| Signal P&L | 34-35 | Last entry vs current price (open signal tracker) |
| Active SL/TP | 36-38 | Current SL level, TP1/2/3, RR ratio |
| Liquidity Zones | 39-42 | Sniper/flip status, break status, zone count |

---

## Pairs & Deployment

| Pair | Mode | Why |
|------|------|-----|
| R_75 (Volatility 75) | All signals — primary | High volatility, clean structure, 24/7, no news risk |
| XAUUSD | Sovereign flip + Sniper only | Strong trend days, London/NY session |
| GBPUSD | Rise/Fall + ATM entry | News-driven momentum, predictable BOS |

---

## Project Files

```
TRON_JARVIS/
├── README.md                          ← you are here — full vision + masterclass
│
├── Pine Script (TRON)
│   └── TRON_Glassbox_SignalGenerator.pine  ← ACTIVE v4.0 — the only Pine Script in this repo
│
├── Legacy / Reference
│   ├── AgentProtocol_LiquiditySuite.mq5
│   ├── Agent - Liquidity Suite.txt
│   ├── Agent V7 Strategy - Tradesgnl.txt
│   └── June TradeSgnl Syntax.txt
│
└── (coming) Jarvis/
    ├── brain.py                       ← position ledger, episodic memory
    ├── signal_engine.py               ← Tron-parity analysis (Deriv API)
    ├── telegram_bot.py                ← briefing dispatch, tap-to-trade
    ├── deriv_client.py                ← execution bridge (Rise/Fall + Vanilla)
    └── config.yaml                    ← pairs, risk params, session filters
```

---

## The Formula

```
Analysis   → TRON sees it. Jarvis confirms it.
Capital    → Deriv Vanilla Options (defined risk, no stop-hunt)
             Deriv Rise/Fall (pure direction, scalp speed)
Execution  → Human-in-loop now. Autonomous later.
```

---

## Conversation Lock — The Origin Story

> "Tron from Ares. And Jarvis from Iron Man. A Tron-Jarvis for trading vanilla options and perpetual futures. Tron needs to design itself first in Pinescript — that's the Tron version of itself. It lives on the price grid. Jarvis does market analysis, uses the Deriv API to extract data, researches opportunities based on the Tron architecture. Jarvis also executes and makes Tron smarter."

> "The formula is simple. Analysis + Capital + Execution — our intraday momentum trading formula to success with risk management."

> "Jarvis even its analysis is Pinescript amplified. If it sends a signal and you load the Pine agent we get the same thing. This way we have a system that's glass box and makes money."

> "Do we have liquidity trail entries? Those are super entries and they guide the rest especially when it comes to exits and regime shifts, we can with confidence consider exits as well."

> "The entries I meant were the liquidity trail flips — those are sniper flips for these options. The MTF trail flips would be perfect entries even for Rise and Fall."

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
  - [x] Liquidity Zone Sniper Engine — break + retest detection
  - [x] **MTF Trail Flip Sniper entries** — chart/M15/H1/H4 flip signals, tiered by TF
  - [x] **SL/TP lines drawn on chart** — auto-drawn on every entry, persist until next entry
  - [x] **Rise/Fall mode** — alert format + dashboard adapts, no strike needed
  - [x] 24 alertcondition() entries (full dropdown in TradingView)
  - [x] Cognitive dashboard (43 rows — full architecture state at a glance)
  - [x] Operator masterclass (this README — how to act on every alert type)
- [ ] Phase 2 — Jarvis Brain (Python)
  - [ ] Deriv API data feed
  - [ ] Tron-parity signal engine
  - [ ] Position ledger + episodic memory
  - [ ] Telegram bot + briefings
  - [ ] LLM narrative generation (Claude API)
  - [ ] Rise/Fall execution via Deriv API
- [ ] Phase 3 — Execution
  - [ ] Deriv API order execution (Vanilla + Rise/Fall)
  - [ ] Human-in-loop tap-to-trade
  - [ ] Risk gate (daily limits, session filters)
- [ ] Phase 4 — Mini App
  - [ ] Telegram mini app (tap-to-trade UI)
  - [ ] Live dashboard (positions, P&L, signal history)
  - [ ] Bybit perpetual futures (after Deriv mastery)
