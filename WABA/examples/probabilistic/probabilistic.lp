%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% WEIGHTS AS PROBABILITIES — most-probable-proof (Viterbi) WABA
%%
%% Probabilities MULTIPLY along a derivation; -ln turns product into sum, so the
%% TROPICAL semiring (min,+) computes the most-probable proof (Viterbi):
%%
%%   encode:  w = round(-1000 * ln p)     (p in (0,1] -> integer w >= 0; p=1 -> 0)
%%   decode:  p = exp(-w / 1000)
%%
%%   conjunction (rule body)   : +   over body  = surprisal of the product of premises
%%   disjunction (derivations) : min            = the most probable proof
%%
%% This is the Viterbi semiring ([0,1], max, x) carried onto tropical (min,+) by
%% p |-> -ln p (max is mapped to min because -ln reverses the usual order).
%% The result is a BEST-PROOF score, not a marginal probability.  Exact ProbLog
%% marginals compile the proofs into a Boolean explanation and perform weighted
%% model counting.  Merely replacing min by sum would double-count possible worlds
%% whenever proofs overlap, so a plain sum-product fold is not enough.
%%
%% Probability table used below (p -> encoded weight):
%%   rain        p = 0.90  ->  105
%%   sprinkler   p = 0.70  ->  357
%%   cold_night  p = 0.50  ->  693
%%
%% SEMIRING : tropical (min,+), lower-is-better (smaller surprisal = more probable)
%% MONOID   : sum  (the dismissed attacks' numeric surprisals add; an upper-bound
%%            budget enforces sum(w_i) <= beta, equivalently
%%            product(exp(-w_i/1000)) >= exp(-beta/1000)).
%%
%% The product in that identity is a product of decoded BEST-PROOF SCORES.  It is
%% not, in general, the joint probability of the discarded attacks: attacks can
%% share probabilistic leaves.  Also note the polarity forced by surprisal: a more
%% probable attack has a smaller numeric discard price.  `beta` is therefore a
%% bound in surprisal units, not a probability-mass budget or evidential resistance.
%%
%% RUN (pure propagation; read supported_with_weight(X,w) and decode p = exp(-w/1000)):
%%   ./bin/waba run --framework examples/probabilistic/probabilistic.lp \
%%        --semiring tropical --semantics stable --show standard
%%
%% RUN (budgeted: is the dry_path defence affordable? enumerate within beta):
%%   clingo -n 0 -c beta=800 core/base.lp semiring/tropical.lp monoid/sum.lp \
%%        constraint/ub.lp filter/projection.lp semantics/stable.lp \
%%        examples/probabilistic/probabilistic.lp
%%   The {rain,sprinkler,cold_night,dry_path} extension discards `slippery` at
%%   surprisal 798 (decoded best-proof score about 0.45) and is feasible iff
%%   beta >= 798; it vanishes below 798.  Under sum-min the optimiser instead
%%   prefers discarding nothing, i.e. dry_path out at cost 0.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Probabilistic leaves (assumptions), weights = surprisals
assumption(rain).        weight(rain, 105).        % p = 0.90
assumption(sprinkler).   weight(sprinkler, 357).   % p = 0.70
assumption(cold_night).  weight(cold_night, 693).  % p = 0.50

%% grass_wet holds if it rained OR the sprinkler ran (two independent proofs)
head(r1, grass_wet).  body(r1, rain).        % grass_wet <- rain
head(r2, grass_wet).  body(r2, sprinkler).   % grass_wet <- sprinkler
%% => supported_with_weight(grass_wet, min(105,357)=105) -> p = e^-0.105 = 0.90
%%    (the most probable proof: it rained)

%% the path is slippery if the grass is wet AND the night is cold (frost)
head(r3, slippery).   body(r3, grass_wet).  body(r3, cold_night).   % slippery <- grass_wet, cold_night
%% => supported_with_weight(slippery, 105+693=798) -> p = e^-0.798 = 0.45 = 0.90 * 0.50

%% Default belief: the path is safe to walk. The (probabilistic) conclusion
%% `slippery` is its contrary, i.e. slippery attacks dry_path with weight 798.
assumption(dry_path).
%% The probabilistic leaves are unattacked assumptions, represented by fresh underivable
%% contraries so that contrary/2 remains a total function.
contrary(rain, not_rain).
contrary(sprinkler, not_sprinkler).
contrary(cold_night, not_cold_night).
contrary(dry_path, slippery).
%% Under sum+ub, dry_path can be accepted only by discarding the slippery attack,
%% at surprisal cost 798 (decoded best-proof score about 0.45); beta caps that
%% numeric surprisal.  It does not turn the extension into a probabilistic event.
