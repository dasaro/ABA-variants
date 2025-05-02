head(r1, fly(tweety)).
body(r1, bird(tweety)).
body(r1, normal(tweety)).

head(r2, fly(joe)).
body(r2, bird(joe)).
body(r2, normal(joe)).

head(r3, not_fly(tweety)).
body(r3, penguin(tweety)).

head(r4, not_fly(joe)).
body(r4, penguin(joe)).

head(r5, bird(tweety)).
body(r5, penguin(tweety)).

head(r6, bird(joe)).
body(r6, penguin(joe)).

head(r7, penguin(tweety)).

head(r8, bird(joe)).

assumption(normal(tweety)).
contrary(normal(tweety), not_fly(tweety)).

assumption(normal(joe)).
contrary(normal(joe), not_fly(joe)).
