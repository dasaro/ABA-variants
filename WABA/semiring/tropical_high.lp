%% ALIAS — not a separate algebra.
%% `tropical_high` is the higher-is-better (reward) polarity dual of `tropical` (min,+).
%% That dual is exactly the (max, +) arctic algebra, so this file is a thin alias for
%% semiring/arctic.lp. Kept so that `--semiring tropical_high` and raw
%% `clingo ... semiring/tropical_high.lp ...` runs keep resolving.
#include "arctic.lp".
