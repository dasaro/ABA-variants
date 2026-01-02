%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GROUNDED SEMANTICS (WABA) via LEAST FIXPOINT of the characteristic operator
%%
%% Uses SUCCESSFUL attacks only (i.e., non-discarded attacks):
%%   attacks_successfully_with_weight(Attacker, TargetAssumption, Weight).
%%
%% No weak constraints / minimization. No “in2=in” saturation trap.
%% Produces the unique grounded extension by construction, then enforces:
%%     in(X)  <->  g_in(X)
%%
%% Intended to be loaded *instead of* other semantics modules.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- attack relation (ignore weights)
% Use successful attacks (after discarding) to compute grounded extension
att(A,B) :- attacks_successfully_with_weight(A,B,_).

% We compute the grounded set only for assumptions (these are the “arguments”
% whose membership is decided by in/1 in your core).
arg(X) :- assumption(X).

% Bound the number of fixpoint iterations by the number of assumptions.
n_assum(N) :- N = #count{ X : arg(X) }.
step(0..N) :- n_assum(N).

% ---- Characteristic operator F(S):
% X is acceptable w.r.t. S iff every attacker of X is attacked by some member of S.
% Here “member of S” means an assumption already accepted at the current step.

% An attacker Y of X is counter-attacked at step S if some grounded assumption Z at S attacks Y.
countered(Y,S) :- g_in_step(Z,S), arg(Z), att(Z,Y).

% Acceptable at step S: for all Y such that att(Y,X), we have countered(Y,S).
acceptable(X,S) :- arg(X), step(S),
                   countered(Y,S) : att(Y,X).

% Base: F(∅) = all unattacked arguments.
g_in_step(X,0) :- arg(X), not att(_,X).

% Induction: S_{k+1} = F(S_k).
% (We also propagate membership monotonically, which is sound because F is monotone
%  in standard AFs and thus S_k ⊆ S_{k+1}.)
g_in_step(X,S1) :- step(S), n_assum(N), S < N, S1 = S+1, acceptable(X,S).
g_in_step(X,S1) :- step(S), n_assum(N), S < N, S1 = S+1, g_in_step(X,S).

% Final grounded set = union across steps (stabilizes by N).
g_in(X) :- g_in_step(X,_).

% ---- Enforce that the chosen extension equals the grounded one.
:- g_in(X), not in(X).
:- in(X), not g_in(X).

#project in/1.
#show in/1.