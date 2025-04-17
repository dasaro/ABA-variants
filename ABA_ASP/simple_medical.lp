% ----------------------------
% ASSUMPTIONS (ethical principles)
% ----------------------------

assumption(respect_autonomy).
assumption(act_beneficently).

% ----------------------------
% CHOICE RULES FOR CONTEXTUAL FACTORS
% ----------------------------

%head(ctx1, opinion(refuses_meds)). % X = wants_meds; refuses_meds; is_neutral
head(ctx2, risk(high)). % X = bad; mid; good

% ----------------------------
% RULES - FLAT ABA HAS ASSUMPTIONS IN THE BODY
% ----------------------------

% action(give_meds) :- act_beneficently, severity(bad)
head(r1, action(give_meds)).
body(r1, risk(high)).
body(r1, act_beneficently).

% dont_give_meds :- respect_autonomy, opinion(refuses_meds)
head(r2, action(dont_give_meds)).
body(r2, respect_autonomy).
body(r2, opinion(refuses_meds)).

% action(give_meds_against_will) :- action(give_meds), opinion(refuses_meds)
head(r3, ca).
body(r3, action(give_meds)).
body(r3, opinion(refuses_meds)).

head(r4, cb).
body(r4, action(dont_give_meds)).
body(r4, risk(high)).

% ----------------------------
% CONTRARIES: ethical tensions
% ----------------------------

contrary(respect_autonomy, ca).
contrary(act_beneficently, cb).