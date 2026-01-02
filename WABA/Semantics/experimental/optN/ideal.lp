%% Ideal Semantics (Optimization-based - optN mode, requires common_pref/1)
%%
%% Definition: Maximal admissible subset of ∩Pref (intersection of all preferred)
%%
%% Approach: Given common_pref/1 facts (intersection of preferred extensions),
%%           maximize inclusion within common_pref while maintaining admissibility
%%
%% Two-step process:
%%   Step 1: Compute common_pref/1 using preferred with --enum-mode=cautious
%%   Step 2: Run this file with common_pref/1 facts to find ideal extension
%%
%% Usage (Step 2):
%%   clingo 0 core/base.lp semiring/godel.lp constraint/ub_max.lp \
%%          semantics/admissible.lp semantics/optimization/ideal.lp \
%%          common_pref_facts.lp <framework>.lp \
%%          --opt-mode=optN --quiet=1 --project
%%
%% Flags:
%%   --opt-mode=optN: compute optimum, then enumerate all optimal models
%%   --quiet=1: print only optimal models (suppress non-optimal)
%%   --project: avoid duplicates by projecting on shown atoms
%%   0 / -n 0: allow enumerating all models (needed for optN)
%%
%% Note: Maximizes cardinality inside common_pref. Since ideal is unique and
%%       defined by ⊆-maximality, this typically yields the ideal extension.
%%       For pathological cases where size ≠ maximality, use saturation-based.

%% ========================================
%% RESTRICT EXTENSION TO COMMON_PREF
%% ========================================

%% Only assumptions in common_pref can be in the extension
:- in(X), not common_pref(X).
out(X) :- assumption(X), not common_pref(X).

%% Admissibility is enforced by loading admissible.lp

%% ========================================
%% MAXIMIZE INCLUSION INSIDE COMMON_PREF
%% ========================================

%% Minimize what we leave out from common_pref
miss_common(X) :- common_pref(X), not in(X).
#minimize { 1@1,X : miss_common(X) }.

%% ========================================
%% OUTPUT
%% ========================================

#show in/1.
