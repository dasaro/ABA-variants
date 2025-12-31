%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% NHST-STYLE HYPOTHESIS TESTING (faithful + WABA-compatible, drop-in)
%%
%% STORY (NHST-style):
%% - H0: no effect (null)
%% - H1: positive effect
%% - H2: adverse side effects
%%
%% Tests yield p-values. If p <= alpha, the corresponding “significant_*” node
%% is derivable and can (i) reject H0, and (ii) create pressure between H1/H2.
%%
%% KEY MODELLING CHOICES (to match NHST better):
%% 1) “Reject H0” is driven by *significant results* (p <= alpha), not by
%%    accepting H1/H2. This mirrors NHST’s primary move: reject/fail-to-reject H0.
%% 2) Evidence is *independent of the hypothesis choices*: tests are observational.
%% 3) Discarding an attack = “ignoring evidence”, cost = evidence strength.
%% 4) We DO NOT require H1/H2 to be “proved”; they are defeasible commitments
%%    constrained by evidence and budget.
%%
%% WEIGHTS:
%% Evidence strength = floor(100*(1-p)).
%% We encode p as basis points (bp): p=0.001 -> 10bp, p=0.030 -> 300bp, p=0.045 -> 450bp
%% Then 100*p = bp/100, so:
%%   strength = floor(100 - bp/100) = 100 - ceil(bp/100)
%% Implemented as: 100 - ((bp + 99) / 100).
%%
%% SEMIRING: Tropical (⊗ = +, ⊕ = min)
%% MONOID:   Sum (total ignored evidence)
%% OPT:      Minimize (ignore as little evidence as possible)
%%
%% BUDGET beta (upper bound on total ignored evidence strength):
%% This file ENFORCES beta directly (so you don’t *need* constraint/ub.lp),
%% by summing discarded attack weights.
%%
%% USAGE (example):
%% clingo -n 0 --opt-mode=opt -c beta=100 -c alpha=5 \
%%   WABA/core/base.lp \
%%   WABA/semiring/tropical.lp \
%%   WABA/monoid/sum_minimization.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/<your_semantics>.lp \
%%   WABA/constraint/ub_sum.lp \
%%   WABA/examples/scientific_discovery_nhst/nhst.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#const beta  = 100.
#const alpha = 5.   % alpha as percent (5 means 0.05)

%% ============================================================================
%% ASSUMPTIONS (Hypotheses)
%% ============================================================================

assumption(h0).  % Null: no effect
assumption(h1).  % Positive effect
assumption(h2).  % Side effects

%% Optional priors (these only matter if your semiring module uses weight/2 for assumptions)
weight(h0,40).
weight(h1,50).
weight(h2,60).

%% ============================================================================
%% OBSERVATIONAL TEST OUTCOMES (p-values as facts)
%% ============================================================================

%% p-values in basis points (bp): p * 10000
pval_bp(test_perf, 10).    % 0.001
pval_bp(test_safe, 300).   % 0.030
pval_bp(test_repl, 450).   % 0.045

%% “Tests happened” as observational facts (encoded as empty-body rules).
head(r1, test_perf).
head(r2, test_safe).
head(r3, test_repl).

%% Evidence strength from p-values:
%% strength = 100 - ceil(bp/100) = 100 - ((bp+99)/100)
weight(T,W) :- pval_bp(T,BP), W = 100 - ((BP + 99) / 100).

%% ============================================================================
%% SIGNIFICANCE GATING (depends on alpha)
%% ============================================================================

%% alpha threshold in bp: alpha% = alpha * 100 bp
alpha_bp(A) :- A = alpha * 100.

%% “alpha allows this p-value” as derived facts (empty-body rules generated conditionally)
%% These atoms exist iff p <= alpha.
head(r_ok_perf, alpha_ok_perf) :- pval_bp(test_perf,BP), alpha_bp(A), BP <= A.
head(r_ok_safe, alpha_ok_safe) :- pval_bp(test_safe,BP), alpha_bp(A), BP <= A.
head(r_ok_repl, alpha_ok_repl) :- pval_bp(test_repl,BP), alpha_bp(A), BP <= A.

%% Neutral weights for alpha_ok_* (so they don’t change evidence strength under Tropical sum)
weight(alpha_ok_perf,0).
weight(alpha_ok_safe,0).
weight(alpha_ok_repl,0).

%% Significant results (derived only when p <= alpha)
head(r4, significant_perf).
body(r4, test_perf).
body(r4, alpha_ok_perf).

head(r5, significant_safe).
body(r5, test_safe).
body(r5, alpha_ok_safe).

head(r6, significant_repl).
body(r6, test_repl).
body(r6, alpha_ok_repl).

%% ============================================================================
%% NHST CORE: SIGNIFICANCE ATTACKS THE NULL
%% ============================================================================

%% Each significant result produces a distinct “rejection token” attacking H0.
%% This makes “ignoring evidence” granular (you can discard one token but not the other).
head(r7, rejects_h0_by_perf).
body(r7, significant_perf).

head(r8, rejects_h0_by_repl).
body(r8, significant_repl).

contrary(h0, rejects_h0_by_perf).
contrary(h0, rejects_h0_by_repl).

%% ============================================================================
%% COMPETING INTERPRETATIONS (H1 vs H2) + PRACTICAL DECISION
%% ============================================================================

%% Evidence that supports *efficacy* (kept simple: driven by the main efficacy test)
head(r9,  efficacy_evidence).
body(r9,  significant_perf).

%% Evidence that supports *side-effects* (driven by safety test)
head(r10, side_effects_evidence).
body(r10, significant_safe).

%% Competing pressure:
%% - Side-effects evidence attacks committing to “approve” (H1)
%% - Efficacy evidence attacks committing to “harmful/side-effect hypothesis dominates” (H2)
contrary(h1, side_effects_evidence).
contrary(h2, efficacy_evidence).

%% Practical/clinical significance:
%% Require both efficacy significance + independent replication to claim “large effect”.
head(r11, effect_size_large).
body(r11, significant_perf).
body(r11, significant_repl).

weight(effect_size_large,80).

%% Policy acceptance is a mixed-body conclusion:
%% you must commit to H1 and have large-effect support.
head(r12, accept_practical_policy).
body(r12, h1).
body(r12, effect_size_large).

weight(accept_practical_policy,90).

%% ============================================================================
%% BUDGET CONSTRAINT
%% ============================================================================

%% Budget constraint enforced by loading constraint/ub_sum.lp
%% (total ignored evidence ≤ β)
budget(beta).
