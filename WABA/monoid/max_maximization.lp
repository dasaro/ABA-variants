%% Maximum Monoid - Maximization (Reward Semantics)
%% Monoid: (ℤ ∪ {±∞}, max, #inf)
%% - Domain: All integers plus infinities
%% - Operation: maximum
%% - Identity: #inf (algebraic identity for max operation)
%%
%% DIRECT MAXIMIZE WITH STRATIFIED PRIORITIES
%% ===========================================
%% Uses #maximize directive with priority levels for optimal performance.
%%
%% Semantics:
%% - Weights represent REWARDS/BENEFITS
%% - Goal: Maximize the maximum discarded attack weight (maximize best reward)
%%
%% Performance:
%% - #maximize with priorities is faster than weak constraints
%% - Requires extension_cost/1 for proper #sup/#inf handling

%% Maximize the maximum discarded attack weight using weak constraints
%% OPTIMIZED: Weak constraint avoids extension_cost/1 predicate (saves ~9% grounding)
%% Syntax: :~ condition. [weight@priority]
%% Stratified priorities handle edge cases (#inf, #sup) without explicit predicates
%% Negative weights = maximization (minimize -M = maximize M)

%% Priority @2: Reject #inf (highest priority - #inf is worst for rewards)
:~ M = #max { W : discarded_attack(_,_,W) }, M = #inf. [1@2]

%% Priority @1: Prefer #sup over finite (for reward semantics, highest is best)
:~ M = #max { W : discarded_attack(_,_,W) }, M != #sup. [-1@1]

%% Priority @0: Maximize finite costs (lowest priority)
:~ M = #max { W : discarded_attack(_,_,W) }, M != #sup, M != #inf. [-M@0]
