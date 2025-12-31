%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MEDICAL TRIAGE - Emergency Department Resource Allocation
%%
%% STORY (ASYMMETRIC - Clear Priority Hierarchy):
%% Three patients arrive simultaneously at an emergency department:
%% - Patient A: 8-year-old child with severe trauma (life-threatening)
%% - Patient B: 75-year-old with cardiac symptoms (serious but stable)
%% - Patient C: Adult with mild respiratory distress (non-critical)
%%
%% Critical resources (OR, ICU) are limited. The triage decision creates
%% a clear ethical priority: the child's life-threatening condition demands
%% immediate attention, even if this means delaying treatment for others.
%%
%% WEIGHT INTERPRETATION:
%% Weights represent harm severity (0-100) if a patient's condition is
%% deprioritized (i.e., their diagnostic assumption is defeated).
%%
%% SEMIRING: Tropical (+/min)
%% JUSTIFICATION: Harm costs accumulate additively through treatment chains.
%% Total harm from a triage decision is the sum of individual harms to
%% deprioritized patients.
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
%% β = 35 means "no patient suffers harm > 35 severity"
%% With asymmetric priorities: β≥35 allows treating child (discarding attacks on B,C)
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
%%   WABA/semiring/tropical.lp \
%%   WABA/monoid/max_minimization.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/stable.lp \
%%   WABA/constraint/ub_max.lp \
%%   WABA/examples/medical_triage/medical_triage.lp
%%
%% EXPECTED: With β=50, optimal extension is {assume_severe_trauma}
%% (Treat child, deprioritize elderly cardiac [harm 35] and respiratory [harm 15])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (set via -c beta=N)
%% Removed: #const beta = 50 (was causing issues)

%% Budget constraint (requires constraint/ub_max.lp to be loaded)
budget(beta).

%% ============================================================================
%% ASSUMPTIONS (Defeasible Patient Conditions)
%% ============================================================================

assumption(assume_severe_trauma).     % Patient A: child with life-threatening trauma
assumption(assume_cardiac_event).     % Patient B: elderly with stable cardiac event
assumption(assume_respiratory_distress). % Patient C: adult with mild respiratory distress

%% ============================================================================
%% WEIGHTS (Harm Severity if Condition Deprioritized)
%% ============================================================================

weight(assume_severe_trauma, 90).        % Critical harm if child trauma patient deprioritized
weight(assume_cardiac_event, 35).        % Moderate harm if elderly cardiac patient deprioritized
weight(assume_respiratory_distress, 15). % Low harm if stable respiratory patient deprioritized

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

%% r4-r6: Resource conflicts create harm to deprioritized patients
%% If child trauma is treated, others must wait → harm them
head(r4, harm_to_cardiac).
body(r4, protocol_surgery).  % Trauma monopolizes resources → cardiac patient harmed

head(r5, harm_to_respiratory).
body(r5, protocol_surgery).  % Trauma monopolizes resources → respiratory patient harmed

%% r6: If cardiac patient is treated, respiratory must wait
head(r6, harm_to_respiratory).
body(r6, protocol_cardiac_cath).  % Cardiac in ICU → respiratory patient harmed

%% No resource constraint on protocol_surgery itself - child can always be treated

%% ============================================================================
%% WEIGHTS FOR HARM ATOMS (Explicit harm costs for deprioritization)
%% ============================================================================

weight(harm_to_cardiac, 35).       % Moderate harm to deprioritize elderly cardiac patient
weight(harm_to_respiratory, 15).   % Low harm to deprioritize stable respiratory patient

%% ============================================================================
%% CONTRARIES (Harm Defeats Patient Assumptions)
%% ============================================================================

contrary(assume_cardiac_event, harm_to_cardiac).
contrary(assume_respiratory_distress, harm_to_respiratory).

%% ============================================================================
%% BUDGET CONSTRAINT (Max Harm ≤ β)
%% ============================================================================

%% Budget constraint enforced by loading constraint/ub_max.lp
%% (worst single harm severity ≤ β)
