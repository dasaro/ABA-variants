%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Framework F30: Classical ABA (No Placeholder Attacks)
%%
%% GOAL: Replicate classical ABA behavior by:
%%   1. NO placeholder self-attacks (contrary(a,a))
%%   2. All weights = 1 (equal weight)
%%   3. Budget = 0 (no attack discarding allowed - pure ABA)
%%
%% This should give us classical ABA semantics!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(0).  %% Classical ABA: no attack discarding

%% =============================================================================
%% Classic odd cycle: x → y → z → x
%% Expected: Stable=0, Preferred=3
%% =============================================================================
assumption(x).
assumption(y).
assumption(z).

weight(x, 1).
weight(y, 1).
weight(z, 1).

%% Cycle attacks
contrary(y, x).  % x attacks y
contrary(z, y).  % y attacks z
contrary(x, z).  % z attacks x

%% NO self-attacks!

%% =============================================================================
%% Unattacked assumption (should be in grounded)
%% =============================================================================
assumption(u).

weight(u, 1).

%% u has NO attackers - NO contrary(u, ...) defined at all!
%% In classical ABA, this means u is always defended (no attackers to defend against)

%% =============================================================================
%% Expected at beta=0 (classical ABA):
%% =============================================================================
%% - Grounded: {u} (only unattacked)
%% - Stable: {u} only (odd cycle prevents x,y,z from being stable)
%% - Preferred: {u,x}, {u,y}, {u,z} (maximal admissible with u and one from cycle)
%% - Semi-stable: Should be subset of preferred
%% - Complete: {u}, {u,x}, {u,y}, {u,z}
%% - Admissible: {}, {u}, {x}, {y}, {z}, {u,x}, {u,y}, {u,z}
%%
%% This should give: Stable < Preferred!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
