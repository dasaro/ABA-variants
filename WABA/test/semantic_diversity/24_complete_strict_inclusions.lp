%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Framework F24: Complete Strict Semantic Inclusions
%%
%% GOAL: Achieve ALL 10 strict inclusions at appropriate beta
%%
%% STRATEGY:
%% 1. Core stable extension (unattacked assumptions)
%% 2. Additional admissible-but-not-stable (creates stable < semi-stable)
%% 3. Multiple preferred extensions (creates semi-stable < preferred)
%% 4. Non-maximal complete (creates preferred < complete)
%% 5. Non-admissible CF (creates admissible < CF)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(beta).

%% =============================================================================
%% LAYER 1: Core stable extension (always stable)
%% =============================================================================
assumption(core1).
assumption(core2).

weight(core1, 1).
weight(core2, 1).

contrary(core1, core1).  % Placeholder
contrary(core2, core2).  % Placeholder

%% =============================================================================
%% LAYER 2: Mutual choice (creates multiple complete extensions)
%% =============================================================================
assumption(a).
assumption(b).

weight(a, 5).
weight(b, 5).

%% a and b attack each other
contrary(a, b).
contrary(b, a).

%% This creates TWO complete extensions:
%% E1 = {core1, core2, a}
%% E2 = {core1, core2, b}

%% =============================================================================
%% LAYER 3: Non-defended assumption (creates admissible < CF)
%% =============================================================================
assumption(undefended).

weight(undefended, 10).

%% Attacked by core1 (always in), so never defended
contrary(undefended, core1).

%% This allows CF = {core1, core2, undefended} which is NOT admissible

%% =============================================================================
%% LAYER 4: Weak attacked assumption (creates stable < semi-stable)
%% =============================================================================
assumption(weak).

weight(weak, 3).

%% Weak is attacked by 'a', so it can be in E2 but not in E1
contrary(weak, a).

%% Now:
%% - Stable: Only {core1, core2} (must reject both a and b to avoid conflict)
%% - But wait, we need to check if {core1, core2, a} is stable...
%% - Actually {core1, core2, a} IS stable if we can discard attack from b

%% =============================================================================
%% LAYER 5: Self-attacking assumption (for range/staged)
%% =============================================================================
assumption(self_attack).

weight(self_attack, 15).

contrary(self_attack, self_attack).

%% This creates extensions that include self_attack (larger range for staged)

%% =============================================================================
%% EXPECTED BEHAVIOR (beta = 20):
%% =============================================================================
%%
%% Stable: {core1, core2, a}, {core1, core2, b}
%%   - Must discard attacks between a/b (cost 5 each)
%%
%% Semi-stable: Stable + admissible with max range
%%   - Should include extensions with 'weak'
%%
%% Preferred: All maximal admissible
%%   - Should have more than semi-stable
%%
%% Complete: All complete extensions
%%   - Should include non-maximal admissible
%%
%% Admissible: All admissible extensions
%%   - Includes subsets of preferred
%%
%% CF: All conflict-free
%%   - Includes {undefended, core2} etc (not admissible)
%%
%% Naive: Maximal conflict-free
%%   - Should be strict subset of CF
%%
%% Staged: Maximal range among CF
%%   - Includes sets with self_attack (larger range)
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
