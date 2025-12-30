%% Framework demonstrating: grounded ⊂ ideal (strict)
%%
%% AF: 2 arguments where b self-attacks
%% att(a,b), att(b,a), att(b,b)
%%
%% Expected:
%% - Grounded: ∅ (no unattacked arguments)
%% - Ideal: {a} (maximal admissible in intersection of preferred)
%%
%% Analysis:
%% - No unattacked arguments → grounded = ∅
%% - b can't be in any conflict-free set (self-attack)
%% - {a} is admissible (defends against b by attacking b)
%% - Only preferred extension is {a}
%% - Ideal = {a} (maximal admissible in ∩Pref = {a})

assumption(a).
assumption(b).

%% att(a,b) → contrary(b,a)
contrary(b, a).

%% att(b,a) → contrary(a,b)
contrary(a, b).

%% att(b,b) → contrary(b,b) (self-attack)
contrary(b, b).

weight(a, 100).
weight(b, 100).

#const beta = 0.
budget(beta).
