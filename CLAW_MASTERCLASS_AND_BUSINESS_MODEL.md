# THE AGENT PROTOCOL — LIQUIDITY SUITE
## Operator Masterclass & Intraday Trading Business Model
**Absolute Dollar Intelligence | Founder: Emma Munene | Nairobi, Kenya**

---

## HOW TO USE THIS DOCUMENT

This document is three things at once:

1. **A self-prompt** — Everything the next Claude Code session (or a human developer) needs to continue building the masterclass, the Agent Protocol EA, or the business model. No context is lost.
2. **A masterclass blueprint** — The Liquidity Suite indicator deconstructed layer by layer into plain English. Each module maps directly to a week of teaching content.
3. **A business framework** — The commercial model for turning this tool into a licensed, community-backed, affiliate-linked trading business.

Read the whole thing before starting any new work session.

---

# PART 1 — THE TECHNICAL TRUTH BEHIND THE INDICATOR

## What the Liquidity Suite actually is

The indicator is called "THE AGENT PROTOCOL — LIQUIDITY SUITE" and it runs on TradingView in Pine Script v6. Its job is not to predict the market. Its job is to filter out all the noise and present only the highest-probability moments to enter a trade.

The architecture is a five-layer decision chain:

```
TRIGGER → GATE → CONFLUENCE → CONFIDENCE → EXECUTION
```

Nothing gets executed unless it passes every layer in sequence. Most signals never make it through. That is the point.

---

## LAYER 1 — THE TRIGGER (ATM Bot + Smart Signal)

**What it does:** Detects the moment price starts moving with enough conviction to warrant attention.

**Two trigger types:**

### ATM Bot (⚡ signal)
The ATM Bot is an ATR-based trailing stop crossover. It works like this:
- It builds a dynamic level above price (sell trail) and below price (buy trail) based on how volatile the market is right now
- When price crosses from below the buy trail to above it — and stays there — that is an ATM buy signal
- When price crosses from above the sell trail to below it — that is an ATM sell signal
- The signal only fires on a confirmed closed bar (`barstate.isconfirmed`)

**Key parameters and why they are set that way:**
- **Buy/Sell Sensitivity: 3.0** — This is how many ATR units the trail sits away from price. Higher = wider = fewer signals but higher quality. 3.0 is conservative enough to avoid false triggers in choppy markets while still being responsive in trending moves.
- **Buy/Sell ATR Period: 1** — This uses a 1-bar ATR, meaning it reacts to the very latest volatility, not a smoothed average. This gives the trail its responsiveness without over-smoothing.

### Smart Signal (🧠 signal)
The Smart Signal fires when RSI crosses into positive or negative momentum territory AND the M5 timeframe confirms the same direction at the same time.
- RSI must cross above 50 (the midline) with price EMA slope turning up → Smart Bull
- RSI must cross below 50 with price EMA slope turning down → Smart Bear
- M5 RSI and M5 EMA slope must agree at the same moment

**Why two triggers?** ATM catches momentum shifts (trend starts). Smart Signal catches momentum continuation (trend confirms). Together they cover the two most important entry moments: the break and the continuation.

---

## LAYER 2 — THE GATE (Liquidity Trail Direction)

**What it does:** Tells the trigger which direction is allowed.

The Liquidity Trail is the single most important line on the chart. It is computed with:
```
EMA(50) ± 1.25 × ATR(14)
```

When price is above the trail → `ltf_trend = 1` → only longs are allowed
When price is below the trail → `ltf_trend = -1` → only shorts are allowed

A trigger that fires against the trail direction is immediately rejected. It shows up as a grey X on the chart (`rejected_*` signals).

**Why this matters:** The ATM Bot can fire in both directions. Without a gate it would be just another oscillator crossover. The trail gate ensures the trigger is always going with the flow of money, not against it.

