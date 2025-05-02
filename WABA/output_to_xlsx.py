import re
import argparse
import pandas as pd


def split_predicates(ans_text: str):
    """
    Split a Clingo answer-set line into individual predicate strings, handling nested parentheses.
    """
    preds = []
    i = 0
    n = len(ans_text)
    while i < n:
        # Skip whitespace
        while i < n and ans_text[i].isspace():
            i += 1
        if i >= n:
            break
        # Read predicate name
        start = i
        while i < n and (ans_text[i].isalnum() or ans_text[i] == '_'):
            i += 1
        name = ans_text[start:i]
        # If there's a '(', capture until matching ')'
        if i < n and ans_text[i] == '(':
            depth = 0
            arg_start = i
            while i < n:
                if ans_text[i] == '(':
                    depth += 1
                elif ans_text[i] == ')':
                    depth -= 1
                    if depth == 0:
                        i += 1
                        break
                i += 1
            preds.append(name + ans_text[arg_start:i])
        else:
            preds.append(name)
    return preds


def parse_answerset(line: str):
    """
    Parse a single answer set line into its components.
    Returns a dict with:
      - 'in': set of assumptions (strings)
      - 'cost': integer cost (with '#inf' mapped to 0)
      - 'actions': dict mapping action(...) literal to weight
    """
    result = {'in': set(), 'cost': None, 'actions': {}}
    # Remove trailing period
    line = line.rstrip('.').strip()
    preds = split_predicates(line)
    for p in preds:
        if p.startswith('in(') and p.endswith(')'):
            arg = p[3:-1]
            result['in'].add(arg)
        elif p.startswith('extension_cost(') and p.endswith(')'):
            val = p[len('extension_cost('):-1]
            # Map '#inf' to 0, else parse int or keep literal
            if val == '#inf':
                cost = 0
            else:
                try:
                    cost = int(val)
                except ValueError:
                    cost = val
            result['cost'] = cost
        elif p.startswith('supported_with_weight(') and p.endswith(')'):
            inner = p[len('supported_with_weight('):-1]
            # split on comma at top level
            depth = 0
            for idx, ch in enumerate(inner):
                if ch == '(':
                    depth += 1
                elif ch == ')':
                    depth -= 1
                elif ch == ',' and depth == 0:
                    a_part = inner[:idx].strip()
                    w_part = inner[idx+1:].strip()
                    break
            else:
                continue
            # only keep action weights
            if not a_part.startswith('action('):
                continue
            action_lit = a_part
            # parse weight, map '#inf' to 0
            if w_part == '#inf':
                w = 0
            else:
                try:
                    w = int(w_part)
                except ValueError:
                    w = w_part
            result['actions'][action_lit] = w
    return result


def main():
    parser = argparse.ArgumentParser(
        description='Convert Clingo answer sets to Excel for weighted extensions.'
    )
    parser.add_argument('input', help='Path to Clingo output file')
    parser.add_argument('output', help='Path to output XLSX file')
    args = parser.parse_args()

    # Read all lines
    with open(args.input, 'r') as f:
        lines = f.readlines()

    # Extract answer sets until SATISFIABLE
    sets = []
    current = []
    seen_first = False
    for line in lines:
        if line.startswith('SATISFIABLE'):
            if seen_first and current:
                sets.append(' '.join(current))
            break
        if line.startswith('Answer:'):
            if seen_first and current:
                sets.append(' '.join(current))
            seen_first = True
            current = []
            continue
        if not seen_first:
            continue
        if line.strip() == '':
            if current:
                sets.append(' '.join(current))
                current = []
            continue
        current.append(line.strip())
    if seen_first and current:
        sets.append(' '.join(current))

    # Parse answer sets
    parsed = [parse_answerset(s) for s in sets]

    # Collect all assumptions and actions
    all_assumptions = sorted({a for ps in parsed for a in ps['in']})
    all_actions = sorted({a for ps in parsed for a in ps['actions']})

    # Build rows
    rows = []
    for idx, ps in enumerate(parsed, start=1):
        row = {'n': idx, 'extension_cost': ps['cost']}
        for a in all_assumptions:
            row[a] = 1 if a in ps['in'] else 0
        for a in all_actions:
            row[a] = ps['actions'].get(a, 0)
        rows.append(row)

    # Create DataFrame and export to Excel
    df = pd.DataFrame(rows, columns=['n', 'extension_cost'] + all_assumptions + all_actions)
    df.to_excel(args.output, index=False)
    print(f"Exported {len(rows)} extensions to {args.output}")


if __name__ == '__main__':
    main()
