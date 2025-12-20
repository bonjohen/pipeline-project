# MACRO & MARKET SIGNAL REFERENCE

This document describes a set of widely used macroeconomic and market-structure signals. Each section includes a clear definition, formal calculation, interpretation, and common data sources. These signals are commonly used as inputs to systematic trading models, risk dashboards, or macro monitoring pipelines.

---

1. YIELD CURVE INVERSION

---

Definition
A yield curve inversion occurs when shorter-maturity government bond yields exceed longer-maturity yields, contradicting the normal upward-sloping term structure of interest rates.

Formal Calculation
Most commonly measured as a spread:

10Y–2Y Yield Curve Spread

```
Spread = Y(10Y) − Y(2Y)
```

Inversion condition:

```
Y(10Y) − Y(2Y) < 0
```

Alternative spreads:

* 10Y – 3M
* 5Y – 2Y

What It Indicates

* Elevated probability of recession within approximately 6–18 months
* Tightening credit conditions
* Declining growth expectations

Data Sources

* U.S. Treasury (daily yields)
* FRED (Federal Reserve Economic Data)
* Bloomberg / Refinitiv

---

2. MARKET BREADTH THRUSTS (ZWEIG / MCCLELLAN)

---

Definition
A breadth thrust is a sudden, broad expansion in advancing stocks, signaling aggressive institutional risk-on behavior.

Formal Calculation (Zweig Breadth Thrust)

Breadth Ratio:

```
Breadth Ratio = Advancing Issues / (Advancing Issues + Declining Issues)
```

Zweig Thrust condition:

* Ratio rises from below 0.40 to above 0.615
* Occurs within 10 trading days

What It Indicates

* Initiation of a durable bull market
* Broad participation rather than narrow leadership

Data Sources

* NYSE advance/decline data
* Nasdaq market statistics
* Bloomberg breadth indicators

---

3. CREDIT SPREADS (HIGH YIELD VS TREASURIES)

---

Definition
Credit spreads measure the risk premium demanded for holding corporate debt instead of risk-free government bonds.

Formal Calculation

```
Credit Spread = Y(High Yield) − Y(Treasury, matched duration)
```

Common benchmark:

```
HY Spread = Y(BB/B Rated Index) − Y(10Y Treasury)
```

What It Indicates

* Rising spreads indicate increasing default risk and equity downside
* Falling spreads indicate improving growth expectations

Data Sources

* ICE BofA Corporate Bond Indices
* FRED
* Bloomberg / Refinitiv

---

4. REPO MARKET STRESS / SOFR SPIKES

---

Definition
Stress in short-term funding markets where institutions borrow cash using securities as collateral.

Formal Calculation

```
SOFR Spread = SOFR − Fed Funds Target Midpoint
```

Stress condition:

* Sudden upward spike relative to recent baseline

What It Indicates

* Liquidity shortages
* Forced deleveraging
* Potential for rapid, disorderly asset repricing

Data Sources

* Federal Reserve Bank of New York
* FRED
* Bloomberg money-market dashboards

---

5. VIX TERM STRUCTURE INVERSION

---

Definition
An inversion of expected volatility where near-term implied volatility exceeds longer-dated implied volatility.

Formal Calculation

```
VIX Term Slope = VIX Front Month − VIX 3-Month
```

Inversion condition:

```
VIX Front Month > VIX Later Months
```

What It Indicates

* Acute near-term fear
* High probability of short-term equity drawdown

Data Sources

* CBOE
* Bloomberg options analytics
* OptionMetrics

---

6. VOLATILITY COMPRESSION TO EXPANSION

---

Definition
Periods of unusually low realized and implied volatility followed by sharp increases.

Formal Calculation

Realized volatility:

```
sigma_realized = sqrt(252) * StdDev( ln(P_t / P_(t-1)) )
```

Compression condition:

* Realized volatility in the lowest decile of its historical range

What It Indicates

* Large directional move forthcoming
* Direction requires confirmation from other signals

Data Sources

* Equity price histories (Yahoo Finance, Bloomberg)
* CBOE implied volatility data

---

7. FAILED BREAKOUTS (BULL / BEAR TRAPS)

---

Definition
A failed breakout occurs when price breaks a key technical level but quickly reverses back into the prior range.

Formal Condition

* Price closes above resistance (or below support)
* Fails to hold the level within N days (commonly 1–5)
* Returns inside prior range with expanding volume

What It Indicates

* Trapped participants
* High-probability move in the opposite direction

Data Sources

* Price and volume data (any market data provider)

---

8. VOLUME DIVERGENCE

---

Definition
A disagreement between price trend and trading volume.

Formal Conditions

Bullish divergence:

* Lower price lows with higher volume lows

Bearish divergence:

* Higher price highs with declining volume

Often measured using On-Balance Volume (OBV).

What It Indicates

* Trend exhaustion
* Reduced participation

Data Sources

* Exchange volume data
* Bloomberg technical indicators
* Yahoo Finance

---

9. SECTOR AND FACTOR ROTATION

---

Definition
Systematic leadership changes between defensive and cyclical sectors or between capitalization tiers.

Formal Calculation

```
Relative Strength (RS) = Price of Sector A / Price of Sector B
```

Examples

* Industrials versus Utilities
* Russell 2000 versus S&P 500

What It Indicates

* Shifts in macro risk appetite
* Economic cycle transitions

Data Sources

* ETF price data (SPDR, iShares)
* Bloomberg factor models

---

10. SENTIMENT EXTREMES (PUT/CALL, SURVEYS)

---

Definition
Measures of investor positioning and emotional extremes.

Formal Calculations

Put/Call Ratio:

```
PCR = Put Volume / Call Volume
```

Typical extreme thresholds:

* PCR greater than approximately 1.2 indicates fear
* PCR less than approximately 0.6 indicates complacency

What It Indicates

* Short-term reversal probability using a contrarian framework

Data Sources

* CBOE
* AAII sentiment surveys
* NAAIM exposure index

---

END OF DOCUMENT
