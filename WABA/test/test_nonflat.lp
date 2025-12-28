%% Test Case: Non-Flat WABA
%% =========================
%%
%% This example demonstrates non-flat WABA where assumptions can appear as rule heads.
%%
%% SCENARIO: Medical diagnosis with hierarchical evidence
%% -------------------------------------------------------
%% - Direct observations (symptoms) are base assumptions
%% - Inferred conditions (e.g., "has_infection") are also assumptions
%%   but can be DERIVED from symptoms
%% - This creates an assumption hierarchy

%% ================
%% BASE ASSUMPTIONS
%% ================

assumption(fever).         % Direct observation
assumption(inflammation).  % Direct observation
assumption(has_infection). % Can be observed OR inferred

%% ============
%% WEIGHTS
%% ============

weight(fever, 10).
weight(inflammation, 15).
% has_infection has no explicit weight - will use default or derived

%% ====================
%% RULES (HIERARCHICAL)
%% ====================

%% has_infection can be DERIVED from fever + inflammation
%% This makes it NON-FLAT: an assumption appears as a rule head!
head(r_infer_infection, has_infection).
body(r_infer_infection, fever).
body(r_infer_infection, inflammation).

%% Diagnosis is derived from has_infection
head(r_diagnosis, bacterial_infection).
body(r_diagnosis, has_infection).

%% ============
%% CONTRARIES
%% ============

contrary(fever, healthy).
contrary(inflammation, healthy).
contrary(has_infection, no_infection).

%% ==================
%% BUDGET
%% ==================

budget(100).

%% ==================
%% EXPECTED RESULTS
%% ==================
%%
%% In FLAT-WABA (with constraint/flat.lp):
%% - This framework is REJECTED because has_infection appears as rule head
%% - Error: constraint violated
%%
%% In NON-FLAT-WABA (without constraint/flat.lp):
%% - fever and inflammation can be IN
%% - has_infection can be:
%%   a) Directly selected (in), OR
%%   b) Derived from fever + inflammation, OR
%%   c) Both (in AND derived)
%% - If derived, weight = fever_weight + inflammation_weight = 10 + 15 = 25
%% - If just IN with no explicit weight, weight = #sup
%% - If both, weight = min(#sup, 25) = 25
%%
%% TEST COMMANDS:
%%
%% 1. Test FLAT-WABA (should FAIL):
%% clingo core/base.lp semiring/tropical.lp monoid/baseline/max.lp \
%%        constraint/flat.lp filter/standard.lp semantics/stable.lp \
%%        test/test_nonflat.lp
%% Expected: UNSATISFIABLE (constraint violated)
%%
%% 2. Test NON-FLAT-WABA (should SUCCEED):
%% clingo -n 0 core/base.lp semiring/tropical.lp monoid/baseline/max.lp \
%%        filter/standard.lp semantics/stable.lp test/test_nonflat.lp
%% Expected: Extensions with has_infection supported with weight 25
