%%%%%%%%%%%
% Utilities
%%%%%%%%%%%

% subset(+Set, -Subset)
subset([], []).
subset([H|T], [H|Sub]) :- subset(T, Sub).
subset([_|T], Sub) :- subset(T, Sub).

% includes(+Superset, +Subset)
includes(_, []).
includes(Sup, [X|Xs]) :-
    member(X, Sup),
    includes(Sup, Xs).

% strictly_includes(+Superset, +Subset)
strictly_includes(Sup, Sub) :-
    includes(Sup, Sub),
    \+ includes(Sub, Sup).

%%%%%%%%%%%%%%%%%%%
% Derivation in ABA
%%%%%%%%%%%%%%%%%%%

context_derivable(A) :-
    head(R, A),
    body(R, []).

% assumptions
derivable(Set, A) :-
    member(A, Set), assumption(A).

% facts (contextual)
derivable(_, A) :-
    context_derivable(A).

% recursive rules
derivable(Set, A) :-
    head(R, A),
    body(R, Body),
    all_derivable(Set, Body).

all_derivable(_, []).
all_derivable(Set, [H|T]) :-
    derivable(Set, H),
    all_derivable(Set, T).

%%%%%%%%%%%%%%%%%%%
% Conflict-Freeness
%%%%%%%%%%%%%%%%%%%

% attacks(+Set, +A): Set attacks A if it derives contrary of A
attacks(Set, A) :-
    contrary(A, C),
    derivable(Set, C).

% conflict_free(+Set)
conflict_free(Set) :-
    \+ (member(A, Set), attacks(Set, A)).

%%%%%%%%%
% Defense
%%%%%%%%%

% defends(+Set, +A): Set defends A if it attacks all attackers of A
defends(Set, A) :-
    \+ (assumption(B),
        attacks([B], A),
        \+ attacks(Set, B)).

% all_defended(+Set, +Elements): every element in Elements is defended by Set
all_defended(_, []).
all_defended(Set, [A|T]) :-
    defends(Set, A),
    all_defended(Set, T).

%%%%%%%%%%%%%%%
% Admissibility
%%%%%%%%%%%%%%%

% admissible(+Set)
admissible(Set) :-
    conflict_free(Set),
    all_defended(Set, Set).

%%%%%%%%%%%%%%%%%%%%%%%
% Maximal Admissibility
%%%%%%%%%%%%%%%%%%%%%%%

% preferred(-MaxSet)
preferred(MaxSet) :-
    all_assumptions(All),
    subset(All, MaxSet),
    admissible(MaxSet),
    \+ (subset(All, Other), admissible(Other), strictly_includes(Other, MaxSet)).

% naive(-MaxSet)
naive(MaxSet) :-
    all_assumptions(All),
    subset(All, MaxSet),
    conflict_free(MaxSet),
    \+ (subset(All, Other), conflict_free(Other), strictly_includes(Other, MaxSet)).