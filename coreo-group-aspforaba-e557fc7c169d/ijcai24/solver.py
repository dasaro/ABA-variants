#!/usr/bin/env python3

import clingo
import sys, os
import argparse
import pathlib

import logging
#logging.basicConfig(level=logging.DEBUG, format=' %(asctime)s -  %(levelname)s -  %(message)s')
logging.basicConfig(level=logging.DEBUG, format='%(levelname)s - %(message)s')
logging.basicConfig(level=logging.INFO, format='%(levelname)s - %(message)s')
logging.disable(logging.CRITICAL)

class Solver:

    def __init__(self):
        self.assumptions = []
        self.ctl = None
        self.current_dir = pathlib.Path(__file__).parent.resolve()
        self.guess_adm = os.path.join(self.current_dir, "encodings", "guess_nonflat_aba_adm.lp")
        self.guess_com = os.path.join(self.current_dir, "encodings", "guess_nonflat_aba_com.lp")
        self.verify_adm = os.path.join(self.current_dir, "encodings", "verify_nonflat_aba_adm.lp")
        self.verify_com = os.path.join(self.current_dir, "encodings", "verify_nonflat_aba_com.lp")
        self.stb_encoding = os.path.join(self.current_dir, "encodings", "nonflat_aba_stb.lp")

        self.asmpt_to_clingo_in = dict()
        self.asmpt_to_clingo_out = dict()
        self.asmpt_to_clingo_defeated = dict()
        self.asmpt_to_clingo_target = dict()
        self.in_set = set()
        self.out_set = set()
        self.defeated_set = set()

        # for debugging
        self.asmpt_to_clingo_derived = dict()
        #self.derived_set = set()

    def _init_clingo_funcions(self):
        for a in self.assumptions:
            self.asmpt_to_clingo_in[a] = clingo.Function("in", [clingo.Function(a)])
            self.asmpt_to_clingo_out[a] = clingo.Function("out", [clingo.Function(a)])
            self.asmpt_to_clingo_defeated[a] = clingo.Function("defeated", [clingo.Function(a)])
            self.asmpt_to_clingo_target[a] = clingo.Function("target", [clingo.Function(a)])
            self.asmpt_to_clingo_derived[a] = clingo.Function("derived", [clingo.Function(a)])

    def _parse_input(self, input_file):
        text = open(input_file, "r").read().split("\n")
        for line in text:
            if line.startswith("assumption"):
                self.assumptions.append(line.split("(")[1].split(")")[0])

    def _guess_on_model(self, model):
        #logging.debug(model)
        for a in self.assumptions:
            in_atom = self.asmpt_to_clingo_in[a]
            out_atom = self.asmpt_to_clingo_out[a]
            defeated_atom = self.asmpt_to_clingo_defeated[a]
            if model.contains(defeated_atom):
                self.defeated_set.add(a)

            if model.contains(in_atom):
                self.in_set.add(a)
            else:
                self.out_set.add(a)

        #if model.contains(self.asmpt_to_clingo_derived[a]):
        #    self.derived_set.add(a)

    def refine_exact_set(self, in_set, out_set):
        body = []
        with self.ctl.backend() as backend:
            for a in in_set:
                inatom = self.asmpt_to_clingo_in[a]
                body.append(backend.add_atom(inatom))
            for a in out_set:
                outatom = self.asmpt_to_clingo_out[a]
                body.append(backend.add_atom(outatom))

            backend.add_rule(head=[], body=body)

    def _clean(self):
        self.in_set = set()
        self.out_set = set()
        self.defeated_set = set()
        self.derived_set = set()

    def _in_and_undefeated_as_asp_string(self, in_set, defeated_set):
        output = ""
        for a in in_set:
            output += f"in({a}). "
        for a in defeated_set:
            output += f"defeated({a}). "

        return output

    def adm(self, input_file, query_assumption):
        self._init_clingo_funcions()

        self.ctl.load(self.guess_adm)
        self.ctl.load(input_file)
        self.ctl.ground([("base", [])], context=self)

        n_cands = 0
        while True:
            res = self.ctl.solve(on_model=self._guess_on_model, assumptions=query_assumption)
            if not res.satisfiable:
                break

            n_cands+=1

            # Refine the abstraction by prohibiting the candidate
            self.refine_exact_set(self.in_set, self.out_set)

            logging.debug(f"Candidate {n_cands}: {self.in_set}  --  defeated: {self.defeated_set}")
            #logging.debug(f"Candidate {n_cands}: {self.in_set}, out: {self.out_set}")
            #logging.debug(f"Candidate: {self.in_set}, out: {self.out_set}, derived: {self.derived_set}")

            #if self.in_set == set():
            #    return True, self.in_set

            adm_verifier = clingo.Control(["--warn=none"])
            adm_verifier.load(self.verify_adm)
            adm_verifier.load(input_file)

            in_defeated_string = self._in_and_undefeated_as_asp_string(self.in_set, self.defeated_set)
            adm_verifier.add("base", [], in_defeated_string)
            adm_verifier.ground([("base", [])], context=self)

            res = adm_verifier.solve()
            if not res.satisfiable:
                return True, self.in_set

            self._clean()

        return False, None

    def stb(self, input_file, query_assumption):
        self._init_clingo_funcions()

        self.ctl.load(self.stb_encoding)
        self.ctl.load(input_file)
        self.ctl.ground([("base", [])], context=self)

        res = self.ctl.solve(on_model=self._guess_on_model, assumptions=query_assumption)
        if res.satisfiable:
            return True, self.in_set
        else:
            return False, None

    def com(self, input_file, query_assumption):
        self._init_clingo_funcions()

        #self.ctl.load(self.guess_adm)
        self.ctl.load(self.guess_com)
        self.ctl.load(input_file)
        self.ctl.ground([("base", [])], context=self)

        n_cands = 0

        while True:
            res = self.ctl.solve(on_model=self._guess_on_model, assumptions=query_assumption)
            if not res.satisfiable:
                break

            n_cands += 1

            # Refine the abstraction by prohibiting the candidate
            self.refine_exact_set(self.in_set, self.out_set)

            logging.debug(f"Candidate {n_cands}: {self.in_set}  --  defeated: {self.defeated_set}")
            #logging.debug(f"Candidate {n_cands}: {self.in_set}  --   out: {self.out_set}")
            #logging.debug(f"Candidate: {self.in_set}, out: {self.out_set}, derived: {self.derived_set}")

            adm_verifier = clingo.Control(["--warn=none"])
            adm_verifier.load(self.verify_adm)
            adm_verifier.load(input_file)

            in_defeated_string = self._in_and_undefeated_as_asp_string(self.in_set, self.defeated_set)
            adm_verifier.add("base", [], in_defeated_string)

            adm_verifier.ground([("base", [])], context=self)

            res = adm_verifier.solve()
            # Adm counterexample found; refinement done already
            if res.satisfiable:
                self._clean()
                continue

            out_undefeated_asmpts = set(self.assumptions) - self.defeated_set - self.in_set
            # Candidate is stable and thus complete
            if not out_undefeated_asmpts:
                return True, self.in_set
            # Otherwise, check if assumption a that is not in candidate is truly defended
            com_ce_found = False
            for a in out_undefeated_asmpts:
                com_verifier = clingo.Control()
                #com_verifier = clingo.Control(["--warn=none"])
                com_verifier.load(self.verify_com)
                com_verifier.load(input_file)

                input_string = self._in_and_undefeated_as_asp_string(self.in_set, self.defeated_set)
                input_string += f"target({a})."
                com_verifier.add("base", [], input_string)

                com_verifier.ground([("base", [])], context=self)

                res = com_verifier.solve()
                if not res.satisfiable:
                    logging.debug(input_string)
                    com_ce_found = True
                    break

            if not com_ce_found:
                return True, self.in_set

            self._clean()

        return False, None

    def run(self):
        parser = argparse.ArgumentParser()

        parser.add_argument("-f", "--file", required=True)
        parser.add_argument("-p", "--problem", choices=["DC-CO", "DC-ST", "DC-AD"], required=True)
