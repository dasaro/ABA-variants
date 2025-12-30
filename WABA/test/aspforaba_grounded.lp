%% ASPforABA Grounded Encoding (from encoder.py lines 45-60)
%% Reference implementation (proven correct)

n_assumptions(N) :- #count{X : assumption(X)} = N.
iteration(0..N) :- n_assumptions(N).
supported(X,I) :- assumption(X), in(X,I).
supported(X,I) :- head(R,X), triggered_by_in(R,I).
triggered_by_in(R,I) :- iteration(I), head(R,_), supported(X,I) : body(R,X).
:- in(X,I), contrary(X,Y), supported(Y,I).
defeated(X,I) :- supported(Y,I), contrary(X,Y).
derived_from_undefeated(X,I) :- iteration(I), assumption(X), not defeated(X,I).
derived_from_undefeated(X,I) :- head(R,X), triggered_by_undefeated(R,I).
triggered_by_undefeated(R,I) :- iteration(I), head(R,_), derived_from_undefeated(X,I) : body(R,X).
attacked_by_undefeated(X,I) :- contrary(X,Y), derived_from_undefeated(Y,I).
in(X,I) :- iteration(J), assumption(X), not attacked_by_undefeated(X,J), J+1=I.
in(X) :- in(X,N), n_assumptions(N).
supported(X) :- supported(X,N), n_assumptions(N).