**Key parameters:**
- **MA Length: 50** — 50-bar EMA gives medium-term trend context. Fast enough to respond to intraday direction changes, slow enough to ignore micro noise.
- **ATR Length: 14** — Standard 14-bar ATR, matching industry convention. 14 bars = roughly 2.5 trading weeks of data on daily, or 3.5 hours on M15.
- **Trail Distance: 1.25 ATR** — This is tight. 1.0 would be too tight (lots of whipsaws). 2.0 would be too loose (slow reversals). 1.25 is the sweet spot that stays inside trending moves without giving back too much on reversals.

---

## LAYER 3 — CONFLUENCE (The Six Filters)

After the trigger fires and the gate allows it, the indicator checks six separate measurements of market condition. Each one votes. The votes are weighted.

### Filter 1 — MTF (Multi-Timeframe Trail) — Weight: 1.5 (HIGHEST)
Checks whether H1 and M15 trails are both aligned with the current signal direction.
- Both H1 and M15 agree → FULL score (1.5 points)
- Only one agrees → PARTIAL score (0.6 points, 40% of weight)
- Neither agrees → 0 points

**Why 1.5 weight?** The MTF trail is the highest-quality filter because it requires the same mathematical engine to agree on two longer timeframes. If H1 and M15 are both bullish, the move has institutional backing. If they disagree, the move is likely noise.

**Why H1 and M15 specifically?** H1 is the intraday map — it captures where price is going over the session. M15 is the tactical battlefield — it shows whether the intraday move has momentum. Together they form a top-down view that eliminates counter-trend entries.

### Filter 2 — Market Structure — Weight: 1.0
Checks whether price is making Higher Highs and Higher Lows (bullish structure) or Lower Highs and Lower Lows (bearish structure).
- HH/HL pattern → bullish structure confirmed (1.0 point)
- LH/LL pattern → bearish structure confirmed (1.0 point)
- Mixed → 0 points

A Break of Structure (BOS) is also tracked: when price breaks above a previous HH it signals bullish momentum; breaking below a previous LL signals bearish momentum.

**Key parameter — Swing Size: 25** — A pivot must be the highest/lowest point over 25 bars on each side to qualify as a structure point. This eliminates micro pivots that mean nothing. 25 bars on M5 = about 2 hours. On M15 = about 6 hours. This catches real swing points.

### Filter 3 — RSI Momentum — Weight: 1.0
Checks whether RSI is in sustained positive territory (above 50, EMA slope rising) or sustained negative territory (below 50, EMA slope falling).
- Positive momentum active → 1.0 point
- Negative momentum active → 1.0 point
- Neutral/mixed → 0 points

M5 RSI is also checked as a secondary confirmation. The current-timeframe RSI must agree with the M5 RSI direction before the Smart Signal fires.

**Why RSI 50 as the level?** Not overbought/oversold. The midline. RSI above 50 simply means bulls have outpunched bears over the lookback period. That is the minimum requirement, not the maximum.

**Sustain Momentum toggle:** Once RSI enters positive territory, it stays positive even if RSI temporarily dips, as long as the EMA slope is still rising. This prevents the indicator from flipping off a perfectly good trend at the first retracement.

### Filter 4 — VWAP Anchor — Weight: 1.0
The VWAP here is not a session VWAP. It is an adaptive VWAP anchored from the most recent swing high or swing low. When the most recent swing high is more recent than the most recent swing low, direction is bearish (price came from a high). When the most recent swing low is more recent, direction is bullish.
- VWAP anchored from swing low, trending up → bullish (1.0 point)
- VWAP anchored from swing high, trending down → bearish (1.0 point)

**Swing Period: 100** — Looks back 100 bars to find the dominant swing. On M5, that is about 8 hours. On M15, that is about 25 hours. Long enough to capture the intraday narrative, short enough to update when the story changes.

**Adaptive Tracking: 20** — Controls how fast the VWAP adapts to new price/volume. 20 is a balanced decay factor. Too fast and VWAP follows price like a moving average. Too slow and it never updates.

