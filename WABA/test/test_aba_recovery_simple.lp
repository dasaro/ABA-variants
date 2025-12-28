%% Simple ABA Framework for Testing Recovery
%%
%% Non-circular attacks to ensure stable extensions exist
%% Classical ABA should have: {a, c} as the only stable extension

assumption(a).
assumption(b).
assumption(c).

%% Linear attack chain: a attacks b, b attacks c
contrary(b, a).  % a attacks b
contrary(c, b).  % b attacks c

%% Expected classical ABA result:
%% Extension {a, c}:
%% - a is in
%% - a attacks b → b is defeated → b is out
%% - c is in (not attacked by anyone since b is out)
%% - Stable: ✓ conflict-free, ✓ all non-defeated are in

%% To recover this with WABA (no discarding):
%% - Default weights should make discarding impossible
%% - Any combination that prevents discarding should give same result
