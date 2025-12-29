%% Framework designed to separate Admissible from CF
%%
%% This framework should have CF extensions that are NOT admissible
%%
%% Structure:
%%   a attacks b
%%   b attacks a
%%   c attacks a (but a doesn't attack c back)
%%
%% Expected:
%%   CF extensions: {}, {a}, {b}, {c}, {b,c}
%%   Admissible extensions: {}, {b}, {c}, {b,c}
%%
%%   {a} is CF (not defeated when a is in, b is out, c is out)
%%   {a} is NOT admissible (a is attacked by c, but doesn't defend against c)

assumption(a).
assumption(b).
assumption(c).

% a attacks b
contrary(b, a).

% b attacks a
contrary(a, b).

% c attacks a (asymmetric - a doesn't attack c)
contrary(a, c).

% Weights
weight(a, 10).
weight(b, 10).
weight(c, 10).

% Budget - very restrictive, can't discard all attacks
budget(5).  % Can only discard attacks costing ≤5
