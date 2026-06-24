# Absolute Dollar Intelligence — Risk & P&L Master Cheat Sheet
**ADSA v7.0 | Operator Execution Reference | Deriv MT5 Edition**

---

## HOW THIS CHEAT SHEET WORKS

Every table below shows the **real dollar P&L** for each asset based on verified Deriv MT5 contract specifications. The formula driving every number:

```
Dollar P&L  = Points Moved × Pip Value ($/pt/lot) × Lot Size
Dollar Risk = SL Distance (pts) × Pip Value × Lot Size
Lot Size    = Dollar Risk Target ÷ (SL Distance × Pip Value)
```

These are the same calculations the agent's Platinum Risk Model uses internally. The agent does it automatically — this sheet makes it visible so operators understand exactly what is at stake on every trade before touching the MT5 terminal.

---

## MASTER PIP VALUE TABLE — ALL TRADED ASSETS

| Asset | Contract Size | Point/Pip | $/pt at 1 lot | Min Lot (Deriv) | $/pt at Min Lot | Agent TradeSgnl Lot | $/pt at Agent Lot |
|-------|--------------|-----------|--------------|-----------------|-----------------|---------------------|-------------------|
| XAUUSD | 100 oz | 0.01 | $1.00 | 0.01 | $0.01 | 0.05 | $0.05 |
| GBPUSD | 100,000 | 0.0001 pip | $10.00 | 0.01 | $0.10 | 0.05 | $0.50 |
| Volatility 75 | 1 (contract) | 1 point | $1.00 | 0.001 | $0.001 | 0.10 | $0.10 |
| Volatility 25 | 1 (contract) | 1 point | $0.10 | 0.50 | $0.05 | 0.50 | $0.05 |
| Volatility 10 | 1 (contract) | 1 point | $0.10 | 0.30 | $0.03 | 1.00 | $0.10 |
| Step Index | 1 (contract) | 0.10 step | $1.00 | 0.10 | $0.10 | — | — |

> **Sources:** XAUUSD and GBPUSD — standard MT5 forex/commodity specs confirmed across Deriv, Pepperstone and universal broker documentation. V75 — directly verified: 0.001 lot × 1,000 points = $1.00 (multiple community sources). V10 and V25 — derived from Deriv MT5 point structure (3-decimal price = 0.001 mintick × contract notional). Verify once via MT5 Symbol Specification right-click → check "Tick Value" at 1.0 lot.

---

## SECTION 1 — XAUUSD (GOLD SPOT)

**Verified spec:** 100 troy oz per lot | 1 point = $0.01 price move | $1.00/pt/lot

### P&L Matrix — Dollar Risk/Reward at Key Lot Sizes

| SL (points) | 0.01 lot | 0.02 lot | 0.05 lot ★ | 0.10 lot | 0.20 lot | 0.50 lot |
|-------------|----------|----------|------------|----------|----------|----------|
| 10 pts      | $0.10    | $0.20    | $0.50      | $1.00    | $2.00    | $5.00    |
| 20 pts      | $0.20    | $0.40    | $1.00      | $2.00    | $4.00    | $10.00   |
| 30 pts      | $0.30    | $0.60    | $1.50      | $3.00    | $6.00    | $15.00   |
| 40 pts      | $0.40    | $0.80    | $2.00      | $4.00    | $8.00    | $20.00   |
| 50 pts      | $0.50    | $1.00    | $2.50      | $5.00    | $10.00   | $25.00   |
| 60 pts      | $0.60    | $1.20    | $3.00      | $6.00    | $12.00   | $30.00   |
| 80 pts      | $0.80    | $1.60    | $4.00      | $8.00    | $16.00   | $40.00   |
| 100 pts     | $1.00    | $2.00    | $5.00      | $10.00   | $20.00   | $50.00   |
| 120 pts     | $1.20    | $2.40    | $6.00      | $12.00   | $24.00   | $60.00   |
| 150 pts     | $1.50    | $3.00    | $7.50      | $15.00   | $30.00   | $75.00   |
| 200 pts     | $2.00    | $4.00    | $10.00     | $20.00   | $40.00   | $100.00  |

