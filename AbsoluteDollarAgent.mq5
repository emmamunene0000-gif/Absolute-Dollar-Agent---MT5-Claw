//+------------------------------------------------------------------+
//|  ABSOLUTE DOLLAR AGENT — MT5 Execution Engine                   |
//|  © Absolute Dollar Intelligence 2026                            |
//+------------------------------------------------------------------+
//
//  Architecture:
//
//    OnTick()
//      │
//      ├─ [1] TRIGGER    ATM Bot  — ATR trailing-stop crossover
//      │                 Smart Signal — RSI momentum (M5 confirm, optional)
//      │
//      ├─ [2] GATE       MTF Trail lock — optional (M5 / M15 / H1 / OFF)
//      │                 When ON: trail direction on chosen TF must agree.
//      │                 When OFF: trigger fires directly.
//      │
//      └─ [3] EXECUTE    SL  = swing extreme ± ATR buffer
//                        Lot = Risk_$ ÷ (sl_ticks × tick_value_per_lot)
//                        TP1/TP2/TP3 = SL_dist × RR multipliers
//                        ManageTrade() — partial exits → Holder trail
//
//+------------------------------------------------------------------+
#property copyright "Absolute Dollar Intelligence 2026"
#property version   "1.00"
#include <Trade\Trade.mqh>

CTrade Trade;

// ══════════════════════════════════════════════════════════════════
// SECTION 1 — INPUTS
// ══════════════════════════════════════════════════════════════════

// ── ATM Bot ────────────────────────────────────────────────────────
input group           "ATM Bot"
input double          ATM_BuySens     = 3.5;   // Buy ATR multiplier
input int             ATM_BuyPeriod   = 2;     // Buy ATR period
input double          ATM_SellSens    = 3.5;   // Sell ATR multiplier
input int             ATM_SellPeriod  = 2;     // Sell ATR period

// ── MTF Trail Gate (optional direction lock) ───────────────────────
input group           "MTF Trail Gate (optional)"
input bool            Trail_Enable    = true;          // ON = hard gate, OFF = trigger fires freely
input string          Trail_TF        = "M15";         // Timeframe to lock on: M5 | M15 | H1
input int             Trail_MA_Len    = 50;            // Trail EMA length
input int             Trail_ATR_Len   = 14;            // Trail ATR length
input double          Trail_ATR_Mult  = 1.25;          // Trail ATR multiplier

// ── Smart Signals ─────────────────────────────────────────────────
input group           "Smart Signals"
input bool            Smart_Enable    = true;   // RSI-momentum entries alongside ATM
input int             RSI_Period      = 14;
input int             RSI_PosLevel    = 55;     // Bull cross-above threshold
input int             RSI_NegLevel    = 50;     // Bear cross-below threshold
input int             EMA_Fast        = 5;      // EMA slope for momentum
input bool            Smart_M5Confirm = true;   // Require M5 RSI to agree

// ── Risk ──────────────────────────────────────────────────────────
input group           "Risk Management"
input double          Risk_Dollars    = 15.0;  // $ to risk per trade
input double          Risk_SL_ATRx    = 1.5;   // SL ATR buffer multiplier
input int             Risk_SwingBars  = 5;     // Bars back for swing SL anchor
input double          TP1_RR          = 1.0;   // TP1 risk:reward ratio
input double          TP2_RR          = 1.5;   // TP2 risk:reward ratio
input double          TP3_RR          = 2.0;   // TP3 risk:reward ratio
input double          TP1_ClosePct    = 0.33;  // % of position to close at TP1
input double          TP2_ClosePct    = 0.50;  // % of remaining to close at TP2

// ══════════════════════════════════════════════════════════════════
// SECTION 2 — STATE
// ══════════════════════════════════════════════════════════════════

struct TrailState {
    double trail;
    int    trend;   // 1 = bull, -1 = bear, 0 = uninitialised
};

