%% Semi-Stable Semantics (Optimization-based - optN mode)
%%
%% Definition: Admissible extensions with maximal range
%% Range: range(S) = S ∪ S⁺ (assumptions in or defeated by extension)
%%
%% Approach: Minimize complement of range (equivalently: maximize range)
%% Use Clingo's optN mode to find all optimal (range-maximal) solutions
%%
%% Usage:
%%   clingo 0 core/base.lp semiring/godel.lp constraint/ub_max.lp \
%%          semantics/admissible.lp semantics/optimization/semi-stable.lp \
%%          <framework>.lp \
%%          --opt-mode=optN --quiet=1 --project
%%
%% Flags:
%%   --opt-mode=optN: compute optimum, then enumerate all optimal models
%%   --quiet=1: print only optimal models (suppress non-optimal)
%%   --project: avoid duplicates by projecting on shown atoms
%%   0 / -n 0: allow enumerating all models (needed for optN)

%% ========================================
%% RANGE TO MAXIMIZE
%% ========================================

range(X) :- assumption(X), in(X).
range(X) :- assumption(X), defeated(X).

%% ========================================
%% MINIMIZE COMPLEMENT OF RANGE
%% ========================================

miss(X) :- assumption(X), not range(X).
#minimize { 1@1,X : miss(X) }.

%% ========================================
%% OUTPUT
%% ========================================

#show in/1.

%% Optional: show range for debugging
%% #show range/1.
