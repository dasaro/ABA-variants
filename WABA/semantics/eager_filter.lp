%% Exact per-reduct eager filtering over precomputed complete candidates.
%%
%% Expected facts:
%%   candidate(M).
%%   member(M,A).
%%   range_member(M,A).       % S union the assumptions attacked by S
%%   discarded_member(M,X,Y,W).
%%
%% Output:
%%   keep(M).
%%
%% First identify the semi-stable candidates: the complete candidates whose
%% ranges are subset-maximal in one fixed reduct.  The eager extension is the
%% greatest admissible set contained in every semi-stable extension; it is
%% complete, so it is enough to retain complete candidates with that universal
%% containment property and then subset-maximise them.  Every comparison below
%% is guarded by equality of the discard witness D.

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

not_range_subset(I,J) :-
    model_pair(I,J), range_member(I,A), not range_member(J,A).
has_range_extra(J,I) :-
    model_pair(I,J), range_member(J,A), not range_member(I,A).
strict_range_subset(I,J) :-
    model_pair(I,J),
    not not_range_subset(I,J),
    has_range_extra(J,I).

not_semi_stable(I) :- strict_range_subset(I,J).
semi_stable(I) :- candidate(I), not not_semi_stable(I).

not_in_every_semi_stable(I) :-
    same_reduct(I,P), semi_stable(P), member(I,A), not member(P,A).
eager_set(I) :- candidate(I), not not_in_every_semi_stable(I).

dominated_eager(I) :- eager_set(I), eager_set(J), strict_subset(I,J).
keep(I) :- eager_set(I), not dominated_eager(I).

#show keep/1.
