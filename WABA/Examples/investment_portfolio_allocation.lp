%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% WABA Example: Investment Portfolio Allocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Domain: Financial decision-making - constructing an optimal investment
%% portfolio under uncertainty with competing objectives.
%%
%% Scenario:
%% An investment advisor must allocate capital across different asset classes
%% (stocks, bonds, real estate, commodities) based on market indicators,
%% risk tolerance, and investment goals. Multiple strategies compete based
%% on different market assumptions and risk/return preferences.
%%
%% Features demonstrated:
%% - Indirect derivations: market indicators -> strategies -> allocation decisions
%% - Hybrid derivations: combining market data with investment principles
%% - Weighted arguments: confidence in market forecasts and strategy soundness
%% - Budget constraint: risk tolerance / acceptable portfolio volatility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Market Indicators (Assumptions)
assumption(equity_bull_trend).           % Stock market upward trend
assumption(low_interest_rates).          % Central bank rates near zero
assumption(inflation_rising).            % CPI increasing above target
assumption(recession_risk_low).          % Economic expansion continuing
assumption(tech_sector_strong).          % Technology stocks outperforming
assumption(real_estate_stable).          % Property values holding steady
assumption(commodity_volatility).        % Raw materials prices fluctuating
assumption(bond_yields_stable).          % Fixed income yields predictable
assumption(currency_strength).           % Domestic currency appreciating
assumption(geopolitical_stability).      % No major international crises

%% Investment Principles (Assumptions)
assumption(diversification_important).   % Don't put all eggs in one basket
assumption(long_term_horizon).           % 5+ year investment timeframe
assumption(risk_adjusted_returns).       % Optimize Sharpe ratio

%% Derived Investment Strategies
assumption(growth_strategy).             % Aggressive equity-focused portfolio
assumption(balanced_strategy).           % Mixed equities and fixed income
assumption(defensive_strategy).          % Conservative capital preservation
assumption(inflation_hedge_strategy).    % Real assets to protect purchasing power

%% Portfolio Decisions (Derived)
assumption(allocate_equities_high).      % 60%+ stocks
assumption(allocate_bonds_moderate).     % 20-40% fixed income
assumption(allocate_real_estate).        % 10-20% property/REITs
assumption(allocate_commodities).        % 5-15% gold/commodities

%% Final Decision
assumption(portfolio_approved).          % Final allocation plan confirmed

%% Weights (confidence in forecasts/principles: 0-100)
%% Higher weight = stronger signal or more established principle

% Market indicator confidence
weight(equity_bull_trend, 75).           % Technical + fundamental confluence
weight(low_interest_rates, 90).          % Observable policy
weight(inflation_rising, 80).            % Multiple data sources
weight(recession_risk_low, 70).          % Leading indicators
weight(tech_sector_strong, 65).          % Sector rotation analysis
weight(real_estate_stable, 60).          % Regional data variance
weight(commodity_volatility, 85).        % High certainty of uncertainty
weight(bond_yields_stable, 70).          % Central bank guidance
weight(currency_strength, 55).           % FX market complexity
weight(geopolitical_stability, 50).      % Inherent unpredictability

% Investment principle weights (time-tested wisdom)
weight(diversification_important, 95).   % Modern portfolio theory
weight(long_term_horizon, 85).           % Client confirmed
weight(risk_adjusted_returns, 90).       % Fundamental objective

% Strategy weights (methodology soundness)
weight(growth_strategy, 80).             % Evidence-based in bull markets
weight(balanced_strategy, 90).           % Robust across conditions
weight(defensive_strategy, 75).          % Preserves capital
weight(inflation_hedge_strategy, 70).    % Protects purchasing power

% Allocation decision weights
weight(allocate_equities_high, 75).
weight(allocate_bonds_moderate, 80).
weight(allocate_real_estate, 65).
weight(allocate_commodities, 60).
weight(portfolio_approved, 85).

