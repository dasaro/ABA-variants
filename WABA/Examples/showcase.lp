%% ============================================================================
%% WABA Showcase Example
%% ============================================================================
%% Demonstrates how different semiring/monoid combinations produce different
%% results on the same argumentation framework.
%%
%% SCENARIO: Multi-agent resource allocation
%%   - 4 agents (a1,a2,a3,a4) request access to a shared resource
%%   - Granting requests creates mutual exclusion conflicts
%%   - To include all 4 agents, must discard conflicting attacks
%%
%% HOW DIFFERENCES ARISE:
%%   1. Semirings propagate weights differently through rule derivations:
%%      - Fuzzy: min (weakest link in conjunction)
%%      - Tropical: + (additive costs)
%%      - Probabilistic: average (approximate)
%%      - Boolean: AND (binary logic)
%%
%%   2. Monoids aggregate discarding costs differently:
%%      - Max: cares only about the largest discarded attack
%%      - Sum: cares about total of all discarded attacks
%%      - Count: cares only about number of discards (weight-agnostic)
%%      - Min: cares only about smallest discard (quality threshold)
%%      - Lex: cares about (max, sum, count) in lexicographic order
%%
%% EXPECTED RESULTS (for extension with all 4 agents using CF semantics):
%%   Fuzzy + Max: cost 30,  Sum: cost 61,  Count: cost 4
%%   Tropical + Min: cost 8,  Count: cost 4,  Lex: (max=30, sum=81, cnt=4)
%%   Probabilistic + Max: cost 30,  Sum: cost 61,  Count: cost 4
%%   Boolean + Max: cost 18,  Sum: cost 43,  Count: cost 4,  Lex: (18,43,4)
%%
%% TEST COMMANDS:
%%   # Fuzzy + Sum
%%   clingo -n 0 core_base.lp semiring/fuzzy.lp monoid/sum.lp \\
%%          filter.lp Semantics/cf.lp Examples/showcase.lp
%%
%%   # Boolean + Lex (use filter_lex.lp to see all components)
%%   clingo -n 0 core_base.lp semiring/boolean.lp monoid/lex.lp \\
%%          filter_lex.lp Semantics/cf.lp Examples/showcase.lp
%%
%%   # Tropical + Min (note: uses maximize_cost.lp, not minimize)
%%   clingo -n 0 core_base.lp semiring/tropical.lp monoid/min.lp \\
%%          filter.lp Semantics/cf.lp Examples/showcase.lp
%% ============================================================================

%% Agent requests (all desirable assumptions)
assumption(a1).  % Agent 1 requests resource - weight 8
assumption(a2).  % Agent 2 requests resource - weight 15
assumption(a3).  % Agent 3 requests resource - weight 20
assumption(a4).  % Agent 4 requests resource - weight 30

weight(a1, 8).
weight(a2, 15).
weight(a3, 20).
weight(a4, 30).

%% Support factors (different combinations create different propagated weights)
head(s1, support_low).      % Weight 5
head(s2, support_med).      % Weight 12
head(s3, support_high).     % Weight 18

weight(support_low, 5).
weight(support_med, 12).
weight(support_high, 18).

%% Grant decisions derived from requests + support
%% Different body structures create different propagated weights in each semiring

%% Grant1: From a1 + light support
%% Fuzzy: min(8,5)=5, Tropical: 8+5=13, Prob: avg≈6.5, Boolean: 1
head(g1, grant1).
body(g1, a1).
body(g1, support_low).

%% Grant2: From a2 + medium support
%% Fuzzy: min(15,12)=12, Tropical: 15+12=27, Prob: avg≈13.5, Boolean: 1
head(g2, grant2).
body(g2, a2).
body(g2, support_med).

%% Grant3: From a3 + a1 (two agents collaborate)
%% Fuzzy: min(20,8)=8, Tropical: 20+8=28, Prob: avg≈14, Boolean: 1
head(g3, grant3).
body(g3, a3).
body(g3, a1).

%% Grant4: From a4 + high support
%% Fuzzy: min(30,18)=18, Tropical: 30+18=48, Prob: avg≈24, Boolean: 1
head(g4, grant4).
body(g4, a4).
body(g4, support_high).

%% Mutual exclusion conflicts
%% Each grant creates attacks on competing agents
%%
%% Fuzzy attack weights: 5, 12, 8, 18
%% Tropical attack weights: 13, 27, 28, 48
%% To have all 4 agents, must discard some attacks
%%
%% Max monoid: cares about largest (18 fuzzy, 48 tropical)
%% Sum monoid: cares about total (43 fuzzy, 116 tropical)
%% Count monoid: cares about number (4 attacks)
%% Lex monoid: cares about (max, sum, count) in order

contrary(a2, grant1).  % grant1 attacks a2 (weight 5 fuzzy, 13 tropical)
contrary(a3, grant2).  % grant2 attacks a3 (weight 12 fuzzy, 27 tropical)
contrary(a4, grant3).  % grant3 attacks a4 (weight 8 fuzzy, 28 tropical)
contrary(a1, grant4).  % grant4 attacks a1 (weight 18 fuzzy, 48 tropical)

%% Budget: High enough to allow all combinations to achieve all 4 agents
%% To have all 4 agents, must discard all 4 attacks with total costs:
%% - Fuzzy: max=18, sum=43, count=4
%% - Tropical: max=48, sum=116, count=4
%% - Probabilistic: max≈24, sum≈58, count=4
%% - Boolean: max=1, sum=4, count=4
%% Budget=120 allows all combinations (tropical sum=116 is highest)
budget(120).
