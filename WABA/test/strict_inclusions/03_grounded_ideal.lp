%% Framework: grounded ⊂ ideal
%%
%% Setup: Self-attacking assumption b, independent assumption a
%%
%% Expected:
%%   Grounded: {∅}
%%   Preferred: {{a}}
%%   Ideal: {a} (maximal admissible in ∩Pref = {a})
%%
%% Demonstrates: grounded ⊂ ideal

assumption(a).
assumption(b).

contrary(a, a).  % Dummy contrary (never triggered)
contrary(b, b).  % b attacks itself

weight(a, 10).
weight(b, 10).

budget(0).  % No attacks can be discarded
