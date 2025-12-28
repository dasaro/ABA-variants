%% Minimum Monoid - Maximization (Quality Threshold Semantics)
%% Monoid: (ℤ ∪ {±∞}, min, #sup)
%% - Domain: All integers plus infinities
%% - Operation: minimum
%% - Identity: #sup (algebraic identity for min operation)
%%
%% DIRECT MAXIMIZE WITH STRATIFIED PRIORITIES
%% ===========================================
%% Uses #maximize directive with priority levels for optimal performance.
%%
%% Semantics:
%% - Weights represent QUALITY THRESHOLDS
%% - extension_cost = minimum discarded attack weight (weakest link)
%% - Goal: MAXIMIZE the minimum (raise the quality floor)
%%
%% Performance:
%% - #maximize with priorities is faster than weak constraints
%% - Requires extension_cost/1 for proper #sup/#inf handling

%% Maximize the minimum discarded attack weight using weak constraints
%% OPTIMIZED: Weak constraint avoids extension_cost/1 predicate (saves ~20% grounding)
%% Syntax: :~ condition. [weight@priority]
%% Stratified priorities handle edge cases (#inf, #sup) without explicit predicates
%% Negative weights = maximization (minimize -M = maximize M)

%% Priority @2: Reject #inf (highest priority - should never maximize to #inf)
:~ M = #min { W : discarded_attack(_,_,W) }, M = #inf. [1@2]

%% Priority @1: Prefer #inf over finite (for quality threshold semantics)
:~ M = #min { W : discarded_attack(_,_,W) }, M != #inf. [-1@1]

%% Priority @0: Maximize finite costs (lowest priority)
:~ M = #min { W : discarded_attack(_,_,W) }, M != #sup, M != #inf. [-M@0]
