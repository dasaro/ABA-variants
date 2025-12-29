%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EPISTEMIC JUSTIFICATION - Coherent Belief Revision Under Uncertainty
%%
%% STORY:
%% An agent receives conflicting perceptual reports about the same event
%% (whether it is raining). Four defeasible sensory observations clash:
%% visual perception says rain, auditory perception says no rain sounds,
%% tactile perception says ground is wet, weather forecast says dry.
%% These observations, combined with background theories, generate predictions
%% that contradict each other, forcing the agent to revise some perceptual
%% beliefs to maintain epistemic coherence.
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
%%   WABA/examples/epistemic_justification/epistemic_justification.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 80.

%% Łukasiewicz K parameter (saturation bound, override via -c k=N)
#const k = 100.

%% ============================================================================
%% ASSUMPTIONS (Defeasible Perceptual Beliefs)
%% ============================================================================

assumption(assume_visual_rain).      % Visual perception: it's raining
assumption(assume_audio_no_rain).    % Auditory perception: no rain sounds
assumption(assume_tactile_wet).      % Tactile perception: ground feels wet
assumption(assume_forecast_dry).     % Testimony: weather forecast says dry

%% ============================================================================
%% WEIGHTS (Epistemic Unreliability)
%% ============================================================================

%% Perceptual source unreliability (0-100, higher = less reliable)
weight(assume_visual_rain, 20).      % Vision relatively reliable
weight(assume_audio_no_rain, 30).    % Hearing moderately reliable
weight(assume_tactile_wet, 25).      % Touch relatively reliable
weight(assume_forecast_dry, 40).     % Forecasts less reliable (prediction)

%% Conflict unreliability weights (reflects severity of contradiction)
weight(contradicts_visual_evidence, 20).
weight(contradicts_audio_evidence, 30).
weight(contradicts_tactile_evidence, 25).
weight(contradicts_forecast, 40).

%% Theoretical prediction weights
weight(predict_wet_ground, 15).
weight(predict_rain_sounds, 20).

%% ============================================================================
%% RULES (Perceptual Beliefs → Theoretical Predictions → Conflicts)
%% ============================================================================

%% r1: Visual rain perception + theory → predicts wet ground
%% (Mixed body: perception assumption + background theory)
head(r1, predict_wet_ground).
body(r1, assume_visual_rain).
body(r1, theory_rain_wets_ground).  % Background theory (derived)

%% r2: Visual rain perception + theory → predicts rain sounds
head(r2, predict_rain_sounds).
body(r2, assume_visual_rain).
body(r2, theory_rain_is_audible).

%% r3: Background theory: rain wets ground (always holds)
head(r3, theory_rain_wets_ground).
% No body - this is a standing background belief

%% r4: Background theory: rain is audible (always holds)
head(r4, theory_rain_is_audible).

%% r5: Auditory "no rain" + prediction of rain sounds → conflict
head(r5, contradicts_audio_evidence).
body(r5, assume_audio_no_rain).
body(r5, predict_rain_sounds).

%% r6: Dry forecast + tactile wet perception → conflict
head(r6, contradicts_tactile_evidence).
body(r6, assume_forecast_dry).
body(r6, assume_tactile_wet).

%% r7: Dry forecast + wet ground prediction → conflict
head(r7, contradicts_forecast).
body(r7, assume_forecast_dry).
body(r7, predict_wet_ground).

%% r8: Visual rain + auditory no-rain → direct perceptual conflict
head(r8, contradicts_visual_evidence).
body(r8, assume_visual_rain).
body(r8, assume_audio_no_rain).

%% ============================================================================
%% CONTRARIES (Evidential Conflicts Defeat Perceptual Beliefs)
%% ============================================================================

contrary(assume_visual_rain, contradicts_visual_evidence).
contrary(assume_audio_no_rain, contradicts_audio_evidence).
contrary(assume_tactile_wet, contradicts_tactile_evidence).
contrary(assume_forecast_dry, contradicts_forecast).

%% ============================================================================
%% BUDGET CONSTRAINT (Total Unreliability ≤ β)
%% ============================================================================

%% The sum_minimization.lp monoid defines extension_cost(C) = sum of discarded attack weights.
%% We enforce: extension_cost ≤ beta (total unreliability ≤ β)

:- extension_cost(C), C > beta.

%% ============================================================================
%% BUDGET FACT (Needed by core/base.lp)
%% ============================================================================

budget(beta).
