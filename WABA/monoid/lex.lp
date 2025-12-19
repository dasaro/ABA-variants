%% WABA Monoid: Lexicographic
%% Cost aggregation: Three components with lexicographic ordering
%%   Primary: cost_max (maximum discarded attack weight)
%%   Secondary: cost_sum (sum of discarded attack weights)
%%   Tertiary: cost_cnt (count of discarded attacks)
%%
%% Semantics:
%%   - Minimize cost_max first (prefer discarding weak attacks)
%%   - Break ties by minimizing cost_sum
%%   - Break remaining ties by minimizing cost_cnt
%%   - Budget constraint applies only to cost_max component
%%
%% Compatible semirings: All (uses weight-based max, sum, and count)
%%
%% Identity element: #sup (hardest to discard = infinite cost)
%% Budget constraint: C > B on cost_max (enforce max <= B)
%% Optimization: Use optimize_lex.lp for true lexicographic minimization

%% Default weight for unweighted assumptions
%% (makes them hard to discard, compatible with all semirings)
supported_with_weight(X,#sup) :- assumption(X), in(X), not weight(X,_).

%% Maximum component: largest discarded attack weight
cost_max(M) :- discarded_attack(_,_,_), M = #max{ W,X,Y : discarded_attack(X,Y,W) }.
cost_max(0) :- not discarded_attack(_,_,_).

%% Sum component: total cost of all discarded attacks
cost_sum(S) :- discarded_attack(_,_,_), S = #sum{ W,X,Y : discarded_attack(X,Y,W) }.
cost_sum(0) :- not discarded_attack(_,_,_).

%% Count component: number of discarded attacks
cost_cnt(K) :- K = #count{ X,Y : discarded_attack(X,Y,_) }.

%% Extension cost = maximum component (for budget checking)
extension_cost(M) :- cost_max(M).

%% Budget violation: cost_max exceeds budget
budget_violation :- cost_max(M), budget(B), M > B.