★ = Agent TradeSgnl default lot

### 3-TP Payout Table — XAUUSD at 0.05 lot (agent default)

| SL (pts) | Risk ($) | TP1 1:1 (33%) | TP2 1.5:1 (50% rem) | TP3 2:1 (runner) | Full Exit TP3 ($) |
|----------|----------|----------------|----------------------|-------------------|-------------------|
| 30 pts   | $1.50    | +$0.50         | +$0.56               | +$0.75 runner     | +$3.00            |
| 50 pts   | $2.50    | +$0.83         | +$0.94               | +$1.25 runner     | +$5.00            |
| 60 pts   | $3.00    | +$1.00         | +$1.13               | +$1.50 runner     | +$6.00            |
| 80 pts   | $4.00    | +$1.32         | +$1.50               | +$2.00 runner     | +$8.00            |
| 100 pts  | $5.00    | +$1.65         | +$1.88               | +$2.50 runner     | +$10.00           |
| 120 pts  | $6.00    | +$1.98         | +$2.25               | +$3.00 runner     | +$12.00           |

> TP1 = 33% of position × 1:1 RR | TP2 = 50% of remaining × 1.5:1 RR | TP3 runner at 2:1+ in Holder Mode

### Required Lot Size — XAUUSD (to hit exact dollar risk target)

Formula: `Lot Size = $ Risk ÷ (SL pts × $1.00)`

| Target Risk | SL 30 pts | SL 50 pts | SL 60 pts | SL 80 pts | SL 100 pts | SL 150 pts |
|-------------|-----------|-----------|-----------|-----------|------------|------------|
| $1.50       | 0.05      | 0.03      | 0.025     | 0.02      | 0.015      | 0.01       |
| $3.00       | 0.10      | 0.06      | 0.05      | 0.04      | 0.03       | 0.02       |
| $5.00       | 0.17      | 0.10      | 0.08      | 0.06      | 0.05       | 0.03       |
| $10.00      | 0.33      | 0.20      | 0.17      | 0.13      | 0.10       | 0.07       |
| $15.00      | 0.50      | 0.30      | 0.25      | 0.19      | 0.15       | 0.10       |
| $20.00      | 0.67      | 0.40      | 0.33      | 0.25      | 0.20       | 0.13       |
| $50.00      | 1.67      | 1.00      | 0.83      | 0.63      | 0.50       | 0.33       |

---

## SECTION 2 — GBPUSD (FOREX)

**Verified spec:** 100,000 units per lot | 1 pip = 0.0001 price change | $10.00/pip/lot

### P&L Matrix — Dollar Risk/Reward at Key Lot Sizes

| SL (pips) | 0.01 lot | 0.02 lot | 0.05 lot ★ | 0.10 lot | 0.20 lot | 0.50 lot |
|-----------|----------|----------|------------|----------|----------|----------|
| 3 pips    | $0.30    | $0.60    | $1.50      | $3.00    | $6.00    | $15.00   |
| 5 pips    | $0.50    | $1.00    | $2.50      | $5.00    | $10.00   | $25.00   |
| 8 pips    | $0.80    | $1.60    | $4.00      | $8.00    | $16.00   | $40.00   |
| 10 pips   | $1.00    | $2.00    | $5.00      | $10.00   | $20.00   | $50.00   |
| 12 pips   | $1.20    | $2.40    | $6.00      | $12.00   | $24.00   | $60.00   |
| 15 pips   | $1.50    | $3.00    | $7.50      | $15.00   | $30.00   | $75.00   |
| 20 pips   | $2.00    | $4.00    | $10.00     | $20.00   | $40.00   | $100.00  |
| 25 pips   | $2.50    | $5.00    | $12.50     | $25.00   | $50.00   | $125.00  |
| 30 pips   | $3.00    | $6.00    | $15.00     | $30.00   | $60.00   | $150.00  |
| 50 pips   | $5.00    | $10.00   | $25.00     | $50.00   | $100.00  | $250.00  |

