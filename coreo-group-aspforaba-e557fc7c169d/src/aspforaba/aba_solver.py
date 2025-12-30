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

import clingo
from .encoder import Encoder
from .parser import Parser
from .abaf import ABAF, AssumptionSet

class ABASolver:

    def __init__(self, assumptions = list(), contraries = list(), rules = list(), from_file = None, file_format = None):
        self.query = None

        # NOTE: parsing from file overrides provided by parameter. Could maybe change to avoid mixing both?
        if from_file:
            assumptions, rules, contraries = Parser.parse_input(from_file, file_format)

        self.abaf = ABAF(assumptions, rules, contraries)

        self._solving_assumptions = list()
        self._last_model = None
        self._refinement_asmpts = list()
        self._enumeration_answers = list()
        # self.encoded = False

    @property
    def atoms(self) -> set[str]:
        return set(self.abaf.atom_to_idx.keys())

    @property
    def assumptions(self) -> set[str]:
        return set(self.abaf.asmpt_to_idx.keys())

    @property
    def rules(self) -> list:
        ret = list()
        for h, body in self.abaf.rules:
            ret.append((self.abaf.idx_to_atom[h], [self.abaf.idx_to_atom[b] for b in body]))

        return ret

    @property
    def contraries(self) -> dict[str,set]:
        return {self.abaf.idx_to_atom[asmpt] : {self.abaf.idx_to_atom[c] for c in contrary} for asmpt, contrary in self.abaf.contraries.items()}

    def add_assumption(self, assumption: str):
        if not isinstance(assumption, str):
            raise ValueError(f"assumption '{assumption}': assumption must be of type str")

        self.abaf.add_asmpt(assumption)

    def add_rule(self, head: str, body: list[str]):
        if not isinstance(head, str):
            raise ValueError(f"atom '{head}' is not of type str")

        if not isinstance(body, list):
            raise ValueError(f"'{body}': rule body must be a list of strings")

        for b in body:
            if not isinstance(b, str):
                raise ValueError(f"atom '{body}' is not of type str")

        self.abaf.add_rule((head,body))

    def add_contrary(self, assumption, contrary):
        if not assumption in self.abaf.asmpt_to_idx:
            # self.add_assumption(assumption)
            raise ValueError("{assumption} is not an assumption in the current ABAF")

        if not isinstance(contrary, str):
            raise ValueError(f"atom '{contrary}': contrary must be of type str")

        self.abaf.add_contrary(assumption, contrary)

    def decide_credulous(self, semantics, query) -> bool:
        if query not in self.abaf.atom_to_idx:
            raise ValueError(f"query '{query}' is not an atom in the current ABAF")

        self._initialize_clingo(semantics)

        if semantics == "ID":
            ideal_ext = self._ideal(query)
            return query in ideal_ext.consequences or query in ideal_ext.assumptions

        self.ctl.ground([("base", [])], context=self)

        query_idx = self.abaf.atom_to_idx[query]
        query_supported = (clingo.Function("supported", [clingo.Function(f"a{query_idx}")]), True)

        sat = self.ctl.solve(assumptions=[query_supported]).satisfiable
        return sat

    def decide_skeptical(self, semantics, query, require_existence = False) -> bool:
        if query not in self.abaf.atom_to_idx:
            raise ValueError(f"query '{query}' is not an atom in the current ABAF")

        self._initialize_clingo(semantics)

        if semantics == "ID":
            ideal_ext = self._ideal(query)
            return query in ideal_ext.consequences or query in ideal_ext.assumptions

        if semantics == "PR":
            return self._skept_pref(query)

        if semantics == "AD":
            # Enforcing empty extension
            # TODO: could remove guess from encoding completely to save grounding time
            self.ctl.add("base", [], ":- in(X), assumption(X).")

        self.ctl.ground([("base", [])], context=self)

        # ST the only supported semantics where existence of extension is not guaranteed
        if require_existence and semantics == "ST":
            self.ctl.ground([("base", [])], context=self)
            if not self.ctl.solve().satisfiable:
                return False

        query_idx = self.abaf.atom_to_idx[query]
        query_not_supported = (clingo.Function("supported", [clingo.Function(f"a{query_idx}")]), False)

        sat = self.ctl.solve(assumptions=[query_not_supported]).satisfiable
        return not sat

    def find_extension(self, semantics) -> AssumptionSet | None:
        if semantics == "CO":
            semantics = "GR"

        self._initialize_clingo(semantics)

        if semantics == "ID":
            return self._ideal()

        if semantics == "PR":
            self._ee_pref(k = 1)
            return self._enumeration_answers[0]

        sat = self.ctl.solve(on_model=self._record_model).satisfiable
        if not sat:
            return None

        ans = self._interpret_extension(self._last_model)
        return ans

    def enumerate_extensions(self, semantics, k = 0) -> list[AssumptionSet] | None:
        if not isinstance(k, int) or k < 0:
            raise ValueError(f"k={k}; need a non-negative integer")

        self._initialize_clingo(semantics)

        if semantics == "ID":
            return [self._ideal()]

        if semantics == "PR":
            self._ee_pref(k)
            return self._enumeration_answers

        self.ctl.configuration.solve.models = k
        sat = self.ctl.solve(on_model=self._record_enumeration).satisfiable
        if not sat:
            return None

        ans = self._enumeration_answers
        return ans

    def _initialize_clingo(self, semantics):
        self._solving_assumptions.clear()
        self._last_model = None
        self._refinement_asmpts.clear()
        self._enumeration_answers.clear()

        self.ctl = clingo.Control(["--warn=none"])
        Encoder.encode_instance(self.ctl, self.abaf.idx_to_asmpt.keys(), self.abaf.contraries, self.abaf.rules)
        Encoder.encode_semantics(self.ctl, semantics)
        self.ctl.ground([("base", [])], context=self)

        if semantics == "ID":
            self.ctl.configuration.solve.enum_mode = "cautious"

    def _ee_pref(self, k = 0):
        enum_all = k == 0

        i = 0
        while True:
            self._solving_assumptions = []
            if not self.ctl.solve(on_model=self._maximize).satisfiable:
                break

            while True:
                rule = []
                with self.ctl.backend() as backend:
                    for a in self._refinement_asmpts:
                        rule.append(backend.add_atom(a))
                    backend.add_rule(head=[],body=rule)
                if not self.ctl.solve(assumptions=self._solving_assumptions,on_model=self._maximize).satisfiable:
                    self._enumeration_answers.append(self._interpret_extension(self._last_model))
                    i += 1
                    if not enum_all and i == k:
                        return

                    break

    def _skept_pref(self, query):

        query_idx = self.abaf.atom_to_idx[query]
        query_supported = clingo.Function("supported", [clingo.Function(f"a{query_idx}")])
        query_assumption = [(query_supported,False)]
        while True:
            self._solving_assumptions = list(query_assumption)
            if not self.ctl.solve(assumptions=query_assumption, on_model=self._maximize).satisfiable:
                break

            while True:
                rule = []
                with self.ctl.backend() as backend:
                    for a in self._refinement_asmpts:
                        rule.append(backend.add_atom(a))
                    backend.add_rule(head=[],body=rule)
                if not self.ctl.solve(assumptions=self._solving_assumptions,on_model=self._maximize).satisfiable:
                    break

            self._solving_assumptions[0] = (query_supported,True)
            if not self.ctl.solve(assumptions=self._solving_assumptions, on_model=self._record_model).satisfiable:
                return False

        return True

    def _ideal(self, query=None):
        self.ctl.solve(on_model=self._record_model)

        not_adm = {int(item.arguments[0].name[1:]) for item in self._last_model if item.name == "out"}

        cred_accepted = set(self.abaf.idx_to_asmpt) - not_adm
        accepted = list(cred_accepted)

        # conflict-freeness
        derived_from_cred_accepted = self._derivable_from(cred_accepted)
        for asm in accepted[:]:
            if asm not in self.abaf.contraries:
                continue
            if self.abaf.contraries[asm].intersection(derived_from_cred_accepted):
                accepted.remove(asm)

        # compute what is defended
        changes = True
        while changes:
            changes = False

            derived_from_accepted = self._derivable_from(accepted)

            not_defeated = self.assumptions
            updated_not_defeated = set()
            for asm in not_defeated:
                asm_idx = self.abaf.atom_to_idx[asm]
                if asm_idx not in self.abaf.contraries: continue
                if not self.abaf.contraries[asm_idx].intersection(derived_from_accepted):
                    updated_not_defeated.add(asm_idx)

            not_defeated = list(updated_not_defeated)
            derived_from_not_defeated = self._derivable_from(not_defeated)
            updated_accepted = list()
            for asm_idx in accepted[:]:
                if asm_idx not in self.abaf.contraries or not self.abaf.contraries[asm_idx].intersection(derived_from_not_defeated):
                    updated_accepted.append(asm_idx)
                else:
                    changes = True
            accepted = updated_accepted

        assumptions = set()
        consequences = set()

        # get answer
        for asmpt_index in accepted:
            assumptions.add(self.abaf.idx_to_asmpt[asmpt_index])

        for cons_index in self._derivable_from(accepted):
            if cons_index not in self.abaf.idx_to_asmpt:
                consequences.add(self.abaf.idx_to_atom[int(cons_index)])

        witness = AssumptionSet(assumptions, consequences)
        return witness

    def _derivable_from(self, original):
        derivable = set(original)
        changes = True
        # TODO: can make faster by only calling this once
        unused = list(self.abaf.rules)
        while changes:
            changes = False
            for rule in unused[:]:
                head, body = rule
                if not body or set(body).issubset(derivable):
                    derivable.add(head)
                    changes = True
                    unused.remove(rule)
        return derivable

    def _maximize(self, model):
        body = []
        self._refinement_asmpts = []

        for a in self.abaf.idx_to_asmpt.keys():
            atom = clingo.Function("out", [clingo.Function(f"a{a}")])
            if model.contains(atom):
                self._refinement_asmpts.append(atom)
            else:
                inatom = clingo.Function("in", [clingo.Function(f"a{a}")])
                self._solving_assumptions.append((inatom,True))

        self._last_model = model.symbols(shown=True)

    def _record_model(self, model):
        self._last_model = model.symbols(shown=True)

    def _record_enumeration(self, model):
        self._enumeration_answers.append(self._interpret_extension(model.symbols(shown=True)))

    def _interpret_extension(self, model):
        assumptions = set()
        consequences = set()

        if model:
            for sym in model:
                # NOTE: for non-flat, need different!
                if sym.name == "supported":
                    index = int(sym.arguments[0].name[1:])
                    if index in self.abaf.idx_to_asmpt:
                        assumptions.add(self.abaf.idx_to_asmpt[index])
                    else:
                        consequences.add(self.abaf.idx_to_atom[index])

        witness = AssumptionSet(assumptions, consequences)

        return witness

