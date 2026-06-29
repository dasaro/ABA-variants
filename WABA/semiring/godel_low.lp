%% ALIAS — not a separate algebra.
%% `godel_low` is the lower-is-better (cost) polarity dual of `godel` (max,min).
%% That dual is exactly the (min, max) bottleneck-cost algebra, so this file is a
%% thin alias for semiring/bottleneck_cost.lp. Kept so that `--semiring godel_low`
%% and raw `clingo ... semiring/godel_low.lp ...` runs keep resolving.
#include "bottleneck_cost.lp".
