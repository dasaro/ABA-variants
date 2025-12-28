%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% WABA Example: Network Troubleshooting and Fault Diagnosis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Domain: Technical diagnosis - identifying root cause of network
%% connectivity issues through symptom analysis and diagnostic testing.
%%
%% Scenario:
%% Users report intermittent connectivity issues. Network engineers must
%% diagnose the problem by analyzing symptoms (packet loss, latency spikes),
%% running diagnostic tests (ping, traceroute, DNS queries), and considering
%% multiple potential causes (hardware failure, software bug, configuration
%% error, external attack, ISP issues).
%%
%% Features demonstrated:
%% - Indirect derivations: symptoms -> tests -> fault hypotheses -> root cause
%% - Hybrid derivations: combining symptoms with test results
%% - Weighted arguments: confidence in diagnostic tests and symptom reports
%% - Budget constraint: diagnostic certainty threshold for taking action
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Reported Symptoms (Assumptions)
assumption(packet_loss_observed).        % Users experiencing dropped packets
assumption(high_latency_spikes).         % Intermittent delay increases
assumption(dns_resolution_slow).         % Domain name lookups taking long
assumption(connection_timeouts).         % TCP connections failing to establish
assumption(bandwidth_degradation).       % Throughput lower than normal
assumption(error_logs_present).          % System logs show network errors
assumption(specific_subnet_affected).    % Only certain IP ranges impacted
assumption(all_users_affected).          % Problem is widespread

%% Diagnostic Test Results (Assumptions)
assumption(ping_successful).             % ICMP echo replies received
assumption(traceroute_shows_delays).     % Hop-by-hop path analysis reveals issues
assumption(dns_server_responds).         % DNS queries complete successfully
assumption(firewall_logs_normal).        % No blocked packets in firewall
assumption(switch_ports_up).             % Physical links show connected
assumption(cpu_usage_normal).            % Router/switch CPU not maxed
assumption(interface_errors_detected).   % NIC reporting CRC/frame errors
assumption(duplicate_ip_detected).       % ARP table shows IP conflict

%% Derived Fault Hypotheses
assumption(hardware_fault).              % Physical equipment failure
assumption(software_bug).                % Firmware/OS issue
assumption(configuration_error).         % Misconfigured routing/VLAN
assumption(network_congestion).          % Bandwidth saturation
assumption(external_attack).             % DDoS or intrusion
assumption(isp_issue).                   % Upstream provider problem

%% Diagnostic Conclusions (Derived)
assumption(layer1_problem).              % Physical layer fault
assumption(layer2_problem).              % Data link layer fault
assumption(layer3_problem).              % Network layer fault
assumption(application_layer_problem).   % Application/DNS layer fault

%% Root Cause Determination
assumption(root_cause_identified).       % Primary fault isolated
assumption(mitigation_recommended).      % Action plan defined

%% Weights (diagnostic confidence: 0-100)
%% Based on test reliability and symptom consistency

% Symptom report reliability
weight(packet_loss_observed, 85).        % Measurable metric
weight(high_latency_spikes, 80).         % Objective measurement
weight(dns_resolution_slow, 70).         % User perception + logs
weight(connection_timeouts, 90).         % Clear failure indicator
weight(bandwidth_degradation, 75).       % Throughput monitoring
weight(error_logs_present, 95).          % System-generated evidence
weight(specific_subnet_affected, 80).    % Network segmentation clue
weight(all_users_affected, 85).          % Scope indicator

% Diagnostic test confidence
weight(ping_successful, 90).             % Reliable test
weight(traceroute_shows_delays, 85).     % Path analysis
weight(dns_server_responds, 80).         % Application layer test
weight(firewall_logs_normal, 75).        % Security audit
weight(switch_ports_up, 95).             % Physical layer verification
weight(cpu_usage_normal, 85).            % Resource monitoring
weight(interface_errors_detected, 90).   % Hardware health check
weight(duplicate_ip_detected, 95).       % Address conflict detection

% Fault hypothesis weights
weight(hardware_fault, 85).
weight(software_bug, 70).
weight(configuration_error, 80).
weight(network_congestion, 75).
weight(external_attack, 65).
weight(isp_issue, 60).

% Layer diagnosis weights
weight(layer1_problem, 90).
weight(layer2_problem, 85).
weight(layer3_problem, 80).
weight(application_layer_problem, 75).

% Conclusion weights
weight(root_cause_identified, 90).
weight(mitigation_recommended, 85).

