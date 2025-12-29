%% CF2 (Conflict-Free 2) Semantics
%% An extension E is CF2 if:
%% 1. E is conflict-free
%% 2. E is maximal: no assumption can be added while remaining conflict-free
%%
%% Note: In this implementation, CF2 ≡ Naive (both are maximal conflict-free)
%% The chain Stable ⊆ CF2 ⊆ Naive ⊆ CF holds with CF2 = Naive
%%
%% Usage: clingo -n 0 <files> semantics/cf2.lp

%% Conflict-freeness
:- in(X), defeated(X).

%% CF2 constraint: Maximal conflict-free (same as Naive)
%% An out assumption X blocks maximality if:
%% - X is not currently defeated
%% - Adding X wouldn't violate conflict-freeness

blocks_maximality(X) :- assumption(X),
                        out(X),
                        not defeated(X),
                        not has_contrary_in_extension(X).

%% X has a contrary in the extension if something in the extension attacks X
has_contrary_in_extension(X) :- assumption(X),
                                 contrary(X, Y),
                                 in(Y).

%% Reject non-maximal extensions
:- blocks_maximality(X).
