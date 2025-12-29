%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% WABA Example: Scientific Hypothesis Evaluation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Domain: Scientific discovery - evaluating competing hypotheses
%% about an anomalous astronomical observation.
%%
%% Scenario:
%% Astronomers observe unusual light curve patterns from a distant star.
%% Multiple hypotheses compete to explain the observations: exoplanet transit,
%% stellar variability, instrumental artifact, or interstellar dust.
%% Each hypothesis is supported by different observations and theoretical models.
%%
%% Features demonstrated:
%% - Indirect derivations: observations -> predictions -> hypothesis support
%% - Hybrid derivations: combining observations with theoretical models
%% - Weighted arguments: measurement confidence and model reliability
%% - Budget constraint: statistical significance threshold for accepting hypothesis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Observational Data (Assumptions)
assumption(periodic_dimming).            % Regular brightness decrease pattern
assumption(asymmetric_profile).          % Light curve shape is asymmetric
assumption(infrared_excess).             % Extra infrared radiation detected
assumption(spectral_shift).              % Wavelength shifts observed
assumption(consistent_period).           % Period stable over observations
assumption(multiple_wavelengths).        % Pattern seen across wavelengths
assumption(no_parallax_change).          % No positional shift detected
assumption(deep_transit_depth).          % Large brightness decrease (>1%)

%% Instrumental/Calibration Data
assumption(telescope_stable).            % Instrument performing normally
assumption(calibration_verified).        % Calibration checked recently
assumption(other_stars_normal).          % Nearby stars show no anomalies

%% Theoretical Predictions (Derived)
assumption(planet_transit_predicted).    % Exoplanet model predicts observations
assumption(stellar_pulsation_predicted). % Variable star model predicts observations
assumption(dust_cloud_predicted).        % Dust obscuration model fits
assumption(instrumental_artifact).       % Artifact hypothesis explains data

%% Hypothesis Support (Derived)
assumption(exoplanet_hypothesis).        % Best explanation: exoplanet
assumption(variable_star_hypothesis).    % Best explanation: intrinsic variability
assumption(artifact_hypothesis).         % Best explanation: instrument error

%% Final Conclusion
assumption(discovery_confirmed).         % Novel astronomical discovery confirmed

%% Weights (observational confidence: 0-100)
%% Based on measurement precision, signal-to-noise ratio, and reproducibility

% High-confidence observations (multiple independent confirmations)
weight(periodic_dimming, 90).            % Very robust detection
weight(consistent_period, 85).           % Precise period measurement
weight(multiple_wavelengths, 80).        % Chromatic analysis
weight(deep_transit_depth, 85).          % High signal-to-noise

% Moderate-confidence observations (single instrument/method)
weight(asymmetric_profile, 70).          % Shape analysis uncertainty
weight(infrared_excess, 65).             % IR measurement challenges
weight(spectral_shift, 60).              % Spectroscopic noise
weight(no_parallax_change, 75).          % Astrometric precision

% Calibration confidence
weight(telescope_stable, 85).
weight(calibration_verified, 80).
weight(other_stars_normal, 90).          % Strong control check

% Theoretical model weights (predictive power/simplicity)
weight(planet_transit_predicted, 85).    % Well-established physics
weight(stellar_pulsation_predicted, 75). % More free parameters
weight(dust_cloud_predicted, 65).        % Complex dynamics
weight(instrumental_artifact, 55).       % Ad-hoc explanation

% Hypothesis support weights
weight(exoplanet_hypothesis, 90).
weight(variable_star_hypothesis, 75).
weight(artifact_hypothesis, 50).
weight(discovery_confirmed, 95).

%% Contrary weights (alternative explanations/uncertainties)
weight(c_periodic_dimming, 30).          % Could be aliasing
weight(c_asymmetric_profile, 45).        % Measurement uncertainty
weight(c_infrared_excess, 50).           % Background contamination
weight(c_spectral_shift, 55).            % Telluric lines confusion
weight(c_consistent_period, 35).         % Limited baseline
weight(c_multiple_wavelengths, 40).      % Wavelength-dependent systematics
weight(c_no_parallax_change, 30).        % Insufficient precision
weight(c_deep_transit_depth, 25).        % Unlikely false positive

weight(c_telescope_stable, 40).          % Intermittent issues possible
weight(c_calibration_verified, 35).      % Calibration drift
weight(c_other_stars_normal, 20).        % Target-specific issue

weight(c_planet_transit_predicted, 60).  % Alternative models exist
weight(c_stellar_pulsation_predicted, 70). % Doesn't explain all features
weight(c_dust_cloud_predicted, 75).      % Implausible dust geometry
weight(c_instrumental_artifact, 80).     % Control checks passed

weight(c_exoplanet_hypothesis, 65).
weight(c_variable_star_hypothesis, 70).
weight(c_artifact_hypothesis, 85).       % Strong evidence against
weight(c_discovery_confirmed, 70).       % Requires independent confirmation

%% Derivation Rules

% r1: planet_transit_predicted <- periodic_dimming, consistent_period, deep_transit_depth.
head(r1, planet_transit_predicted; r1, periodic_dimming; r1, consistent_period; r1, deep_transit_depth).

