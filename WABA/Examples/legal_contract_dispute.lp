%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% WABA Example: Legal Contract Dispute Resolution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Domain: Legal reasoning - resolving a contract breach dispute
%% with competing arguments based on evidence and legal precedents.
%%
%% Scenario:
%% A contractor (defendant) is accused of breaching a construction contract.
%% Multiple pieces of evidence and legal doctrines interact to determine
%% whether breach occurred and whether any defenses apply.
%%
%% Features demonstrated:
%% - Indirect derivations: facts -> legal doctrines -> conclusions
%% - Hybrid derivations: combining factual evidence with legal principles
%% - Weighted arguments: strength of evidence and precedent authority
%% - Budget constraint: burden of proof threshold
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Factual Evidence (Assumptions)
assumption(contract_signed).             % Valid contract exists
assumption(work_incomplete).             % Contractor did not finish work
assumption(payment_withheld).            % Client withheld payment
assumption(delay_documented).            % Delays are documented
assumption(quality_defects).             % Work quality issues documented
assumption(weather_delays).              % Severe weather caused delays
assumption(material_shortage).           % Materials unavailable in market
assumption(client_change_orders).        % Client requested scope changes
assumption(contractor_notified_client).  % Contractor gave timely notice
assumption(force_majeure_clause).        % Contract includes force majeure

%% Legal Doctrines (Derived)
assumption(material_breach).             % Breach is material (serious)
assumption(force_majeure_applies).       % Force majeure defense valid
assumption(impossibility_defense).       % Impossibility of performance
assumption(client_contributory_breach).  % Client also breached contract

%% Legal Conclusions
assumption(breach_established).          % Breach of contract proven
assumption(damages_recoverable).         % Client entitled to damages
assumption(defendant_liable).            % Contractor is liable

%% Weights (strength of evidence/precedent: 0-100)
%% Higher weight = stronger evidence/more authoritative precedent

% Factual evidence weights
weight(contract_signed, 95).             % Strong documentary evidence
weight(work_incomplete, 85).             % Clear factual evidence
weight(payment_withheld, 80).            % Documented financial records
weight(delay_documented, 75).            % Written delay reports
weight(quality_defects, 70).             % Inspection reports
weight(weather_delays, 65).              % Weather service records
weight(material_shortage, 60).           % Market reports
weight(client_change_orders, 80).        % Written change requests
weight(contractor_notified_client, 70).  % Correspondence records
weight(force_majeure_clause, 90).        % Contract language

% Legal doctrine weights (based on precedent strength)
weight(material_breach, 85).             % Well-established doctrine
weight(force_majeure_applies, 75).       % Jurisdiction-dependent
weight(impossibility_defense, 70).       % High bar to prove
weight(client_contributory_breach, 65).  % Comparative fault doctrine

% Conclusion weights
weight(breach_established, 90).
weight(damages_recoverable, 85).
weight(defendant_liable, 95).

%% Contrary weights (strength of counter-arguments)
weight(c_contract_signed, 50).           % Contract validity challenges
weight(c_work_incomplete, 60).           % Substantial completion argument
weight(c_payment_withheld, 45).          % Payment timing disputes
weight(c_delay_documented, 40).          % Documentation disputes
weight(c_quality_defects, 55).           % Quality standard disputes
weight(c_weather_delays, 35).            % Weather severity disputes
weight(c_material_shortage, 40).         % Foreseeability arguments
weight(c_client_change_orders, 30).      % Scope interpretation
weight(c_contractor_notified_client, 50). % Notice adequacy
weight(c_force_majeure_clause, 25).      % Clause interpretation

weight(c_material_breach, 70).           % Minor breach argument
weight(c_force_majeure_applies, 65).     % Clause applicability limits
weight(c_impossibility_defense, 75).     % Foreseeability objection
weight(c_client_contributory_breach, 60). % No client fault argument

weight(c_breach_established, 80).        % No breach argument
weight(c_damages_recoverable, 70).       % No damages argument
weight(c_defendant_liable, 85).          % No liability argument

%% Derivation Rules

