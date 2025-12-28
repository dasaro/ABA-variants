%% Flat-WABA Constraint
%% =====================
%%
%% Enforces the flat-WABA restriction: assumptions can ONLY appear in rule bodies,
%% never as rule heads. This ensures assumptions are "atomic" - they are not derivable
%% from other assumptions or rules.
%%
%% FLAT-WABA:
%% - Assumptions are the base level of argumentation
%% - Only non-assumption atoms can be derived via rules
%% - Simpler semantics: no circularity, no assumption hierarchies
%% - Every assumption is either chosen (in) or rejected (out) independently
%%
%% NON-FLAT-WABA (without this constraint):
%% - Assumptions can appear as rule heads
%% - Assumptions can be derived from other assumptions
%% - More expressive: allows assumption hierarchies
%% - More complex semantics: derived assumptions have combined weights
%%
%% USAGE:
%% Load this file to enforce flat-WABA:
%%   clingo ... constraint/flat.lp ...
%%
%% Omit this file to allow non-flat-WABA (default).

%% CONSTRAINT: Reject if any assumption appears as a rule head
:- assumption(X), head(_,X).

%% This ensures that in flat-WABA:
%% 1. Assumptions are only selected via in/out choice
%% 2. Assumptions have no derivation path from rules
%% 3. Weight propagation only flows TO assumptions (via attacks), never FROM them via rules
%% 4. No circularity: assumption hierarchies are impossible
