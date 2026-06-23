//+------------------------------------------------------------------+
//|  ABSOLUTE DOLLAR AGENT — MT5 Execution Engine                   |
//|  © Absolute Dollar Intelligence 2026                            |
//+------------------------------------------------------------------+
//
//  Architecture:
//    [1] TRIGGER    ATM Bot — ATR trailing-stop crossover
//                  Smart Signal — RSI momentum (M5 confirm, optional)
//    [2] GATE       MTF Trail lock — optional (M5 / M15 / H1 / OFF)
//    [3] EXECUTE    SL = swing ± ATR buffer
//                  Lots = Risk_$ ÷ ((sl_dist / tickSize) × tickValue)
//                  TP1→TP2→TP3 at RR multiples → Holder trail exit
//
//+------------------------------------------------------------------+
#property copyright "Absolute Dollar Intelligence 2026"
#property version   "1.00"
#include <Trade\Trade.mqh>

CTrade Trade;

// ══════════════════════════════════════════════════════════════════
// SECTION 1 — INPUTS
// ══════════════════════════════════════════════════════════════════

input group           "ATM Bot"
input double          ATM_BuySens     = 3.5;
input int             ATM_BuyPeriod   = 2;
input double          ATM_SellSens    = 3.5;
input int             ATM_SellPeriod  = 2;

input group           "MTF Trail Gate (optional)"
input bool            Trail_Enable    = true;
input string          Trail_TF        = "M15";   // M5 | M15 | H1
input int             Trail_MA_Len    = 50;
input int             Trail_ATR_Len   = 14;
input double          Trail_ATR_Mult  = 1.25;

input group           "Smart Signals"
input bool            Smart_Enable    = true;
input int             RSI_Period      = 14;
input int             RSI_PosLevel    = 55;
input int             RSI_NegLevel    = 50;
input int             EMA_Fast        = 5;
input bool            Smart_M5Confirm = true;

input group           "Risk Management"
input double          Risk_Dollars    = 15.0;
input double          Risk_SL_ATRx    = 1.5;
input int             Risk_SwingBars  = 5;
input double          TP1_RR          = 1.0;
input double          TP2_RR          = 1.5;
input double          TP3_RR          = 2.0;
input double          TP1_ClosePct    = 0.33;
input double          TP2_ClosePct    = 0.50;

// ══════════════════════════════════════════════════════════════════
// SECTION 2 — INDICATOR HANDLES
// In MQL5 indicator functions return handles, not values.
// Handles are created once in OnInit(); values read via CopyBuffer().
// ══════════════════════════════════════════════════════════════════

int h_atr_buy  = INVALID_HANDLE;   // ATR for ATM buy trigger
int h_atr_sell = INVALID_HANDLE;   // ATR for ATM sell trigger (may differ in period)
int h_atr_sl   = INVALID_HANDLE;   // ATR(14) for SL placement
int h_ema21    = INVALID_HANDLE;   // EMA(21) for SL anchor
int h_rsi_curr = INVALID_HANDLE;   // RSI current TF
int h_rsi_m5   = INVALID_HANDLE;   // RSI M5 (Smart Signal confirm)
int h_ema_curr = INVALID_HANDLE;   // EMA(fast) current TF
int h_ema_m5   = INVALID_HANDLE;   // EMA(fast) M5

// Trail handles for M5, M15, H1 — all created on init, selected by Trail_TF
int h_trail_ma [3] = {INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE};
int h_trail_atr[3] = {INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE};
ENUM_TIMEFRAMES TRAIL_TFS[3] = {PERIOD_M5, PERIOD_M15, PERIOD_H1};

// ══════════════════════════════════════════════════════════════════
// SECTION 3 — STATE
// ══════════════════════════════════════════════════════════════════

struct TrailState {
    double trail;
    int    trend;
};

struct TradeState {
    bool   active;
    int    direction;
    double entry;
    double sl;
    double tp1, tp2, tp3;
    double riskDist;
    double lots;
    ulong  ticket;
    double initialLots;
    bool   tp1Hit, tp2Hit, tp3Hit;
};

double     g_atmTrailBuy  = 0.0;
double     g_atmTrailSell = 0.0;
TrailState g_gateTF;
TradeState g_trade;
datetime   g_lastBar = 0;

// ══════════════════════════════════════════════════════════════════
// SECTION 4 — INIT / DEINIT
// ══════════════════════════════════════════════════════════════════

