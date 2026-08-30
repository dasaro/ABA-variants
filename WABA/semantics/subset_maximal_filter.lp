%% Exact per-reduct subset-maximal filtering over precomputed candidates.
%%
%% Expected facts:
%%   candidate(M).
%%   member(M,A).
%%   discarded_member(M,X,Y,W).
%%
%% Output:
%%   keep(M).
%%
%% Each M records both an admissible assumption set and the affordable discard
%% witness D that determines its reduced framework.  Beta-preferred means:
%% choose D, apply ordinary preferred semantics to Att \ D, then existentially
%% forget D.  Consequently candidates may dominate one another only when their
%% discard sets are identical.  Global maximality across different witnesses is
%% a different semantics.

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

dominated(I) :- strict_subset(I,J).
keep(I) :- candidate(I), not dominated(I).

#show keep/1.
