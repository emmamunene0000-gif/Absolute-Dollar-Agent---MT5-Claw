//+------------------------------------------------------------------+
//| AgentProtocol_LiquiditySuite.mq5                                |
//| THE AGENT PROTOCOL — LIQUIDITY SUITE v1.0 (MQL5 Port)          |
//| Phase 1: Bar-for-bar signal parity with Pine Script v6          |
//| Architecture: TRIGGER → GATE → CONFLUENCE → CONFIDENCE → EXEC   |
//+------------------------------------------------------------------+
#property copyright "Absolute Dollar Intelligence"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 10
#property indicator_plots   8

// Plot 0: Trail line
#property indicator_label1  "Trail"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLime
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// Plot 1: ATM Buy  (⚡Buy)
#property indicator_label2  "ATM Buy"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrLime
#property indicator_width2  2

// Plot 2: ATM Sell (⚡Sell)
#property indicator_label3  "ATM Sell"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrRed
#property indicator_width3  2

// Plot 3: Smart Buy  (🧠Buy)
#property indicator_label4  "Smart Buy"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrLime
#property indicator_width4  1

// Plot 4: Smart Sell (🧠Sell)
#property indicator_label5  "Smart Sell"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrRed
#property indicator_width5  1

// Plot 5: Rejected Long
#property indicator_label6  "Rejected Long"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrGray
#property indicator_width6  1

// Plot 6: Rejected Short
#property indicator_label7  "Rejected Short"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrGray
#property indicator_width7  1

// Plot 7: Trail Flip (direction change)
#property indicator_label8  "Trail Flip"
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrYellow
#property indicator_width8  2

//+------------------------------------------------------------------+
//| INPUTS — Matching Pine parameter names and defaults exactly      |
//+------------------------------------------------------------------+

// Group 1: MTF Trail
input int    ma_len      = 50;    // MA Length
input int    atr_len     = 14;    // ATR Length
input double atr_mult    = 1.25;  // Trail Distance (ATR)

// Group 2: Liquidity Trail & Zones
input int    swing_len      = 14;    // Swing Lookback
input bool   show_zones     = false; // Show Liquidity Zones
input int    max_zones      = 3;     // Max Zones
input int    extend_bars    = 50;    // Extend Bars
input double zone_atr_mult  = 0.35;  // Zone Thickness (ATR)
input bool   keep_broken    = true;  // Keep Broken Zones

// Group 3: ATM Bot
input double a_buy  = 3.0; // Buy Sensitivity
input int    c_buy  = 1;   // Buy ATR Period
input double a_sell = 3.0; // Sell Sensitivity
input int    c_sell = 1;   // Sell ATR Period

// Group 4: Market Structure
input int    swingSize        = 25;             // Swing Size
input string bosConfType      = "Candle Close"; // BOS Confirmation: Candle Close | Wick
input bool   showStructLabels = true;           // Show Structure Labels
input bool   showBOSlines     = true;           // Show BOS Lines

// Group 5: RSI Momentum
input int    rsiLen           = 14;   // RSI Length
input int    rsi_ema_len      = 5;    // Momentum EMA Length
input int    pmom             = 50;   // Positive Above
input int    nmom             = 50;   // Negative Below
input bool   sustain_momentum = true; // Sustain Momentum
input bool   use_m5_confirm   = true; // M5 RSI Confirmation

// Group 6: VWAP & Fib Regime
input bool   enableRegimeFilter = true;  // Enable Regime Filter
input bool   requireFibTrend    = false; // Require Fib Trend Confirmation
input int    prd                = 100;   // Swing Period (VWAP)
input double baseAPT            = 20.0;  // Adaptive Tracking
input bool   useAdapt           = false; // Adapt by ATR
input double volBias_vwap       = 10.0;  // Volatility Bias
input int    len_fib            = 200;   // Fib Length
input int    atrLen_fib         = 14;    // Fib ATR Length
input bool   useATR_fib         = true;  // Fib Use ATR

// Group 7: Volume Profile
input bool   vpEnabled    = true; // Enable Volume Profile
input int    vpResolution = 30;   // Resolution (bins)
input int    vpVAwidth    = 70;   // Value Area %

// Group 8: Confidence Engine
input string claw_mode        = "Moderate"; // Claw Mode: Conservative|Moderate|Aggressive|Custom
input int    custom_threshold = 60;          // Custom Threshold %
input double mtf_weight       = 1.5;         // MTF Weight
input double struct_weight    = 1.0;         // Structure Weight
input double rsi_weight_inp   = 1.0;         // RSI Weight
input double vwap_weight      = 1.0;         // VWAP Weight
input double fib_weight       = 0.5;         // Fib Weight
input double vp_weight_inp    = 0.5;         // VP Weight

// Group 10: Dashboard
input bool   dashOn = true; // Show Dashboard

//+------------------------------------------------------------------+
//| INDICATOR BUFFERS                                                |
//+------------------------------------------------------------------+
double TrailBuffer[];       // 0 - Trail line
double ATMBuyBuffer[];      // 1 - ⚡Buy arrows
double ATMSellBuffer[];     // 2 - ⚡Sell arrows
double SmartBuyBuffer[];    // 3 - 🧠Buy arrows
double SmartSellBuffer[];   // 4 - 🧠Sell arrows
double RejLongBuffer[];     // 5 - Rejected long
double RejShortBuffer[];    // 6 - Rejected short
double FlipBuffer[];        // 7 - Trail flip
double ConfLongBuffer[];    // 8 - Bull confidence % (for EA reads via iCustom)
double ConfShortBuffer[];   // 9 - Bear confidence % (for EA reads via iCustom)

// Internal state arrays (not plotted)
int    g_ltf_trend[];
double g_ltf_trail[];
int    g_m15_trend[];
int    g_h1_trend[];
bool   g_rsi_pos[];
bool   g_rsi_neg[];
int    g_struct_bias[];
int    g_vwap_dir[];
int    g_fib_trend[];
double g_vp_poc[];
double g_vp_vah[];
double g_vp_val[];