int OnInit() {
    ZeroMemory(g_trade);
    ZeroMemory(g_gateTF);

    // ATM Bot
    h_atr_buy  = iATR(_Symbol, PERIOD_CURRENT, ATM_BuyPeriod);
    h_atr_sell = iATR(_Symbol, PERIOD_CURRENT, ATM_SellPeriod);

    // SL & EMA anchor
    h_atr_sl = iATR(_Symbol, PERIOD_CURRENT, 14);
    h_ema21  = iMA (_Symbol, PERIOD_CURRENT, 21, 0, MODE_EMA, PRICE_CLOSE);

    // Smart Signals
    h_rsi_curr = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    h_rsi_m5   = iRSI(_Symbol, PERIOD_M5,      RSI_Period, PRICE_CLOSE);
    h_ema_curr = iMA (_Symbol, PERIOD_CURRENT, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
    h_ema_m5   = iMA (_Symbol, PERIOD_M5,      EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);

    // Trail gate handles for all three TFs
    for (int i = 0; i < 3; i++) {
        h_trail_ma [i] = iMA (_Symbol, TRAIL_TFS[i], Trail_MA_Len,  0, MODE_EMA, PRICE_CLOSE);
        h_trail_atr[i] = iATR(_Symbol, TRAIL_TFS[i], Trail_ATR_Len);
    }

    // Validate
    if (h_atr_buy  == INVALID_HANDLE || h_atr_sell == INVALID_HANDLE ||
        h_atr_sl   == INVALID_HANDLE || h_ema21    == INVALID_HANDLE ||
        h_rsi_curr == INVALID_HANDLE || h_rsi_m5   == INVALID_HANDLE ||
        h_ema_curr == INVALID_HANDLE || h_ema_m5   == INVALID_HANDLE) {
        Print("[ADA] INIT FAILED — could not create indicator handles");
        return INIT_FAILED;
    }

    Trade.SetExpertMagicNumber(20260101);
    Trade.SetDeviationInPoints(20);
    Print("[ADA] Initialised — Trail gate: ", Trail_Enable ? Trail_TF : "OFF",
          " | CLAN: OFF | Risk $", Risk_Dollars);
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    // Release handles
    int all[] = {h_atr_buy, h_atr_sell, h_atr_sl, h_ema21,
                 h_rsi_curr, h_rsi_m5, h_ema_curr, h_ema_m5};
    for (int i = 0; i < ArraySize(all); i++)
        if (all[i] != INVALID_HANDLE) IndicatorRelease(all[i]);
    for (int i = 0; i < 3; i++) {
        if (h_trail_ma [i] != INVALID_HANDLE) IndicatorRelease(h_trail_ma[i]);
        if (h_trail_atr[i] != INVALID_HANDLE) IndicatorRelease(h_trail_atr[i]);
    }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 5 — VALUE HELPER
// Single call to read one bar of any indicator buffer.
// shift=1 → last confirmed bar (bar[1]), which is what we always want.
// ══════════════════════════════════════════════════════════════════

double V(int handle, int shift = 1, int buf = 0) {
    double arr[];
    ArraySetAsSeries(arr, true);
    if (CopyBuffer(handle, buf, shift, 1, arr) <= 0) return 0.0;
    return arr[0];
}

// ══════════════════════════════════════════════════════════════════
// SECTION 6 — MAIN LOOP
// ══════════════════════════════════════════════════════════════════

void OnTick() {
    datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if (barTime == g_lastBar) {
        if (g_trade.active) ManageTrade();
        return;
    }
    g_lastBar = barTime;

    // ── [1] TRIGGER ───────────────────────────────────────────────
    bool atmBuy    = CalcATMTrigger(true,  g_atmTrailBuy);
    bool atmSell   = CalcATMTrigger(false, g_atmTrailSell);
    bool smartBuy  = Smart_Enable ? CalcSmartSignal(true)  : false;
    bool smartSell = Smart_Enable ? CalcSmartSignal(false) : false;

    bool trigBuy  = atmBuy  || smartBuy;
    bool trigSell = atmSell || smartSell;

    if (!trigBuy && !trigSell) return;

    // ── [2] GATE — optional MTF trail ────────────────────────────
    if (Trail_Enable) {
        int tfIdx = TrailTFIndex();
        CalcTrailGate(h_trail_ma[tfIdx], h_trail_atr[tfIdx], TRAIL_TFS[tfIdx]);

        trigBuy  = trigBuy  && (g_gateTF.trend ==  1);
        trigSell = trigSell && (g_gateTF.trend == -1);

        if (!trigBuy && !trigSell) return;
    }

    // ── [3] EXECUTE ───────────────────────────────────────────────
    if (g_trade.active) return;

    if (trigBuy)       OpenTrade(1);
    else if (trigSell) OpenTrade(-1);
}

// ══════════════════════════════════════════════════════════════════
// SECTION 7 — TRIGGER FUNCTIONS
// ══════════════════════════════════════════════════════════════════

// ATM Bot — pass trail by reference so it updates in place.
// Reference parameter works; ternary-to-reference does not.
bool CalcATMTrigger(bool isBuy, double &trail) {
    double atr   = isBuy ? V(h_atr_buy) : V(h_atr_sell);
    double sens  = isBuy ? ATM_BuySens  : ATM_SellSens;
    double nLoss = sens * atr;
    double src   = iClose(_Symbol, PERIOD_CURRENT, 1);
    double srcP  = iClose(_Symbol, PERIOD_CURRENT, 2);

    if (trail == 0.0) {
        trail = isBuy ? src - nLoss : src + nLoss;
        return false;
    }

    double prev = trail;

    if (src > prev && srcP > prev)
        trail = MathMax(prev, src - nLoss);
    else if (src < prev && srcP < prev)
        trail = MathMin(prev, src + nLoss);
    else
        trail = (src > prev) ? src - nLoss : src + nLoss;

    return isBuy
        ? (src > trail && srcP <= prev)
        : (src < trail && srcP >= prev);
}

// Smart Signal — RSI momentum cross with optional M5 confirmation
bool CalcSmartSignal(bool isBull) {
    double rsi  = V(h_rsi_curr, 1);
    double rsiP = V(h_rsi_curr, 2);
    double ema1 = V(h_ema_curr, 1);
    double ema2 = V(h_ema_curr, 2);

    bool m5ok = true;
    if (Smart_M5Confirm) {
        double rsi5  = V(h_rsi_m5, 1);
        double ema5a = V(h_ema_m5, 1);
        double ema5b = V(h_ema_m5, 2);
        m5ok = isBull
            ? (rsi5 > RSI_PosLevel && ema5a > ema5b)
            : (rsi5 < RSI_NegLevel && ema5a < ema5b);
    }

    return isBull
        ? (rsiP < RSI_PosLevel && rsi >= RSI_PosLevel && ema1 > ema2 && m5ok)
        : (rsiP > RSI_NegLevel && rsi <= RSI_NegLevel && ema1 < ema2 && m5ok);
}

// ══════════════════════════════════════════════════════════════════
// SECTION 8 — TRAIL GATE
// ══════════════════════════════════════════════════════════════════

void CalcTrailGate(int hMA, int hATR, ENUM_TIMEFRAMES tf) {
    double ma    = V(hMA,  1);
    double atr   = V(hATR, 1);
    double src   = iClose(_Symbol, tf, 1);
    double rawUp = ma - atr * Trail_ATR_Mult;
    double rawDn = ma + atr * Trail_ATR_Mult;

    if (g_gateTF.trail == 0.0) {
        g_gateTF.trend = (src > ma) ? 1 : -1;
        g_gateTF.trail = (g_gateTF.trend == 1) ? rawUp : rawDn;
        return;
    }

    double prev = g_gateTF.trail;
    if (g_gateTF.trend == 1) {
        g_gateTF.trail = MathMax(rawUp, prev);
        if (src < g_gateTF.trail) { g_gateTF.trend = -1; g_gateTF.trail = rawDn; }
    } else {
        g_gateTF.trail = MathMin(rawDn, prev);
        if (src > g_gateTF.trail) { g_gateTF.trend =  1; g_gateTF.trail = rawUp; }
    }
}

int TrailTFIndex() {
    if (Trail_TF == "M5") return 0;
    if (Trail_TF == "H1") return 2;
    return 1;   // M15 default
}

// ══════════════════════════════════════════════════════════════════
// SECTION 9 — EXECUTION  (Platinum Risk Model)
// ══════════════════════════════════════════════════════════════════

void OpenTrade(int dir) {
    double src   = iClose(_Symbol, PERIOD_CURRENT, 1);
    double atr   = V(h_atr_sl);
    double ema21 = V(h_ema21);

    // ── SL placement ────────────────────────────────────────────────
    double sl;
    if (dir == 1) {
        int    loIdx    = iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, Risk_SwingBars, 1);
        double swingLow = iLow(_Symbol, PERIOD_CURRENT, loIdx);
        sl = MathMax(ema21, swingLow) - atr * Risk_SL_ATRx;
        if (sl >= src) sl = src - atr * 1.5;
    } else {
        int    hiIdx     = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, Risk_SwingBars, 1);
        double swingHigh = iHigh(_Symbol, PERIOD_CURRENT, hiIdx);
        sl = MathMin(ema21, swingHigh) + atr * Risk_SL_ATRx;
        if (sl <= src) sl = src + atr * 1.5;
    }

    double riskDist = MathAbs(src - sl);

    // ── Lot size via tick-value reverse engineering ───────────────────
    // If SL hit: loss = (riskDist / tickSize) × tickValue × lots
    // Solve for lots: lots = Risk_$ / ((riskDist / tickSize) × tickValue)
    double lots = CalcLotSize(riskDist);
    if (lots <= 0.0) { Print("[ADA] CalcLotSize=0 — skip"); return; }

    // ── TP levels ────────────────────────────────────────────────────
    double tp1 = dir == 1 ? src + riskDist * TP1_RR : src - riskDist * TP1_RR;
    double tp2 = dir == 1 ? src + riskDist * TP2_RR : src - riskDist * TP2_RR;
    double tp3 = dir == 1 ? src + riskDist * TP3_RR : src - riskDist * TP3_RR;

    // ── Order ────────────────────────────────────────────────────────
    bool ok = (dir == 1)
        ? Trade.Buy (lots, _Symbol, 0, sl, tp3, "ADA-LONG")
        : Trade.Sell(lots, _Symbol, 0, sl, tp3, "ADA-SHORT");

    if (!ok) {
        PrintFormat("[ADA] Order failed %d: %s",
                    Trade.ResultRetcode(), Trade.ResultRetcodeDescription());
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
    g_trade.lots        = lots;
    g_trade.ticket      = Trade.ResultOrder();
    g_trade.initialLots = lots;
    g_trade.tp1Hit = g_trade.tp2Hit = g_trade.tp3Hit = false;

    PrintFormat("[ADA] %s | Entry %.5f | SL %.5f (%.1f pips / $%.2f) | "
                "TP1 %.5f (1R) | TP2 %.5f (1.5R) | TP3 %.5f (2R) | Lots %.4f",
                dir == 1 ? "LONG" : "SHORT",
                src, sl, DistToPips(riskDist), Risk_Dollars,
                tp1, tp2, tp3, lots);
}

// ══════════════════════════════════════════════════════════════════
// SECTION 10 — TRADE MANAGEMENT  (TP1 → TP2 → TP3 → Holder Mode)
// ══════════════════════════════════════════════════════════════════

void ManageTrade() {
    if (!g_trade.active) return;

    bool   isLong = (g_trade.direction == 1);
    double price  = isLong
        ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
        : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    // ── TP1 ─────────────────────────────────────────────────────────
    if (!g_trade.tp1Hit) {
        if (isLong ? price >= g_trade.tp1 : price <= g_trade.tp1) {
            PartialClose(NormLots(g_trade.initialLots * TP1_ClosePct));
            ModifySL(g_trade.entry);
            g_trade.sl     = g_trade.entry;
            g_trade.tp1Hit = true;
            PrintFormat("[ADA] TP1 (%.1f pips) — SL → breakeven",
                        DistToPips(MathAbs(g_trade.tp1 - g_trade.entry)));
        }
        return;
    }

    // ── TP2 ─────────────────────────────────────────────────────────
    if (!g_trade.tp2Hit) {
        if (isLong ? price >= g_trade.tp2 : price <= g_trade.tp2) {
            double remaining = g_trade.initialLots * (1.0 - TP1_ClosePct);
            PartialClose(NormLots(remaining * TP2_ClosePct));
            g_trade.tp2Hit = true;
            PrintFormat("[ADA] TP2 (%.1f pips) — runner to TP3",
                        DistToPips(MathAbs(g_trade.tp2 - g_trade.entry)));
        }
        return;
    }

    // ── TP3 → switch to Holder Mode ──────────────────────────────────
    if (!g_trade.tp3Hit) {
        if (isLong ? price >= g_trade.tp3 : price <= g_trade.tp3) {
            g_trade.tp3Hit = true;
            Print("[ADA] TP3 — Holder Mode active");
        }
    }

    // ── Holder Mode: trail runner with gate trail ─────────────────────
    if (g_trade.tp3Hit) {
        int tfIdx = Trail_Enable ? TrailTFIndex() : 1;   // M15 fallback
        CalcTrailGate(h_trail_ma[tfIdx], h_trail_atr[tfIdx], TRAIL_TFS[tfIdx]);

        double trailSL = g_gateTF.trail;
        bool   improved = isLong ? trailSL > g_trade.sl : trailSL < g_trade.sl;
        if (improved) { ModifySL(trailSL); g_trade.sl = trailSL; }

        bool broken = isLong ? price < trailSL : price > trailSL;
        if (broken) {
            Trade.PositionClose(g_trade.ticket);
            ZeroMemory(g_trade);
            g_trade.active = false;
            Print("[ADA] Holder exit — trail broken");
        }
    }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 11 — LOT SIZING & UTILITIES
// ══════════════════════════════════════════════════════════════════

double CalcLotSize(double slDist) {
    double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    if (tickSize <= 0.0 || tickValue <= 0.0) return 0.0;

    double riskPerLot = (slDist / tickSize) * tickValue;
    if (riskPerLot <= 0.0) return 0.0;

    return NormLots(Risk_Dollars / riskPerLot);
}

double NormLots(double lots) {
    double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double minL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    return MathMax(minL, MathMin(maxL, MathFloor(lots / step) * step));
}

double DistToPips(double dist) {
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double pip = _Point * (digits % 2 == 1 ? 10.0 : 1.0);
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
