%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EPISTEMIC JUSTIFICATION - Coherent Belief Revision Under Uncertainty
%%
%% STORY (ASYMMETRIC - Clear Visual Dominance):
%% An agent sees rain (visual perception - highly reliable) but the weather
%% forecast predicted dry conditions (less reliable, often wrong). Only these
%% TWO sources conflict. The agent must decide: trust direct visual perception
%% (low unreliability cost) or trust the forecast (high unreliability cost).
%% Visual perception clearly wins as it's direct observation vs. prediction.
%%
%% WEIGHT INTERPRETATION:
%% Weights represent epistemic unreliability (0-100) of sensory sources.
%% Higher weights = less reliable source. When we discard a conflict,
%% we accept that the source generating the conflict is unreliable.
%%
%% SEMIRING: Łukasiewicz (bounded sum, K=100)
%% JUSTIFICATION: Evidence accumulates but saturates. Multiple pieces of
%% evidence supporting a belief increase its strength, but with diminishing
%% returns (bounded support models epistemic saturation - additional evidence
%% beyond a threshold provides minimal extra justification).
%%
%% MONOID: Sum
%% JUSTIFICATION: Extension cost = total epistemic unreliability of
%% discarded conflicts. We sum the unreliability of all evidence we reject.
%%
%% OPTIMIZATION: Minimize
%% JUSTIFICATION: Weights represent costs (unreliability). We minimize
%% total unreliability to find the most epistemically secure belief set.
%%
%% BUDGET β: Upper bound on total unreliability of discarded evidence.
%% β = 80 means "total unreliability ≤ 80"
%%
%% DISCARDED ATTACK INTERPRETATION:
%% Overriding a conflict = accepting that the evidence generating the
%% conflict is unreliable (at cost = unreliability weight).
%%
%% USAGE:
%% clingo -n 0 --opt-mode=opt -c beta=80 -c k=100 \
%%   WABA/core/base.lp \
%%   WABA/semiring/lukasiewicz.lp \
%%   WABA/monoid/sum_minimization.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/stable.lp \
%%   WABA/constraint/ub_sum.lp \
%%   WABA/examples/epistemic_justification/epistemic_justification.lp
%%
%% EXPECTED: Extension {assume_visual_rain}
%% (Trust direct visual perception, reject unreliable forecast)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 80.

%% Łukasiewicz K parameter (saturation bound, override via -c k=N)
#const k = 100.

%% Budget constraint (requires constraint/ub_sum.lp to be loaded)
budget(beta).

%% ============================================================================
%% ASSUMPTIONS (Defeasible Perceptual Beliefs)
%% ============================================================================

assumption(assume_visual_rain).      % Visual perception: it's raining (highly reliable)
assumption(assume_forecast_dry).     % Weather forecast: dry conditions (less reliable)
% Removed: audio and tactile perceptions (simplified to 2-way conflict)

%% ============================================================================
%% WEIGHTS (Epistemic Unreliability)
%% ============================================================================

%% Perceptual source unreliability (0-100, higher = less reliable) - ASYMMETRIC
weight(assume_visual_rain, 10).      % Direct observation - very reliable
weight(assume_forecast_dry, 50).     % Prediction - often wrong, unreliable

%% Conflict unreliability weights
weight(contradicts_visual_evidence, 10).  % Low cost to discard (trust vision)
weight(contradicts_forecast, 50).         % High cost to discard (distrust vision)

%% ============================================================================
%% RULES (Perceptual Beliefs → Theoretical Predictions → Conflicts)
%% ============================================================================

%% r1: Direct perceptual conflict - visual rain vs. forecast dry
head(r1, contradicts_forecast).
body(r1, assume_visual_rain).
body(r1, assume_forecast_dry).

%% r2: Symmetric conflict - forecast contradicts visual evidence
head(r2, contradicts_visual_evidence).
body(r2, assume_forecast_dry).
body(r2, assume_visual_rain).

%% Simplified: removed background theories and intermediate predictions
%% Only direct 2-way conflict between visual perception and forecast

%% ============================================================================
%% CONTRARIES (Evidential Conflicts Defeat Perceptual Beliefs)
%% ============================================================================

contrary(assume_visual_rain, contradicts_visual_evidence).
contrary(assume_forecast_dry, contradicts_forecast).

%% ============================================================================
%% BUDGET CONSTRAINT
%% ============================================================================

%% Budget constraint enforced by loading constraint/ub_sum.lp
%% (total unreliability ≤ β)