% r1: material_breach <- work_incomplete, quality_defects.
head(r1, material_breach; r1, work_incomplete; r1, quality_defects).

% r2: material_breach <- work_incomplete, delay_documented.
head(r2, material_breach; r2, work_incomplete; r2, delay_documented).

% r3: force_majeure_applies <- force_majeure_clause, weather_delays, contractor_notified_client.
head(r3, force_majeure_applies; r3, force_majeure_clause; r3, weather_delays; r3, contractor_notified_client).

% r4: impossibility_defense <- material_shortage, contractor_notified_client.
head(r4, impossibility_defense; r4, material_shortage; r4, contractor_notified_client).

% r5: impossibility_defense <- force_majeure_applies. [INDIRECT: derived from derived]
head(r5, impossibility_defense; r5, force_majeure_applies).

% r6: client_contributory_breach <- client_change_orders, payment_withheld.
head(r6, client_contributory_breach; r6, client_change_orders; r6, payment_withheld).

% r7: breach_established <- contract_signed, material_breach. [HYBRID: assumption + derived]
head(r7, breach_established; r7, contract_signed; r7, material_breach).

% r8: breach_established <- contract_signed, work_incomplete, delay_documented. [HYBRID: assumptions]
head(r8, breach_established; r8, contract_signed; r8, work_incomplete; r8, delay_documented).

% r9: damages_recoverable <- breach_established. [INDIRECT: derived from derived]
head(r9, damages_recoverable; r9, breach_established).

% r10: defendant_liable <- breach_established, damages_recoverable. [HYBRID: derived + derived]
head(r10, defendant_liable; r10, breach_established; r10, damages_recoverable).

%% Attacks via contraries (total function)
contrary(contract_signed, c_contract_signed).
contrary(work_incomplete, c_work_incomplete).
contrary(payment_withheld, c_payment_withheld).
contrary(delay_documented, c_delay_documented).
contrary(quality_defects, c_quality_defects).
contrary(weather_delays, c_weather_delays).
contrary(material_shortage, c_material_shortage).
contrary(client_change_orders, c_client_change_orders).
contrary(contractor_notified_client, c_contractor_notified_client).
contrary(force_majeure_clause, c_force_majeure_clause).

contrary(material_breach, c_material_breach).
contrary(force_majeure_applies, c_force_majeure_applies).
contrary(impossibility_defense, c_impossibility_defense).
contrary(client_contributory_breach, c_client_contributory_breach).

contrary(breach_established, c_breach_established).
contrary(damages_recoverable, c_damages_recoverable).
contrary(defendant_liable, c_defendant_liable).

%% Budget: Burden of proof threshold
%% In civil cases, typically "preponderance of evidence" (>50% certainty)
%% Budget=150: Can overcome reasonable counter-arguments
%% Higher budget = lower burden of proof (easier to establish claim)
%% Lower budget = higher burden of proof (harder to establish claim)
budget(150).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Expected behavior with Gödel + Max semantics:
%%
%% Plaintiff's Strong Case:
%% - All factual evidence present: contract_signed, work_incomplete,
%%   quality_defects, delay_documented
%% - Derives: material_breach (via r1), breach_established (via r7),
%%   damages_recoverable (via r9), defendant_liable (via r10)
%% - Must overcome: c_defendant_liable (85), c_damages_recoverable (70),
%%   c_breach_established (80)
%% - Max cost: 85 (within budget=150)
%%
%% Defendant's Force Majeure Defense:
%% - Include: force_majeure_clause, weather_delays, contractor_notified_client
%% - Derives: force_majeure_applies (via r3), impossibility_defense (via r5)
%% - Attacks breach_established and defendant_liable
%% - Competing extensions depend on attack weights
%%
%% Mixed Evidence:
%% - Both sides have evidence: work_incomplete vs. weather_delays
%% - client_change_orders + payment_withheld -> client_contributory_breach
%% - May result in comparative fault or split liability
%% - Budget determines which arguments can be accepted
%%
%% This demonstrates WABA's ability to model legal argumentation where
%% evidence has varying strengths, legal doctrines interact, and the
%% burden of proof (budget) determines which arguments prevail.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
