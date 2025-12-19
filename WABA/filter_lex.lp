%% Output filtering for Lexicographic Monoid
%% Shows all three cost components plus standard predicates
%%
%% Usage: Replace filter.lp with this when using monoid/lex.lp
%% Example:
%%   clingo -n 0 core_base.lp semiring/fuzzy.lp monoid/lex.lp \
%%          filter_lex.lp optimize_lex.lp Semantics/stable.lp instance.lp

#show in/1.
#show supported_with_weight/2.
#show attacks_successfully_with_weight/3.
#show extension_cost/1.
#show cost_max/1.
#show cost_sum/1.
#show cost_cnt/1.