### Filter 5 — Fib Bands — Weight: 0.5 (OPTIONAL GATE)
Fib Bands use a double-smoothed EMA as a basis with ATR-based Fibonacci extensions (0.618 and 2.618 levels). When the basis is rising, the lower Fib channels form a bullish regime. When falling, upper channels form a bearish resistance zone.
- Basis rising → fibBullish = 1 (0.5 point if enabled)
- Basis falling → fibBearish = 1 (0.5 point if enabled)

**Why 0.5 weight?** Fib Bands are the slowest filter (double-smoothed EMA of 200 bars). They confirm the macro trend, not the immediate setup. Lower weight reflects that they are context, not confirmation.

**Why is it optional?** Sometimes a perfectly valid intraday entry will be against the daily/Fib macro trend. Experienced operators know when to use it. The option to disable makes the indicator adaptable.

### Filter 6 — Volume Profile — Weight: 0.5
The Volume Profile shows where the most trading activity happened over the selected session (Daily by default). Three key levels:
- **POC** — Point of Control: the price level with the most volume traded
- **VAH** — Value Area High: upper boundary of the 70% volume zone
- **VAL** — Value Area Low: lower boundary of the 70% volume zone

Price above VAL = price is inside or above the value zone = bulls have defended this area → bullish confirmation
Price below VAH = price is inside or below the value zone = bears have defended this area → bearish confirmation

**Why 0.5 weight?** Volume Profile is context-providing, not triggering. It tells you where the market found value. Combined with the other five filters it is powerful. Alone it would cause too many entries at wrong moments.

---

## LAYER 4 — CONFIDENCE ENGINE (THE CLAW)

Once all six filters have voted, the scores are added up and converted to a percentage:

```
Confidence % = (earned points ÷ max possible points) × 100
```

Maximum possible points (with Fib and VP enabled):
- MTF: 1.5
- Structure: 1.0
- RSI: 1.0
- VWAP: 1.0
- Fib: 0.5
- VP: 0.5
- Total max: 5.5 points

A trigger is only executed if confidence meets or exceeds the Claw Mode threshold:

| Claw Mode | Threshold | Meaning |
|-----------|-----------|---------|
| Conservative | 80% | Only enters when nearly everything aligns — fewer trades, higher win rate |
| Moderate | 60% | Standard operating mode — good balance of frequency and quality |
| Aggressive | 40% | Enters on partial confirmation — more trades, higher risk per signal |
| Custom | User-set | Expert use only |

**The dashboard shows exactly why the score is what it is.** Every filter is listed with its current state, points earned, and pass/fail status. This is the Glass Box principle: the operator always knows what the indicator is thinking and why.

---

## LAYER 5 — EXECUTION

Only signals that pass all four layers above appear on chart:
- `⚡Buy` / `⚡Sell` — ATM Bot trigger, gated and confidence-confirmed
- `🧠Buy` / `🧠Sell` — Smart Signal trigger, gated and confidence-confirmed
- Grey X — Signal fired but was rejected (gate or confidence failure)

**The grey X is important.** It tells the operator: "The market wanted to move here, but the conditions were not right." Watching grey X patterns teaches timing more than any textbook.

---

# PART 2 — THE DASHBOARD — WHAT EVERY ROW MEANS

The dashboard has 28 rows. Here is what each section tells you and what to do with it:

### Self-Awareness Section (I AM / WAITING / FLIP IF)
- **I AM** — Current trail direction + whether you're in a long or short + current confidence %
- **WAITING** — What needs to happen next. Either "ATM Trigger" (confidence is already met, just waiting for the timing signal) or "Conf X%→Y%" (showing how far short you are of the threshold)
- **FLIP IF** — What would cause the system to switch direction. "Trail flip → bearish" means the trail currently shows bullish, and only a trail reversal changes that

### Fractal Section (H1 / M15 / NOW)
- Shows H1 trail direction, M15 trail direction, and current-bar structure
- The ✅ or ⚠️ tells you whether each higher timeframe agrees with the current bar's setup
- You want all three showing ✅ before touching the trade

