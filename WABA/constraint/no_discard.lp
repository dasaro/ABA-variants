%% No Attack Discarding Constraint
%% =================================
%%
%% Forces plain ABA behavior by preventing any attack discarding.
%% Use this to test semantics against classical ABA/AAF behavior.
%%
%% Usage: Include this file instead of ub_*.lp or lb_*.lp constraints
%%        to enforce zero-cost extensions only (no attacks discarded).

%% Reject any extension that discards attacks
:- discarded_attack(_,_,_).
