assumption(a1). weight(a1, 0).
assumption(a2). weight(a2, 0).

head(ctx1, c1). weight(c1, 8).
head(ctx2, c2). weight(c2, 4).

head(r1, a).
body(r1, c1).
body(r1, c2).
body(r1, a1).

head(r2, a).
body(r2, a2).
body(r2, c2).

head(r3, a).
body(r3, a1).
body(r3, c1).

head(r4, b).
body(r4, a1).
body(r4, c2).

contrary(a1, b).
contrary(a2, a).
