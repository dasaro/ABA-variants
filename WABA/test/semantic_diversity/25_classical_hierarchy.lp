%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Framework F25: Classical Semantic Hierarchy (Weight-Agnostic Design)
%%
%% GOAL: Achieve strict inclusions using classical ABA structure
%%
%% KEY INSIGHT: Use self-attacks and rule structures to create distinctions,
%% not budget-dependent attacks. Set beta high enough to eliminate budget
%% as a constraint.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).  %% High budget - not a limiting factor

%% =============================================================================
%% Part 1: Grounded vs Complete
%% =============================================================================
%% Two mutually attacking assumptions with no external support
%% Creates: grounded = {}, but complete includes {x} and {y}

assumption(x).
assumption(y).

weight(x, 1).
weight(y, 1).

contrary(x, y).
contrary(y, x).

%% =============================================================================
%% Part 2: Stable vs Semi-stable
%% =============================================================================
%% Classic Dung example: three-cycle creates semi-stable but not stable
%% a → b → c → a

assumption(a).
assumption(b).
assumption(c).

weight(a, 1).
weight(b, 1).
weight(c, 1).

contrary(b, a).
contrary(c, b).
contrary(a, c).

%% For this cycle:
%% - No stable extensions (no conflict-free set defeats all out elements)
%% - Semi-stable: All three {a}, {b}, {c} have equal range
%% Actually wait, this won't work either...

%% =============================================================================
%% Part 3: Preferred vs Complete via Reinstatement
%% =============================================================================
%% d is attacked by e
%% e is attacked by f
%% f is attacked by g
%% Creates multiple complete but fewer preferred

assumption(d).
assumption(e).
assumption(f).
assumption(g).

weight(d, 1).
weight(e, 1).
weight(f, 1).
weight(g, 1).

contrary(d, e).
contrary(e, f).
contrary(f, g).
contrary(g, g).  %% g self-attacks

%% Extensions:
%% {} is complete (empty is always complete)
%% {d, f} is complete (d defended by f)
%% {d, f} is ALSO preferred (maximal)

%% =============================================================================
%% Part 4: Admissible vs CF
%% =============================================================================
%% Undefended assumption

assumption(h).
assumption(i).

weight(h, 1).
weight(i, 1).

contrary(h, i).
contrary(i, i).  %% i self-attacks, so h always defeats i

%% {i} is conflict-free but NOT admissible (doesn't defend itself)
%% {h} is admissible

%% =============================================================================
%% Part 5: Additional assumptions for CF diversity
%% =============================================================================

assumption(j).
assumption(k).

weight(j, 1).
weight(k, 1).

contrary(j, k).
contrary(k, j).

%% Creates more CF sets that aren't admissible

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPECTED: This is still hard because WABA's weight structure makes
%% traditional ABA examples behave differently...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
