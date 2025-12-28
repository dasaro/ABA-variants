assumption(a).
assumption(b).
assumption(c).

weight(a, 80).
weight(b, 60).
weight(c, 40).

weight(c_a, 70).
weight(c_b, 50).
weight(c_c, 30).

head(r1, c_a). body(r1, b).
head(r2, c_a). body(r2, c).

contrary(a, c_a).
contrary(b, c_b).
contrary(c, c_c).