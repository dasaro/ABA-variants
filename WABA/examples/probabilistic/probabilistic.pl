% ProbLog counterpart of probabilistic.lp.
%
% The probabilistic facts are independent choices.  ProbLog answers a different
% question from tropical wABA: it returns the marginal probability of a query,
% i.e. the probability of the union of all worlds in which some proof succeeds.
% In particular, the rain and sprinkler proofs overlap when both facts are true.

0.9::rain.
0.7::sprinkler.
0.5::cold_night.

grass_wet :- rain.
grass_wet :- sprinkler.
slippery :- grass_wet, cold_night.

query(grass_wet).
query(slippery).

% Exact marginals:
%   P(grass_wet) = 1 - (1 - 0.9)(1 - 0.7) = 0.97
%   P(slippery)  = 0.5 * P(grass_wet)       = 0.485
%
% Tropical wABA instead selects the best proof:
%   V(grass_wet) = max(0.9, 0.7) = 0.9
%   V(slippery)  = 0.5 * V(grass_wet) = 0.45
