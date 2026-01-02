%% Eager Semantics (Optimization-based - optN mode, requires common_complete/1)
%%
%% Definition: Maximal admissible subset of ∩Complete
%%
%% Two-step process:
%%   Step 1: Compute complete extensions with complete.lp + preferred.lp (optN)
%%          Use --enum-mode=cautious OR manually compute intersection
%%   Step 2: Create common_complete/1 facts from ∩Complete
%%   Step 3: Run this file with common_complete/1 to find eager extension
%%
%% NOTE: Eager is unique (always exactly one eager extension)
%% NOTE: grounded ⊆ ideal ⊆ eager ⊆ complete

%% ========================================
%% RESTRICT EXTENSION TO COMMON_COMPLETE
%% ========================================

%% Only assumptions in common_complete can be in the extension
:- in(X), not common_complete(X).
out(X) :- assumption(X), not common_complete(X).

%% Admissibility is enforced by loading admissible.lp

%% ========================================
%% MAXIMIZE INCLUSION INSIDE COMMON_COMPLETE
%% ========================================

%% Minimize what we leave out from common_complete
miss_common(X) :- common_complete(X), not in(X).
#minimize { 1@1,X : miss_common(X) }.

%% ========================================
%% OUTPUT
%% ========================================

#show in/1.
