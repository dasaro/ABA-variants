%% Exact per-reduct range-maximal filtering over precomputed candidates.
%%
%% Expected facts:
%%   candidate(M).
%%   range_member(M,A).       % S union the assumptions attacked by S
%%   discarded_member(M,X,Y,W).
%%
%% Output:
%%   keep(M).
%%
%% Loading complete candidates yields ordinary assumption-level semi-stable
%% semantics; loading conflict-free candidates yields stage semantics.  Equal
%% maximal ranges may have several witnessing extensions, all of which survive.

discard_diff(I,J) :- candidate(I), candidate(J),
    discarded_member(I,X,Y,W), not discarded_member(J,X,Y,W).
discard_diff(I,J) :- candidate(I), candidate(J),
    discarded_member(J,X,Y,W), not discarded_member(I,X,Y,W).

same_reduct(I,J) :- candidate(I), candidate(J), not discard_diff(I,J).
model_pair(I,J) :- same_reduct(I,J), I != J.

not_range_subset(I,J) :-
    model_pair(I,J), range_member(I,A), not range_member(J,A).
has_range_extra(J,I) :-
    model_pair(I,J), range_member(J,A), not range_member(I,A).

strict_range_subset(I,J) :-
    model_pair(I,J),
    not not_range_subset(I,J),
    has_range_extra(J,I).

dominated(I) :- strict_range_subset(I,J).
keep(I) :- candidate(I), not dominated(I).

#show keep/1.
