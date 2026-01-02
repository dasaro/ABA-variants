%% Framework: stable ⊂ semi-stable
%%
%% Setup: Self-attacking assumption v, plus independent assumptions a, b
%%
%% Expected:
%%   Stable: {{a}, {b}}
%%   Semi-stable: {{a}, {b}, {v}}
%%
%% Demonstrates: stable ⊂ semi-stable (v is semi-stable but not stable)

assumption(a).
assumption(b).
assumption(v).

contrary(a, b).
contrary(b, a).
contrary(v, v).  % v attacks itself

weight(a, 10).
weight(b, 10).
weight(v, 10).

budget(0).  % No attacks can be discarded
