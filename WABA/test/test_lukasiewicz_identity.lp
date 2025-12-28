%% Test Łukasiewicz Identity Elements
%%
%% Mathematical identities should be:
%% - Conjunction: K (default K=100)
%% - Disjunction: 0
%%
%% Test: r: c <- a, identity_conj (where identity_conj has weight K)
%% Expected: c gets weight equal to a's weight

assumption(a). weight(a, 50).
assumption(identity_conj). weight(identity_conj, 100).  % K = 100

head(r1, c).
body(r1, a).
body(r1, identity_conj).

%% Expected with Łukasiewicz AND:
%% c = max(0, 50 + 100 - 100*1) = max(0, 50) = 50 ✓
%% This confirms K=100 is the conjunction identity

%% Test disjunction identity:
assumption(b). weight(b, 30).
assumption(identity_disj). weight(identity_disj, 0).

head(r2, d).
body(r2, b).

head(r3, d).
body(r3, identity_disj).

%% Expected with Łukasiewicz OR:
%% d gets max(0, 30) from r2 = 30
%% d gets max(0, 0) from r3 = 0
%% Combined: min(100, 30 + 0) = 30 ✓
%% This confirms 0 is the disjunction identity
