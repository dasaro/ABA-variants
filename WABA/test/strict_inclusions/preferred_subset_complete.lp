%% Framework demonstrating: preferred ⊂ complete (strict)
%%
%% Expected:
%% - Preferred: {a, b}
%% - Complete: {a}, {a, b}
%%
%% Reason: {a} is complete but not maximal (not preferred)

assumption(a).
assumption(b).

%% b is not attacked
%% a is not attacked

weight(a, 100).
weight(b, 100).

#const beta = 0.
budget(beta).
