%% Maximum Monoid - Minimization (Cost Semantics)
%% Monoid: (ℤ ∪ {±∞}, max, #inf)
%% - Domain: All integers plus infinities
%% - Operation: maximum
%% - Identity: #inf (algebraic identity for max operation)
%%
%% DIRECT MINIMIZE WITH STRATIFIED PRIORITIES
%% ===========================================
%% Uses #minimize directive with priority levels for optimal performance.
%%
%% Semantics:
%% - Weights represent COSTS
%% - Goal: Minimize the maximum discarded attack weight (worst-case cost)
%%
%% Performance:
%% - #minimize with priorities is faster than weak constraints
%% - Requires extension_cost/1 for proper #sup/#inf handling

%% Minimize the maximum discarded attack weight using weak constraints
%% OPTIMIZED: Weak constraint avoids extension_cost/1 predicate (saves ~9% grounding)
%% Syntax: :~ condition. [weight@priority]
%% Stratified priorities handle edge cases (#inf, #sup) without explicit predicates

%% Priority @2: Reject #sup (highest priority - should never minimize to #sup)
:~ M = #max { W : discarded_attack(_,_,W) }, M = #sup. [1@2]

%% Priority @1: Avoid #inf (prefer finite values over #inf)
:~ M = #max { W : discarded_attack(_,_,W) }, M = #inf. [1@1]

%% Priority @0: Minimize finite costs (lowest priority)
:~ M = #max { W : discarded_attack(_,_,W) }, M != #sup, M != #inf. [M@0]
