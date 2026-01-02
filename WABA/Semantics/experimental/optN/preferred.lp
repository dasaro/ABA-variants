%% Preferred Semantics (Optimization-based - optN mode)
%%
%% Definition: Maximal (⊆) complete extensions
%%
%% Approach: Maximize extension size (minimize complement of in/1)
%% Use Clingo's optN mode to find all optimal (⊆-maximal) solutions
%%
%% Usage:
%%   clingo 0 core/base.lp semiring/godel.lp constraint/ub_max.lp \
%%          semantics/complete.lp semantics/optimization/preferred.lp \
%%          <framework>.lp \
%%          --opt-mode=optN --quiet=1 --project
%%
%% Flags:
%%   --opt-mode=optN: compute optimum, then enumerate all optimal models
%%   --quiet=1: print only optimal models (suppress non-optimal)
%%   --project: avoid duplicates by projecting on shown atoms
%%   0 / -n 0: allow enumerating all models (needed for optN)

%% ========================================
%% MAXIMIZE EXTENSION SIZE
%% ========================================

%% Minimize the number of assumptions NOT in the extension
out(X) :- assumption(X), not in(X).
#minimize { 1@1,X : out(X) }.

%% ========================================
%% OUTPUT
%% ========================================

#show in/1.