#parser.add_argument("-p", "--problem", choices=["DC-CO", "DC-ST", "DS-PR", "DS-ST", "SE-PR", "SE-ST"])
        parser.add_argument("-a", "--query", type=str, required=True)
        args = parser.parse_args()

        if not os.path.isfile(args.file):
            print(f"Error: Instance file '{args.file}' not found.")
            sys.exit(1)

        input_file = args.file
        self._parse_input(input_file)

        #self.ctl = clingo.Control()
        self.ctl = clingo.Control(["--warn=none"])

        task, semantics = args.problem.split("-")

        if task == "DC":
            query_atom = clingo.Function("derived", [clingo.Function(args.query)])
            query_assumption = [(query_atom,True)]
            if semantics == "AD":
                res, witness = self.adm(input_file, query_assumption)
                if res == True:
                    print("YES")
                    logging.info(f"Witness: {witness}")
                elif res == False:
                    print("NO")
                else:
                    sys.exit(f"ERROR: {res} returned")
            elif semantics == "CO":
                res, witness = self.com(input_file, query_assumption)
                if res == True:
                    print("YES")
                    logging.info(f"Witness: {witness}")
                elif res == False:
                    print("NO")
                else:
                    sys.exit(f"ERROR: {res} returned")
            elif semantics == "ST":
                res, witness = self.stb(input_file, query_assumption)
                if res == True:
                    print("YES")
                    logging.info(f"Witness: {witness}")
                elif res == False:
                    print("NO")
                else:
                    sys.exit(f"ERROR: {res} returned")

if __name__ == "__main__":
    Solver().run()
