%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Beta-Sensitive Strict Inclusions
%%
%% GOAL: Demonstrate ALL strict semantic inclusions at appropriate beta
%%
%% DESIGN: Multi-layer structure with varying attack costs
%%   - Layer 1: Unattacked assumptions (always in grounded)
%%   - Layer 2: Defended assumptions (complete but not grounded)
%%   - Layer 3: Choice assumptions (creates multiple extensions)
%%   - Layer 4: Expensive self-attacks (budget-dependent)
%%
%% EXPECTED: Different beta values unlock different extension sets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget will be set via -c beta=N
budget(beta).

%% =============================================================================
%% LAYER 1: Core (always grounded)
%% =============================================================================
assumption(core1).
assumption(core2).

weight(core1, 5).
weight(core2, 5).

%% No attacks on core assumptions
contrary(core1, core1).  % Placeholder
contrary(core2, core2).  % Placeholder

%% =============================================================================
%% LAYER 2: Defended choice (creates complete vs grounded distinction)
%% =============================================================================
assumption(choice_a).
assumption(choice_b).

weight(choice_a, 10).
weight(choice_b, 10).

%% Mutual attacks (must choose one)
contrary(choice_a, choice_b).
contrary(choice_b, choice_a).

%% =============================================================================
%% LAYER 3: Dependent assumptions (creates preferred vs complete)
%% =============================================================================
assumption(dep_a).
assumption(dep_b).

weight(dep_a, 15).
weight(dep_b, 15).

%% dep_a is defended ONLY if choice_a is in
head(r_choice_a_defends_dep_a, helper_a).
body(r_choice_a_defends_dep_a, choice_a).
contrary(dep_a, dep_a).  % Self-attack
head(r_block_dep_a, attacker_dep_a).
contrary(helper_a, attacker_dep_a).  % choice_a defends dep_a

%% dep_b is defended ONLY if choice_b is in
head(r_choice_b_defends_dep_b, helper_b).
body(r_choice_b_defends_dep_b, choice_b).
contrary(dep_b, dep_b).  % Self-attack
head(r_block_dep_b, attacker_dep_b).
contrary(helper_b, attacker_dep_b).

%% =============================================================================
%% LAYER 4: Expensive assumptions (beta-dependent)
%% =============================================================================
assumption(expensive1).
assumption(expensive2).

weight(expensive1, 50).
weight(expensive2, 50).

%% Expensive self-attacks (need high beta to include)
contrary(expensive1, expensive1).
contrary(expensive2, expensive2).

%% =============================================================================
%% LAYER 5: Range expansion (for staged/semi-stable)
%% =============================================================================
assumption(range1).
assumption(range2).

weight(range1, 20).
weight(range2, 20).

%% Attacked by expensive assumptions (expands range when expensive included)
head(r_exp1_attacks_range1, c_range1).
body(r_exp1_attacks_range1, expensive1).
contrary(range1, c_range1).

head(r_exp2_attacks_range2, c_range2).
body(r_exp2_attacks_range2, expensive2).
contrary(range2, c_range2).

%% =============================================================================
%% LAYER 6: Non-admissible CF (creates admissible < CF)
%% =============================================================================
assumption(not_adm).

weight(not_adm, 25).

%% not_adm is attacked and NOT defended (but can be in CF if budget allows)
head(r_attack_not_adm, c_not_adm).
body(r_attack_not_adm, core1).
contrary(not_adm, c_not_adm).

%% =============================================================================
%% EXPECTED BEHAVIOR AT DIFFERENT BETAS
%% =============================================================================
%%
%% Beta = 0 (strict budget):
%%   - Grounded: {core1, core2}
%%   - Complete: {core1, core2, choice_a}, {core1, core2, choice_b}
%%   - Preferred: {core1, core2, choice_a}, {core1, core2, choice_b}
%%   - Admissible: CF without expensive/not_adm
%%   - CF: All combinations within budget
%%
%% Beta = 30:
%%   - Can include not_adm (cost 25) → admissible < CF
%%   - Can include one dependent → preferred < complete
%%
%% Beta = 60:
%%   - Can include expensive assumptions → larger range for staged
%%   - More semantic distinctions emerge
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
