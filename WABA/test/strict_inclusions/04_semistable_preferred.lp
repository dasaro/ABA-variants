%% Framework: semi-stable ⊂ preferred
%%
%% Setup: Chain a→b with isolated c
%%
%% Expected:
%%   Semi-stable: {{a}, {c}} (maximal range)
%%   Preferred: {{a}, {c}, {a,c}} (all are maximal complete)
%%
%% Demonstrates: semi-stable ⊂ preferred ({a,c} is preferred but not semi-stable)

assumption(a).
assumption(b).
assumption(c).

contrary(a, b).  % a attacks b
contrary(b, a).  % b attacks a (never triggered since b never supported)
contrary(c, c).  % Dummy contrary for c

weight(a, 10).
weight(b, 10).
weight(c, 10).

budget(0).  % No attacks can be discarded
