%% Test Arctic Semiring with Attacks and Budget Constraints
%%
%% Scenario: Research funding allocation
%% - Projects accumulate evidence scores (citations, awards, grants)
%% - Projects attack each other (competition for limited funding)
%% - Budget limits which attacks can be discarded
%%
%% Expected behavior:
%% - Arctic semiring accumulates evidence via + (conjunction)
%% - Strongest evidence chain wins via max (disjunction)
%% - Attack weights accumulated from evidence
%% - Budget determines which projects can win

%% Three competing research projects
assumption(fund_project_a).
assumption(fund_project_b).
assumption(fund_project_c).

%% Evidence for Project A: Strong cumulative evidence (facts with weights)
assumption(citations_a). weight(citations_a, 30).
assumption(grant_a). weight(grant_a, 25).
assumption(award_a). weight(award_a, 20).

%% Evidence for Project B: Moderate evidence
assumption(citations_b). weight(citations_b, 40).
assumption(grant_b). weight(grant_b, 15).

%% Evidence for Project C: Single strong piece
assumption(publications_c). weight(publications_c, 60).

%% Rules: Project impact scores derived from evidence
%% r1: impact_a <- fund_project_a, citations_a, grant_a, award_a.
head(r1, impact_a).
body(r1, fund_project_a).
body(r1, citations_a).
body(r1, grant_a).
body(r1, award_a).

%% r2: impact_b <- fund_project_b, citations_b, grant_b.
head(r2, impact_b).
body(r2, fund_project_b).
body(r2, citations_b).
body(r2, grant_b).

%% r3: impact_c <- fund_project_c, publications_c.
head(r3, impact_c).
body(r3, fund_project_c).
body(r3, publications_c).

%% Conflicts: Projects attack each other (only one can be funded)
%% Project A attacks B and C
contrary(fund_project_b, impact_a).
contrary(fund_project_c, impact_a).

%% Project B attacks A and C
contrary(fund_project_a, impact_b).
contrary(fund_project_c, impact_b).

%% Project C attacks A and B
contrary(fund_project_a, impact_c).
contrary(fund_project_b, impact_c).

%% Budget: Can discard attacks up to total cost 60
budget(60).

%% EXPECTED RESULTS with Arctic + MAX, budget=60:
%%
%% Derivation weights (Arctic: accumulate via +):
%% - impact_a: 0 (fund_project_a default) + 30 + 25 + 20 = 75
%% - impact_b: 0 (fund_project_b default) + 40 + 15 = 55
%% - impact_c: 0 (fund_project_c default) + 60 = 60
%%
%% Attack strengths:
%% - impact_a attacks fund_project_b (weight 75)
%% - impact_a attacks fund_project_c (weight 75)
%% - impact_b attacks fund_project_a (weight 55)
%% - impact_b attacks fund_project_c (weight 55)
%% - impact_c attacks fund_project_a (weight 60)
%% - impact_c attacks fund_project_b (weight 60)
%%
%% Extension {fund_project_a}:
%% - Accepts: impact_a (weight 75)
%% - Discards attacks from: impact_b (55), impact_c (60)
%% - Cost (MAX monoid): max(55, 60) = 60 ≤ budget ✓
%%
%% Extension {fund_project_c}:
%% - Accepts: impact_c (weight 60)
%% - Discards attacks from: impact_a (75), impact_b (55)
%% - Cost (MAX monoid): max(75, 55) = 75 > budget ✗
%%
%% EXPECTED: Only {fund_project_a} is within budget
%% Project A has strongest cumulative evidence (75) and can discard competing attacks

%% Run with:
%%   clingo -n 0 core/base.lp semiring/arctic.lp monoid/baseline/max.lp \
%%          filter/standard.lp semantics/stable.lp test/test_arctic_attacks.lp