### Confluence Breakdown (LONG % and SHORT %)
- Shows the exact contribution of every filter to the long and short confidence scores
- Green ✅ = filter is active and contributing
- Red ❌ = filter is not confirming
- Orange ⚠️ = partial confirmation (MTF partial case)

### Execution Section
- **TRIGGER** — Is an ATM or Smart signal firing right now?
- **DIR** — Is the trail gate open (L for long, S for short)?
- **CONF GATE** — Is confidence above threshold? If yes + trigger fires → EXEC
- **CLAW MODE** — Current mode and the threshold number
- **VOL** — Is price above VAH (premium), in value area, or below VAL (discount)?

---

# PART 3 — PARAMETER RATIONALE TABLE

Every parameter has a reason. This table is the "why" behind the settings operators will receive.

| Parameter | Default | Why This Number |
|-----------|---------|-----------------|
| MA Length | 50 | Medium-term trend. Fast enough for intraday, slow enough to filter noise |
| ATR Length | 14 | Industry standard. 14 bars = 2.5 weeks on D1, 70 min on M5 |
| Trail Distance | 1.25 | Tight trail keeps you close to trend without whipsawing |
| Swing Lookback (LTF) | 14 | Matches ATR for consistency in zone calculations |
| Swing Size (SMC) | 25 | Eliminates micro pivots. Real structure pivots only |
| ATM Sensitivity | 3.0 | Conservative. 3× ATR away = conviction required before trigger |
| ATM ATR Period | 1 | Single-bar ATR for real-time sensitivity |
| RSI Length | 14 | Matches ATR. Standard across all assets |
| RSI Midline | 50/50 | Simple bull/bear split. Not OB/OS — this is momentum, not extremes |
| Momentum EMA | 5 | Ultra-fast slope detection for RSI momentum change |
| VWAP Swing Period | 100 | ~8 hours on M5 — covers the full intraday narrative |
| Adaptive Tracking | 20 | Balanced VWAP decay. Neither too sticky nor too reactive |
| Fib Length | 200 | Long-term context. 200 bars = institutional baseline |
| VP Resolution | 30 | 30 price bins = granular enough to see structure, readable on screen |
| VP Value Area | 70% | Standard institutional value area definition |
| Signal Smoothing | 34 | Fibonacci number. Smooth signal without excessive lag |
| BOS Confirmation | Candle Close | Requires full close beyond level — not just a wick |

---

# PART 4 — THE MASTERCLASS CURRICULUM

## Module Structure: 6 Weeks, 1 Topic Per Week

### WEEK 1 — WHAT THE INDICATOR IS NOT
- It is not a buy/sell signal generator
- It is a market intelligence engine that filters for high-probability moments
- The trail is truth. The trigger is timing. The difference matters.
- Lab: Load the indicator. Watch 50 bars. Count grey X rejections vs. executed signals. Journal what you observe.

### WEEK 2 — READING THE DASHBOARD BEFORE TOUCHING A TRADE
- Walk through every row of the dashboard
- What does 82% confidence look like vs. 45%?
- Practical: Screenshot 10 ATM signals. For each one, record: Claw mode, confidence %, which filters were green, which were red
- Exercise: Find 3 examples where trigger fired but trail rejected it. What happened next?

### WEEK 3 — THE FRACTAL — H1 IS THE MAP, M15 IS THE BATTLEFIELD
- Load the indicator on M5 execution timeframe
- Check H1 and M15 rows in the dashboard before every potential entry
- Three scenarios:
  - Both H1 and M15 green ✅✅ → maximum alignment, best setups
  - H1 green, M15 partial ⚠️ → valid but tighter management
  - H1 against M15 ❌ → do not enter regardless of trigger
- Lab: Mark on your chart every entry where all three fractal rows showed ✅. Track outcomes for 2 weeks.

