%% Grounded Semantics
%% Minimal complete extension
%%
%% Implementation: Minimize |in| subject to completeness
%% Priority @5 ensures semantic selection precedes cost optimization

#include "complete.lp".

%% MAIN (@5): Minimize cardinality of extension to find grounded (minimal complete)
%% Priority @5 ensures separation from cost optimization (@1-@3)
#minimize { 1@5, X : in(X) }.
