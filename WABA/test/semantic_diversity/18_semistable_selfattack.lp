%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Semi-stable ⊂ Preferred using Self-Attack
%%
%% KEY INSIGHT: Use self-attacking assumptions to create "unreachable" arguments
%%              that can be in one extension's range but not another's
%%
%% STRUCTURE:
%%
%%   Core: a ↔ b (must choose one)
%%
%%   Peripheral groups:
%%     - {c, d}: attacked only by 'a'
%%     - {e}: self-attacking (can never be in), attacked only by 'c'
%%
%%   Attacks:
%%     - a → b, b → a (mutual)
%%     - a → c (a attacks c)
%%     - a → d (a attacks d)
%%     - c → e (c attacks e)
%%     - e → e (e self-attacks, so e can NEVER be in any extension)
%%
%%   Extensions:
%%
%%     E1 = {a}:
%%       - a in → b out (attacked)
%%       - a in → c out (attacked)
%%       - a in → d out (attacked)
%%       - c out → e unattacked by c
%%       - e cannot be in (self-attack)
%%       - e unattacked → e defended → completeness says e must be in
%%       - BUT e cannot be in (self-attack) → CONTRADICTION?
%%
%% Wait, this creates UNSATISFIABILITY issues again!
%%
%% Let me reconsider: if e has ONLY self-attack:
%%   - e cannot be in (self-attack creates conflict)
%%   - e being out → e→e doesn't fire (e not supported)
%%   - If no other attacks on e → e is defended
%%   - Completeness requires e in → but e cannot be in → UNSAT
%%
%% So e needs EXTERNAL attacks to be validly out.
%%
%% REVISED STRUCTURE:
%%
%%   Core: a ↔ b
%%   - a → {c, d, e}
%%   - b → {f}
%%   - c → e (so e has external attack from c)
%%   - e → e (self-attack)
%%
%%   E1 = {a}:
%%     - a attacks b, c, d, e (all out)
%%     - No assumptions unattacked
%%     - Extension: {a}
%%     - Range: {a, b(att), c(att), d(att), e(att), f?}
%%     - What about f? b is out, so b→f doesn't fire
%%     - f is unattacked → f defended → f MUST be in
%%     - Extension: {a, f}
%%     - Range: {a, b, c, d, e, f} = 6
%%
%%   E2 = {b, c, d}:
%%     - b attacks a → a out
%%     - a out → a's attacks don't fire
%%     - c unattacked → c in
%%     - d unattacked → d in
%%     - e: c→e fires → e attacked → e out
%%     - b in → b→f fires → f attacked → f out
%%     - Extension: {b, c, d}
%%     - Range: {a(att), b, c, d, e(att), f(att)} = 6
%%
%% STILL SAME RANGE!
%%
%% The problem is fundamental: in small connected frameworks, all assumptions
%% end up in the range one way or another.
%%
%% Let me try the USER'S suggestion: find an existing classical ABA example
%% and add weights to it!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Placeholder for now - will use classical ABA test with weights added
budget(0).
assumption(dummy).
weight(dummy, 10).
contrary(dummy, dummy).