struct TradeState {
    bool   active;
    int    direction;     // 1 = long, -1 = short
    double entry;
    double sl;
    double tp1, tp2, tp3;
    double riskDist;      // price distance to SL
    double riskPips;      // same in pips (for display)
    double lots;
    ulong  ticket;
    double initialLots;
    bool   tp1Hit;
    bool   tp2Hit;
    bool   tp3Hit;
};

// ATM Bot trail state (maintained bar-by-bar)
double     g_atmTrailBuy  = 0.0;
double     g_atmTrailSell = 0.0;

// Gate trail state for chosen TF
TrailState g_gateTF;

// Trade state
TradeState g_trade;

// One-bar timer
datetime   g_lastBar = 0;

// ══════════════════════════════════════════════════════════════════
// SECTION 3 — INIT
// ══════════════════════════════════════════════════════════════════

int OnInit() {
    ZeroMemory(g_trade);
    ZeroMemory(g_gateTF);
    Trade.SetExpertMagicNumber(20260101);
    Trade.SetDeviationInPoints(20);
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {}

// ══════════════════════════════════════════════════════════════════
// SECTION 4 — MAIN LOOP
// ══════════════════════════════════════════════════════════════════

void OnTick() {
    // Confirmed-bar cadence
    datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if (barTime == g_lastBar) {
        if (g_trade.active) ManageTrade();   // sub-bar TP/trail checks
        return;
    }
    g_lastBar = barTime;

    // ── [1] TRIGGER ───────────────────────────────────────────────
    bool atmBuy    = CalcATMTrigger(true);
    bool atmSell   = CalcATMTrigger(false);
    bool smartBuy  = Smart_Enable ? CalcSmartSignal(true)  : false;
    bool smartSell = Smart_Enable ? CalcSmartSignal(false) : false;

    bool trigBuy  = atmBuy  || smartBuy;
    bool trigSell = atmSell || smartSell;

    if (!trigBuy && !trigSell) return;

    // ── [2] GATE — optional MTF trail ────────────────────────────
    if (Trail_Enable) {
        ENUM_TIMEFRAMES gateTF = ParseTF(Trail_TF);
        CalcTrailForTF(gateTF, g_gateTF);

        bool trailOkLong  = (g_gateTF.trend == 1);
        bool trailOkShort = (g_gateTF.trend == -1);

        trigBuy  = trigBuy  && trailOkLong;
        trigSell = trigSell && trailOkShort;

        if (!trigBuy && !trigSell) return;
    }

    // ── [3] EXECUTE ───────────────────────────────────────────────
    if (g_trade.active) return;   // one trade at a time

    if (trigBuy)       OpenTrade(1);
    else if (trigSell) OpenTrade(-1);
}

// ══════════════════════════════════════════════════════════════════
// SECTION 5 — TRIGGER FUNCTIONS
// ══════════════════════════════════════════════════════════════════

// ATM Bot — ATR trailing stop, returns true on the crossover bar only
bool CalcATMTrigger(bool isBuy) {
    double sens   = isBuy ? ATM_BuySens   : ATM_SellSens;
    int    period = isBuy ? ATM_BuyPeriod : ATM_SellPeriod;

    double atr   = iATR(_Symbol, PERIOD_CURRENT, period, 1);
    double nLoss = sens * atr;
    double src   = iClose(_Symbol, PERIOD_CURRENT, 1);   // confirmed close
    double srcP  = iClose(_Symbol, PERIOD_CURRENT, 2);   // previous close

    double &trail = isBuy ? g_atmTrailBuy : g_atmTrailSell;

    // First bar: seed the trail
    if (trail == 0.0) {
        trail = isBuy ? src - nLoss : src + nLoss;
        return false;
    }

    double prev = trail;

    // Ratchet the trail
    if (src > prev && srcP > prev)
        trail = MathMax(prev, src - nLoss);
    else if (src < prev && srcP < prev)
        trail = MathMin(prev, src + nLoss);
    else
        trail = (src > prev) ? src - nLoss : src + nLoss;

    // Signal = price just crossed the trail
    return isBuy
        ? (src > trail && srcP <= prev)    // crossed above
        : (src < trail && srcP >= prev);   // crossed below
}

// Smart Signal — RSI momentum cross, optional M5 confirmation
bool CalcSmartSignal(bool isBull) {
    double rsi  = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE, 1);
    double rsiP = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE, 2);
    double ema1 = iMA(_Symbol, PERIOD_CURRENT, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 1);
    double ema2 = iMA(_Symbol, PERIOD_CURRENT, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 2);

    bool m5ok = true;
    if (Smart_M5Confirm) {
        double rsi5  = iRSI(_Symbol, PERIOD_M5, RSI_Period, PRICE_CLOSE, 1);
        double ema5a = iMA(_Symbol,  PERIOD_M5, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 1);
        double ema5b = iMA(_Symbol,  PERIOD_M5, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 2);
        m5ok = isBull
            ? (rsi5 > RSI_PosLevel && ema5a > ema5b)
            : (rsi5 < RSI_NegLevel && ema5a < ema5b);
    }

    return isBull
        ? (rsiP < RSI_PosLevel && rsi >= RSI_PosLevel && ema1 > ema2 && m5ok)
        : (rsiP > RSI_NegLevel && rsi <= RSI_NegLevel && ema1 < ema2 && m5ok);
}