%% Contrary weights (alternative explanations/false positives)
weight(c_packet_loss_observed, 40).      % Measurement error
weight(c_high_latency_spikes, 45).       % Transient congestion
weight(c_dns_resolution_slow, 55).       % Client-side caching
weight(c_connection_timeouts, 35).       % Strong signal
weight(c_bandwidth_degradation, 50).     % Time-of-day variation
weight(c_error_logs_present, 25).        % Logs very reliable
weight(c_specific_subnet_affected, 50).  % Coincidental
weight(c_all_users_affected, 40).        % Sampling bias

weight(c_ping_successful, 30).           % Ping rarely lies
weight(c_traceroute_shows_delays, 40).   % Hop asymmetry
weight(c_dns_server_responds, 45).       % Intermittent issue
weight(c_firewall_logs_normal, 50).      % Logging gaps
weight(c_switch_ports_up, 20).           % Physical state clear
weight(c_cpu_usage_normal, 45).          % Sampling frequency
weight(c_interface_errors_detected, 30). % Hardware metrics reliable
weight(c_duplicate_ip_detected, 25).     % ARP table accurate

weight(c_hardware_fault, 60).            % Hardware usually reliable
weight(c_software_bug, 70).              % Software complex
weight(c_configuration_error, 55).       % Human error common
weight(c_network_congestion, 65).        % Can be transient
weight(c_external_attack, 75).           % Requires strong evidence
weight(c_isp_issue, 70).                 % Outside control

weight(c_layer1_problem, 60).
weight(c_layer2_problem, 65).
weight(c_layer3_problem, 70).
weight(c_application_layer_problem, 65).

weight(c_root_cause_identified, 65).     % Requires high confidence
weight(c_mitigation_recommended, 60).    % Action requires certainty

%% Derivation Rules

% r1: layer1_problem <- interface_errors_detected, switch_ports_up.
head(r1, layer1_problem; r1, interface_errors_detected; r1, switch_ports_up).

% r2: layer2_problem <- duplicate_ip_detected, error_logs_present.
head(r2, layer2_problem; r2, duplicate_ip_detected; r2, error_logs_present).

% r3: layer2_problem <- specific_subnet_affected, switch_ports_up.
head(r3, layer2_problem; r3, specific_subnet_affected; r3, switch_ports_up).

% r4: layer3_problem <- traceroute_shows_delays, packet_loss_observed.
head(r4, layer3_problem; r4, traceroute_shows_delays; r4, packet_loss_observed).

% r5: application_layer_problem <- dns_resolution_slow, dns_server_responds.
head(r5, application_layer_problem; r5, dns_resolution_slow; r5, dns_server_responds).

% r6: hardware_fault <- layer1_problem, interface_errors_detected. [HYBRID]
head(r6, hardware_fault; r6, layer1_problem; r6, interface_errors_detected).

% r7: configuration_error <- layer2_problem, firewall_logs_normal. [HYBRID]
head(r7, configuration_error; r7, layer2_problem; r7, firewall_logs_normal).

% r8: configuration_error <- layer3_problem, cpu_usage_normal. [HYBRID]
head(r8, configuration_error; r8, layer3_problem; r8, cpu_usage_normal).

% r9: software_bug <- error_logs_present, cpu_usage_normal, ping_successful.
head(r9, software_bug; r9, error_logs_present; r9, cpu_usage_normal; r9, ping_successful).

% r10: network_congestion <- bandwidth_degradation, high_latency_spikes, all_users_affected.
head(r10, network_congestion; r10, bandwidth_degradation; r10, high_latency_spikes; r10, all_users_affected).

% r11: external_attack <- all_users_affected, connection_timeouts, packet_loss_observed.
head(r11, external_attack; r11, all_users_affected; r11, connection_timeouts; r11, packet_loss_observed).

% r12: isp_issue <- ping_successful, traceroute_shows_delays, all_users_affected.
head(r12, isp_issue; r12, ping_successful; r12, traceroute_shows_delays; r12, all_users_affected).

% r13: root_cause_identified <- hardware_fault, layer1_problem. [HYBRID]
head(r13, root_cause_identified; r13, hardware_fault; r13, layer1_problem).

% r14: root_cause_identified <- configuration_error, layer2_problem. [HYBRID]
head(r14, root_cause_identified; r14, configuration_error; r14, layer2_problem).

% r15: root_cause_identified <- configuration_error, layer3_problem. [HYBRID]
head(r15, root_cause_identified; r15, configuration_error; r15, layer3_problem).

