%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simple Beta-Sensitive Framework
%%
%% GOAL: Show strict semantic inclusions with appropriate beta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(beta).

%% Core assumptions (unattacked)
assumption(u1).
assumption(u2).

weight(u1, 5).
weight(u2, 5).

contrary(u1, u1).  % Placeholder
contrary(u2, u2).  % Placeholder

%% Choice assumptions (mutual attack)
assumption(a).
assumption(b).

weight(a, 10).
weight(b, 10).

contrary(a, b).
contrary(b, a).

%% Dependent on choice
assumption(da).
assumption(db).

weight(da, 15).
weight(db, 15).

%% da attacked by b
contrary(da, b).
%% db attacked by a
contrary(db, a).

%% Non-defended assumption (for admissible < CF)
assumption(undefended).

weight(undefended, 20).

%% Attacked by u1 (always in), so never defended
contrary(undefended, u1).

%% Expensive assumption (needs high beta)
assumption(expensive).

weight(expensive, 50).

contrary(expensive, expensive).  % Self-attack

%% Range extender
assumption(r1).

weight(r1, 25).

contrary(r1, expensive).  % Attacked by expensive
