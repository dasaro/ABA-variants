%% Naive Semantics (Saturation-Based)
%%
%% Definition: Maximal (w.r.t. set inclusion) conflict-free extensions
%%
%% Usage: clingo -n 0 <files> semantics/naive_saturation.lp
%%
%% Approach: Saturation-based subset-maximality check
%% - If not ⊆-maximal (unstable), try to witness a strictly larger conflict-free extension
%% - If witness succeeds (spoil=false), reject the extension
%% - If witness fails (spoil=true), accept (extension is maximal)

%% Conflict-freeness
:- in(X), defeated(X).

%% Check if subset-maximal
miss(X) :- assumption(X), not in(X).
unstable :- miss(_).

%% When unstable, guess a strictly larger extension
larger_ext(X) : miss(X) :- unstable.
larger_ext(X) :- in(X), unstable.

%% Ensure larger_ext is strictly larger (at least one miss assumption added)
:- unstable, { larger_ext(X) : miss(X) } = 0.

%% Compute what's supported under larger_ext
supported_larger(X) :- assumption(X), larger_ext(X).
supported_larger(X) :- head(R,X), triggered_larger(R).
triggered_larger(R) :- head(R,_), supported_larger(X) : body(R,X).

%% Compute attacks under larger_ext (no weights needed for conflict-freeness check)
attacks_larger(X,Y) :- supported_larger(X), assumption(Y), contrary(Y,X).

%% Compute what's defeated under larger_ext
defeated_larger(X) :- attacks_larger(_,X), assumption(X).

%% Check if larger_ext is conflict-free
%% spoil=true if larger_ext contains a defeated assumption (not conflict-free)
spoil :- larger_ext(X), defeated_larger(X), unstable.

%% Saturation: if spoiled, make all assumptions part of larger_ext
larger_ext(X) :- spoil, assumption(X), unstable.

%% Reject if we found a valid larger conflict-free extension (unstable but not spoiled)
:- unstable, not spoil.

#show in/1.
