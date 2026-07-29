#show in/1.
#show out/1.
#show undec/1.
#show supported_with_weight/2.
#show attacks_successfully_with_weight/3.
#show discarded_attack/3.

% Framework structure (needed for attack derivation tracing)
#show assumption/1.
#show contrary/2.
#show head/2.
#show body/2.

% Advisory diagnostic: an explicit weight on a derived atom that did not take effect
% (usually empty — see core/base.lp and README.md "Where weights live").
#show weight_on_derived_dominated/3.

%% Advisory: a framework-declared budget/1 that the wrapper ignored.
#show framework_budget_ignored/1.
