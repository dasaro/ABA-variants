%% Framework: stable ⊂ stage
%%
%% Setup: 3-cycle (a→b→c→a)
%%
%% Expected:
%%   Stable: {{∅}}
%%   Stage: {{a}, {b}, {c}}
%%
%% Demonstrates: stable ⊂ stage (each singleton is stage but not stable)

assumption(a).
assumption(b).
assumption(c).

contrary(a, b).  % a attacks b
contrary(b, c).  % b attacks c
contrary(c, a).  % c attacks a

weight(a, 10).
weight(b, 10).
weight(c, 10).

budget(0);  % No attacks can be discarded
