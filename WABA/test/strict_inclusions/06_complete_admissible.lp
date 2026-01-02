%% Framework: complete ⊂ admissible
%%
%% Setup: Self-attacker a with rule deriving b from a
%%
%% Expected:
%%   Admissible: {{∅}}
%%   Complete: {{∅}}
%%
%% NOTE: In ABA without complex rules, admissible = complete
%% This demonstrates the inclusion holds (not strict without rules)

assumption(a).

contrary(a, a).  % a attacks itself

weight(a, 10).

budget(0).  % No attacks can be discarded
