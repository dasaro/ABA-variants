%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WABA Staged Semantics (ASPARTIX-based, Simplified)
%
% Staged = Conflict-free with maximal range
% Range = S ∪ defeated(S)
%
% This version uses heuristics instead of saturation
% Usage: clingo -n 0 --heuristic=Domain --enum=domRec <files>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% S has to be conflict-free
:- in(X), defeated(X).

%% Heuristic to maximize range (S ∪ defeated)
%% Prefer including assumptions to maximize coverage
#heuristic in(X) : assumption(X). [1,true]