// ══════════════════════════════════════════════════════════════════
// SECTION 6 — TRAIL GATE
// ══════════════════════════════════════════════════════════════════

void CalcTrailForTF(ENUM_TIMEFRAMES tf, TrailState &state) {
    double ma    = iMA(_Symbol, tf, Trail_MA_Len,  0, MODE_EMA,  PRICE_CLOSE, 1);
    double atr   = iATR(_Symbol, tf, Trail_ATR_Len, 1);
    double src   = iClose(_Symbol, tf, 1);
    double rawUp = ma - atr * Trail_ATR_Mult;
    double rawDn = ma + atr * Trail_ATR_Mult;

    if (state.trail == 0.0) {
        state.trend = (src > ma) ? 1 : -1;
        state.trail = (state.trend == 1) ? rawUp : rawDn;
        return;
    }

    double prev = state.trail;
    if (state.trend == 1) {
        state.trail = MathMax(rawUp, prev);
        if (src < state.trail) { state.trend = -1; state.trail = rawDn; }
    } else {
        state.trail = MathMin(rawDn, prev);
        if (src > state.trail) { state.trend =  1; state.trail = rawUp; }
    }
}

ENUM_TIMEFRAMES ParseTF(string s) {
    if (s == "M5")  return PERIOD_M5;
    if (s == "H1")  return PERIOD_H1;
    return PERIOD_M15;   // default
}

// ══════════════════════════════════════════════════════════════════
// SECTION 7 — EXECUTION  (Platinum Risk Model)
// ══════════════════════════════════════════════════════════════════

