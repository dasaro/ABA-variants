%% Exact subset-maximal filtering over precomputed candidate extensions.
%%
%% Expected facts:
%%   candidate(M).
%%   member(M,A).
%%
%% Output:
%%   keep(M).
%%
%% Rationale:
%%   exact subset-maximality is a set-inclusion property; it is kept separate
%%   from WABA's numeric weight optimization layer instead of being encoded with
%%   plain #maximize priority levels.

model_pair(I,J) :- candidate(I), candidate(J), I != J.

not_subset(I,J) :- model_pair(I,J), member(I,A), not member(J,A).
has_extra(J,I) :- model_pair(I,J), member(J,A), not member(I,A).

strict_subset(I,J) :-
    model_pair(I,J),
    not not_subset(I,J),
    has_extra(J,I).

dominated(I) :- strict_subset(I,J).
keep(I) :- candidate(I), not dominated(I).

#show keep/1.
