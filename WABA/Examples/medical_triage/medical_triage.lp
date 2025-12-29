%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MEDICAL TRIAGE - Emergency Department Resource Allocation
%%
%% STORY:
%% Three patients arrive simultaneously at an emergency department. Each
%% presents defeasible diagnostic indicators (assumptions) warranting
%% different treatment protocols. However, critical resources (OR, cathlab,
%% ICU) are limited. The triage decision requires prioritizing patients by
%% accepting resource unavailability for some, incurring harm costs.
%%
%% WEIGHT INTERPRETATION:
%% Weights represent harm severity (0-100) if a patient's condition is
%% deprioritized (i.e., their diagnostic assumption is defeated).
%%
%% SEMIRING: Gödel (min/max)
%% JUSTIFICATION: Diagnostic certainty propagates via weakest evidence.
%% In safety-critical medical decisions, a treatment protocol is only as
%% reliable as the weakest diagnostic indicator in its evidential chain
%% (weakest-link principle).
%%
%% MONOID: Max
%% JUSTIFICATION: Extension cost = maximum single patient harm.
%% We adopt an egalitarian harm distribution principle: minimize the
%% worst harm to any individual patient (maximin equity).
%%
%% OPTIMIZATION: Minimize
%% JUSTIFICATION: Weights represent costs (harm). We minimize to find the
%% triage policy with the least worst-case patient harm.
%%
%% BUDGET β: Upper bound on maximum harm to any single patient.
%% β = 50 means "no patient suffers harm > 50 severity"
%%
%% DISCARDED ATTACK INTERPRETATION:
%% Overriding resource unavailability = securing that resource for the
%% patient (at cost = harm severity if we fail to secure it). Discarding
%% the attack "no_or_available defeats assume_severe_trauma" means we
%% accept the risk of OR unavailability, allowing trauma patient to be
%% deprioritized with harm cost = weight(no_or_available).
%%
%% USAGE:
%% clingo -n 0 --opt-mode=opt -c beta=50 \
%%   WABA/core/base.lp \
%%   WABA/semiring/godel.lp \
%%   WABA/monoid/max_minimization.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/stable.lp \
%%   WABA/examples/medical_triage/medical_triage.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 50.

%% ============================================================================
%% ASSUMPTIONS (Defeasible Patient Conditions)
%% ============================================================================

assumption(assume_severe_trauma).     % Patient A: trauma indicators
assumption(assume_cardiac_event).     % Patient B: cardiac symptoms
assumption(assume_respiratory_distress). % Patient C: breathing difficulty

%% ============================================================================
%% WEIGHTS (Harm Severity if Condition Deprioritized)
%% ============================================================================

weight(assume_severe_trauma, 80).        % High harm if trauma patient deprioritized
weight(assume_cardiac_event, 70).        % High harm if cardiac patient deprioritized
weight(assume_respiratory_distress, 60). % Moderate-high harm if respiratory patient deprioritized

%% Weights for derived atoms (resource unavailability consequences)
weight(no_or_available, 80).       % OR unavailable → trauma patient harmed
weight(no_cathlab_available, 70).  % Cathlab unavailable → cardiac patient harmed
weight(no_icu_available, 60).      % ICU unavailable → respiratory patient harmed

%% ============================================================================
%% RULES (Diagnostic → Treatment Protocols)
%% ============================================================================

%% r1: Severe trauma + test results indicate surgery
head(r1, protocol_surgery).
body(r1, assume_severe_trauma).

%% r2: Cardiac event indicates catheterization
head(r2, protocol_cardiac_cath).
body(r2, assume_cardiac_event).

%% r3: Respiratory distress indicates ventilation
head(r3, protocol_ventilation).
body(r3, assume_respiratory_distress).

%% r4: Surgery protocol requires OR; if OR busy → no_or_available
head(r4, no_or_available).
body(r4, protocol_surgery).
body(r4, or_occupied). % OR occupied (derived from other patients)

%% r5: Cardiac cath requires cathlab; if cathlab busy → no_cathlab_available
head(r5, no_cathlab_available).
body(r5, protocol_cardiac_cath).
body(r5, cathlab_occupied).

%% r6: Ventilation requires ICU; if ICU full → no_icu_available
head(r6, no_icu_available).
body(r6, protocol_ventilation).
body(r6, icu_occupied).

%% r7: Resource conflicts - if 2+ protocols needed, resources are occupied
%% (This creates the triage dilemma: we can't treat all simultaneously)
head(r7, or_occupied).
body(r7, protocol_cardiac_cath).  % Cardiac patient also needs intervention

head(r8, cathlab_occupied).
body(r8, protocol_ventilation).   % Respiratory patient also needs ICU

head(r9, icu_occupied).
body(r9, protocol_surgery).       % Trauma patient also needs critical care

%% ============================================================================
%% CONTRARIES (Resource Unavailability Defeats Patient Assumptions)
%% ============================================================================

contrary(assume_severe_trauma, no_or_available).
contrary(assume_cardiac_event, no_cathlab_available).
contrary(assume_respiratory_distress, no_icu_available).

%% ============================================================================
%% BUDGET CONSTRAINT (Max Harm ≤ β)
%% ============================================================================

%% Budget constraint enforced by loading constraint/ub_max.lp
%% (worst single harm severity ≤ β)
