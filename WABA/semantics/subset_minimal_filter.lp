%% Exact per-reduct subset-minimal filtering over precomputed candidates.
%%
%% Expected facts:
%%   candidate(M).
%%   member(M,A).
%%   discarded_member(M,X,Y,W).
%%
%% Output:
%%   keep(M).
%%
%% Complete ABA extensions have a unique least member: the grounded extension.
%% The comparison is deliberately local to one discard witness D, because the
%% beta-sigma construction first fixes F-D and only then applies grounded
%% semantics.

discard_diff(I,J) :- candidate(I), candidate(J),
    discarded_member(I,X,Y,W), not discarded_member(J,X,Y,W).
discard_diff(I,J) :- candidate(I), candidate(J),
    discarded_member(J,X,Y,W), not discarded_member(I,X,Y,W).

same_reduct(I,J) :- candidate(I), candidate(J), not discard_diff(I,J).
model_pair(I,J) :- same_reduct(I,J), I != J.

not_subset(I,J) :- model_pair(I,J), member(I,A), not member(J,A).
has_extra(J,I) :- model_pair(I,J), member(J,A), not member(I,A).

strict_subset(I,J) :-
    model_pair(I,J),
    not not_subset(I,J),
    has_extra(J,I).

dominated(I) :- strict_subset(J,I).
keep(I) :- candidate(I), not dominated(I).

#show keep/1.
