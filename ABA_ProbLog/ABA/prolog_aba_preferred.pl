:- use_module(library(lists), [member/2]).

%%%%%%%%%%%%%%%
% ABA Framework
%%%%%%%%%%%%%%%

% contrary(Assumption, Contrary).
% head(Rule, Head).
% body(Rule, [BodyLiterals]).

% Example

% Crisp assumptions
assumption(respect_autonomy).
assumption(act_beneficently).
assumption(act_nonmaleficently).
assumption(act_justly).

% Collection of assumptions as list
all_assumptions([respect_autonomy,act_beneficently,act_nonmaleficently,act_justly]).

% Contextual factors
head(ctx1, opinion(wants_meds)). % X = wants_meds; refuses_meds; is_neutral
body(ctx1, []).

head(ctx2, severity(bad)). % X = bad; mid; good
body(ctx2, []).

0.9::head(ctx3, side_effects(strong)); 0.09::head(ctx3, side_effects(mid)); 0.01::head(ctx3, side_effects(mild)). % X = strong, mid, mild
body(ctx3, []).

head(ctx4, mental(good)). % X = bad; mid; good
body(ctx4, []).

head(ctx5, resources(scarce)). % X = scarce, sufficient, abundant
body(ctx5, []).

% r1: give_meds :- act_beneficently, severity(bad)
head(r1, action(give_meds)).
body(r1, [act_beneficently, severity(bad)]).

% r2: give_meds :- act_beneficently, severity(mid)
head(r2, action(give_meds)).
body(r2, [act_beneficently, severity(mid)]).

% r3: dont_give_meds :- respect_autonomy, opinion(refuses_meds)
head(r3, action(dont_give_meds)).
body(r3, [respect_autonomy, opinion(refuses_meds)]).

% r4: give_meds_against_will :- action(give_meds), opinion(refuses_meds)
head(r4, action(give_meds_against_will)).
body(r4, [action(give_meds), opinion(refuses_meds)]).

% r5: dont_give_meds_when_needed :- action(dont_give_meds), severity(bad)
head(r5, action(dont_give_meds_when_needed)).
body(r5, [action(dont_give_meds), severity(bad)]).

% r6: give_meds_when_unnecessary :- action(give_meds), opinion(wants_meds), resources(scarce), severity(good)
head(r6, action(give_meds_when_unnecessary)).
body(r6, [action(give_meds), opinion(wants_meds), resources(scarce), severity(good)]).

% r7: give_meds :- respect_autonomy, opinion(wants_meds)
head(r7, action(give_meds)).
body(r7, [respect_autonomy, opinion(wants_meds)]).

% r8: dont_give_meds :- act_justly, resources(scarce), severity(good)
head(r8, action(dont_give_meds)).
body(r8, [act_justly, resources(scarce), severity(good)]).

% r9: give_meds :- act_beneficently, severity(bad), opinion(refuses_meds), mental(bad)
head(r9, action(give_meds)).
body(r9, [act_beneficently, severity(bad), opinion(refuses_meds), mental(bad)]).

% r10: dont_give_meds :- respect_autonomy, opinion(refuses_meds), mental(good)
head(r10, action(dont_give_meds)).
body(r10, [respect_autonomy, opinion(refuses_meds), mental(good)]).

% r11: dont_give_meds :- act_nonmaleficently, opinion(wants_meds), mental(bad), side_effects(strong)
head(r11, action(dont_give_meds)).
body(r11, [act_nonmaleficently, opinion(wants_meds), mental(bad), side_effects(strong)]).

% r12: dont_give_meds :- act_nonmaleficently, side_effects(strong), severity(good)
head(r12, action(dont_give_meds)).
body(r12, [act_nonmaleficently, side_effects(strong), severity(good)]).

% r13: give_meds :- side_effects(strong), severity(bad)
head(r13, action(give_meds)).
body(r13, [side_effects(strong), severity(bad)]).

% r14: dont_give_meds :- act_justly, side_effects(strong), resources(scarce)
head(r14, action(dont_give_meds)).
body(r14, [act_justly, side_effects(strong), resources(scarce)]).

% ----------------------------
% CONTRARIES: ethical tensions
% ----------------------------

contrary(respect_autonomy, action(give_meds_against_will)).
contrary(act_beneficently, action(dont_give_meds_when_needed)).
contrary(act_justly, action(give_meds_when_unnecessary)).
contrary(act_nonmaleficently, action(give_meds_with_strong_side_effects)).