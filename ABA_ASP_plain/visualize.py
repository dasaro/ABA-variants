# import re
# import argparse
# from collections import OrderedDict

# def transform_atom(atom_str):
#     """
#     Transform an atom of the form name(arg) into name[arg].
#     """
#     return re.sub(r'(\w+)\(([^()]+)\)', r'\1[\2]', atom_str)

# def parse_asp(input_str):
#     """
#     Parses an ASP file formatted with assumptions, head/body rules, and contraries.
#     Returns:
#         atoms: OrderedDict of all atoms (to preserve order)
#         rules: OrderedDict mapping rule ids to dicts with 'head' and list of 'body' atoms
#         assumptions: List of assumption atoms
#         contraries: List of tuples (assumption, contrary_atom)
#     """
#     atoms = OrderedDict()
#     rules = OrderedDict()
#     assumptions = []
#     contraries = []
    
#     # Regular expression patterns
#     assumption_pattern = re.compile(r'^assumption\(\s*(.+?)\s*\)\.')
#     head_pattern = re.compile(r'^head\(\s*([^,]+)\s*,\s*(.+?)\s*\)\.')
#     body_pattern = re.compile(r'^body\(\s*([^,]+)\s*,\s*(.+?)\s*\)\.')
#     contrary_pattern = re.compile(r'^contrary\(\s*(.+?)\s*,\s*(.+?)\s*\)\.')
    
#     # Process each line in the input
#     for line in input_str.splitlines():
#         line = line.strip()
#         if not line or line.startswith('%'):
#             continue  # Skip comments and empty lines
        
#         # Check for assumption lines
#         m = assumption_pattern.match(line)
#         if m:
#             atom = m.group(1)
#             assumptions.append(atom)
#             if atom not in atoms:
#                 atoms[atom] = True
#             continue
        
#         # Check for head lines
#         m = head_pattern.match(line)
#         if m:
#             rule_id = m.group(1)
#             head_atom = m.group(2)
#             if head_atom not in atoms:
#                 atoms[head_atom] = True
#             if rule_id not in rules:
#                 rules[rule_id] = {'head': head_atom, 'body': []}
#             else:
#                 rules[rule_id]['head'] = head_atom
#             continue
        
#         # Check for body lines
#         m = body_pattern.match(line)
#         if m:
#             rule_id = m.group(1)
#             body_atom = m.group(2)
#             if body_atom not in atoms:
#                 atoms[body_atom] = True
#             if rule_id not in rules:
#                 rules[rule_id] = {'head': None, 'body': [body_atom]}
#             else:
#                 rules[rule_id]['body'].append(body_atom)
#             continue
        
#         # Check for contrary lines
#         m = contrary_pattern.match(line)
#         if m:
#             a1 = m.group(1)
#             a2 = m.group(2)
#             contraries.append((a1, a2))
#             if a1 not in atoms:
#                 atoms[a1] = True
#             if a2 not in atoms:
#                 atoms[a2] = True
#             continue
    
#     return atoms, rules, assumptions, contraries

# def generate_output(atoms, rules, assumptions, contraries):
#     """
#     Generates the output text in four parts: <atoms>, <rules>, <assumptions>, and <contraries>
#     using square bracket notation.
#     """
#     output_lines = []
    
#     # Atoms section
#     output_lines.append("<atoms>")
#     for atom in atoms.keys():
#         output_lines.append(transform_atom(atom))
    
#     # Rules section
#     output_lines.append("")
#     output_lines.append("<rules>")
#     for rule_id, rule in rules.items():
#         head_atom = rule['head']
#         if head_atom is None:
#             continue
#         head_str = transform_atom(head_atom)
#         if rule['body']:
#             body_atoms = ", ".join(transform_atom(b) for b in rule['body'])
#             rule_line = f"{head_str} <- {body_atoms}"
#         else:
#             rule_line = f"{head_str} <- "
#         output_lines.append(rule_line)
    