//+------------------------------------------------------------------+
//| EMA — Pine ta.ema() exact match (iterative, no lookback issue)  |
//+------------------------------------------------------------------+
void CalcEMA(const double &src[], double &out[], int period, int count)
{
    if(count <= 0 || period <= 0) return;
    double k = 2.0 / (period + 1);
    out[0] = src[0];
    for(int i = 1; i < count; i++)
        out[i] = src[i] * k + out[i-1] * (1.0 - k);
}

//+------------------------------------------------------------------+
//| ATR — Wilder's smoothing, matches Pine ta.atr()                 |
//+------------------------------------------------------------------+
void CalcATR(const double &high[], const double &low[], const double &close[],
             double &atr[], int period, int count)
{
    if(count <= 0 || period <= 0) return;
    double sum = 0;
    for(int i = 0; i < count; i++) {
        double tr;
        if(i == 0)
            tr = high[i] - low[i];
        else {
            double hl = high[i] - low[i];
            double hc = MathAbs(high[i] - close[i-1]);
            double lc = MathAbs(low[i]  - close[i-1]);
            tr = MathMax(hl, MathMax(hc, lc));
        }
        if(i < period) {
            sum += tr;
            atr[i] = (i == period - 1) ? sum / period : (i == 0 ? tr : sum / (i + 1));
        } else {
            atr[i] = (atr[i-1] * (period - 1) + tr) / period;
        }
    }
}

//+------------------------------------------------------------------+
//| RSI — Wilder's method, matches Pine ta.rsi()                    |
//+------------------------------------------------------------------+
void CalcRSI(const double &close[], double &rsi[], int period, int count)
{
    if(count <= 0 || period <= 0) return;
    double avg_gain = 0, avg_loss = 0;
    rsi[0] = 50;
    for(int i = 1; i < count; i++) {
        double chg  = close[i] - close[i-1];
        double gain = chg > 0 ? chg : 0.0;
        double loss = chg < 0 ? -chg : 0.0;
        if(i < period) {
            avg_gain += gain; avg_loss += loss;
            rsi[i] = 50;
        } else if(i == period) {
            avg_gain = (avg_gain + gain) / period;
            avg_loss = (avg_loss + loss) / period;
            rsi[i] = avg_loss == 0 ? 100 : 100.0 - 100.0 / (1.0 + avg_gain / avg_loss);
        } else {
            avg_gain = (avg_gain * (period - 1) + gain) / period;
            avg_loss = (avg_loss * (period - 1) + loss) / period;
            rsi[i] = avg_loss == 0 ? 100 : 100.0 - 100.0 / (1.0 + avg_gain / avg_loss);
        }
    }
}