%% Contrary weights (risks/alternative views)
weight(c_equity_bull_trend, 60).         % Bear market risk
weight(c_low_interest_rates, 30).        % Policy highly visible
weight(c_inflation_rising, 45).          % Transitory inflation argument
weight(c_recession_risk_low, 65).        % Yield curve inversion
weight(c_tech_sector_strong, 70).        % Valuation concerns
weight(c_real_estate_stable, 65).        % Bubble fears
weight(c_commodity_volatility, 30).      % Volatility is observed fact
weight(c_bond_yields_stable, 55).        % Rate hike uncertainty
weight(c_currency_strength, 60).         % Trade balance shifts
weight(c_geopolitical_stability, 75).    % Black swan events

weight(c_diversification_important, 20). % Concentration can outperform
weight(c_long_term_horizon, 40).         % Liquidity needs may arise
weight(c_risk_adjusted_returns, 35).     % Absolute returns matter too

weight(c_growth_strategy, 65).           % Higher volatility drawdown
weight(c_balanced_strategy, 40).         % May underperform in trends
weight(c_defensive_strategy, 70).        % Opportunity cost in bull market
weight(c_inflation_hedge_strategy, 60).  % Underperforms in deflation

weight(c_allocate_equities_high, 70).    % Concentration risk
weight(c_allocate_bonds_moderate, 50).   % Duration risk
weight(c_allocate_real_estate, 65).      % Illiquidity risk
weight(c_allocate_commodities, 55).      % Speculation concerns
weight(c_portfolio_approved, 60).        % Requires client sign-off

%% Derivation Rules

% r1: growth_strategy <- equity_bull_trend, recession_risk_low, long_term_horizon.
head(r1, growth_strategy; r1, equity_bull_trend; r1, recession_risk_low; r1, long_term_horizon).

% r2: growth_strategy <- tech_sector_strong, risk_adjusted_returns.
head(r2, growth_strategy; r2, tech_sector_strong; r2, risk_adjusted_returns).

% r3: balanced_strategy <- diversification_important, long_term_horizon.
head(r3, balanced_strategy; r3, diversification_important; r3, long_term_horizon).

% r4: defensive_strategy <- recession_risk_low. (Contrarian: if recession risk is LOW, defensive not needed)
% Note: This shows attacking defensive_strategy when economy is strong
head(r4, defensive_strategy; r4, bond_yields_stable; r4, geopolitical_stability).

% r5: inflation_hedge_strategy <- inflation_rising, low_interest_rates.
head(r5, inflation_hedge_strategy; r5, inflation_rising; r5, low_interest_rates).

% r6: inflation_hedge_strategy <- commodity_volatility, real_estate_stable.
head(r6, inflation_hedge_strategy; r6, commodity_volatility; r6, real_estate_stable).

% r7: allocate_equities_high <- growth_strategy, equity_bull_trend. [HYBRID]
head(r7, allocate_equities_high; r7, growth_strategy; r7, equity_bull_trend).

% r8: allocate_equities_high <- balanced_strategy, recession_risk_low. [HYBRID]
head(r8, allocate_equities_high; r8, balanced_strategy; r8, recession_risk_low).

% r9: allocate_bonds_moderate <- balanced_strategy. [INDIRECT]
head(r9, allocate_bonds_moderate; r9, balanced_strategy).

% r10: allocate_bonds_moderate <- defensive_strategy, diversification_important. [HYBRID]
head(r10, allocate_bonds_moderate; r10, defensive_strategy; r10, diversification_important).

% r11: allocate_real_estate <- inflation_hedge_strategy, real_estate_stable. [HYBRID]
head(r11, allocate_real_estate; r11, inflation_hedge_strategy; r11, real_estate_stable).

% r12: allocate_commodities <- inflation_hedge_strategy, inflation_rising. [HYBRID]
head(r12, allocate_commodities; r12, inflation_hedge_strategy; r12, inflation_rising).

