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

import sys, os
import argparse

from .aba_solver import ABASolver
from .parser import Parser

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("-f", "--file")
    parser.add_argument("-p", "--problem", type=str, nargs='+')
    parser.add_argument("-a", "--query", type=str)
    parser.add_argument("--problems", action="store_true")
    parser.add_argument("-fo", "--format", choices=["iccma", "asp"])
    parser.add_argument("-pr", "--preferences", action="store_true")
    parser.add_argument("-sre", "--skeptical_requires_existence", action="store_true")

    args = parser.parse_args()

    aba_problems = {
            "DC-AD", "DC-CO", "DC-ST", "DC-PR", "DC-GR", "DC-ID",
            "DS-AD", "DS-CO", "DS-ST", "DS-PR", "DS-GR", "DS-ID",
            "SE-AD", "SE-CO", "SE-PR", "SE-ST", "SE-GR", "SE-ID",
            "EE-AD", "EE-CO", "EE-PR", "EE-ST", "EE-GR", "EE-ID"
            }

    if len(sys.argv) == 1:
        print("ASPforABA v1.1.0\nTuomo Lehtonen, tuomo.lehtonen@aalto.fi")
        sys.exit(0)

    if args.problems:
        print(f"Supported problems: {', '.join(aba_problems)}")
        sys.exit(0)

    if not args.file:
        print("Please provide an input file")
        sys.exit(1)

    if not args.problem:
        print(f"Error: problem not specified.\nSupported problems: {', '.join(aba_problems)}")
        sys.exit(1)

    problem = args.problem[0]

    if not args.preferences:
        if problem not in aba_problems:
            sys.exit(f"Error: problem '{problem}' is not supported\nSupported problems: {', '.join(aba_problems)}")
    else:
        raise NotImplementedError("ABA+")

    task, semantics = problem.split("-")

    if (task == "DC" or task == "DS") and not args.query:
        print("Please provide a query")
        sys.exit(1)

    input_file = args.file
    format = args.format
    if not args.format:
        format = Parser.infer_format(input_file)

    assumptions, rules, contraries = Parser.parse_input(input_file, args.format)

    solver = ABASolver(assumptions, contraries, rules)

    if task == "DC":
        acc = solver.decide_credulous(semantics, args.query)
        if acc:
            print("YES")
        else:
            print("NO")
    elif task == "DS":
        acc = solver.decide_skeptical(semantics, args.query, require_existence = args.skeptical_requires_existence)
        if acc:
            print("YES")
        else:
            print("NO")
    elif task == "SE":
        answer = solver.find_extension(semantics)
        if answer is None:
            sys.exit("NO")
        ans = list(answer.assumptions)
        if format == "iccma":
            ans.sort(key=int)
            print(f"w {' '.join(ans)}")
        elif format == "asp":
            print(f"Found extension: {', '.join(ans)}")
        else:
            raise Exception("File format not recognized")
    elif task == "EE":
        k = 0
        if len(args.problem) > 1:
            k = int(args.problem[1])
        answers = solver.enumerate_extensions(semantics, k)
        if not answers:
            print("NO")
            sys.exit(0)
        if format == "asp":
            print("Found extensions")
        for ans in answers:
            extension = list(ans.assumptions)

            if format == "iccma":
                extension.sort(key=int)
                print(f"w {' '.join(extension)}")
            elif format == "asp":
                print(f"{', '.join(extension)}")
            else:
                raise Exception("File format not recognized")

if __name__ == '__main__':
  main()