### WEEK 4 — CLAW MODE SELECTION AND RISK CALIBRATION
- Conservative = 80%: Fewer than 3 trades per day on most assets. Win rate above 65%.
- Moderate = 60%: 3–8 trades per day. Standard for intraday operators.
- Aggressive = 40%: High frequency. Appropriate only with strict lot sizing.
- How to choose: Match your account size to the mode. Small account ($50–$100) → Conservative. Funded challenge → Moderate. Live large account → operator's choice.
- Risk calibration exercise: Calculate dollar risk per trade at your account size using RISK_PNL_MATRIX_TEMPLATE.md.

### WEEK 5 — THE ANATOMY OF A COMPLETE TRADE
**Before entry:**
1. Check H1 trend direction (dashboard row 6)
2. Check M15 alignment (dashboard row 7)
3. Check Confidence % vs. threshold (dashboard row 9 or 16)
4. Check Volume Profile position — are we above VAL (long) or below VAH (short)?
5. Is the TRIGGER column showing ATM or Smart signal?

**At entry:**
- Note your lot size vs. risk dollar amount
- Note your SL level — it is beyond the trail, not arbitrary
- Note your three TP levels (1:1, 1.5:1, 2:1 for 3-TP system)

**During the trade:**
- Watch for trail flip (exit signal)
- After TP1: move SL to breakeven
- After TP2: trail tightens
- Runner: stays until trail flips

**Post-trade:**
- Record in trade journal: entry reason (which filters were active), outcome, what confidence % was at entry
- If a loss: which filter that was green should have been red? What did the market tell you that the indicator missed?

### WEEK 6 — THE BUSINESS: TURNING SKILL INTO INCOME
See Part 5 of this document.

---

# PART 5 — THE INTRADAY TRADING BUSINESS MODEL

## The Core Idea

You have a tool that is not widely accessible. It is built from scratch by a founder who trades it live. The mechanics are proven. The Glass Box design means it is teachable.

The business is built on three pillars:
1. **Access** — You need the indicator to participate
2. **Community** — Everyone uses the same tool, creating shared language and accountability
3. **Affiliate** — Deposits flow through your link, generating commission

## The Accountability Advantage

In most trading communities the mentor says "trust me, buy here." Operators using the Liquidity Suite look at the same dashboard and see:
- The same confidence %, the same fractal status, the same trigger label
- If you are both in Moderate mode and confidence is 72%, you both see 72%
- The conversation changes from "why did you enter?" to "what did the system show you?"

This is not a trust-me-bro community. It is a same-tool community. Same dashboard, same language, same decisions.

## Tiered Access Structure

### Tier 1 — Observer ($0, access to public content only)
- Weekly market analysis posts using Liquidity Suite screenshots
- No indicator access
- Funnel: Join community → see results → want to know how → upgrade

### Tier 2 — Operator ($50 Deriv deposit via affiliate link)
- Access to The Agent Protocol indicator (Liquidity Suite)
- Access to RISK_PNL_MATRIX_TEMPLATE.md cheat sheet
- Access to Weeks 1–4 of the masterclass
- Manual trading only
- Community: same channel, accountable to group

### Tier 3 — Semi-Operator ($100+ deposit + TradeSgnl basic)
- Everything in Tier 2
- TradeSgnl alert handshake setup (Pine → MT5)
- ADSA v7.0 indicator as the alert source OR Liquidity Suite alerts
- Still requires operator to approve entries (not fully automated)
- Access to Weeks 5–6 masterclass

### Tier 4 — Master Control Operator (Invite only)
- Full TradeSgnl Advanced configuration
- vol_dollar Platinum Risk Model enabled
- 3-TP automation active
- Pyramid scaling logic
- Access to the Agent Protocol EA when it is built (MQL5 native)
- Direct access to founder for Q&A

## Affiliate Model

