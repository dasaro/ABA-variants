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
%% This is the Viterbi semiring ([0,1], max, x) carried onto tropical (min,+) by the
%% order-isomorphism p |-> -ln p. (Full MARGINAL probabilities -- a sum over ALL
%% proofs -- would instead need the sum-product semiring, i.e. the ProbLog setting.)
%%
%% Probability table used below (p -> encoded weight):
%%   rain        p = 0.90  ->  105
%%   sprinkler   p = 0.70  ->  357
%%   cold_night  p = 0.50  ->  693
%%
%% SEMIRING : tropical (min,+), lower-is-better (smaller surprisal = more probable)
%% MONOID   : sum  (the dismissed attacks' surprisals add; ub budget beta bounds the
%%            JOINT probability of what you dismiss: sum <= beta  <=>  prod p >= e^-beta/1000)
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
%%   surprisal 798 (probability 0.45) and is feasible iff beta >= 798; it vanishes
%%   at beta < 798. (sum+ub bounds the JOINT probability of the dismissed attacks
%%   at >= exp(-beta/1000); under sum-min the optimiser instead prefers discarding
%%   nothing, i.e. dry_path out at cost 0.)
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
contrary(dry_path, slippery).
%% Under sum+ub, dry_path can be accepted only by discarding the slippery attack,
%% at surprisal cost 798 (probability 0.45); beta caps that cost.