% r16: mitigation_recommended <- root_cause_identified, error_logs_present. [HYBRID]
head(r16, mitigation_recommended; r16, root_cause_identified; r16, error_logs_present).

%% Contrary Relation (total function)
contrary(packet_loss_observed, c_packet_loss_observed).
contrary(high_latency_spikes, c_high_latency_spikes).
contrary(dns_resolution_slow, c_dns_resolution_slow).
contrary(connection_timeouts, c_connection_timeouts).
contrary(bandwidth_degradation, c_bandwidth_degradation).
contrary(error_logs_present, c_error_logs_present).
contrary(specific_subnet_affected, c_specific_subnet_affected).
contrary(all_users_affected, c_all_users_affected).

contrary(ping_successful, c_ping_successful).
contrary(traceroute_shows_delays, c_traceroute_shows_delays).
contrary(dns_server_responds, c_dns_server_responds).
contrary(firewall_logs_normal, c_firewall_logs_normal).
contrary(switch_ports_up, c_switch_ports_up).
contrary(cpu_usage_normal, c_cpu_usage_normal).
contrary(interface_errors_detected, c_interface_errors_detected).
contrary(duplicate_ip_detected, c_duplicate_ip_detected).

contrary(hardware_fault, c_hardware_fault).
contrary(software_bug, c_software_bug).
contrary(configuration_error, c_configuration_error).
contrary(network_congestion, c_network_congestion).
contrary(external_attack, c_external_attack).
contrary(isp_issue, c_isp_issue).

contrary(layer1_problem, c_layer1_problem).
contrary(layer2_problem, c_layer2_problem).
contrary(layer3_problem, c_layer3_problem).
contrary(application_layer_problem, c_application_layer_problem).

contrary(root_cause_identified, c_root_cause_identified).
contrary(mitigation_recommended, c_mitigation_recommended).

%% Budget: Diagnostic certainty threshold
%% Budget=150: Moderate certainty required before taking action
%% - Can tolerate minor conflicting signals (transient measurements)
%% - Cannot proceed with high uncertainty (competing root causes)
%% Higher budget = lower certainty requirement (faster troubleshooting)
%% Lower budget = higher certainty requirement (more thorough diagnosis)
budget(150).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Expected behavior with Gödel + Max semantics:
%%
%% Hardware Failure Scenario:
%% - Symptoms: packet_loss_observed, error_logs_present, interface_errors_detected
%% - Tests: switch_ports_up (paradoxically - port is up but interface has errors)
%% - Derives: layer1_problem (via r1)
%%           -> hardware_fault (via r6)
%%           -> root_cause_identified (via r13)
%%           -> mitigation_recommended (via r16)
%% - Must overcome: c_root_cause_identified (65)
%% - Max cost: 65 (within budget=150)
%% - Action: Replace faulty NIC/cable
%%
%% Configuration Error Scenario:
%% - Symptoms: specific_subnet_affected, error_logs_present
%% - Tests: switch_ports_up, firewall_logs_normal, cpu_usage_normal
%% - Derives: layer2_problem (via r3)
%%           -> configuration_error (via r7)
%%           -> root_cause_identified (via r14)
%% - Action: Review VLAN/routing config
%%
%% ISP Issue Scenario:
%% - Symptoms: all_users_affected, high_latency_spikes, packet_loss_observed
%% - Tests: ping_successful (local), traceroute_shows_delays (external hops)
%% - Derives: isp_issue (via r12)
%% - Cannot derive mitigation_recommended (outside control)
%% - Action: Contact ISP support
%%
%% DDoS Attack Scenario:
%% - Symptoms: all_users_affected, connection_timeouts, packet_loss_observed,
%%   bandwidth_degradation
%% - Derives: external_attack (via r11)
%%          + network_congestion (via r10)
%% - Competing hypotheses - may need more evidence
%% - Must overcome: c_external_attack (75) - high bar for claiming attack
%%
%% Ambiguous Scenario (Multiple Hypotheses):
%% - Mixed signals: some layer2 + some layer3 symptoms
%% - Both configuration_error and software_bug derivable
%% - Budget determines which conflicting evidence can be tolerated
%% - May require additional diagnostic tests to disambiguate
%%
%% This demonstrates WABA's ability to model technical troubleshooting where
%% symptoms are ambiguous, tests have varying reliability, and diagnostic
%% certainty thresholds (budget) determine when to take corrective action.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
