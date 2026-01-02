%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Framework F26: Forced Semantic Separation at Beta=0
%%
%% GOAL: Create stable ⊂ semi-stable ⊂ preferred at beta=0 using classical
%%       ABA structures that are known to separate these semantics.
%%
%% STRATEGY:
%%   Part 1: Odd cycle (creates semi-stable but no stable)
%%   Part 2: Multiple complete with different ranges (separates semi-stable/preferred)
%%   Part 3: Additional admissible for CF distinction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(0).  %% Force beta=0 - strictest constraint

%% =============================================================================
%% PART 1: Three-cycle (NO stable extensions, but has semi-stable)
%% =============================================================================
%% Classic Dung: x → y → z → x (odd cycle has no stable extension)

assumption(x).
assumption(y).
assumption(z).

weight(x, 1).
weight(y, 1).
weight(z, 1).

%% x attacks y, y attacks z, z attacks x (cycle)
contrary(y, x).
contrary(z, y).
contrary(x, z).

%% At beta=0, these attacks MUST be respected (cannot discard)
%% Expected:
%%   - Stable: {} (no stable in odd cycle)
%%   - Semi-stable: {x}, {y}, {z} (all have same maximal range)
%%   - Preferred: {x}, {y}, {z} (all maximal admissible)

%% =============================================================================
%% PART 2: Isolated assumption (always included in preferred)
%% =============================================================================
assumption(core).

weight(core, 1).

contrary(core, core).  %% Placeholder - no real attack

%% This can be added to all extensions from Part 1
%% {x, core}, {y, core}, {z, core} are all preferred

%% =============================================================================
%% PART 3: Choice pair (creates different ranges)
%% =============================================================================
assumption(a).
assumption(b).

weight(a, 1).
weight(b, 1).

%% a and b mutually attack
contrary(a, b).
contrary(b, a).

%% =============================================================================
%% PART 4: Dependent on choice (creates range difference)
%% =============================================================================
assumption(dep_a).
assumption(dep_b).

weight(dep_a, 1).
weight(dep_b, 1).

%% dep_a is attacked ONLY by b
contrary(dep_a, b).

%% dep_b is attacked ONLY by a
contrary(dep_b, a).

%% This creates:
%% - If we choose {a}, then b is defeated, so dep_a can be in
%%   Range includes {dep_a}
%% - If we choose {b}, then a is defeated, so dep_b can be in
%%   Range includes {dep_b}

%% =============================================================================
%% PART 5: Non-admissible CF (creates admissible < CF)
%% =============================================================================
assumption(undef).

weight(undef, 1).

%% undef is attacked by core (which is always defended)
%% So {undef} is CF but NOT admissible
contrary(undef, core).

%% =============================================================================
%% EXPECTED at beta=0:
%% =============================================================================
%%
%% Stable: NONE (odd cycle prevents stability)
%%
%% Semi-stable: Admissible with maximal range
%%   - {x, core, a, dep_a}: range includes attacked assumptions
%%   - {y, core, a, dep_a}
%%   - {z, core, a, dep_a}
%%   - {x, core, b, dep_b}
%%   - {y, core, b, dep_b}
%%   - {z, core, b, dep_b}
%%   - Need to check which have maximal range
%%
%% Preferred: Maximal admissible
%%   - All combinations of {x|y|z} + {core} + {a|b} + {dep_a|dep_b}
%%   - More than semi-stable if ranges differ
%%
%% Complete: All complete extensions
%%   - Includes non-maximal admissible
%%
%% Admissible: All admissible
%%   - Includes subsets of preferred
%%
%% CF: All conflict-free
%%   - Includes {undef, ...} which are not admissible
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
