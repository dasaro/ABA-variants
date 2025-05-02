assumption(respect_autonomy).
assumption(act_beneficently).

head(ctx1, refuses_meds).
head(ctx2, physical_risk).

head(r1, action(give_meds)).
body(r1, act_beneficently).
body(r1, physical_risk).

head(r2, action(dont_give_meds)).
body(r2, respect_autonomy).
body(r2, refuses_meds).

head(r3, ca).
body(r3, action(give_meds)).
body(r3, refuses_meds).

head(r4, cb).
body(r4, action(dont_give_meds)).
body(r4, physical_risk).

contrary(respect_autonomy, ca).
contrary(act_beneficently, cb).