% r2: planet_transit_predicted <- periodic_dimming, multiple_wavelengths, asymmetric_profile.
head(r2, planet_transit_predicted; r2, periodic_dimming; r2, multiple_wavelengths; r2, asymmetric_profile).

% r3: stellar_pulsation_predicted <- periodic_dimming, spectral_shift.
head(r3, stellar_pulsation_predicted; r3, periodic_dimming; r3, spectral_shift).

% r4: stellar_pulsation_predicted <- periodic_dimming, infrared_excess.
head(r4, stellar_pulsation_predicted; r4, periodic_dimming; r4, infrared_excess).

% r5: dust_cloud_predicted <- asymmetric_profile, infrared_excess.
head(r5, dust_cloud_predicted; r5, asymmetric_profile; r5, infrared_excess).

% r6: instrumental_artifact <- periodic_dimming. (Only if calibration fails)
head(r6, instrumental_artifact; r6, periodic_dimming).

% r7: exoplanet_hypothesis <- planet_transit_predicted, telescope_stable, other_stars_normal. [HYBRID]
head(r7, exoplanet_hypothesis; r7, planet_transit_predicted; r7, telescope_stable; r7, other_stars_normal).

% r8: exoplanet_hypothesis <- planet_transit_predicted, no_parallax_change, multiple_wavelengths. [HYBRID]
head(r8, exoplanet_hypothesis; r8, planet_transit_predicted; r8, no_parallax_change; r8, multiple_wavelengths).

% r9: variable_star_hypothesis <- stellar_pulsation_predicted, spectral_shift. [HYBRID]
head(r9, variable_star_hypothesis; r9, stellar_pulsation_predicted; r9, spectral_shift).

% r10: artifact_hypothesis <- instrumental_artifact, calibration_verified. [HYBRID - paradoxical]
head(r10, artifact_hypothesis; r10, instrumental_artifact; r10, calibration_verified).

% r11: discovery_confirmed <- exoplanet_hypothesis, multiple_wavelengths, deep_transit_depth. [HYBRID]
head(r11, discovery_confirmed; r11, exoplanet_hypothesis; r11, multiple_wavelengths; r11, deep_transit_depth).

% r12: discovery_confirmed <- exoplanet_hypothesis, consistent_period, other_stars_normal. [HYBRID]
head(r12, discovery_confirmed; r12, exoplanet_hypothesis; r12, consistent_period; r12, other_stars_normal).

%% Contrary Relation (total function)
contrary(periodic_dimming, c_periodic_dimming).
contrary(asymmetric_profile, c_asymmetric_profile).
contrary(infrared_excess, c_infrared_excess).
contrary(spectral_shift, c_spectral_shift).
contrary(consistent_period, c_consistent_period).
contrary(multiple_wavelengths, c_multiple_wavelengths).
contrary(no_parallax_change, c_no_parallax_change).
contrary(deep_transit_depth, c_deep_transit_depth).

contrary(telescope_stable, c_telescope_stable).
contrary(calibration_verified, c_calibration_verified).
contrary(other_stars_normal, c_other_stars_normal).

contrary(planet_transit_predicted, c_planet_transit_predicted).
contrary(stellar_pulsation_predicted, c_stellar_pulsation_predicted).
contrary(dust_cloud_predicted, c_dust_cloud_predicted).
contrary(instrumental_artifact, c_instrumental_artifact).

contrary(exoplanet_hypothesis, c_exoplanet_hypothesis).
contrary(variable_star_hypothesis, c_variable_star_hypothesis).
contrary(artifact_hypothesis, c_artifact_hypothesis).

contrary(discovery_confirmed, c_discovery_confirmed).

%% Budget: Statistical significance threshold
%% Budget=150: Corresponds to ~3-sigma confidence level
%% Can tolerate moderate systematic uncertainties but not major anomalies
%% Higher budget = lower significance threshold (accept weaker claims)
%% Lower budget = higher significance threshold (require stronger evidence)
budget(150).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Expected behavior with Gödel + Max semantics:
%%
%% Strong Exoplanet Case:
%% - All key observations: periodic_dimming, consistent_period, deep_transit_depth,
%%   multiple_wavelengths, telescope_stable, other_stars_normal
%% - Derives: planet_transit_predicted (via r1, r2)
%%           -> exoplanet_hypothesis (via r7, r8)
%%           -> discovery_confirmed (via r11, r12)
%% - Must overcome: c_discovery_confirmed (70), c_exoplanet_hypothesis (65)
%% - Max cost: 70 (well within budget=150)
%%
%% Variable Star Alternative:
%% - Include: periodic_dimming, spectral_shift, infrared_excess
%% - Derives: stellar_pulsation_predicted (via r3, r4)
%%           -> variable_star_hypothesis (via r9)
%% - Competes with exoplanet_hypothesis
%% - Extension depends on which observations are included
%%
%% Artifact Concern:
%% - If telescope_stable or calibration_verified are challenged
%% - instrumental_artifact becomes viable (via r6)
%% - artifact_hypothesis may be derived (via r10)
%% - Attacks discovery_confirmed
%% - Cost: c_artifact_hypothesis (85) - high cost to accept artifact
%%
%% This demonstrates WABA's ability to model scientific reasoning where
%% observations have uncertainties, theories compete, and statistical
%% significance thresholds (budget) determine which hypotheses are accepted.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
