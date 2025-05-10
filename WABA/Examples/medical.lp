assumption(respect_autonomy;act_beneficently;act_nonmaleficently;act_justly).

% ----------------------------
% CONTEXTUAL FACTS
% ----------------------------
head(
	pos(c1),pos(refuses_meds);
	pos(c2),pos(severe_condition);
	pos(c3),pos(side_effects);
	pos(c4),pos(resource_scarcity);
	pos(c5),pos(mental_risk)).

weight(
	pos(refuses_meds),97;
	pos(severe_condition),73;
	pos(side_effects),29;
	pos(resource_scarcity),11;
	pos(mental_risk),91).

head(neg(R),neg(X)) :- head(pos(R),pos(X)).
weight(neg(X),100-W) :- weight(pos(X), W).

% ----------------------------
% DECISION RULES
% ----------------------------
head(r1, action(give_meds)). body(r1, act_beneficently; r1, pos(severe_condition); r1, pos(mental_risk)).
head(r6, action(give_meds)). body(r6, act_nonmaleficently; r6, pos(severe_condition); r6, neg(side_effects)).
head(r7, action(give_meds)). body(r7, act_justly; r7, pos(severe_condition); r7, pos(resource_scarcity)).
head(r13, action(give_meds)). body(r13, respect_autonomy; r13, pos(side_effects); r13, neg(refuses_meds)).
head(r3, action(dont_give_meds)). body(r3, respect_autonomy; r3, pos(refuses_meds); r3, neg(mental_risk)).
head(r4, action(dont_give_meds)). body(r4,act_nonmaleficently;r4,pos(side_effects);r4,neg(severe_condition)).
head(r5, action(dont_give_meds)). body(r5,act_justly; r5,pos(resource_scarcity); r5,neg(severe_condition)).
head(r8, action(dont_give_meds)). body(r8, respect_autonomy; r8, pos(side_effects); r8, neg(mental_risk)).

% ----------------------------
% CONTRARY‐DERIVATION RULES
% ----------------------------
head(r9, ca). body(r9, action(give_meds); r9, pos(refuses_meds)).
head(r14, ca). body(r14, action(dont_give_meds); r9, neg(refuses_meds)).
head(r10, cb). body(r10, action(dont_give_meds); r10, pos(severe_condition)).
head(r11, cn). body(r11, action(give_meds); r11, pos(side_effects)).
head(r12, cj). body(r12, action(dont_give_meds); r12, neg(resource_scarcity)).

% ----------------------------
% CONTRARY MAPPING
% ----------------------------
contrary(respect_autonomy, ca).
contrary(act_beneficently, cb).
contrary(act_nonmaleficently, cn).
contrary(act_justly, cj).