#     # Assumptions section
#     output_lines.append("")
#     output_lines.append("<assumptions>")
#     for atom in assumptions:
#         output_lines.append(transform_atom(atom))
    
#     # Contraries section
#     output_lines.append("")
#     output_lines.append("<contraries>")
#     for a1, a2 in contraries:
#         output_lines.append(f"({transform_atom(a1)}, {transform_atom(a2)})")
    
#     return "\n".join(output_lines)

# if __name__ == "__main__":
#     parser = argparse.ArgumentParser(
#         description="Transform an ASP file (ABA format) into four parts: <atoms>, <rules>, <assumptions>, <contraries>."
#     )
#     parser.add_argument("input_file", help="Path to the input ASP file.")
#     args = parser.parse_args()

#     try:
#         with open(args.input_file, "r") as f:
#             input_asp = f.read()
#     except FileNotFoundError:
#         print(f"Error: File '{args.input_file}' not found.")
#         exit(1)
    
#     # Parse the ASP input and generate the output
#     atoms, rules, assumptions, contraries = parse_asp(input_asp)
#     output_text = generate_output(atoms, rules, assumptions, contraries)
#     print(output_text)

import argparse
import re
import matplotlib.pyplot as plt
from py_arg.aba_classes.rule import Rule
from py_arg.aba_classes.aba_framework import ABA
from py_arg.aba_classes.argumentation_framework import visualize
from py_arg.aba_classes.semantics.get_semantics import get_preferred_extensions
from py_arg.aba_classes.argument import generate_arguments
from py_arg.aba_classes.attack import determine_attacks
from py_arg.aba_classes.argumentation_framework import generate_af_from_aba_framework

def parse_lp_file(file_path):
    """
    Parses a .lp file to extract atoms, rules, assumptions, and contraries.
    """
    atoms = set()
    rules = []
    assumptions = set()
    contraries = {}

    with open(file_path, 'r') as file:
        for line in file:
            line = line.strip()
            if line.startswith('assumption('):
                match = re.match(r'assumption\((.*?)\)\.', line)
                if match:
                    assumption = match.group(1)
                    assumptions.add(assumption)
                    atoms.add(assumption)
            elif line.startswith('head('):
                match = re.match(r'head\((.*?),(.*?)\)\.', line)
                if match:
                    rule_name = match.group(1).strip()
                    head = match.group(2).strip()
                    body = []
                    atoms.add(head)
                    rules.append(Rule(rule_name, set(body), head))
            elif line.startswith('body('):
                match = re.match(r'body\((.*?),(.*?)\)\.', line)
                if match:
                    rule_name = match.group(1).strip()
                    body_atom = match.group(2).strip()
                    atoms.add(body_atom)
                    for rule in rules:
                        if rule.name == rule_name:
                            rule.premises.add(body_atom)
                            break
            elif line.startswith('contrary('):
                match = re.match(r'contrary\((.*?),(.*?)\)\.', line)
                if match:
                    assumption = match.group(1).strip()
                    contrary = match.group(2).strip()
                    contraries[assumption] = contrary
                    atoms.add(contrary)

    return atoms, rules, assumptions, contraries

def main():
    parser = argparse.ArgumentParser(description="Parse a .lp file and visualize its ABA framework.")
    parser.add_argument('file_path', type=str, help="Path to the .lp file")
    args = parser.parse_args()

    atoms, rules, assumptions, contraries = parse_lp_file(args.file_path)

    # Create ABA framework
    aba_framework = (atoms, rules, assumptions, contraries)

    # Generate arguments
    arguments = generate_arguments(aba_framework)

    # Determine attacks
    attacks = determine_attacks(arguments, aba_framework)

    # Generate the corresponding argumentation framework
    af = generate_af_from_aba_framework(arguments, attacks)

    # Visualize the argumentation framework
    visualize(af)
    
    plt.show()

    # Optionally, compute and display preferred extensions
    preferred_extensions = get_preferred_extensions(af)
    print("Preferred Extensions:")
    for ext in preferred_extensions:
        print(ext)

if __name__ == "__main__":
    main()