★ = Agent TradeSgnl default lot

### 3-TP Payout Table — GBPUSD at 0.05 lot (agent default)

| SL (pips) | Risk ($) | TP1 1:1 (33%) | TP2 1.5:1 (50% rem) | Full Exit TP3 ($) |
|-----------|----------|----------------|----------------------|-------------------|
| 3 pips    | $1.50    | +$0.50         | +$0.56               | +$3.00            |
| 5 pips    | $2.50    | +$0.83         | +$0.94               | +$5.00            |
| 8 pips    | $4.00    | +$1.32         | +$1.50               | +$8.00            |
| 10 pips   | $5.00    | +$1.65         | +$1.88               | +$10.00           |
| 15 pips   | $7.50    | +$2.48         | +$2.81               | +$15.00           |
| 20 pips   | $10.00   | +$3.30         | +$3.75               | +$20.00           |

### Required Lot Size — GBPUSD (to hit exact dollar risk target)

Formula: `Lot Size = $ Risk ÷ (SL pips × $10.00)`

| Target Risk | SL 5 pips | SL 8 pips | SL 10 pips | SL 15 pips | SL 20 pips |
|-------------|-----------|-----------|------------|------------|------------|
| $1.50       | 0.03      | 0.02      | 0.015      | 0.01       | 0.01       |
| $3.00       | 0.06      | 0.04      | 0.03       | 0.02       | 0.015      |
| $5.00       | 0.10      | 0.06      | 0.05       | 0.03       | 0.025      |
| $10.00      | 0.20      | 0.13      | 0.10       | 0.07       | 0.05       |
| $15.00      | 0.30      | 0.19      | 0.15       | 0.10       | 0.075      |
| $20.00      | 0.40      | 0.25      | 0.20       | 0.13       | 0.10       |
| $50.00      | 1.00      | 0.63      | 0.50       | 0.33       | 0.25       |

---

## SECTION 3 — VOLATILITY 75 INDEX (Deriv Synthetic)

**Verified spec:** Contract size 1 | $1.00 per point per standard lot | Min lot: 0.001
> Verified: 0.001 lot × 1,000 point move = $1.00. Price range ~38,000–42,000. Typical daily range: 1,000–3,000 points (2–7%).

### P&L Matrix — Dollar Risk/Reward at Key Lot Sizes

| SL (points) | 0.001 lot | 0.01 lot | 0.05 lot | 0.10 lot ★ | 0.20 lot | 0.50 lot |
|-------------|-----------|----------|----------|------------|----------|----------|
| 100 pts     | $0.10     | $1.00    | $5.00    | $10.00     | $20.00   | $50.00   |
| 200 pts     | $0.20     | $2.00    | $10.00   | $20.00     | $40.00   | $100.00  |
| 300 pts     | $0.30     | $3.00    | $15.00   | $30.00     | $60.00   | $150.00  |
| 400 pts     | $0.40     | $4.00    | $20.00   | $40.00     | $80.00   | $200.00  |
| 500 pts     | $0.50     | $5.00    | $25.00   | $50.00     | $100.00  | $250.00  |
| 700 pts     | $0.70     | $7.00    | $35.00   | $70.00     | $140.00  | $350.00  |
| 1000 pts    | $1.00     | $10.00   | $50.00   | $100.00    | $200.00  | $500.00  |
| 1500 pts    | $1.50     | $15.00   | $75.00   | $150.00    | $300.00  | $750.00  |
| 2000 pts    | $2.00     | $20.00   | $100.00  | $200.00    | $400.00  | $1000.00 |

★ = Agent TradeSgnl default lot

### 3-TP Payout Table — V75 at 0.10 lot (agent default)

