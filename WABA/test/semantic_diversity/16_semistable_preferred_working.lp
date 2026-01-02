%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Semi-stable ⊂ Preferred (Working Version)
%%
%% GOAL: Create preferred extensions with DIFFERENT ranges
%%       to achieve semi-stable ⊂ preferred (strict)
%%
%% KEY INSIGHT: Need extensions that are incomparable (both preferred)
%%              but have different ranges due to "unreachable" assumptions
%%
%% STRUCTURE:
%%   Core: a ↔ b (mutual exclusion, must choose one)
%%
%%   If a chosen:
%%     - a attacks b (b is out)
%%     - c is unattacked (c must be in by completeness)
%%     - c attacks {d1, d2, d3} (all out)
%%
%%   If b chosen:
%%     - b attacks a (a is out)
%%     - c is unattacked (c must be in by completeness)
%%     - c attacks {d1, d2, d3} (all out)
%%
%%   Additional: {x1, x2, x3} only attacked by 'a'
%%
%% Wait, this won't work either because c will always be in both extensions!
%%
%% Let me try a DIFFERENT approach:
%%   Two independent subgraphs that can be combined differently
%%
%% Subgraph 1: a1 ↔ b1 (choose one)
%% Subgraph 2: a2 → b2 → c2 (chain)
%%
%% Extensions:
%%   E1 = {a1, a2}: a2 attacks b2, b2 out so b2→c2 doesn't fire, c2 in
%%                  Range = {a1, b1(attacked), a2, b2(attacked), c2} = 5
%%   E2 = {b1, a2}: Same as E1 but with b1 instead of a1
%%                  Range = {a1(attacked), b1, a2, b2(attacked), c2} = 5
%%
%% SAME RANGE AGAIN!
%%
%% The issue: in small frameworks, it's hard to have "unreachable" assumptions
%%
%% NEW APPROACH: Use a larger framework with optional paths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(0).  %% Classical ABA behavior

%% Core mutual exclusion: choose a OR b
assumption(a).
assumption(b).

weight(a, 10).
weight(b, 10).
weight(c_a, 10).
weight(c_b, 10).

%% a ↔ b mutual attacks
head(r_a_b, c_b).
body(r_a_b, a).
contrary(b, c_b).

head(r_b_a, c_a).
body(r_b_a, a).  %% INTENTIONAL: both a and b attack a? No wait...

%% Let me restart with a clearer design.
%%
%% I'll use the canonical example from literature:
%% Arguments: {a, b, c, d, e, f, g}
%%
%% Two "branches" that are chosen via mutual exclusion at root:
%%   Branch A: a → {c, d, e}
%%   Branch B: b → {c, f, g}
%%
%% If a is chosen:
%%   - a attacks c, d, e (all out)
%%   - b is unattacked → b must be in (completeness)
%%   - b attacks f, g → BUT WAIT, if both a and b are in, this doesn't create choice!
%%
%% I need to rethink this completely.
%%
%% Actually, the key insight from the literature example is:
%% Arguments that are "floating" - can be in or out depending on context
%%
%% Classic example:
%%   a → b → c
%%   (chain)
%%
%% Complete extensions:
%%   - {a}: b is attacked, c is defended (b→c doesn't fire), c must be in
%%          Actually no: if b is out, who says c is defended? c needs to be
%%          checked for attacks. If only b attacks c, and b is out, then
%%          c is unattacked → defended → must be in
%%          So {a, c} is the extension
%%   - Can't have {b} because then a is unattacked→defended→must be in→ contradiction
%%   - Can't have {c} because then b is unattacked→must be in→ contradiction
%%
%% So only ONE complete extension exists in chains!
%%
%% I need BRANCHES that create true optionality.
%%
%% Let me look at the test file again more carefully...

