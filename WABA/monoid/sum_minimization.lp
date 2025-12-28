%% Sum Monoid - Minimization (Cost Semantics)
%% Monoid: (ℤ ∪ {±∞}, +, 0)
%% - Domain: All integers plus infinities
%% - Operation: sum (addition)
%% - Identity: 0 (algebraic identity for addition)
%%
%% DIRECT MINIMIZE APPROACH (PERFORMANCE OPTIMIZED)
%% =================================================
%% Uses direct #minimize aggregate for optimal performance.
%%
%% Semantics:
%% - Weights represent COSTS
%% - Goal: Minimize total cost of discarded attacks
%%
%% Performance:
%% - Direct #minimize is faster than weak constraints
%% - No intermediate extension_cost/1 computation needed

%% Minimize total cost of discarded attacks directly
#minimize { W,X,Y : discarded_attack(X,Y,W) }.
