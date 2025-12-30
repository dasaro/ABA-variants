%% Simple Example from ASPforABA tests
%% Reference: test_simple.py - simple_abaf()
%%
%% Framework:
%% - Assumptions: a, b, c
%% - Rules: -a <- b; y <- (fact)
%% - Contraries: (a, -a), (c, y)
%%
%% Expected behavior:
%% - 'a' is not credulously accepted in CO/PR (attacked by b)
%% - 'b' is credulously and skeptically accepted in CO/PR
%% - 'y' is skeptically accepted in PR
%% - '-a' is credulously accepted in CO

%% Assumptions
assumption(a).
assumption(b).
assumption(c).

%% Rules
% -a <- b
head(r1, neg_a). body(r1, b).

% y <- (fact)
head(r2, y).

%% Contraries
contrary(a, neg_a).
contrary(c, y).

%% Weights (all unweighted = default #sup)
weight(a, 100).
weight(b, 100).
weight(c, 100).
weight(neg_a, 100).
weight(y, 100).

%% Budget: 0 for classical ABA
#const beta = 0.
budget(beta).
