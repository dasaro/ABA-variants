%% Test case for MIN monoid beta behavior
%% Tests whether ungrounded beta is equivalent to #inf for MIN monoid

% Simple framework with attacks
assumption(a1).
assumption(a2).
assumption(a3).

weight(a1, 50).
weight(a2, 30).
weight(a3, 20).

% a1 attacks a2 (weight 50 in tropical: 50+0=50)
contrary(a2, a1).

% a3 attacks a1 (weight 20 in tropical: 20+0=20)
contrary(a1, a3).

% NOTE: NO budget() defined
% Compatible with: tropical + min (only legal tropical+min combo)
