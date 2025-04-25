% 1. Aggiungere pesi -> volto all'integrazione con sistemi fuzzy
% 2. Fare degli esempi più sofisticati sulla base della letteratura
% 3. Giustificare la semantica (stable)
% 4. Vedere come problema di ottimizzazione multi-obiettivo simbolico
% 5. Aggiungere assunzioni (non necessariamente strettamente bioetiche)
% 6. Principi SLEEC (sociali, giuridici...)
% 7. Visualizzazione dell'ABA (utile per evidenzare errori, cambiare la teoria senza dover fare handcoding)
% 8. Aspetto ILP

assumption(respect_autonomy).
assumption(act_beneficently).

head(ctx1, refuses_meds). weight(refuses_meds,9).
head(ctx2, physical_risk). weight(physical_risk,7).

head(r1, action(give_meds)).
body(r1, act_beneficently).
body(r1, physical_risk).

head(r3, action(dont_give_meds)).
body(r3, respect_autonomy).
body(r3, refuses_meds).

head(r4, ca).
body(r4, action(give_meds)).
body(r4, refuses_meds).

head(r5, cb).
body(r5, action(dont_give_meds)).
body(r5, physical_risk).

contrary(respect_autonomy, ca).
contrary(act_beneficently, cb).
