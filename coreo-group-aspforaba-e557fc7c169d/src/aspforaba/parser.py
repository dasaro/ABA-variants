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

import sys
from collections import defaultdict

from .abaf import ABAF

class Parser:

    def infer_format(input_file):
        with open(input_file, "r") as f:
            text = f.read().split("\n")
        if text[0].startswith("p aba"):
            return "iccma"
        if text[0].startswith("assumption(") or text[0].startswith("contrary(") or text[0].startswith("head(") or text[0].startswith("body("):
            return "asp"

        return "unknown"

    def parse_input(input_file, format = None):
        if format == "iccma":
            return Parser._parse_input_iccma(input_file)
        elif format == "asp":
            raise NotImplementedError("ASP format")
            return Parser._parse_input_asp(input_file)
        else:
            format = Parser.infer_format(input_file)
            if format == "iccma":
                return Parser._parse_input_iccma(input_file)
            elif format == "asp":
                return Parser._parse_input_asp(input_file)

            raise Exception(f"File '{input_file}' is not in valid format.")

    def _parse_input_iccma(input_file):
        assumptions = list()
        rules = list()
        contraries = list()

        with open(input_file, "r") as f:
            text = f.read().split("\n")
        if not text[0].startswith("p aba"):
            raise Exception(f"File '{input_file}' is not in ICCMA23 format (missing p-line).")
        for line in text[1:]:
            if line.startswith("a "):
                assumptions.append(line.split()[1])
            elif line.startswith("r "):
                components = line.split()[1:]
                head, body = components[0], components[1:]
                rules.append((head,body))
            elif line.startswith("c "):
                components = line.split()
                contraries.append((components[1], components[2]))
            elif line.startswith("#") or not line:
                continue
            else:
                raise Exception(f"Unrecognized line in the input file '{input_file}': '{line}'")

        return assumptions, rules, contraries

    def _parse_input_asp(input_file):
        assumptions = list()
        rules = list()
        contraries = list()

        head_dict = defaultdict(list)
        body_dict = defaultdict(list)

        with open(input_file, "r") as f:
            text = f.read().split("\n")
        for line in text:
            if line.startswith("assumption"):
                assumptions.append(line.split("(")[1].split(")")[0].strip())
            elif line.startswith("contrary"):
                asmpt, cont = map(str.strip, line.split("(")[1].split(")")[0].split(","))
                contraries.append((asmpt, cont))
            elif line.startswith("head"):
                idx, head = map(str.strip, line.split("(")[1].split(")")[0].split(","))
                if idx in head_dict:
                    raise Exception(f"Rule with index {idx} has more than one head")
                head_dict[idx] = head
            elif line.startswith("body"):
                idx, body_elem = map(str.strip, line.split("(")[1].split(")")[0].split(","))
                body_dict[idx].append(body_elem)
            elif line.startswith("%") or not line:
                continue
            else:
                raise Exception(f"Unrecognized line in the input file '{input_file}': '{line}'")

        for idx in head_dict.keys():
            rules.append((head_dict[idx], body_dict[idx]))

        return assumptions, rules, contraries