void OpenTrade(int dir) {
    double src  = iClose(_Symbol, PERIOD_CURRENT, 1);
    double atr  = iATR(_Symbol,   PERIOD_CURRENT, 14, 1);
    double ema21= iMA(_Symbol, PERIOD_CURRENT, 21, 0, MODE_EMA, PRICE_CLOSE, 1);

    // ── SL placement ────────────────────────────────────────────────
    double sl;
    if (dir == 1) {
        int    loIdx    = iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, Risk_SwingBars, 1);
        double swingLow = iLow(_Symbol, PERIOD_CURRENT, loIdx);
        sl = MathMax(ema21, swingLow) - atr * Risk_SL_ATRx;
        if (sl >= src) sl = src - atr * 1.5;   // fallback: SL must be below entry
    } else {
        int    hiIdx     = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, Risk_SwingBars, 1);
        double swingHigh = iHigh(_Symbol, PERIOD_CURRENT, hiIdx);
        sl = MathMin(ema21, swingHigh) + atr * Risk_SL_ATRx;
        if (sl <= src) sl = src + atr * 1.5;
    }

    double riskDist = MathAbs(src - sl);

    // ── Lot size: reverse-engineered from tick value ─────────────────
    // If SL is hit the loss = (riskDist / tickSize) × tickValue × lots
    // Solving for lots: lots = Risk_$ / ((riskDist / tickSize) × tickValue)
    double lots = CalcLotSize(riskDist);
    if (lots <= 0.0) {
        Print("[ADA] CalcLotSize returned 0 — skipping trade");
        return;
    }

    // ── TP levels ────────────────────────────────────────────────────
    double tp1 = dir == 1 ? src + riskDist * TP1_RR : src - riskDist * TP1_RR;
    double tp2 = dir == 1 ? src + riskDist * TP2_RR : src - riskDist * TP2_RR;
    double tp3 = dir == 1 ? src + riskDist * TP3_RR : src - riskDist * TP3_RR;

    // ── Send order ───────────────────────────────────────────────────
    bool ok = (dir == 1)
        ? Trade.Buy (lots, _Symbol, 0, sl, tp3, "ADA-LONG")
        : Trade.Sell(lots, _Symbol, 0, sl, tp3, "ADA-SHORT");

    if (!ok) {
        PrintFormat("[ADA] Order failed: %d %s", Trade.ResultRetcode(), Trade.ResultRetcodeDescription());
        return;
    }

    // ── Lock state ───────────────────────────────────────────────────
    g_trade.active      = true;
    g_trade.direction   = dir;
    g_trade.entry       = src;
    g_trade.sl          = sl;
    g_trade.tp1         = tp1;
    g_trade.tp2         = tp2;
    g_trade.tp3         = tp3;
    g_trade.riskDist    = riskDist;
    g_trade.riskPips    = DistToPips(riskDist);
    g_trade.lots        = lots;
    g_trade.ticket      = Trade.ResultOrder();
    g_trade.initialLots = lots;
    g_trade.tp1Hit      = false;
    g_trade.tp2Hit      = false;
    g_trade.tp3Hit      = false;

    PrintFormat(
        "[ADA] %s | Entry %.5f | SL %.5f (%.1f pips / $%.2f) | "
        "TP1 %.5f (%.1f pips / 1R) | TP2 %.5f (%.1f pips / 1.5R) | "
        "TP3 %.5f (%.1f pips / 2R) | Lots %.4f",
        dir == 1 ? "LONG" : "SHORT",
        src, sl, DistToPips(riskDist), Risk_Dollars,
        tp1, DistToPips(MathAbs(tp1 - src)),
        tp2, DistToPips(MathAbs(tp2 - src)),
        tp3, DistToPips(MathAbs(tp3 - src)),
        lots
    );
}

// ══════════════════════════════════════════════════════════════════
// SECTION 8 — TRADE MANAGEMENT  (TP1 → TP2 → TP3 → Holder Mode)
// ══════════════════════════════════════════════════════════════════