% r13: portfolio_approved <- allocate_equities_high, allocate_bonds_moderate, diversification_important. [HYBRID]
head(r13, portfolio_approved; r13, allocate_equities_high; r13, allocate_bonds_moderate; r13, diversification_important).

% r14: portfolio_approved <- balanced_strategy, risk_adjusted_returns. [HYBRID]
head(r14, portfolio_approved; r14, balanced_strategy; r14, risk_adjusted_returns).

%% Contrary Relation (total function)
contrary(equity_bull_trend, c_equity_bull_trend).
contrary(low_interest_rates, c_low_interest_rates).
contrary(inflation_rising, c_inflation_rising).
contrary(recession_risk_low, c_recession_risk_low).
contrary(tech_sector_strong, c_tech_sector_strong).
contrary(real_estate_stable, c_real_estate_stable).
contrary(commodity_volatility, c_commodity_volatility).
contrary(bond_yields_stable, c_bond_yields_stable).
contrary(currency_strength, c_currency_strength).
contrary(geopolitical_stability, c_geopolitical_stability).

contrary(diversification_important, c_diversification_important).
contrary(long_term_horizon, c_long_term_horizon).
contrary(risk_adjusted_returns, c_risk_adjusted_returns).

contrary(growth_strategy, c_growth_strategy).
contrary(balanced_strategy, c_balanced_strategy).
contrary(defensive_strategy, c_defensive_strategy).
contrary(inflation_hedge_strategy, c_inflation_hedge_strategy).

contrary(allocate_equities_high, c_allocate_equities_high).
contrary(allocate_bonds_moderate, c_allocate_bonds_moderate).
contrary(allocate_real_estate, c_allocate_real_estate).
contrary(allocate_commodities, c_allocate_commodities).

contrary(portfolio_approved, c_portfolio_approved).

%% Budget: Risk tolerance / maximum acceptable portfolio volatility
%% Budget=180: Moderate risk tolerance
%% - Can accept some contrarian views (bear market risk, recession fears)
%% - Cannot accept extreme scenarios (geopolitical crisis + tech bubble)
%% Higher budget = higher risk tolerance (accept more uncertainty)
%% Lower budget = lower risk tolerance (require more consensus)
budget(180).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Expected behavior with Gödel + Max semantics:
%%
%% Bullish Scenario (Strong Economy):
%% - Include: equity_bull_trend, low_interest_rates, recession_risk_low,
%%   tech_sector_strong, long_term_horizon, diversification_important
%% - Derives: growth_strategy (via r1, r2)
%%           -> allocate_equities_high (via r7)
%%           + balanced_strategy (via r3)
%%           -> allocate_bonds_moderate (via r9)
%%           -> portfolio_approved (via r13, r14)
%% - Must overcome: c_allocate_equities_high (70), c_growth_strategy (65)
%% - Max cost: 70 (within budget=180)
%%
%% Inflationary Scenario:
%% - Include: inflation_rising, low_interest_rates, commodity_volatility,
%%   real_estate_stable
%% - Derives: inflation_hedge_strategy (via r5, r6)
%%           -> allocate_real_estate (via r11)
%%           -> allocate_commodities (via r12)
%% - Alternative allocation focusing on real assets
%% - Must overcome inflation hedge contraries
%%
%% Risk-Off Scenario (Defensive):
%% - Include: bond_yields_stable, geopolitical_stability, diversification_important
%% - Derives: defensive_strategy (via r4)
%%           -> allocate_bonds_moderate (via r10)
%% - Lower equity allocation
%% - Must overcome: c_defensive_strategy (70) - opportunity cost concern
%%
%% Mixed Signals:
%% - Some bullish (equity_bull_trend) + some bearish (recession_risk_low challenged)
%% - Multiple competing strategies may be viable
%% - Budget determines which conflicting signals can be tolerated
%% - May result in balanced_strategy as compromise
%%
%% This demonstrates WABA's ability to model investment decision-making where
%% market forecasts are uncertain, strategies compete, and risk tolerance
%% (budget) determines which allocation plans are acceptable.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
