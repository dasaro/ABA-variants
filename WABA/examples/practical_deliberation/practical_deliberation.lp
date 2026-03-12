%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PRACTICAL DELIBERATION - Commonsense Default Reasoning for Daily Planning
%%
%% STORY:
%% An agent planning a Sunday routine relies on four defeasible default beliefs:
%% traffic is light on Sundays, gym opens at 7am, no rain expected, no meetings.
%% These defaults generate action plans. Unexpected events (gym_closed,
%% traffic_heavy, rain_detected, meeting_scheduled) defeat defaults, forcing
%% belief revision. We minimize revision count (cognitive parsimony).
%%
%% WEIGHT INTERPRETATION:
%% Weights represent cognitive revision cost (1-10, belief entrenchment).
%% Higher weights = more entrenched belief (harder to revise).
%%
%% SEMIRING: Arctic (sum/max, dual of Tropical)
%% JUSTIFICATION: Belief strength accumulates (reward-based). Stronger defaults
%% = higher cumulative value. Arctic is dual of Tropical (identity 0, not #sup).
%%
%% MONOID: Count
%% JUSTIFICATION: Extension cost = number of revised defaults (cardinality).
%% We count belief revisions regardless of individual weights.
%%
%% OPTIMIZATION: Minimize
%% JUSTIFICATION: Minimize number of revisions (cognitive conservatism).
%%
%% BUDGET β: Upper bound on number of revisions.
%% β = 2 means "revise at most 2 defaults"
%%
%% DISCARDED ATTACK INTERPRETATION:
%% Overriding a disruption = maintaining the default despite contrary evidence
%% (cost = 1 revision in count). We count how many defaults we must abandon.
%%
%% USAGE:
%% clingo -n 0 --opt-mode=optN -c beta=2 \
%%   WABA/core/base.lp \
%%   WABA/semiring/arctic.lp \
%%   WABA/monoid/count.lp \
%%   WABA/optimize/minimize.lp \
%%   WABA/constraint/ub.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/stable.lp \
%%   WABA/examples/practical_deliberation/practical_deliberation.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 2.

%% ============================================================================
%% ASSUMPTIONS (Commonsense Defaults)
%% ============================================================================

assumption(assume_traffic_light).  % Default: Sunday traffic is light
assumption(assume_gym_open).       % Default: Gym open at 7am
assumption(assume_weather_good).   % Default: No rain expected
assumption(assume_no_meeting).     % Default: No Sunday meetings

%% ============================================================================
%% WEIGHTS (Belief Entrenchment - for Arctic semiring)
%% ============================================================================

%% Default belief weights (entrenchment 1-10)
weight(assume_traffic_light, 8).   % Highly entrenched: Sundays are usually quiet
weight(assume_gym_open, 7).         % Moderately entrenched: Usually open
weight(assume_weather_good, 6).     % Less entrenched: Weather variable
weight(assume_no_meeting, 9).       % Very entrenched: Rarely meet Sundays

%% Disruption weights (for Arctic accumulation, but Count monoid ignores these)
weight(gym_closed, 7).
weight(traffic_heavy, 8).
weight(rain_detected, 6).
weight(meeting_scheduled, 9).

%% Plan weights
weight(plan_early_workout, 5).
weight(plan_drive_downtown, 6).
weight(plan_outdoor_run, 5).

%% ============================================================================
%% RULES (Defaults → Plans, Disruptions Defeat Defaults)
%% ============================================================================

%% r1: Gym open default → plan early workout
head(r1, plan_early_workout).
body(r1, assume_gym_open).

%% r2: Light traffic default → plan to drive
head(r2, plan_drive_downtown).
body(r2, assume_traffic_light).

%% r3: Good weather default → plan outdoor run
head(r3, plan_outdoor_run).
body(r3, assume_weather_good).

%% r4: Gym closed observed → disruption
head(r4, gym_closed).
% No body - this is an observed fact (gym unexpectedly closed on Sundays)

%% r5: Traffic report shows heavy traffic → disruption
head(r5, traffic_heavy).
% No body - unexpected traffic due to event

%% r6: Weather update shows rain → disruption
head(r6, rain_detected).
% No body - forecast updated

%% r7: Meeting invitation received → disruption
head(r7, meeting_scheduled).
% No body - unexpected Sunday meeting

%% ============================================================================
%% CONTRARIES (Disruptions Defeat Defaults)
%% ============================================================================

contrary(assume_gym_open, gym_closed).
contrary(assume_traffic_light, traffic_heavy).
contrary(assume_weather_good, rain_detected).
contrary(assume_no_meeting, meeting_scheduled).

%% ============================================================================
%% BUDGET CONSTRAINT
%% ============================================================================

%% Budget constraint enforced by loading constraint/ub.lp
%% (revision count ≤ β)
