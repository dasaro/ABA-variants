%% Sum Monoid - Maximization (Reward Semantics)
%% Monoid: (ℤ ∪ {±∞}, +, 0)
%% - Domain: All integers plus infinities
%% - Operation: sum (addition)
%% - Identity: 0 (algebraic identity for addition)
%%
%% DIRECT MAXIMIZE APPROACH (PERFORMANCE OPTIMIZED)
%% =================================================
%% Uses direct #maximize aggregate for optimal performance.
%%
%% Semantics:
%% - Weights represent REWARDS/BENEFITS
%% - Goal: Maximize total benefit of discarded attacks
%%
%% Performance:
%% - Direct #maximize is faster than weak constraints
%% - No intermediate extension_cost/1 computation needed

%% Maximize total benefit of discarded attacks directly
#maximize { W,X,Y : discarded_attack(X,Y,W) }.
