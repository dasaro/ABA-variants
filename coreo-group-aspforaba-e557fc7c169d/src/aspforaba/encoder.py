"""
Copyright <2023-2024> <Tuomo Lehtonen, University of Helsinki>

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
"""

class Encoder:
    COMMON_ENCODING = """
        { in(X) : assumption(X) }.
        out(X) :- not in(X), assumption(X).
        supported(X) :- assumption(X), in(X).
        supported(X) :- head(R,X), triggered_by_in(R).
        triggered_by_in(R) :- head(R,_), supported(X) : body(R,X).
        :- in(X), contrary(X,Y), supported(Y).
        defeated(X) :- supported(Y), contrary(X,Y).
        """

    ADMISSIBLE_ADD = """
        derived_from_undefeated(X) :- assumption(X), not defeated(X).
        derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
        triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).
        attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y).
        :- in(X), attacked_by_undefeated(X).
        """

    COMPLETE_ADD = ":- out(X), not attacked_by_undefeated(X)."

    STABLE_ADD = ":- not defeated(X), out(X)."

    GROUNDED_ENCODING = """
        n_assumptions(N) :- #count{X : assumption(X)} = N.
        iteration(0..N) :- n_assumptions(N).
        supported(X,I) :- assumption(X), in(X,I).
        supported(X,I) :- head(R,X), triggered_by_in(R,I).
        triggered_by_in(R,I) :- iteration(I), head(R,_), supported(X,I) : body(R,X).
        :- in(X,I), contrary(X,Y), supported(Y,I).
        defeated(X,I) :- supported(Y,I), contrary(X,Y).
        derived_from_undefeated(X,I) :- iteration(I), assumption(X), not defeated(X,I).
        derived_from_undefeated(X,I) :- head(R,X), triggered_by_undefeated(R,I).
        triggered_by_undefeated(R,I) :- iteration(I), head(R,_), derived_from_undefeated(X,I) : body(R,X).
        attacked_by_undefeated(X,I) :- contrary(X,Y), derived_from_undefeated(Y,I).
        in(X,I) :- iteration(J), assumption(X), not attacked_by_undefeated(X,J), J+1=I.
        in(X) :- in(X,N), n_assumptions(N).
        supported(X) :- supported(X,N), n_assumptions(N).
        """

    DERIVABLE_ENCODING = """
        supported(X) :- assumption(X), in(X).
        supported(X) :- head(R,X), triggered_by_in(R).
        triggered_by_in(R) :- head(R,_), supported(X) : body(R,X).
        """

    def _admissible_encoding(ctl):
        ctl.add("base", [], Encoder.COMMON_ENCODING)
        ctl.add("base", [], Encoder.ADMISSIBLE_ADD)

    def _complete_encoding(ctl):
        ctl.add("base", [], Encoder.COMMON_ENCODING)
        ctl.add("base", [], Encoder.ADMISSIBLE_ADD)
        ctl.add("base", [], Encoder.COMPLETE_ADD)

    def _stable_encoding(ctl):
        ctl.add("base", [], Encoder.COMMON_ENCODING)
        ctl.add("base", [], Encoder.STABLE_ADD)

    def _grounded_encoding(ctl):
        ctl.add("base", [], Encoder.GROUNDED_ENCODING)

    def _derivable_encoding(ctl):
        ctl.add("base", [], Encoder.DERIVABLE_ENCODING)

    def encode_instance(ctl, assumptions, contraries, rules):
        # 'a' denotes atom
        assumptions_str = ' '.join({f"assumption(a{asm})." for asm in assumptions})
        ctr_str = ""
        for a, ctrs in contraries.items():
            for c in ctrs:
                ctr_str += f"contrary(a{a},a{c})."

        head_str = ""
        body_str = ""
        for i, rule in enumerate(rules):
            head_str += f"head({i},a{rule[0]}). "
            for b in rule[1]:
                body_str += f"body({i},a{b}). "
        ctl.add("base", [], assumptions_str)
        ctl.add("base", [], ctr_str)
        ctl.add("base", [], head_str)
        ctl.add("base", [], body_str)

    def encode_semantics(ctl, semantics):
        if semantics == "AD" or semantics == "ID":
            Encoder._admissible_encoding(ctl)
        elif semantics == "CO" or semantics == "PR":
            Encoder._complete_encoding(ctl)
        elif semantics == "ST":
            Encoder._stable_encoding(ctl)
        elif semantics == "GR":
            Encoder._grounded_encoding(ctl)
        elif semantics == "derivability":
            # NOTE: Not used atm
            Encoder._derivable_encoding(ctl)
        else:
            raise ValueError(f"Semantics '{semantics}' not supported")

        ctl.add("base", [], "#show in/1. #show supported/1.")
        if semantics == "PR" or semantics == "ID":
            ctl.add("base", [], "#show out/1.")



