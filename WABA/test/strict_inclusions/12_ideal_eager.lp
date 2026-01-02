%% Framework: ideal ⊂ eager (or eager ⊂ ideal?)
%%
%% Setup: Self-attacking b, independent a
%%
%% Expected:
%%   Complete: {{∅}, {a}}
%%   Preferred: {{a}}
%%   ∩Complete = {∅}
%%   ∩Pref = {a}
%%   Ideal = maximal admissible in {a} = {a}
%%   Eager = maximal admissible in {∅} = {∅}
%%
%% NOTE: This shows eager ⊂ ideal (not ideal ⊂ eager)
%% Since Pref ⊆ Complete, we have ∩Pref ⊇ ∩Complete

assumption(a).
assumption(b).

contrary(a, a).  % Dummy contrary (never triggered)
contrary(b, b).  % b attacks itself

weight(a, 10).
weight(b, 10).

budget(0).  % No attacks can be discarded