| SL (pts) | Risk ($) | TP1 1:1 (33%) | TP2 1.5:1 (50% rem) | Full Exit TP3 ($) |
|----------|----------|----------------|----------------------|-------------------|
| 100 pts  | $10.00   | +$3.30         | +$3.75               | +$20.00           |
| 200 pts  | $20.00   | +$6.60         | +$7.50               | +$40.00           |
| 300 pts  | $30.00   | +$9.90         | +$11.25              | +$60.00           |
| 500 pts  | $50.00   | +$16.50        | +$18.75              | +$100.00          |

### Required Lot Size — V75 (to hit exact dollar risk target)

Formula: `Lot Size = $ Risk ÷ (SL pts × $1.00)`

| Target Risk | SL 100 pts | SL 200 pts | SL 300 pts | SL 500 pts | SL 700 pts |
|-------------|------------|------------|------------|------------|------------|
| $5.00       | 0.05       | 0.025      | 0.017      | 0.01       | 0.007      |
| $10.00      | 0.10       | 0.05       | 0.033      | 0.02       | 0.014      |
| $15.00      | 0.15       | 0.075      | 0.05       | 0.03       | 0.021      |
| $20.00      | 0.20       | 0.10       | 0.067      | 0.04       | 0.029      |
| $50.00      | 0.50       | 0.25       | 0.167      | 0.10       | 0.071      |

---

## SECTION 4 — VOLATILITY 25 INDEX (Deriv Synthetic)

**Spec:** Contract size 1 | ~$0.10 per point per standard lot | Min lot: 0.50
> Price range ~2,400–2,700. 3-decimal pricing (e.g. 2,572.224). Typical day: 50–150 points.
> At min lot (0.50): $0.05 per point. At agent lot (0.50): same.

### P&L Matrix — Dollar Risk/Reward at Key Lot Sizes

| SL (points) | 0.50 lot ★ | 1.00 lot | 2.00 lots | 5.00 lots |
|-------------|------------|----------|-----------|-----------|
| 20 pts      | $1.00      | $2.00    | $4.00     | $10.00    |
| 30 pts      | $1.50      | $3.00    | $6.00     | $15.00    |
| 50 pts      | $2.50      | $5.00    | $10.00    | $25.00    |
| 75 pts      | $3.75      | $7.50    | $15.00    | $37.50    |
| 100 pts     | $5.00      | $10.00   | $20.00    | $50.00    |
| 150 pts     | $7.50      | $15.00   | $30.00    | $75.00    |
| 200 pts     | $10.00     | $20.00   | $40.00    | $100.00   |
| 300 pts     | $15.00     | $30.00   | $60.00    | $150.00   |

★ = Agent TradeSgnl default lot (also min lot)

### 3-TP Payout Table — V25 at 0.50 lot (agent default)

| SL (pts) | Risk ($) | TP1 1:1 (33%) | TP2 1.5:1 (50% rem) | Full Exit TP3 ($) |
|----------|----------|----------------|----------------------|-------------------|
| 30 pts   | $1.50    | +$0.50         | +$0.56               | +$3.00            |
| 50 pts   | $2.50    | +$0.83         | +$0.94               | +$5.00            |
| 100 pts  | $5.00    | +$1.65         | +$1.88               | +$10.00           |
| 150 pts  | $7.50    | +$2.48         | +$2.81               | +$15.00           |

### Required Lot Size — V25 (to hit exact dollar risk target)

Formula: `Lot Size = $ Risk ÷ (SL pts × $0.10)`

| Target Risk | SL 30 pts | SL 50 pts | SL 100 pts | SL 150 pts | SL 200 pts |
|-------------|-----------|-----------|------------|------------|------------|
| $1.50       | 0.50      | 0.30      | 0.15       | 0.10       | 0.075      |
| $3.00       | 1.00      | 0.60      | 0.30       | 0.20       | 0.15       |
| $5.00       | 1.67      | 1.00      | 0.50       | 0.33       | 0.25       |
| $10.00      | 3.33      | 2.00      | 1.00       | 0.67       | 0.50       |
| $15.00      | 5.00      | 3.00      | 1.50       | 1.00       | 0.75       |

---

