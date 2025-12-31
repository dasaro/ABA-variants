%% Minimum Monoid - Minimization (Quality Threshold Semantics)
%% Monoid: (ℤ ∪ {±∞}, min, #sup)
%% - Domain: All integers plus infinities
%% - Operation: minimum
%% - Identity: #sup (algebraic identity for min operation)
%%
%% DIRECT MINIMIZE WITH STRATIFIED PRIORITIES
%% ===========================================
%% Uses #minimize directive with priority levels for optimal performance.
%%
%% Semantics:
%% - Weights represent QUALITY THRESHOLDS
%% - extension_cost = minimum discarded attack weight (weakest link)
%% - Goal: MINIMIZE the minimum (lower quality threshold = more permissive)
%%
%% Performance:
%% - #minimize with priorities is faster than weak constraints
%% - Requires extension_cost/1 for proper #sup/#inf handling

%% Minimize the minimum discarded attack weight using weak constraints
%% OPTIMIZED: Weak constraint avoids extension_cost/1 predicate (saves ~20% grounding)
%% Syntax: :~ condition. [weight@priority]
%% Stratified priorities handle edge cases (#inf, #sup) without explicit predicates

%% Priority @2: Reject #inf (highest priority - should never minimize to #inf)
:~ M = #min { W : discarded_attack(_,_,W) }, M = #inf. [1@2]

%% Priority @1: Cost=0 (no discarded attacks) gets 0 penalty
:~ M = #min { W : discarded_attack(_,_,W) }, M = #sup. [0@1]

%% Priority @0: Minimize finite costs (lowest priority)
:~ M = #min { W : discarded_attack(_,_,W) }, M != #sup, M != #inf. [M@0]