- All tiers require a Deriv account via your affiliate link
- Deriv pays commission on deposits and volume
- Every operator in your community generates lifetime affiliate revenue
- As volume grows, affiliate commission grows passively

**Why Deriv specifically:**
- Access to Deriv Synthetic Indices (V10, V25, V75, Step Index) — available 24/7, no news risk, no London open spread games
- Low minimum deposit ($10 live, $50 to unlock proper lot sizing)
- MT5 native, making the eventual MQL5 port natural
- Bybit may be added later for crypto spot/perps — same affiliate model

## Revenue per Operator (Example)

| Deposit | Affiliate Rate | Monthly Volume Est. | Monthly Commission |
|---------|---------------|--------------------|--------------------|
| $50 | ~30–40% of spread | ~$2,000 | ~$6–12 |
| $100 | same | ~$4,000 | ~$12–24 |
| $500 | same | ~$20,000 | ~$60–120 |

At 50 active operators at $100 average deposit: $600–$1,200/month passive from volume alone. Plus any direct subscription or masterclass fees.

## Community Model

The community has one language: the dashboard.

When an operator shares a trade, the conversation looks like:
> "ATM Buy fired on XAUUSD M5. H1 ✅, M15 ✅, Confidence 74% (Moderate mode = 60% threshold). Structure: HH/HL. VP: above VAL. Entered 0.05 lot, $1.50 risk on 30pt SL. TP1 hit, moved SL to BE."

That is a reproducible, teachable, accountable entry. Anyone with the same tool can validate it.

Weekly group review: share screenshots, dashboard state at entry, outcome. This builds the performance database and the community narrative simultaneously.

---

# PART 6 — THE EXECUTION ARCHITECTURE (CURRENT STATE + ROADMAP)

## Current State (What Exists Today)

```
TradingView — Liquidity Suite indicator
     ↓ (fires alert on confirmed signal)
TradeSgnl EA on MT5
     ↓ (receives webhook, parses lot/SL/TP)
Deriv MT5 Account — trade executed
```

**Alert format (from June TradeSgnl Syntax):**
```
LICENSE_ID,XAUUSD,buy,vol_lots=0.05,sl_price={{sl}},tp1_price={{tp1}},pct1=0.33,tp2_price={{tp2}},pct2=0.50,tp3_price={{tp3}},exent=1,comment=XAUUSD Agent
```

**Default lots by asset:**
| Asset | Agent TradeSgnl Lot | Dollar risk at 30pt SL |
|-------|--------------------|-----------------------|
| XAUUSD | 0.05 lot | $1.50 |
| GBPUSD | 0.05 lot | $1.50 (15 pips) |
| Volatility 75 | 0.10 lot | $3.00 (300 pts) |
| Volatility 25 | 0.50 lot | $2.50 (500 pts) |
| Volatility 10 | 1.00 lot | $3.00 (300 pts) |

## Planned: Agent Protocol EA (The CLAW EA — MQL5 Native)

The long-term goal is to port the entire brain into MQL5 so TradingView is no longer required for execution. The EA reads the indicator directly via `iCustom()`.

Architecture:
```
MT5 — MQL5 Indicator (same logic as Liquidity Suite, ported)
     ↓ (iCustom() buffer read, same bar)
MT5 — Agent Protocol EA
     ↓ (orders to broker directly)
Deriv MT5 Account
```

**What the EA needs to build:**
- Lot sizing (risk_usd ÷ sl_distance × pip_value)
- SL placement (beyond ltf_trail at time of signal)
- TP1/TP2/TP3 at 1:1 / 1.5:1 / 2:1 from entry
- Partial close at TP1 (25%), TP2 (25%), TP3 (25%), runner (25%)
- SL move to breakeven after TP1
- Trail tighten after TP2 (ATR × 0.75)
- Runner exits only on trail flip
- Pyramid scale-in: 3 levels max, each trail-anchored, $7.50 add-on risk
- Telegram broadcast integration
- Canvas dashboard panel

