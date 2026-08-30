%% Internal projection used by the range-based post-filters.
%% `defeated/1` is supplied by cf.lp/admissible.lp and denotes exactly the
%% assumptions attacked by the current candidate in the fixed reduct.

semantic_range(X) :- in(X).
semantic_range(X) :- defeated(X).

#show semantic_range/1.