//+------------------------------------------------------------------+
//| LIQUIDITY TRAIL — exact port of Pine calcLiqTrail()             |
//| State is carried bar-to-bar via arrays (replaces Pine var)      |
//+------------------------------------------------------------------+
void CalcLiqTrail(const double &close[], const double &ema[], const double &atr_arr[],
                  double &trail[], int &trend[], int count, double mult)
{
    for(int i = 0; i < count; i++) {
        double raw_up = ema[i] - atr_arr[i] * mult;
        double raw_dn = ema[i] + atr_arr[i] * mult;
        if(i == 0) {
            trend[i] = close[i] > ema[i] ? 1 : -1;
            trail[i] = close[i] > ema[i] ? raw_up : raw_dn;
        } else {
            int    prev_t = trend[i-1];
            double prev_l = trail[i-1];
            if(prev_t == 1) {
                trail[i] = MathMax(raw_up, prev_l);
                trend[i] = close[i] < trail[i] ? -1 : 1;
                if(trend[i] == -1) trail[i] = raw_dn;
            } else {
                trail[i] = MathMin(raw_dn, prev_l);
                trend[i] = close[i] > trail[i] ? 1 : -1;
                if(trend[i] == 1) trail[i] = raw_up;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| ATM BOT — exact port of Pine STEP 6                             |
//+------------------------------------------------------------------+
void CalcATMBot(const double &close[],
                const double &atr_b[], double ab,
                const double &atr_s[], double as_val,
                double &tb[], double &ts[],
                bool &buy_sig[], bool &sell_sig[], int count)
{
    for(int i = 0; i < count; i++) {
        double nl_b = ab * atr_b[i];
        double nl_s = as_val * atr_s[i];
        if(i == 0) {
            tb[i] = close[i] - nl_b;
            ts[i] = close[i] + nl_s;
        } else {
            // Buy trail: ratchets up when price above, ratchets down when below
            if(close[i] > tb[i-1] && close[i-1] > tb[i-1])
                tb[i] = MathMax(tb[i-1], close[i] - nl_b);
            else if(close[i] < tb[i-1] && close[i-1] < tb[i-1])
                tb[i] = MathMin(tb[i-1], close[i] + nl_b);
            else
                tb[i] = close[i] > tb[i-1] ? close[i] - nl_b : close[i] + nl_b;
            // Sell trail
            if(close[i] > ts[i-1] && close[i-1] > ts[i-1])
                ts[i] = MathMax(ts[i-1], close[i] - nl_s);
            else if(close[i] < ts[i-1] && close[i-1] < ts[i-1])
                ts[i] = MathMin(ts[i-1], close[i] + nl_s);
            else
                ts[i] = close[i] > ts[i-1] ? close[i] - nl_s : close[i] + nl_s;
        }
        buy_sig[i] = false; sell_sig[i] = false;
        if(i > 0) {
            // crossover(ema_buy=close, trail_buy): close crosses above trail_buy
            bool cross_up = (close[i] > tb[i]) && (close[i-1] <= tb[i-1]);
            // crossover(trail_sell, ema_sell=close): trail_sell crosses above close
            bool cross_dn = (ts[i] > close[i]) && (ts[i-1] <= close[i-1]);
            buy_sig[i]  = cross_up && (close[i] > tb[i]);
            sell_sig[i] = cross_dn && (close[i] < ts[i]);
        }
    }
}

//+------------------------------------------------------------------+
//| MTF TRAIL — compute trail on H1/M15 and map to current bars     |
//+------------------------------------------------------------------+
bool CalcMTFTrail(ENUM_TIMEFRAMES tf, const datetime &cur_time[], int cur_count,
                  int &trend_out[], int malen, int atrlen, double mult)
{
    MqlRates rates[];
    // Fetch enough history. For M1 chart + H1 trail we need ~1000 H1 bars.
    int fetch = 2000;
    int copied = CopyRates(_Symbol, tf, 0, fetch, rates);
    if(copied < atrlen + malen + 10) return false;

    // CopyRates returns [0]=most recent. Reverse to chronological (0=oldest).
    int n = copied;
    ArrayResize(rates, n);
    for(int i = 0; i < n / 2; i++) {
        MqlRates tmp = rates[i];
        rates[i] = rates[n - 1 - i];
        rates[n - 1 - i] = tmp;
    }

    double tf_close[], tf_high[], tf_low[], tf_ema[], tf_atr[], tf_trail[];
    int    tf_trend[];
    ArrayResize(tf_close, n); ArrayResize(tf_high, n); ArrayResize(tf_low, n);
    ArrayResize(tf_ema,   n); ArrayResize(tf_atr,  n); ArrayResize(tf_trail, n);
    ArrayResize(tf_trend, n);

    for(int i = 0; i < n; i++) {
        tf_close[i] = rates[i].close;
        tf_high[i]  = rates[i].high;
        tf_low[i]   = rates[i].low;
    }
    CalcEMA(tf_close, tf_ema, malen, n);
    CalcATR(tf_high, tf_low, tf_close, tf_atr, atrlen, n);
    CalcLiqTrail(tf_close, tf_ema, tf_atr, tf_trail, tf_trend, n, mult);

    ArrayResize(trend_out, cur_count);
    long tf_period_sec = PeriodSeconds(tf);

    for(int ci = 0; ci < cur_count; ci++) {
        datetime bar_t = cur_time[ci];
        // Find the HTF bar whose time <= bar_t (largest time <= bar_t)
        int htf_idx = -1;
        // Binary search (rates are chronological now)
        int lo = 0, hi = n - 1;
        while(lo <= hi) {
            int mid = (lo + hi) / 2;
            if((datetime)rates[mid].time <= bar_t) { htf_idx = mid; lo = mid + 1; }
            else hi = mid - 1;
        }
        trend_out[ci] = (htf_idx >= 0) ? tf_trend[htf_idx] : 1;
    }
    return true;
}

//+------------------------------------------------------------------+
//| RSI MOMENTUM — port of Pine STEP 7                              |
//+------------------------------------------------------------------+
void CalcRSIMomentum(const double &rsi[], const double &ema5[],
                     const double &rsi_m5[], const double &ema_m5[],
                     bool &pos[], bool &neg[],
                     bool &pos_m5[], bool &neg_m5[],
                     bool &newBull[], bool &newBear[],
                     bool &pcond[], bool &ncond[], int count)
{
    ArrayInitialize(pos, false); ArrayInitialize(neg, false);
    ArrayInitialize(pos_m5, false); ArrayInitialize(neg_m5, false);
    ArrayInitialize(newBull, false); ArrayInitialize(newBear, false);
    ArrayInitialize(pcond, false); ArrayInitialize(ncond, false);

    for(int i = 1; i < count; i++) {
        double d5   = ema5[i]  - ema5[i-1];
        double dm5  = ema_m5[i] - ema_m5[i-1];
        bool m5_bull = dm5 > 0;
        bool m5_bear = dm5 < 0;

        // Pine: p_mom = rsi[1]<pmom and rsi>pmom and rsi>nmom and change_ema5>0
        bool p_mom = (rsi[i-1] < pmom) && (rsi[i] > pmom) && (rsi[i] > nmom) && (d5 > 0);
        bool n_mom = (rsi[i] < nmom) && (d5 < 0);

        bool p_sust = sustain_momentum && pos[i-1] && (rsi[i] > pmom) && (d5 > 0);
        bool n_sust = sustain_momentum && neg[i-1] && (rsi[i] < nmom) && (d5 < 0);

        // Persist state
        pos[i] = pos[i-1]; neg[i] = neg[i-1];
        if(p_mom || p_sust) { pos[i] = true;  neg[i] = false; }
        if(n_mom || n_sust) { pos[i] = false; neg[i] = true;  }

        // M5 momentum state
        bool p_mom_m5 = (rsi_m5[i-1] < pmom) && (rsi_m5[i] > pmom) && (rsi_m5[i] > nmom) && m5_bull;
        bool n_mom_m5 = (rsi_m5[i] < nmom) && m5_bear;

        pos_m5[i] = pos_m5[i-1]; neg_m5[i] = neg_m5[i-1];
        if(p_mom_m5) { pos_m5[i] = true;  neg_m5[i] = false; }
        if(n_mom_m5) { pos_m5[i] = false; neg_m5[i] = true;  }

        // smartBull / smartBear — for newSmartBull/Bear we need prev state
        bool sb_now  = (rsi[i] > pmom)   && (d5 > 0) && (!use_m5_confirm || ((rsi_m5[i] > pmom) && m5_bull));
        bool se_now  = (rsi[i] < nmom)   && (d5 < 0) && (!use_m5_confirm || ((rsi_m5[i] < nmom) && m5_bear));

        double d5p  = (i > 1) ? ema5[i-1]  - ema5[i-2]  : 0;
        double dm5p = (i > 1) ? ema_m5[i-1] - ema_m5[i-2] : 0;
        bool sb_prev = (rsi[i-1] > pmom) && (d5p > 0) && (!use_m5_confirm || ((rsi_m5[i-1] > pmom) && (dm5p > 0)));
        bool se_prev = (rsi[i-1] < nmom) && (d5p < 0) && (!use_m5_confirm || ((rsi_m5[i-1] < nmom) && (dm5p < 0)));

        newBull[i] = sb_now && !sb_prev;
        newBear[i] = se_now && !se_prev;

        // pcondition: positive and not positive[1] and (positive_m5 or (rsi_m5>nmom and m5_bull_mom))
        pcond[i] = pos[i] && !pos[i-1] && (pos_m5[i] || (rsi_m5[i] > nmom && m5_bull));
        ncond[i] = neg[i] && !neg[i-1] && (neg_m5[i] || (rsi_m5[i] < pmom && m5_bear));
    }
}

//+------------------------------------------------------------------+
//| MARKET STRUCTURE — SMC pivots + BOS (Pine STEP 4)              |
//+------------------------------------------------------------------+
void CalcMarketStructure(const double &high[], const double &low[], const double &close[],
                         int &bias[], bool &bull_bos[], bool &bear_bos[], int count, int sw)
{
    ArrayInitialize(bias, 0);
    ArrayInitialize(bull_bos, false);
    ArrayInitialize(bear_bos, false);

    double prevH = 0, prevL = 0;
    bool hasPH = false, hasPL = false;
    bool hiActive = false, loActive = false;
    int cur_bias = 0;
    bool use_close = (bosConfType == "Candle Close");

    for(int i = sw; i < count - sw; i++) {
        // Pivot high: high[i] is highest in [i-sw, i+sw]
        bool is_ph = true;
        for(int k = i - sw; k <= i + sw && is_ph; k++)
            if(k != i && high[k] >= high[i]) is_ph = false;

        bool is_pl = true;
        for(int k = i - sw; k <= i + sw && is_pl; k++)
            if(k != i && low[k] <= low[i]) is_pl = false;

        if(is_ph) {
            if(!hasPH || high[i] >= prevH) { cur_bias = 1; }
            else                            { cur_bias = -1; }
            prevH = high[i]; hasPH = true; hiActive = true;
        }
        if(is_pl) {
            if(!hasPL || low[i] >= prevL) { if(cur_bias != -1) cur_bias = 1; }
            else                           { cur_bias = -1; }
            prevL = low[i]; hasPL = true; loActive = true;
        }

        // BOS check: has price broken prev structure level?
        double hSrc = use_close ? close[i] : high[i];
        double lSrc = use_close ? close[i] : low[i];
        if(hasPH && hiActive && hSrc > prevH) {
            bull_bos[i] = (cur_bias == 1);
            hiActive = false;
        }
        if(hasPL && loActive && lSrc < prevL) {
            bear_bos[i] = (cur_bias == -1);
            loActive = false;
        }

        bias[i] = cur_bias;
    }
    // Forward-fill bias
    for(int i = 1; i < count; i++)
        if(bias[i] == 0) bias[i] = bias[i-1];
}

//+------------------------------------------------------------------+
//| VWAP ANCHOR — adaptive EWMA from most recent swing point        |
//| Port of Pine STEP 8                                             |
//+------------------------------------------------------------------+
void CalcVWAPAnchor(const double &high[], const double &low[], const double &close[],
                    const double &vol[], int count, int prd_v, double apt,
                    int &dir_out[])
{
    ArrayInitialize(dir_out, 0);
    if(count < 2) return;

    int phL = 0, plL = 0;
    int last_swing = 0;
    double alpha = 1.0 - MathExp(-MathLog(2.0) / MathMax(1.0, apt));

    for(int i = 0; i < count; i++) {
        int win = MathMin(i + 1, prd_v);
        double hh_val = -1e18, ll_val = 1e18;
        int hh_idx = i, ll_idx = i;
        for(int k = MathMax(0, i - win + 1); k <= i; k++) {
            if(high[k] > hh_val) { hh_val = high[k]; hh_idx = k; }
            if(low[k]  < ll_val) { ll_val = low[k];  ll_idx = k; }
        }
        if(high[i] >= hh_val) phL = i;
        if(low[i]  <= ll_val) plL = i;

        // Pine: dir_vwap = vw_phL > vw_plL ? 1 : -1
        // Higher bar index = more recent.
        // phL > plL → most recent swing is a high → upswing just ended?
        // Per Pine behavior: dir=1 when phL>plL (high bar more recent = we're in uptrend)
        int dir = (phL > plL) ? 1 : -1;

        if(i == 0 || dir != dir_out[i-1])
            last_swing = dir;

        dir_out[i] = last_swing;
    }
}

//+------------------------------------------------------------------+
//| FIB BANDS — double EMA basis + ATR bands (Pine STEP 9)         |
//+------------------------------------------------------------------+
void CalcFibBands(const double &hlc3[], const double &high[], const double &low[],
                  const double &close[], int &fib_trend[], int fib_len, int fib_atr, bool use_atr, int count)
{
    double ema1[], ema2[], vol_fib[];
    ArrayResize(ema1, count); ArrayResize(ema2, count); ArrayResize(vol_fib, count);
    CalcEMA(hlc3, ema1, fib_len, count);
    CalcEMA(ema1, ema2, fib_len, count);
    if(use_atr)
        CalcATR(high, low, close, vol_fib, fib_atr, count);
    else {
        // stdev approximation
        for(int i = 0; i < count; i++) {
            int w = MathMin(i + 1, fib_len);
            double mean = 0;
            for(int k = MathMax(0, i - w + 1); k <= i; k++) mean += hlc3[k];
            mean /= w;
            double var = 0;
            for(int k = MathMax(0, i - w + 1); k <= i; k++) var += (hlc3[k] - mean) * (hlc3[k] - mean);
            vol_fib[i] = MathSqrt(var / w);
        }
    }
    fib_trend[0] = 0;
    for(int i = 1; i < count; i++) {
        if(ema2[i] > ema2[i-1])      fib_trend[i] = 1;
        else if(ema2[i] < ema2[i-1]) fib_trend[i] = -1;
        else                          fib_trend[i] = fib_trend[i-1];
    }
}

//+------------------------------------------------------------------+
//| VOLUME PROFILE — daily sessions, current TF bars                |
//| Pine uses lower_tf tick data; we use current TF bars per day.   |
//| Output: poc/vah/val per bar, reset each day.                    |
//+------------------------------------------------------------------+
void CalcVolumeProfile(const datetime &time[], const double &high[], const double &low[],
                       const double &close[], const long &tick_vol[], int count,
                       int res, int va_pct,
                       double &poc[], double &vah_arr[], double &val_arr[])
{
    ArrayInitialize(poc,     0);
    ArrayInitialize(vah_arr, 0);
    ArrayInitialize(val_arr, 0);

    int session_start = 0;
    for(int i = 1; i <= count; i++) {
        bool is_last = (i == count);
        bool new_day = false;
        if(!is_last) {
            MqlDateTime d1, d2;
            TimeToStruct(time[i],   d1);
            TimeToStruct(time[i-1], d2);
            new_day = (d1.day != d2.day || d1.mon != d2.mon);
        }

        if(new_day || is_last) {
            int end = is_last ? count - 1 : i - 1;
            int nb  = end - session_start + 1;
            if(nb < 2) { session_start = i; continue; }

            double s_hi = high[session_start], s_lo = low[session_start];
            for(int k = session_start + 1; k <= end; k++) {
                if(high[k] > s_hi) s_hi = high[k];
                if(low[k]  < s_lo) s_lo = low[k];
            }
            if(s_hi <= s_lo) { session_start = i; continue; }

            double gap = (s_hi - s_lo) / res;
            double buckets[];
            ArrayResize(buckets, res);
            ArrayInitialize(buckets, 0);

            for(int k = session_start; k <= end; k++) {
                int bkt = (int)MathFloor((close[k] - s_lo) / gap);
                if(bkt < 0) bkt = 0;
                if(bkt >= res) bkt = res - 1;
                buckets[bkt] += (double)tick_vol[k];
            }

            // POC
            int poc_idx = 0; double max_v = 0;
            for(int b = 0; b < res; b++)
                if(buckets[b] > max_v) { max_v = buckets[b]; poc_idx = b; }
            double poc_p = s_lo + (poc_idx + 0.5) * gap;

            // Value area
            double total_vol = 0;
            for(int b = 0; b < res; b++) total_vol += buckets[b];
            double target = total_vol * va_pct / 100.0;
            double accum  = buckets[poc_idx];
            int up_b = poc_idx + 1, dn_b = poc_idx - 1;
            double vah_p = s_lo + (poc_idx + 1) * gap;
            double val_p = s_lo + poc_idx * gap;
            while(accum < target && (up_b < res || dn_b >= 0)) {
                double v_up = up_b < res ? buckets[up_b] : 0;
                double v_dn = dn_b >= 0 ? buckets[dn_b] : 0;
                if(v_up >= v_dn && up_b < res) {
                    accum += v_up; vah_p = s_lo + (up_b + 1) * gap; up_b++;
                } else if(dn_b >= 0) {
                    accum += v_dn; val_p = s_lo + dn_b * gap; dn_b--;
                } else break;
            }

            for(int k = session_start; k <= end; k++) {
                poc[k]     = poc_p;
                vah_arr[k] = vah_p;
                val_arr[k] = val_p;
            }
            session_start = i;
        }
    }
}

//+------------------------------------------------------------------+
//| DASHBOARD — Comment() panel matching Pine dashboard rows        |
//+------------------------------------------------------------------+
void DrawDashboard(int ltf_trend, double conf_long, double conf_short,
                   int conf_thresh, int h1_trend, int m15_trend, int str_bias,
                   bool bull_bos, bool bear_bos,
                   bool mtf_fb, bool mtf_pb, bool mtf_fs, bool mtf_ps,
                   bool rsi_pos, bool rsi_neg, bool vwap_bull, bool vwap_bear,
                   bool fib_bull, bool fib_bear,
                   bool vp_bull, bool vp_bear,
                   double close_p, double vp_val, double vp_vah,
                   bool final_long, bool final_short,
                   bool t_atm_b, bool t_atm_s, bool t_sm_b, bool t_sm_s,
                   bool trail_ok_l, bool trail_ok_s,
                   bool pass_l, bool pass_s, int pos_state)
{
    string bias   = ltf_trend ==  1 ? "BULLISH" : ltf_trend == -1 ? "BEARISH" : "NEUTRAL";
    string action = pos_state ==  1 ? "IN LONG" : pos_state == -1 ? "IN SHORT" : "FLAT";
    double conf   = ltf_trend ==  1 ? conf_long : ltf_trend == -1 ? conf_short : 0;
    string h1s    = h1_trend  ==  1 ? "BULL" : h1_trend  == -1 ? "BEAR" : "NEUT";
    string m15s   = m15_trend ==  1 ? "BULL" : m15_trend == -1 ? "BEAR" : "NEUT";
    string strs   = str_bias  ==  1 ? "BULL" : str_bias  == -1 ? "BEAR" : "NEUT";
    string bos_s  = bull_bos ? "BOS+" : bear_bos ? "BOS-" : "--";
    string h1_ok  = (h1_trend  == ltf_trend) ? "OK" : "!!";
    string m15_ok = (m15_trend == ltf_trend) ? "OK" : "!!";
    string str_ok = (str_bias  == ltf_trend) ? "OK" : "!!";
    string mtf_ls = mtf_fb ? "FULL" : mtf_pb ? "PARTIAL" : "FAIL";
    string mtf_ss = mtf_fs ? "FULL" : mtf_ps ? "PARTIAL" : "FAIL";
    string vp_pos = (vp_vah > 0 && close_p > vp_vah) ? "ABOVE VAH" : (vp_val > 0 && close_p < vp_val) ? "BELOW VAL" : "IN VALUE";
    string wait_s, flip_s;
    if(ltf_trend == 1)
        wait_s = pass_l ? "ATM Trigger" : "Conf " + IntegerToString((int)conf_long) + "%->" + IntegerToString(conf_thresh) + "%";
    else if(ltf_trend == -1)
        wait_s = pass_s ? "ATM Trigger" : "Conf " + IntegerToString((int)conf_short) + "%->" + IntegerToString(conf_thresh) + "%";
    else
        wait_s = "Trail Direction";
    flip_s = ltf_trend == 1 ? "Trail flip->bearish" : ltf_trend == -1 ? "Trail flip->bullish" : "Any trail confirmation";
    string trig_s = t_atm_b ? "ATM BUY" : t_sm_b ? "SMART BUY" : t_atm_s ? "ATM SELL" : t_sm_s ? "SMART SELL" : "WAIT";
    string exec_s = final_long ? "EXEC LONG" : final_short ? "EXEC SHORT" : (pass_l || pass_s) ? "CONF OK / NO TRIG" : "LOW CONF";

    Comment(
        "=== THE AGENT PROTOCOL | LIQUIDITY SUITE ===\n"
        "I AM:      " + bias + " | " + action + " | " + IntegerToString((int)MathRound(conf)) + "% conf\n"
        "WAITING:   " + wait_s + "\n"
        "FLIP IF:   " + flip_s + "\n"
        "--- FRACTAL H1->M15->Now ---\n"
        "H1:        " + h1s  + "  [" + h1_ok  + "]\n"
        "M15:       " + m15s + "  [" + m15_ok + "]\n"
        "STRUCTURE: " + strs + "  " + bos_s + "  [" + str_ok + "]\n"
        "--- LONG  " + IntegerToString((int)MathRound(conf_long))  + "% (need " + IntegerToString(conf_thresh) + "%) ---\n"
        "MTF:" + mtf_ls + " STR:" + (str_bias == 1 ? "HH/HL" : "NO") + " RSI:" + (rsi_pos ? "POS" : "NO") + " VWAP:" + (vwap_bull ? "BULL" : "NO") + " FIB:" + (!requireFibTrend ? "OFF" : fib_bull ? "BULL" : "NO") + " VP:" + (!vpEnabled ? "OFF" : vp_bull ? ">VAL" : "NO") + "\n"
        "--- SHORT " + IntegerToString((int)MathRound(conf_short)) + "% (need " + IntegerToString(conf_thresh) + "%) ---\n"
        "MTF:" + mtf_ss + " STR:" + (str_bias == -1 ? "LH/LL" : "NO") + " RSI:" + (rsi_neg ? "NEG" : "NO") + " VWAP:" + (vwap_bear ? "BEAR" : "NO") + " FIB:" + (!requireFibTrend ? "OFF" : fib_bear ? "BEAR" : "NO") + " VP:" + (!vpEnabled ? "OFF" : vp_bear ? "<VAH" : "NO") + "\n"
        "--- EXECUTION ---\n"
        "TRIGGER: " + trig_s + " | DIR: " + (trail_ok_l ? "L" : trail_ok_s ? "S" : "--") + "\n"
        "CONF GATE: " + exec_s + "\n"
        "CLAW: " + claw_mode + " -> " + IntegerToString(conf_thresh) + "%\n"
        "VOL: " + vp_pos
    );
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, TrailBuffer,    INDICATOR_DATA);
    SetIndexBuffer(1, ATMBuyBuffer,   INDICATOR_DATA);
    SetIndexBuffer(2, ATMSellBuffer,  INDICATOR_DATA);
    SetIndexBuffer(3, SmartBuyBuffer, INDICATOR_DATA);
    SetIndexBuffer(4, SmartSellBuffer,INDICATOR_DATA);
    SetIndexBuffer(5, RejLongBuffer,  INDICATOR_DATA);
    SetIndexBuffer(6, RejShortBuffer, INDICATOR_DATA);
    SetIndexBuffer(7, FlipBuffer,     INDICATOR_DATA);
    SetIndexBuffer(8, ConfLongBuffer, INDICATOR_DATA);
    SetIndexBuffer(9, ConfShortBuffer,INDICATOR_DATA);

    // Empty values (0 = no signal for arrow plots)
    for(int p = 0; p < 10; p++)
        PlotIndexSetDouble(p, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);

    // Arrow codes (Wingdings-style MT5 arrows)
    PlotIndexSetInteger(1, PLOT_ARROW, 233);  // ⚡Buy  — up arrow
    PlotIndexSetInteger(2, PLOT_ARROW, 234);  // ⚡Sell — down arrow
    PlotIndexSetInteger(3, PLOT_ARROW, 233);  // 🧠Buy
    PlotIndexSetInteger(4, PLOT_ARROW, 234);  // 🧠Sell
    PlotIndexSetInteger(5, PLOT_ARROW, 251);  // Rejected — X
    PlotIndexSetInteger(6, PLOT_ARROW, 251);  // Rejected — X
    PlotIndexSetInteger(7, PLOT_ARROW, 168);  // Flip — diamond

    IndicatorSetString(INDICATOR_SHORTNAME, "AGENT PROTOCOL");
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Comment("");
}

//+------------------------------------------------------------------+
//| OnCalculate — main engine                                        |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int      &spread[])
{
    int min_bars = MathMax(MathMax(ma_len * 2, atr_len * 2), MathMax(rsiLen * 2, swingSize * 2 + 10));
    if(rates_total < min_bars) return 0;

    int count = rates_total;

    // --- Size all internal arrays ---
    ArrayResize(g_ltf_trend,   count); ArrayResize(g_ltf_trail, count);
    ArrayResize(g_m15_trend,   count); ArrayResize(g_h1_trend,  count);
    ArrayResize(g_rsi_pos,     count); ArrayResize(g_rsi_neg,   count);
    ArrayResize(g_struct_bias, count); ArrayResize(g_vwap_dir,  count);
    ArrayResize(g_fib_trend,   count);
    ArrayResize(g_vp_poc,      count); ArrayResize(g_vp_vah, count); ArrayResize(g_vp_val, count);

    // =====================================================================
    // STEP 1: LTF Trail (current timeframe)
    // =====================================================================
    double ltf_ema[], ltf_atr_a[];
    ArrayResize(ltf_ema, count); ArrayResize(ltf_atr_a, count);
    CalcEMA(close, ltf_ema, ma_len, count);
    CalcATR(high, low, close, ltf_atr_a, atr_len, count);
    CalcLiqTrail(close, ltf_ema, ltf_atr_a, g_ltf_trail, g_ltf_trend, count, atr_mult);

    // =====================================================================
    // STEP 2: MTF Trails (H1 and M15)
    // =====================================================================
    ENUM_TIMEFRAMES cur_period = (ENUM_TIMEFRAMES)Period();
    if(cur_period < PERIOD_H1)
        CalcMTFTrail(PERIOD_H1, time, count, g_h1_trend, ma_len, atr_len, atr_mult);
    else
        ArrayCopy(g_h1_trend, g_ltf_trend);

    if(cur_period < PERIOD_M15)
        CalcMTFTrail(PERIOD_M15, time, count, g_m15_trend, ma_len, atr_len, atr_mult);
    else if(cur_period == PERIOD_M15)
        ArrayCopy(g_m15_trend, g_ltf_trend);
    else
        ArrayCopy(g_m15_trend, g_h1_trend);

    // =====================================================================
    // STEP 3: ATM Bot
    // =====================================================================
    double atr_cb[], atr_cs[], atm_tb[], atm_ts[];
    bool   atm_b[], atm_s[];
    ArrayResize(atr_cb, count); ArrayResize(atr_cs, count);
    ArrayResize(atm_tb, count); ArrayResize(atm_ts, count);
    ArrayResize(atm_b,  count); ArrayResize(atm_s,  count);
    CalcATR(high, low, close, atr_cb, c_buy,  count);
    CalcATR(high, low, close, atr_cs, c_sell, count);
    CalcATMBot(close, atr_cb, a_buy, atr_cs, a_sell, atm_tb, atm_ts, atm_b, atm_s, count);

    // =====================================================================
    // STEP 4: RSI Momentum
    // =====================================================================
    double rsi_cur[], ema5_cur[];
    ArrayResize(rsi_cur, count); ArrayResize(ema5_cur, count);
    CalcRSI(close, rsi_cur, rsiLen, count);
    CalcEMA(close, ema5_cur, rsi_ema_len, count);

    // M5 RSI — fetch M5 bars and compute, then map to current bars
    double rsi_m5_out[], ema_m5_out[];
    ArrayResize(rsi_m5_out, count); ArrayResize(ema_m5_out, count);

    if(cur_period <= PERIOD_M5) {
        // We are on M5 or lower — fetch M5 data
        MqlRates m5_rates[];
        int m5c = CopyRates(_Symbol, PERIOD_M5, 0, 3000, m5_rates);
        if(m5c > rsiLen + rsi_ema_len) {
            // Reverse to chronological
            for(int i = 0; i < m5c / 2; i++) {
                MqlRates t = m5_rates[i]; m5_rates[i] = m5_rates[m5c-1-i]; m5_rates[m5c-1-i] = t;
            }
            double m5_close[], m5_rsi[], m5_ema5[];
            ArrayResize(m5_close, m5c); ArrayResize(m5_rsi, m5c); ArrayResize(m5_ema5, m5c);
            for(int i = 0; i < m5c; i++) m5_close[i] = m5_rates[i].close;
            CalcRSI(m5_close, m5_rsi, rsiLen, m5c);
            CalcEMA(m5_close, m5_ema5, rsi_ema_len, m5c);
            // Map M5 values to current bars
            for(int ci = 0; ci < count; ci++) {
                int k = -1, lo = 0, hi = m5c - 1;
                while(lo <= hi) {
                    int mid = (lo + hi) / 2;
                    if((datetime)m5_rates[mid].time <= time[ci]) { k = mid; lo = mid + 1; }
                    else hi = mid - 1;
                }
                rsi_m5_out[ci]  = k >= 0 ? m5_rsi[k]  : rsi_cur[ci];
                ema_m5_out[ci]  = k >= 0 ? m5_ema5[k] : ema5_cur[ci];
            }
        } else {
            ArrayCopy(rsi_m5_out, rsi_cur);
            ArrayCopy(ema_m5_out, ema5_cur);
        }
    } else {
        ArrayCopy(rsi_m5_out, rsi_cur);
        ArrayCopy(ema_m5_out, ema5_cur);
    }

    bool pos_m5[], neg_m5[], new_bull[], new_bear[], pcond[], ncond[];
    ArrayResize(pos_m5,   count); ArrayResize(neg_m5,   count);
    ArrayResize(new_bull, count); ArrayResize(new_bear, count);
    ArrayResize(pcond,    count); ArrayResize(ncond,    count);
    CalcRSIMomentum(rsi_cur, ema5_cur, rsi_m5_out, ema_m5_out,
                    g_rsi_pos, g_rsi_neg, pos_m5, neg_m5,
                    new_bull, new_bear, pcond, ncond, count);

    // =====================================================================
    // STEP 5: Market Structure
    // =====================================================================
    bool bull_bos[], bear_bos[];
    ArrayResize(bull_bos, count); ArrayResize(bear_bos, count);
    CalcMarketStructure(high, low, close, g_struct_bias, bull_bos, bear_bos, count, swingSize);

    // =====================================================================
    // STEP 6: VWAP Anchor
    // =====================================================================
    double vol_f[];
    ArrayResize(vol_f, count);
    for(int i = 0; i < count; i++)
        vol_f[i] = (double)(tick_volume[i] > 0 ? tick_volume[i] : (volume[i] > 0 ? volume[i] : 1));
    CalcVWAPAnchor(high, low, close, vol_f, count, prd, baseAPT, g_vwap_dir);

    // =====================================================================
    // STEP 7: Fib Bands
    // =====================================================================
    double hlc3_a[];
    ArrayResize(hlc3_a, count);
    for(int i = 0; i < count; i++) hlc3_a[i] = (high[i] + low[i] + close[i]) / 3.0;
    ArrayResize(g_fib_trend, count);
    CalcFibBands(hlc3_a, high, low, close, g_fib_trend, len_fib, atrLen_fib, useATR_fib, count);

    // =====================================================================
    // STEP 8: Volume Profile
    // =====================================================================
    if(vpEnabled)
        CalcVolumeProfile(time, high, low, close, tick_volume, count,
                          vpResolution, vpVAwidth, g_vp_poc, g_vp_vah, g_vp_val);
    else {
        ArrayInitialize(g_vp_poc, 0);
        ArrayInitialize(g_vp_vah, 1e15);
        ArrayInitialize(g_vp_val, 0);
    }

    // =====================================================================
    // STEP 9–12: Confluence + Signal Generation
    // =====================================================================
    int conf_thresh = 60;
    if(claw_mode == "Conservative")  conf_thresh = 80;
    else if(claw_mode == "Moderate") conf_thresh = 60;
    else if(claw_mode == "Aggressive") conf_thresh = 40;
    else if(claw_mode == "Custom")   conf_thresh = custom_threshold;

    int posState = 0;

    for(int i = 0; i < count; i++) {
        bool trail_l = g_ltf_trend[i] ==  1;
        bool trail_s = g_ltf_trend[i] == -1;

        bool mtf_fb = (g_m15_trend[i] == 1  && g_h1_trend[i] == 1);
        bool mtf_fs = (g_m15_trend[i] == -1 && g_h1_trend[i] == -1);
        bool mtf_pb = (g_m15_trend[i] == 1  || g_h1_trend[i] == 1);
        bool mtf_ps = (g_m15_trend[i] == -1 || g_h1_trend[i] == -1);

        double bs = 0, bm = 0, ss = 0, sm = 0;

        // MTF
        bs += mtf_fb ? mtf_weight : (mtf_pb ? mtf_weight * 0.4 : 0.0); bm += mtf_weight;
        ss += mtf_fs ? mtf_weight : (mtf_ps ? mtf_weight * 0.4 : 0.0); sm += mtf_weight;
        // Structure
        bs += g_struct_bias[i] ==  1 ? struct_weight : 0; bm += struct_weight;
        ss += g_struct_bias[i] == -1 ? struct_weight : 0; sm += struct_weight;
        // RSI
        bs += g_rsi_pos[i] ? rsi_weight_inp : 0; bm += rsi_weight_inp;
        ss += g_rsi_neg[i] ? rsi_weight_inp : 0; sm += rsi_weight_inp;
        // VWAP
        bs += g_vwap_dir[i] ==  1 ? vwap_weight : 0; bm += vwap_weight;
        ss += g_vwap_dir[i] == -1 ? vwap_weight : 0; sm += vwap_weight;
        // Fib (optional gate)
        if(requireFibTrend) {
            bs += g_fib_trend[i] ==  1 ? fib_weight : 0; bm += fib_weight;
            ss += g_fib_trend[i] == -1 ? fib_weight : 0; sm += fib_weight;
        }
        // VP
        bool vp_bull = vpEnabled && g_vp_val[i] > 0 && close[i] > g_vp_val[i];
        bool vp_bear = vpEnabled && g_vp_vah[i] > 0 && close[i] < g_vp_vah[i];
        if(vpEnabled) {
            bs += vp_bull ? vp_weight_inp : 0; bm += vp_weight_inp;
            ss += vp_bear ? vp_weight_inp : 0; sm += vp_weight_inp;
        }

        double conf_l = bm > 0 ? (bs / bm) * 100.0 : 0;
        double conf_s = sm > 0 ? (ss / sm) * 100.0 : 0;
        bool   pass_l = conf_l >= conf_thresh;
        bool   pass_s = conf_s >= conf_thresh;

        // Triggers
        bool t_atm_b = atm_b[i];
        bool t_atm_s = atm_s[i];
        bool t_sm_b  = new_bull[i];
        bool t_sm_s  = new_bear[i];

        // Gated (trail direction must allow)
        bool g_atm_b = t_atm_b && trail_l;
        bool g_atm_s = t_atm_s && trail_s;
        bool g_sm_b  = t_sm_b  && trail_l;
        bool g_sm_s  = t_sm_s  && trail_s;

        // Final (confidence must pass)
        bool f_atm_b = g_atm_b && pass_l;
        bool f_atm_s = g_atm_s && pass_s;
        bool f_sm_b  = g_sm_b  && pass_l;
        bool f_sm_s  = g_sm_s  && pass_s;

        bool final_l = f_atm_b || f_sm_b;
        bool final_s = f_atm_s || f_sm_s;

        // Rejected signals
        bool rej_l = (t_atm_b && !trail_l) || (t_sm_b && !trail_l) || ((g_atm_b || g_sm_b) && !pass_l);
        bool rej_s = (t_atm_s && !trail_s) || (t_sm_s && !trail_s) || ((g_atm_s || g_sm_s) && !pass_s);

        // Position state tracking
        if(final_l && posState <= 0) posState =  1;
        if(final_s && posState >= 0) posState = -1;

        // Trail flip
        bool flip_b = g_ltf_trend[i] ==  1 && (i > 0 ? g_ltf_trend[i-1] == -1 : false);
        bool flip_s = g_ltf_trend[i] == -1 && (i > 0 ? g_ltf_trend[i-1] ==  1 : false);

        // ── Buffer assignments ──────────────────────────────────────────
        bool trend_chg = (i > 0) && (g_ltf_trend[i] != g_ltf_trend[i-1]);
        TrailBuffer[i]    = trend_chg ? EMPTY_VALUE : g_ltf_trail[i];

        double offset = ltf_atr_a[i] * 0.3;
        ATMBuyBuffer[i]    = f_atm_b ? low[i]  - offset      : 0;
        ATMSellBuffer[i]   = f_atm_s ? high[i] + offset      : 0;
        SmartBuyBuffer[i]  = f_sm_b  ? low[i]  - offset*0.6  : 0;
        SmartSellBuffer[i] = f_sm_s  ? high[i] + offset*0.6  : 0;
        RejLongBuffer[i]   = rej_l   ? low[i]  - offset*1.4  : 0;
        RejShortBuffer[i]  = rej_s   ? high[i] + offset*1.4  : 0;
        FlipBuffer[i]      = (flip_b || flip_s) ? g_ltf_trail[i] : 0;

        // Confidence buffers — readable by EA via iCustom(buffer 8/9)
        ConfLongBuffer[i]  = conf_l;
        ConfShortBuffer[i] = conf_s;

        // ── Dashboard (last bar only) ────────────────────────────────────
        if(dashOn && i == count - 1) {
            DrawDashboard(g_ltf_trend[i], conf_l, conf_s, conf_thresh,
                          g_h1_trend[i], g_m15_trend[i], g_struct_bias[i],
                          bull_bos[i], bear_bos[i],
                          mtf_fb, mtf_pb, mtf_fs, mtf_ps,
                          g_rsi_pos[i], g_rsi_neg[i],
                          g_vwap_dir[i] == 1, g_vwap_dir[i] == -1,
                          g_fib_trend[i] == 1, g_fib_trend[i] == -1,
                          vp_bull, vp_bear,
                          close[i], g_vp_val[i], g_vp_vah[i],
                          final_l, final_s,
                          t_atm_b, t_atm_s, t_sm_b, t_sm_s,
                          trail_l, trail_s, pass_l, pass_s, posState);
        }
    }

    return rates_total;
}
