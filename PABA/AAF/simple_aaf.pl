%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Argumentation Framework (AF)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

arg(a).
arg(b).
arg(c).

0.9::att(a,b).
0.3::att(b,a).
0.7::att(c,a).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Basic utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Collect all arguments
all_args([a,b,c]).  % Modify manually if more args are added

% subset(+Set, -Subset)
subset([], []).
subset([H|T], [H|Sub]) :- subset(T, Sub).
subset([_|T], Sub) :- subset(T, Sub).

% member(+X, +List)
member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% conflict_free(+Set)
% True if Set is conflict-free (no internal attacks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

conflict_free([]).
conflict_free([X|Rest]) :-
    \+ (member(Y, Rest), att(X,Y)),
    \+ (member(Y, Rest), att(Y,X)),
    conflict_free(Rest).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% defended(+X, +Set)
% True if Set defends argument X
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

defended(X, Set) :-
    \+ (att(Y, X), \+ (member(Z, Set), att(Z, Y))).

% defended_all(+Set, +Set)
defended_all([], _).
defended_all([X|Xs], Set) :-
    defended(X, Set),
    defended_all(Xs, Set).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% admissible(+Set)
% True if Set is conflict-free and defends all its members
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

admissible(Set) :-
    conflict_free(Set),
    defended_all(Set, Set).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% maximal_admissible(-MaxSet)
% True if MaxSet is a maximal (w.r.t. set inclusion) admissible set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

maximal_admissible(MaxSet) :-
    all_args(All),
    subset(All, MaxSet),
    admissible(MaxSet),
    \+ (subset(All, Other),
        admissible(Other),
        strictly_includes(Other, MaxSet)).

% strictly_includes(+Set1, +Set2)
% True if Set1 ⊃ Set2
strictly_includes(Sup, Sub) :-
    includes(Sup, Sub),
    \+ includes(Sub, Sup).

% includes(+Sup, +Sub)
includes(_, []).
includes(Sup, [X|Xs]) :-
    member(X, Sup),
    includes(Sup, Xs).

query(maximal_admissible(X)).