## SECTION 5 — VOLATILITY 10 INDEX (Deriv Synthetic)

**Spec:** Contract size 1 | ~$0.10 per point per standard lot | Min lot: 0.30
> Price range ~4,500–5,000. 3-decimal pricing (e.g. 4,869.393). Lowest volatility of the range.
> At agent lot (1.0): $0.10 per point. At min lot (0.30): $0.03 per point.

### P&L Matrix — Dollar Risk/Reward at Key Lot Sizes

| SL (points) | 0.30 lot (min) | 0.50 lot | 1.00 lot ★ | 2.00 lots | 5.00 lots |
|-------------|----------------|----------|------------|-----------|-----------|
| 20 pts      | $0.60          | $1.00    | $2.00      | $4.00     | $10.00    |
| 30 pts      | $0.90          | $1.50    | $3.00      | $6.00     | $15.00    |
| 50 pts      | $1.50          | $2.50    | $5.00      | $10.00    | $25.00    |
| 75 pts      | $2.25          | $3.75    | $7.50      | $15.00    | $37.50    |
| 100 pts     | $3.00          | $5.00    | $10.00     | $20.00    | $50.00    |
| 150 pts     | $4.50          | $7.50    | $15.00     | $30.00    | $75.00    |
| 200 pts     | $6.00          | $10.00   | $20.00     | $40.00    | $100.00   |

★ = Agent TradeSgnl default lot

### 3-TP Payout Table — V10 at 1.00 lot (agent default)

| SL (pts) | Risk ($) | TP1 1:1 (33%) | TP2 1.5:1 (50% rem) | Full Exit TP3 ($) |
|----------|----------|----------------|----------------------|-------------------|
| 30 pts   | $3.00    | +$1.00         | +$1.13               | +$6.00            |
| 50 pts   | $5.00    | +$1.65         | +$1.88               | +$10.00           |
| 100 pts  | $10.00   | +$3.30         | +$3.75               | +$20.00           |
| 150 pts  | $15.00   | +$4.95         | +$5.63               | +$30.00           |

### Required Lot Size — V10 (to hit exact dollar risk target)

Formula: `Lot Size = $ Risk ÷ (SL pts × $0.10)`

| Target Risk | SL 30 pts | SL 50 pts | SL 75 pts | SL 100 pts | SL 150 pts |
|-------------|-----------|-----------|-----------|------------|------------|
| $3.00       | 1.00      | 0.60      | 0.40      | 0.30       | 0.20       |
| $5.00       | 1.67      | 1.00      | 0.67      | 0.50       | 0.33       |
| $10.00      | 3.33      | 2.00      | 1.33      | 1.00       | 0.67       |
| $15.00      | 5.00      | 3.00      | 2.00      | 1.50       | 1.00       |

---

## SECTION 6 — ACCOUNT RISK REALITY TABLE

### What 1 trade actually costs — at agent default lots

| Asset | Agent Lot | SL 50 pts | SL 100 pts | SL 150 pts | SL 200 pts |
|-------|-----------|-----------|------------|------------|------------|
| XAUUSD | 0.05 | $2.50 | $5.00 | $7.50 | $10.00 |
| GBPUSD | 0.05 | $2.50 (5 pip) | $5.00 (10 pip) | $7.50 (15 pip) | $10.00 (20 pip) |
| V75 | 0.10 | $5.00 | $10.00 | $15.00 | $20.00 |
| V25 | 0.50 | $2.50 | $5.00 | $7.50 | $10.00 |
| V10 | 1.00 | $5.00 | $10.00 | $15.00 | $20.00 |

### % of Account at Risk (at agent defaults, 100 pt SL)

| Account Balance | XAUUSD 0.05 | GBPUSD 0.05 | V75 0.10 | V25 0.50 | V10 1.00 |
|-----------------|-------------|-------------|----------|----------|----------|
| $50 live        | 10%         | 10%         | 20%      | 10%      | 20%      |
| $100 live       | 5%          | 5%          | 10%      | 5%       | 10%      |
| $200 live       | 2.5%        | 2.5%        | 5%       | 2.5%     | 5%       |
| $500 live       | 1%          | 1%          | 2%       | 1%       | 2%       |
| $10,000 prop    | 0.05%       | 0.05%       | 0.10%    | 0.05%    | 0.10%    |

