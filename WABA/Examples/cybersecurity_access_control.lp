%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% WABA Example: Cybersecurity Access Control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Domain: Network security - deciding whether to allow/block access
%% based on multiple security indicators with varying confidence levels.
%%
%% Scenario:
%% A security system must decide whether to grant network access to a user
%% based on various indicators: authentication status, behavioral patterns,
%% geolocation, device trust, and threat intelligence.
%%
%% Features demonstrated:
%% - Indirect derivations: indicators -> risk levels -> access decisions
%% - Hybrid derivations: combining direct indicators with derived risk scores
%% - Weighted arguments: confidence levels in security indicators
%% - Budget constraint: acceptable risk threshold for access decisions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Security Indicators (Assumptions)
assumption(valid_credentials).           % User provided valid login credentials
assumption(normal_behavior).             % User activity matches historical patterns
assumption(trusted_location).            % Access from known/approved location
assumption(recognized_device).           % Device has been used before
assumption(low_threat_intel).            % No current threat reports for user/IP
assumption(within_working_hours).        % Access attempt during normal hours
assumption(mfa_verified).                % Multi-factor authentication succeeded
assumption(no_recent_failures).          % No recent failed login attempts

%% Derived atoms
assumption(low_risk_profile).            % Overall user risk assessment is low
assumption(high_confidence_auth).        % Strong authentication confidence
assumption(trusted_context).             % Access context is trusted

%% Access decision
assumption(grant_access).                % Final decision: allow access

%% Weights (confidence/severity levels: 0-100)
weight(valid_credentials, 90).           % High confidence in authentication
weight(normal_behavior, 70).             % Moderate confidence in behavior analysis
weight(trusted_location, 60).            % Moderate confidence in geolocation
weight(recognized_device, 65).           % Moderate confidence in device fingerprinting
weight(low_threat_intel, 85).            % High confidence in threat data
weight(within_working_hours, 40).        % Low confidence indicator (easily spoofed)
weight(mfa_verified, 95).                % Very high confidence in MFA
weight(no_recent_failures, 50).          % Moderate confidence indicator

weight(low_risk_profile, 80).            % High confidence in risk assessment
weight(high_confidence_auth, 85).        % High confidence in authentication
weight(trusted_context, 75).             % High confidence in context

weight(c_grant_access, 100).             % Maximum severity for blocking access
weight(c_valid_credentials, 95).         % High severity - credential compromise
weight(c_normal_behavior, 75).           % Moderate severity - anomalous behavior
weight(c_trusted_location, 60).          % Moderate severity - suspicious location
weight(c_recognized_device, 65).         % Moderate severity - unknown device
weight(c_low_threat_intel, 90).          % High severity - known threat
weight(c_within_working_hours, 30).      % Low severity - off-hours access
weight(c_mfa_verified, 98).              % Very high severity - MFA failure
weight(c_no_recent_failures, 55).        % Moderate severity - failed attempts
weight(c_low_risk_profile, 85).          % High severity - risky user profile
weight(c_high_confidence_auth, 90).      % High severity - weak authentication
weight(c_trusted_context, 70).           % Moderate severity - suspicious context

%% Derivation Rules

% r1: high_confidence_auth <- valid_credentials, mfa_verified.
head(r1, high_confidence_auth; r1, valid_credentials; r1, mfa_verified).

% r2: high_confidence_auth <- valid_credentials, no_recent_failures.
head(r2, high_confidence_auth; r2, valid_credentials; r2, no_recent_failures).

% r3: trusted_context <- trusted_location, within_working_hours.
head(r3, trusted_context; r3, trusted_location; r3, within_working_hours).

% r4: trusted_context <- recognized_device, trusted_location.
head(r4, trusted_context; r4, recognized_device; r4, trusted_location).

% r5: low_risk_profile <- normal_behavior, low_threat_intel.
head(r5, low_risk_profile; r5, normal_behavior; r5, low_threat_intel).

% r6: low_risk_profile <- normal_behavior, no_recent_failures, trusted_location.
head(r6, low_risk_profile; r6, normal_behavior; r6, no_recent_failures; r6, trusted_location).

% r7: grant_access <- high_confidence_auth, trusted_context. [HYBRID: derived + derived]
head(r7, grant_access; r7, high_confidence_auth; r7, trusted_context).

% r8: grant_access <- high_confidence_auth, low_risk_profile. [HYBRID: derived + derived]
head(r8, grant_access; r8, high_confidence_auth; r8, low_risk_profile).

% r9: grant_access <- mfa_verified, low_risk_profile, recognized_device. [HYBRID: assumption + derived + assumption]
head(r9, grant_access; r9, mfa_verified; r9, low_risk_profile; r9, recognized_device).

%% Contrary Relation (total function - every assumption has exactly one contrary)
contrary(valid_credentials, c_valid_credentials).
contrary(normal_behavior, c_normal_behavior).
contrary(trusted_location, c_trusted_location).
contrary(recognized_device, c_recognized_device).
contrary(low_threat_intel, c_low_threat_intel).
contrary(within_working_hours, c_within_working_hours).
contrary(mfa_verified, c_mfa_verified).
contrary(no_recent_failures, c_no_recent_failures).
contrary(low_risk_profile, c_low_risk_profile).
contrary(high_confidence_auth, c_high_confidence_auth).
contrary(trusted_context, c_trusted_context).
contrary(grant_access, c_grant_access).

%% Budget: Risk tolerance for granting access
%% Budget=200: Can tolerate discarding attacks up to severity 200
%% (e.g., ignore off-hours access + suspicious location = 30+60=90)
budget(200).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Expected behavior with Gödel + Max semantics:
%%
%% Scenario 1: All positive indicators present
%% - Extension includes all assumptions
%% - grant_access is in
%% - No attacks need to be discarded
%% - Cost: 0
%%
%% Scenario 2: Missing mfa_verified (attacked by c_mfa_verified, weight=98)
%% - Can still derive high_confidence_auth via r2 if valid_credentials + no_recent_failures
%% - Must discard attack on mfa_verified (cost=98)
%% - grant_access may still be derivable via r7 or r8
%% - Cost: 98 (within budget=200)
%%
%% Scenario 3: Multiple failures (missing normal_behavior, missing trusted_location)
%% - Attacks: c_normal_behavior (75) + c_trusted_location (60) = 135
%% - May block low_risk_profile and trusted_context derivations
%% - grant_access becomes harder to derive
%% - Cost: max(75, 60) = 75 with Max monoid (within budget)
%%
%% This demonstrates WABA's ability to model risk-based access control
%% where security indicators have different confidence levels and the system
%% can tolerate certain levels of risk (budget) when making access decisions.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
