%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Framework F27: Minimal Semantic Separation
%%
%% GOAL: Force stable < semi-stable < preferred with MINIMAL structure
%%
%% STRATEGY: Use Dung's classical examples known to separate semantics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).  %% High budget - not the limiting factor

%% =============================================================================
%% Part 1: Unattacked core (grounded, always in all extensions)
%% =============================================================================
assumption(a).
weight(a, 10).
contrary(a, a).  %% Placeholder

%% =============================================================================
%% Part 2: Simple attack chain a → b → c
%% =============================================================================
assumption(b).
assumption(c).

weight(b, 10).
weight(c, 10).

%% a attacks b, b attacks c
contrary(b, a).
contrary(c, b).

%% =============================================================================
%% Part 3: Isolated assumption (no attacks)
%% =============================================================================
assumption(d).
weight(d, 10).
contrary(d, d).  %% Placeholder

%% =============================================================================
%% Part 4: Self-attacking assumption (never in stable, but can be in other semantics)
%% =============================================================================
assumption(self).
weight(self, 10).
contrary(self, self).  %% Real self-attack through placeholder

%% =============================================================================
%% Expected behavior:
%% =============================================================================
%%
%% With a → b → c and isolated d:
%%
%% Conflict-free: Many sets including {a,d}, {c,d}, {a,c,d}, {self,d}, etc.
%%
%% Admissible:
%%   - {a, d} (a defends itself - no attackers, d defends itself)
%%   - {a, c, d} (a defends itself, c is defended by a attacking b, d defends itself)
%%   - Many others...
%%
%% Complete: Must include all defended assumptions
%%   - At minimum: {a, d, c} (a is unattacked, d is unattacked, c is defended by a)
%%
%% Preferred: Maximal admissible
%%   - {a, c, d} should be preferred
%%
%% Semi-stable: Admissible with maximal range
%%   - Range({a, c, d}) = {a, b, c, d} (b is attacked by a)
%%   - This should be semi-stable
%%
%% Stable: Conflict-free + all out are defeated
%%   - {a, d} defeats b (via a), but does NOT defeat c or self
%%   - So {a, d} is NOT stable
%%   - {a, c, d} defeats b (via a) and... c is IN, not OUT...
%%   - What's OUT? {b, self}
%%   - b is defeated by a ✓
%%   - self is defeated? Only if something attacks self... placeholder attacks don't count?
%%   - Hmm, if self has a placeholder, it might not need to be defeated...
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