> **Small account operators ($50–$100):** The agent's default lots hit 5–20% risk per trade which is aggressive for learning. Use minimum lots and manual risk setting in the agent inputs (Risk Per Trade field) until account reaches $500+.

### Recommended Maximum Lot for $50–$100 Live Account (max 5% risk)

| Asset | Max Lot @ $50 (SL 100pts) | Max Lot @ $100 (SL 100pts) |
|-------|---------------------------|----------------------------|
| XAUUSD | 0.025 lot | 0.05 lot |
| GBPUSD (10 pip SL) | 0.025 lot | 0.05 lot |
| V75 | 0.025 lot | 0.05 lot |
| V25 | 2.50 lots | 5.00 lots |
| V10 | 0.25 lot | 0.50 lot |

---

## SECTION 7 — 60-SECOND PRE-TRADE RISK CHECK

When the agent fires a signal, run this check in under 60 seconds:

```
1. READ  → Agent dashboard: Trade Setup block → SL price
2. CALC  → SL distance = |Entry - SL| (in points, shown in dashboard as "(XX.X pts)")
3. FIND  → Your lot size row in the P&L matrix above for this asset
4. CHECK → Dollar risk = SL pts × $/pt at your lot size
5. VERIFY → Is dollar risk ≤ 5% of your account?
             If YES → Execute
             If NO  → Either reduce lot OR pass this trade
6. NOTE  → TP1/TP2/TP3 dollar targets from the 3-TP payout table
```

**The agent already does all this math and shows it in the Trade Setup block.** This cheat sheet lets you verify and learn the math simultaneously.

---

## SECTION 8 — QUICK REFERENCE CARD (Print This)

### Dollar per 1 point moved (at one glance)

```
ASSET          MIN LOT    $/pt MIN LOT    AGENT LOT    $/pt AGENT LOT
─────────────────────────────────────────────────────────────────────
XAUUSD         0.01       $0.01/pt        0.05         $0.05/pt
GBPUSD         0.01       $0.10/pip       0.05         $0.50/pip
V75 Index      0.001      $0.001/pt       0.10         $0.10/pt
V25 Index      0.50       $0.05/pt        0.50         $0.05/pt
V10 Index      0.30       $0.03/pt        1.00         $0.10/pt
```

### The 1:1 RR Dollar Benchmark (what TP1 earns at agent lots)

```
ASSET + LOT       SL 50 pts → RISK    TP1 EARNS (33% position, 1:1)
──────────────────────────────────────────────────────────────────
XAUUSD 0.05       $2.50               $0.83
GBPUSD 0.05       $2.50 (5 pip SL)   $0.83
V75 0.10          $5.00               $1.65
V25 0.50          $2.50               $0.83
V10 1.00          $5.00               $1.65
```

---

*Absolute Dollar Intelligence © 2026 | ADSA v7.0 | Risk P&L Master Cheat Sheet v2.0*
*Built in Nairobi. Executed globally on Deriv MT5 via TradeSgnl Handshake.*
*Not financial advice. Pip values for V10/V25 derived from MT5 point structure — verify via Symbol Specification (right-click → Specification → Tick Value) if in doubt.*

Sources used in building this document:
- [Deriv Trading Specifications](https://deriv.com/trading-specifications)
- [Deriv Pip Calculator](https://deriv.com/trading-calculators/pip-calculator)
- [Pepperstone Pip Value Guide](https://pepperstone.com/en-af/learn-to-trade/trading-guides/what-is-pip-value/)
- [Volatility Indices Lot Size Guide](https://synthetics.info/volatility-indices-lot-size-guide/)
- [Deriv Community Pip Calculation](https://community.deriv.com/t/pip-calculation/28954)