**Position sizing formula (Platinum Risk Model):**
```
lots = risk_usd ÷ (sl_distance × pip_value_per_lot)
```
Where `pip_value_per_lot` = see RISK_PNL_MATRIX_TEMPLATE.md master table.

---

# PART 7 — NEXT SESSION CONTEXT (SELF-PROMPT)

If you are a Claude Code session starting fresh, here is what you need to know:

**Repository:** `emmamunene0000-gif/Absolute-Dollar-Agent---MT5-Claw`
**Working branch:** `claude/youthful-hypatia-ycu5yk`
**Primary files:**
- `Agent - Liquidity Suite.txt` — The full Pine Script v6 indicator (1200 lines). Do not modify without explicit instruction. Read it with offset/limit because it exceeds single-read limits.
- `Agent V7 Strategy - Tradesgnl.txt` — ADSA v7.0 strategy version with Platinum Risk Model and TradeSgnl alert generation (2835 lines)
- `ABSOLUTE_DOLLAR_MASTERCLASS_FRAMEWORK.md` — 4-week masterclass for the strategy version (committed)
- `RISK_PNL_MATRIX_TEMPLATE.md` — Complete hardcoded risk cheat sheet for all traded assets (committed, v2.0)
- `June TradeSgnl Syntax.txt` — TradeSgnl alert syntax per asset with default lot sizes
- `CLAW_MASTERCLASS_AND_BUSINESS_MODEL.md` — This file

**What has been built:**
1. Risk cheat sheet (complete, hardcoded, all five assets) ✅
2. Strategy masterclass framework (4-week curriculum) ✅
3. Liquidity Suite deconstruction and business model (this document) ✅

**What has NOT been built yet:**
- The Agent Protocol EA in MQL5 (the "CLAW EA" that ports the indicator to MT5 natively)
- The Liquidity Suite alert integration (currently the Liquidity Suite fires generic alerts — the TradeSgnl syntax for Liquidity Suite signals has not been formally defined as a document)
- The community onboarding materials (intake form, Telegram welcome message, setup guide for new operators)
- Bybit integration (mentioned but not started)

**User context:**
- Emma Munene, founder of Absolute Dollar Intelligence, Nairobi
- Currently trading manually with the Liquidity Suite on TradingView
- Running a $50–$100 live Deriv account + 1Step $10K prop firm challenge (XAUUSD/GBPUSD)
- The community goal: 50+ operators on same tool, same dashboard, same language
- Deposit requirement: $50 minimum via Deriv affiliate link
- The Liquidity Suite is the core product — the indicator is what operators pay to access

**Tone and approach:**
- No jargon without explanation
- Everything is explainable in plain English
- Numbers are hardcoded, not templates
- The Glass Box principle: the operator always knows what the system is doing and why

**Technical priorities for next session:**
1. If building the CLAW EA: start with `calcLiqTrail()` in MQL5 first — it is the heart of the whole system. Once the trail is working, the rest of the logic flows from it.
2. If expanding the masterclass: Week 6 content (the business model module) needs to be converted into actual workshop slides or a session script.
3. If building operator onboarding: Create a "Day 1 Setup Guide" — step by step from TradingView account to first indicator load to dashboard comprehension.

---

# APPENDIX — QUICK REFERENCE: THE FIVE QUESTIONS BEFORE EVERY TRADE

Before touching MT5, an operator using the Liquidity Suite answers five questions from the dashboard:

1. **What direction is the system?** (I AM row — BULLISH or BEARISH)
2. **Is the fractal aligned?** (H1 and M15 both ✅?)
3. **Is confidence above threshold?** (% shown vs. mode threshold)
4. **Has a trigger fired?** (ATM or Smart signal visible on chart)
5. **Where is price relative to value?** (VOL row — above VAH, in value, below VAL)

If yes to all five: enter.
If no to any one: wait.

That is the whole system in five questions.

---

*Absolute Dollar Intelligence — The same tool, the same truth, every operator.*