void ManageTrade() {
    if (!g_trade.active) return;

    double price  = SymbolInfoDouble(_Symbol,
                       g_trade.direction == 1 ? SYMBOL_BID : SYMBOL_ASK);
    bool   isLong = (g_trade.direction == 1);

    // ── TP1 ─────────────────────────────────────────────────────────
    if (!g_trade.tp1Hit) {
        bool hit = isLong ? price >= g_trade.tp1 : price <= g_trade.tp1;
        if (hit) {
            double closeVol = NormLots(g_trade.initialLots * TP1_ClosePct);
            PartialClose(closeVol);
            ModifySL(g_trade.entry);   // breakeven
            g_trade.sl     = g_trade.entry;
            g_trade.tp1Hit = true;
            PrintFormat("[ADA] TP1 hit (%.1f pips) — SL to breakeven", DistToPips(MathAbs(g_trade.tp1 - g_trade.entry)));
        }
        return;
    }

    // ── TP2 ─────────────────────────────────────────────────────────
    if (!g_trade.tp2Hit) {
        bool hit = isLong ? price >= g_trade.tp2 : price <= g_trade.tp2;
        if (hit) {
            double remaining  = g_trade.initialLots * (1.0 - TP1_ClosePct);
            double closeVol   = NormLots(remaining * TP2_ClosePct);
            PartialClose(closeVol);
            g_trade.tp2Hit = true;
            PrintFormat("[ADA] TP2 hit (%.1f pips) — runner to TP3", DistToPips(MathAbs(g_trade.tp2 - g_trade.entry)));
        }
        return;
    }

    // ── TP3 reached — switch to Holder Mode ─────────────────────────
    if (!g_trade.tp3Hit) {
        bool hit = isLong ? price >= g_trade.tp3 : price <= g_trade.tp3;
        if (hit) {
            g_trade.tp3Hit = true;
            PrintFormat("[ADA] TP3 hit (%.1f pips) — Holder Mode: trailing on gate trail", DistToPips(MathAbs(g_trade.tp3 - g_trade.entry)));
        }
    }

    // ── Holder Mode — trail with the gate trail ──────────────────────
    if (g_trade.tp3Hit) {
        // Keep the gate trail fresh even if Trail_Enable is OFF
        // (use M15 as default holder trail)
        ENUM_TIMEFRAMES holderTF = Trail_Enable ? ParseTF(Trail_TF) : PERIOD_M15;
        TrailState holder;
        CalcTrailForTF(holderTF, holder);

        double trailSL = holder.trail;
        bool   improved = isLong ? trailSL > g_trade.sl : trailSL < g_trade.sl;

        if (improved) {
            ModifySL(trailSL);
            g_trade.sl = trailSL;
        }

        // Trail broken → exit runner
        bool trailBroken = isLong ? price < trailSL : price > trailSL;
        if (trailBroken) {
            Trade.PositionClose(g_trade.ticket);
            ZeroMemory(g_trade);
            g_trade.active = false;
            Print("[ADA] Holder Mode exit — trail broken");
        }
    }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 9 — LOT SIZE  (tick-value reverse engineering)
// ══════════════════════════════════════════════════════════════════

double CalcLotSize(double slDist) {
    // MT5 already knows everything about this instrument:
    //   tickSize  = minimum price move
    //   tickValue = account-currency P&L per lot per tick
    //
    // So:  risk_per_lot_if_sl_hit = (slDist / tickSize) * tickValue
    //      lots = Risk_Dollars / risk_per_lot_if_sl_hit
    //
    // This works universally — forex, crypto, indices, futures —
    // no asset-class switching required.

    double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

    if (tickSize <= 0.0 || tickValue <= 0.0) {
        Print("[ADA] Tick info unavailable — cannot size position");
        return 0.0;
    }

    double riskPerLot = (slDist / tickSize) * tickValue;
    if (riskPerLot <= 0.0) return 0.0;

    double lots = Risk_Dollars / riskPerLot;
    return NormLots(lots);
}

// ══════════════════════════════════════════════════════════════════
// SECTION 10 — UTILITIES
// ══════════════════════════════════════════════════════════════════

double NormLots(double lots) {
    double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double minL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    lots = MathFloor(lots / step) * step;
    return MathMax(minL, MathMin(maxL, lots));
}

double DistToPips(double dist) {
    // Works for 4-digit and 5-digit forex, CFDs, and crypto
    double pip = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE)
               * (SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) % 2 == 1 ? 10.0 : 1.0);
    return pip > 0.0 ? dist / pip : dist / _Point;
}

void PartialClose(double vol) {
    if (vol < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) return;
    Trade.PositionClosePartial(g_trade.ticket, vol);
}

void ModifySL(double newSL) {
    Trade.PositionModify(g_trade.ticket, newSL, 0);
}

//+------------------------------------------------------------------+
//  END — AbsoluteDollarAgent.mq5
//+------------------------------------------------------------------+
