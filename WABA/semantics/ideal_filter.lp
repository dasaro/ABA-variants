%% Exact per-reduct ideal filtering over precomputed admissible candidates.
%%
%% Expected facts:
%%   candidate(M).
%%   member(M,A).
%%   discarded_member(M,X,Y,W).
%%
%% Output:
%%   keep(M).
%%
%% Preferred candidates are the subset-maximal admissible candidates for one
%% fixed reduct.  An ideal set is admissible and contained in every such
%% preferred extension; the (unique) ideal extension is the subset-maximal
%% ideal set.  Both comparisons must remain inside the same reduct.

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

not_preferred(I) :- strict_subset(I,J).
preferred(I) :- candidate(I), not not_preferred(I).

not_in_every_preferred(I) :-
    same_reduct(I,P), preferred(P), member(I,A), not member(P,A).
ideal_set(I) :- candidate(I), not not_in_every_preferred(I).

dominated_ideal(I) :-
    ideal_set(I), ideal_set(J), strict_subset(I,J).
keep(I) :- ideal_set(I), not dominated_ideal(I).

#show keep/1.
