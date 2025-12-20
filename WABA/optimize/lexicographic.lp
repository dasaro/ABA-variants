%% WABA Lexicographic Optimization
%% True lexicographic minimization for lex monoid
%%
%% Priority levels:
%%   @3 (highest): Minimize cost_max (prefer weak attacks)
%%   @2 (medium):  Minimize cost_sum (break ties by total cost)
%%   @1 (lowest):  Minimize cost_cnt (break ties by attack count)
%%
%% Usage: Include AFTER monoid/lex.lp
%% Example:
%%   clingo -n 0 core/base.lp semiring/godel.lp monoid/lex.lp \
%%          optimize/lexicographic.lp semantics/stable.lp instance.lp

%% Primary: minimize maximum discarded attack weight
#minimize { M@3 : cost_max(M) }.

%% Secondary: minimize sum of discarded attack weights
#minimize { S@2 : cost_sum(S) }.

%% Tertiary: minimize count of discarded attacks
#minimize { K@1 : cost_cnt(K) }.
