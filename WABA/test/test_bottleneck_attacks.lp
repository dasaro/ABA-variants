%% Test Bottleneck-Cost Semiring with Attacks and Budget Constraints
%%
%% Scenario: System security configuration
%% - Components have vulnerability scores (higher = more vulnerable)
%% - Configurations attack each other (mutually exclusive)
%% - Budget is quality threshold (only allow configurations below threshold)
%%
%% Expected behavior:
%% - Bottleneck-cost takes MAX (worst vulnerability in chain)
%% - Multiple configs → choose MIN (least vulnerable)
%% - Attack weight = vulnerability score
%% - Budget threshold determines acceptable configs

%% Three possible security configurations
assumption(use_config_legacy).
assumption(use_config_standard).
assumption(use_config_hardened).

%% Component vulnerabilities for Legacy config
%% Worst component: firewall has high vulnerability (80)
assumption(vuln_firewall_legacy). weight(vuln_firewall_legacy, 80).
assumption(vuln_encryption_legacy). weight(vuln_encryption_legacy, 40).
assumption(vuln_auth_legacy). weight(vuln_auth_legacy, 50).

%% Component vulnerabilities for Standard config
%% More balanced: worst is 60
assumption(vuln_firewall_std). weight(vuln_firewall_std, 60).
assumption(vuln_encryption_std). weight(vuln_encryption_std, 55).
assumption(vuln_auth_std). weight(vuln_auth_std, 60).

%% Component vulnerabilities for Hardened config
%% Best security: worst is 30
assumption(vuln_firewall_hard). weight(vuln_firewall_hard, 30).
assumption(vuln_encryption_hard). weight(vuln_encryption_hard, 25).
assumption(vuln_auth_hard). weight(vuln_auth_hard, 30).

%% Rules: System vulnerability = worst component (bottleneck-cost: max)
%% r1: system_risk_legacy <- use_config_legacy, vuln_firewall_legacy, vuln_encryption_legacy, vuln_auth_legacy.
head(r1, system_risk_legacy).
body(r1, use_config_legacy).
body(r1, vuln_firewall_legacy).
body(r1, vuln_encryption_legacy).
body(r1, vuln_auth_legacy).

%% r2: system_risk_std <- use_config_standard, vuln_firewall_std, vuln_encryption_std, vuln_auth_std.
head(r2, system_risk_std).
body(r2, use_config_standard).
body(r2, vuln_firewall_std).
body(r2, vuln_encryption_std).
body(r2, vuln_auth_std).

%% r3: system_risk_hard <- use_config_hardened, vuln_firewall_hard, vuln_encryption_hard, vuln_auth_hard.
head(r3, system_risk_hard).
body(r3, use_config_hardened).
body(r3, vuln_firewall_hard).
body(r3, vuln_encryption_hard).
body(r3, vuln_auth_hard).

%% Conflicts: Configurations are mutually exclusive
contrary(use_config_standard, system_risk_legacy).
contrary(use_config_hardened, system_risk_legacy).

contrary(use_config_legacy, system_risk_std).
contrary(use_config_hardened, system_risk_std).

contrary(use_config_legacy, system_risk_hard).
contrary(use_config_standard, system_risk_hard).

%% Budget: Security policy requires max vulnerability ≤ 65
%% (Using MIN monoid with LB regime for quality threshold)
budget(65).

%% EXPECTED RESULTS with Bottleneck-cost + MIN (LB regime), budget=65:
%%
%% Derivation weights (Bottleneck-cost: max = worst component):
%% - system_risk_legacy: max(#inf, 80, 40, 50) = 80 (firewall is bottleneck)
%% - system_risk_std: max(#inf, 60, 55, 60) = 60 (firewall/auth tied)
%% - system_risk_hard: max(#inf, 30, 25, 30) = 30 (firewall/auth tied)
%%
%% Attack strengths:
%% - system_risk_legacy attacks others (weight 80)
%% - system_risk_std attacks others (weight 60)
%% - system_risk_hard attacks others (weight 30)
%%
%% Extension {use_config_hardened}:
%% - Accepts: system_risk_hard (vulnerability 30)
%% - Discards attacks from: system_risk_legacy (80), system_risk_std (60)
%% - Cost (MIN monoid, LB): min(80, 60) = 60 ≥ 65? NO, but we want HIGH quality (≥ 65 means we DON'T discard strong attacks)
%%
%% Wait, LB regime interpretation: budget=65 means we only accept extensions where
%% min discarded attack ≥ 65. So we need to discard attacks with weight ≥ 65.
%% This means we can only choose configs that are attacked by high-vulnerability systems.
%%
%% Actually, with MIN+LB, lower budget is MORE permissive. Let me reconsider...
%%
%% For quality thresholds with bottleneck-cost, we probably want UB regime (MAX monoid):
%% Extension cost = worst vulnerability, budget = max acceptable vulnerability

%% REVISED: Use MAX monoid (UB regime) for intuitive semantics
%% Extension {use_config_legacy}:
%% - system_risk_legacy has vulnerability 80
%% - No attacks to discard (legacy wins by default if chosen alone)
%% - But 80 > 65, so REJECTED (exceeds security threshold)
%%
%% Extension {use_config_standard}:
%% - system_risk_std has vulnerability 60
%% - 60 ≤ 65, ACCEPTED ✓
%%
%% Extension {use_config_hardened}:
%% - system_risk_hard has vulnerability 30
%% - 30 ≤ 65, ACCEPTED ✓
%%
%% EXPECTED: Both {use_config_standard} and {use_config_hardened} are acceptable
%% Hardened config is best (lowest vulnerability 30)

%% Run with MAX monoid (more intuitive for this scenario):
%%   clingo -n 0 core/base.lp semiring/bottleneck_cost.lp monoid/baseline/max.lp \
%%          filter/standard.lp semantics/stable.lp test/test_bottleneck_attacks.lp
