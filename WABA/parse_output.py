#!/usr/bin/env python3
import re
import sys
import pandas as pd
import argparse

def parse_clingo_output(text):
    text = re.split(r'^(?:SATISFIABLE|UNSATISFIABLE)', text, flags=re.MULTILINE)[0]
    pattern = re.compile(
        r'^Answer:\s*(\d+)\s*(.*?)^(?=Answer:\s*\d+|\Z)',
        re.MULTILINE | re.DOTALL
    )

    rows = []
    for num_str, block in pattern.findall(text):
        num = int(num_str)
        in_atoms = re.findall(r'\bin\(\s*([^\)]+?)\s*\)', block)
        action_ws = re.findall(
            r'weight_of_atom\s*\(\s*action\(\s*([^\)]+?)\s*\)\s*,\s*([^\)]+?)\s*\)',
            block
        )
        m_cost = re.search(r'extension_cost\(\s*([^\)]+?)\s*\)', block)
        cost = m_cost.group(1) if m_cost else ''

        row = {
            'Answer':         num,
            'in_assumptions': ';'.join(in_atoms),
            'extension_cost': cost
        }
        for action, w in action_ws:
            row[f'weight({action})'] = w

        rows.append(row)

    return rows

def main():
    p = argparse.ArgumentParser(
        description="Parse clingo output piped on stdin into a table"
    )
    p.add_argument(
        '-o','--output',
        default='clingo_results.xlsx',
        help="desired output filename (will fall back to .csv if Excel write fails)"
    )
    args = p.parse_args()

    raw = sys.stdin.read()
    data = parse_clingo_output(raw)
    if not data:
        print("No Answer blocks found.", file=sys.stderr)
        sys.exit(1)

    df = pd.DataFrame(data).sort_values('Answer')
    out = args.output
    if out.lower().endswith('.csv'):
        df.to_csv(out, index=False)
        print(f"Wrote results to {out}")
    else:
        # Try Excel first
        try:
            df.to_excel(out, index=False)
            print(f"Wrote results to {out}")
        except Exception:
            # fallback to CSV
            csv_out = out.rsplit('.',1)[0] + '.csv'
            df.to_csv(csv_out, index=False)
            print(f"No Excel engine detected, wrote CSV to {csv_out}")

if __name__ == '__main__':
    main()
