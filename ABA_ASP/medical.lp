% 1. Aggiungere pesi -> volto all'integrazione con sistemi fuzzy
% 2. Fare degli esempi più sofisticati sulla base della letteratura
% 3. Giustificare la semantica (stable)
% 4. Vedere come problema di ottimizzazione multi-obiettivo simbolico
% 5. Aggiungere assunzioni (non necessariamente strettamente bioetiche)
% 6. Principi SLEEC (sociali, giuridici...)
% 7. Visualizzazione dell'ABA (utile per evidenzare errori, cambiare la teoria senza dover fare handcoding)
% 8. Aspetto ILP

% ----------------------------
% ASSUMPTIONS (ethical principles)
% ----------------------------

assumption(respect_autonomy).
assumption(act_beneficently).
assumption(act_nonmaleficently).
assumption(act_justly).

% ----------------------------
% CHOICE RULES FOR CONTEXTUAL FACTORS
% ----------------------------

head(ctx1, opinion(wants_meds)). % X = wants_meds; refuses_meds; is_neutral
head(ctx2, severity(bad)). % X = bad; mid; good
head(ctx3, side_effects(strong)). % X = strong, mid, mild
head(ctx4, mental(good)). % X = bad; mid; good
head(ctx5, resources(scarce)). % X = scarce, sufficient, abundant

% 1{ head(ctx1, opinion(wants_meds)); head(ctx1, opinion(refuses_meds)); head(ctx1, opinion(is_neutral)) }1.
% 1{ head(ctx2, severity(bad)); head(ctx2, severity(mid)); head(ctx2, severity(good)) }1.
% 1{ head(ctx3, side_effects(strong)); head(ctx3, side_effects(mid)); head(ctx3, side_effects(mild)) }1.
% 1{ head(ctx4, mental(bad)); head(ctx4, mental(mid)); head(ctx4, mental(good)) }1.
% 1{ head(ctx5, resources(scarce)); head(ctx5, resources(sufficient)); head(ctx5, resources(abundant)) }1.

% ----------------------------
% RULES - FLAT ABA HAS ASSUMPTIONS IN THE BODY
% ----------------------------

% action(give_meds) :- act_beneficently, severity(bad)
head(r1, action(give_meds)).
body(r1, act_beneficently).
body(r1, severity(bad)).

% action(give_meds) :- act_beneficently, severity(mid)
head(r2, action(give_meds)).
body(r2, act_beneficently).
body(r2, severity(mid)).

% dont_give_meds :- respect_autonomy, opinion(refuses_meds)
head(r3, action(dont_give_meds)).
body(r3, respect_autonomy).
body(r3, opinion(refuses_meds)).

% action(give_meds_against_will) :- action(give_meds), opinion(refuses_meds)
head(r4, action(give_meds_against_will)).
body(r4, action(give_meds)).
body(r4, opinion(refuses_meds)).

% action(dont_give_meds_when_needed) :- action(dont_give_meds), severity(bad)
head(r5, action(dont_give_meds_when_needed)).
body(r5, action(dont_give_meds)).
body(r5, severity(bad)).

% action(give_meds_when_unnecessary) :- action(give_meds), opinion(wants_meds), resources(scarse), severity(good).
head(r6, action(give_meds_when_unnecessary)).
body(r6, action(give_meds)).
body(r6, opinion(wants_meds)).
body(r6, resources(scarce)).
body(r6, severity(good)).

% action(give_meds) :- respect_autonomy, opinion(wants_meds)
head(r7, action(give_meds)).
body(r7, respect_autonomy).
body(r7, opinion(wants_meds)).

% action(dont_give_meds) :- act_justly, resources(scarce), severity(good)
head(r8, action(dont_give_meds)).
body(r8, act_justly).
body(r8, resources(scarce)).
body(r8, severity(good)).

% action(give_meds) :- act_beneficently, severity(bad), opinion(refuses_meds), mental(bad)
head(r9, action(give_meds)).
body(r9, act_beneficently).
body(r9, severity(bad)).
body(r9, opinion(refuses_meds)).
body(r9, mental(bad)).

% action(dont_give_meds) :- respect_autonomy, opinion(refuses_meds), mental(good)
head(r10, action(dont_give_meds)).
body(r10, respect_autonomy).
body(r10, opinion(refuses_meds)).
body(r10, mental(good)).

% action(dont_give_meds) :- act_nonmaleficently, opinion(wants_meds), mental(bad), side_effects(strong)
head(r11, action(dont_give_meds)).
body(r11, act_nonmaleficently).
body(r11, opinion(wants_meds)).
body(r11, mental(bad)).
body(r11, side_effects(strong)).

% action(dont_give_meds) :- act_nonmaleficently, side_effects(strong), severity(good)
head(r12, action(dont_give_meds)).
body(r12, act_nonmaleficently).
body(r12, side_effects(strong)).
body(r12, severity(good)).

% action(give_meds) :- side_effects(strong), severity(bad)
head(r13, action(give_meds)).
body(r13, side_effects(strong)).
body(r13, severity(bad)).

% action(dont_give_meds) :- act_justly, side_effects(strong), resources(scarce)
head(r14, action(dont_give_meds)).
body(r14, act_justly).
body(r14, side_effects(strong)).
body(r14, resources(scarce)).

% ----------------------------
% CONTRARIES: ethical tensions
% ----------------------------

contrary(respect_autonomy, action(give_meds_against_will)).
contrary(act_beneficently, action(dont_give_meds_when_needed)).
contrary(act_justly, action(give_meds_when_unnecessary)).
contrary(act_nonmaleficently, action(give_meds_with_strong_side_effects)).