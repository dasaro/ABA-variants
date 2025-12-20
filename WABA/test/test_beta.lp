%% Test case to verify beta behavior
%% Tests whether NOT setting beta is equivalent to beta=#sup

% Simple framework with attacks
assumption(a1).
assumption(a2).
assumption(a3).

weight(a1, 50).
weight(a2, 30).
weight(a3, 20).

% a1 attacks a2 (weight 50)
contrary(a2, a1).

% a3 attacks a1 (weight 20)
contrary(a1, a3).

% NOTE: NO budget() defined in this file
% We'll test with:
% 1. No beta parameter (ungrounded)
% 2. beta=#sup
% 3. beta=100 (high enough to allow all discards)
