%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WABA Staged Semantics (Debug - No Saturation)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% S has to be conflict-free
:- in(X), defeated(X).

%% Computing the range S+ of the guessed set S
in_range(X) :- in(X).
in_range(X) :- defeated(X).

%% Show range for debugging
#show in_range/1.
