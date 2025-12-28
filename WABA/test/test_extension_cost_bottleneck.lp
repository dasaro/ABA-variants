%% Test Extension Cost Computation with Bottleneck-Cost Semiring
%%
%% Simple scenario to verify extension_cost with different monoids
%%
%% Setup: Three security profiles with different worst-case vulnerabilities
%% - profile_secure: worst component = 20 (best)
%% - profile_standard: worst component = 50 (medium)
%% - profile_legacy: worst component = 80 (worst)
%% All profiles attack each other (mutually exclusive)

%% Three mutually exclusive security profiles
assumption(profile_secure).
assumption(profile_standard).
assumption(profile_legacy).

%% Components for secure profile (all low vulnerabilities)
assumption(firewall_secure). weight(firewall_secure, 15).
assumption(encryption_secure). weight(encryption_secure, 10).
assumption(auth_secure). weight(auth_secure, 20).

%% Components for standard profile (medium vulnerabilities)
assumption(firewall_std). weight(firewall_std, 50).
assumption(encryption_std). weight(encryption_std, 40).
assumption(auth_std). weight(auth_std, 45).

%% Components for legacy profile (high vulnerabilities)
assumption(firewall_legacy). weight(firewall_legacy, 80).
assumption(encryption_legacy). weight(encryption_legacy, 60).
assumption(auth_legacy). weight(auth_legacy, 70).

%% Rules: System risk = worst component (Bottleneck-cost: max)
%% r1: risk_secure <- profile_secure, firewall_secure, encryption_secure, auth_secure.
head(r1, risk_secure).
body(r1, profile_secure).
body(r1, firewall_secure).
body(r1, encryption_secure).
body(r1, auth_secure).

%% r2: risk_standard <- profile_standard, firewall_std, encryption_std, auth_std.
head(r2, risk_standard).
body(r2, profile_standard).
body(r2, firewall_std).
body(r2, encryption_std).
body(r2, auth_std).

%% r3: risk_legacy <- profile_legacy, firewall_legacy, encryption_legacy, auth_legacy.
head(r3, risk_legacy).
body(r3, profile_legacy).
body(r3, firewall_legacy).
body(r3, encryption_legacy).
body(r3, auth_legacy).

%% Mutual attacks (each risk attacks the other profiles)
contrary(profile_secure, risk_standard).
contrary(profile_secure, risk_legacy).

contrary(profile_standard, risk_secure).
contrary(profile_standard, risk_legacy).

contrary(profile_legacy, risk_secure).
contrary(profile_legacy, risk_standard).

%% Budget: High enough to test various combinations
budget(200).

%% EXPECTED RESULTS with Bottleneck-cost:
%%
%% Derivation weights (Bottleneck-cost: max = worst component):
%% - risk_secure: max(#inf, 15, 10, 20) = 20 (auth is worst)
%% - risk_standard: max(#inf, 50, 40, 45) = 50 (firewall is worst)
%% - risk_legacy: max(#inf, 80, 60, 70) = 80 (firewall is worst)
%%
%% With MAX monoid (UB regime):
%% Extension {profile_secure}: extension_cost(0) - no discards
%% Extension {profile_standard}: extension_cost(0) - no discards
%% Extension {profile_legacy}: extension_cost(0) - no discards
%% Extension {profile_secure, profile_standard}: max(20, 50) = 50
%% Extension {profile_secure, profile_legacy}: max(20, 80) = 80
%% Extension {profile_standard, profile_legacy}: max(50, 80) = 80
%% Extension {all three}: max(20, 20, 50, 50, 80, 80) = 80
%%
%% With SUM monoid:
%% Extension {profile_secure, profile_standard}: 20 + 50 = 70
%% Extension {profile_secure, profile_legacy}: 20 + 80 = 100
%% Extension {profile_standard, profile_legacy}: 50 + 80 = 130
%% Extension {all three}: varies based on which attacks discarded
%%
%% With COUNT monoid:
%% Extension {profile_secure, profile_standard}: 2 attacks
%% Extension {all three}: 6 attacks

%% Run with MAX monoid:
%%   clingo -n 0 core/base.lp semiring/bottleneck_cost.lp monoid/baseline/max.lp \
%%          filter/standard.lp semantics/stable.lp test/test_extension_cost_bottleneck.lp
%%
%% Run with SUM monoid:
%%   clingo -n 0 core/base.lp semiring/bottleneck_cost.lp monoid/baseline/sum.lp \
%%          filter/standard.lp semantics/stable.lp test/test_extension_cost_bottleneck.lp
%%
%% Run with MIN monoid (LB regime - quality threshold):
%%   clingo -n 0 core/base.lp semiring/bottleneck_cost.lp monoid/baseline/min.lp \
%%          filter/standard.lp semantics/stable.lp test/test_extension_cost_bottleneck.lp
%%   Extension cost = MIN of discarded attack risks (higher is better in LB)
