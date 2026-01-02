%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Framework F29: Odd Cycle (Classic stable < preferred example)
%%
%% In classical Dung ABA: odd cycles have NO stable extensions
%% but DO have preferred extensions.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(20).  %% Enough to discard one attack

%% Three-cycle: x → y → z → x
assumption(x).
assumption(y).
assumption(z).

weight(x, 5).
weight(y, 5).
weight(z, 5).

%% Attacks
contrary(y, x).  % x attacks y
contrary(z, y).  % y attacks z
contrary(x, z).  % z attacks x

%% =============================================================================
%% Expected in classical ABA:
%% =============================================================================
%% Stable: NONE (odd cycle cannot be stable)
%% Preferred: {x}, {y}, {z} (all maximal admissible)
%%
%% In WABA with budget=20:
%% - To have {x} in: must discard attack from z (cost 5)
%% - To have {y} in: must discard attack from x (cost 5)
%% - To have {z} in: must discard attack from y (cost 5)
%% - All affordable at beta=20
%%
%% Question: Are {x}, {y}, {z} STABLE in WABA?
%% - {x}: out = {y, z}
%%   - y is attacked by x ✓
%%   - z is attacked by... we discarded the attack from y to z
%%   - Wait, who attacks what?
%%
%% Let me trace {x}:
%% - x is IN
%% - x attacks y (via contrary(y, x))
%% - z attacks x, but we DISCARD this attack (cost 5)
%% - y attacks z (via contrary(z, y)), but y is OUT so this doesn't apply?
%%   - Actually, attacks only happen from IN assumptions
%%   - y is OUT, so y doesn't attack anything
%% - So in extension {x}:
%%   - x attacks y → y is attacked ✓
%%   - z is NOT attacked by anyone in {x}
%%   - Out = {y, z}
%%   - y is attacked ✓
%%   - z is NOT attacked ✗
%%   - NOT STABLE!
%%
%% So {x} should NOT be stable in WABA either!
%% This should give: Stable = 0, Preferred = 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
