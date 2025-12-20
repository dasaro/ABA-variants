%% WABA Cost Maximization (for MIN+LB monoid)
%% Maximize extension_cost (prefer higher quality discards)
%% Use with MIN monoid where budget is a lower bound (quality threshold)

#maximize{ X : extension_cost(X) }.
