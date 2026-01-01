%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Fixed Attack Graph (No Weighted Attacks)
%%
%% GOAL: Force grounded ⊂ complete by having NO discarding at all
%%
%% STRATEGY: Use NO weighted attacks - all attacks are via rules only
%%           This eliminates the discarding choice entirely
%%           Attack graph is completely fixed
%%
%% STRUCTURE (Classic even cycle):
%%   - unattacked is unattacked
%%   - a and b attack each other (fixed, cannot be discarded)
%%
%% EXPECTED SEMANTICS:
%%   - Grounded: {unattacked} (only unattacked assumptions)
%%   - Complete: {unattacked,a}, {unattacked,b} (two complete extensions)
%%   - Preferred: {unattacked,a}, {unattacked,b}
%%
%% KEY: NO weight/3 facts except for assumptions themselves
%%      All attacks are structural (via rules) not weight-based
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).

assumption(unattacked).
assumption(a).
assumption(b).

%% Only assumptions have weights (not attacks!)
weight(unattacked, 10).
weight(a, 10).
weight(b, 10).

%% CRITICAL: Contraries have NO weight - they CANNOT be discarded!
%% (or give them weight #sup which means infinite cost to discard)

%% a attacks b (NO WEIGHT - cannot discard)
contrary(b, a).  % Direct contrary - a is contrary of b

%% b attacks a (NO WEIGHT - cannot discard)
contrary(a, b).  % Direct contrary - b is contrary of a

%% unattacked has no contrary
contrary(unattacked, unattacked).  % Placeholder self-loop
