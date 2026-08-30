"""Conservative source-boundary validation for the supported wABA surface.

The five framework relations are data, not extension-dependent ASP predicates.  This
scanner deliberately accepts a small, auditable source language: ground facts, ``#const``
definitions, ``#include`` directives, and comments.  It understands nested function terms,
quoted strings, semicolon pools, intervals, and several statements on one line.

This is not a general ASP parser.  General ASP remains available through direct clingo
composition, outside the supported wrapper contract.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Statement:
    text: str
    line: int
    column: int


class FrameworkSourceError(ValueError):
    """A source construct lies outside the supported data-only boundary."""


def load_policy(root: Path) -> dict:
    return json.loads((root / "input-policy.json").read_text(encoding="utf-8"))


def _location(path: Path, statement: Statement) -> str:
    return f"{path}:{statement.line}:{statement.column}"


def _scan_statements(source: str, path: Path) -> list[Statement]:
    """Remove ASP comments and split at top-level terminators without touching strings."""
    cleaned: list[str] = []
    quote = False
    escaped = False
    line_comment = False
    block_depth = 0
    line = 1
    column = 1
    index = 0

    while index < len(source):
        char = source[index]
        nxt = source[index + 1] if index + 1 < len(source) else ""

        if line_comment:
            if char == "\n":
                line_comment = False
                cleaned.append(char)
                line += 1
                column = 1
            else:
                cleaned.append(" ")
                column += 1
            index += 1
            continue

        if block_depth:
            if char == "%" and nxt == "*":
                block_depth += 1
                cleaned.extend((" ", " "))
                index += 2
                column += 2
                continue
            if char == "*" and nxt == "%":
                block_depth -= 1
                cleaned.extend((" ", " "))
                index += 2
                column += 2
                continue
            if char == "\n":
                cleaned.append(char)
                line += 1
                column = 1
            else:
                cleaned.append(" ")
                column += 1
            index += 1
            continue

        if quote:
            cleaned.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quote = False
            if char == "\n":
                line += 1
                column = 1
            else:
                column += 1
            index += 1
            continue

        if char == "%" and nxt == "*":
            block_depth = 1
            cleaned.extend((" ", " "))
            index += 2
            column += 2
            continue
        if char == "%":
            line_comment = True
            cleaned.append(" ")
            index += 1
            column += 1
            continue
        if char == '"':
            quote = True
        cleaned.append(char)
        if char == "\n":
            line += 1
            column = 1
        else:
            column += 1
        index += 1

    if block_depth:
        raise FrameworkSourceError(f"{path}: unterminated block comment")
    if quote:
        raise FrameworkSourceError(f"{path}: unterminated quoted string")

    text = "".join(cleaned)
    statements: list[Statement] = []
    start: int | None = None
    start_line = 1
    start_column = 1
    line = 1
    column = 1
    round_depth = square_depth = brace_depth = 0
    quote = escaped = False

    for index, char in enumerate(text):
        if start is None and not char.isspace():
            start = index
            start_line = line
            start_column = column

        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quote = False
        else:
            if char == '"':
                quote = True
            elif char == "(":
                round_depth += 1
            elif char == ")":
                round_depth -= 1
            elif char == "[":
                square_depth += 1
            elif char == "]":
                square_depth -= 1
            elif char == "{":
                brace_depth += 1
            elif char == "}":
                brace_depth -= 1

            if min(round_depth, square_depth, brace_depth) < 0:
                where = f"{path}:{line}:{column}"
                raise FrameworkSourceError(f"{where}: unmatched closing delimiter")

            previous = text[index - 1] if index else ""
            following = text[index + 1] if index + 1 < len(text) else ""
            terminator = (
                char == "."
                and round_depth == square_depth == brace_depth == 0
                and previous != "."
                and following != "."
            )
            if terminator and start is not None:
                body = text[start:index].strip()
                if body:
                    statements.append(Statement(body, start_line, start_column))
                start = None

        if char == "\n":
            line += 1
            column = 1
        else:
            column += 1

    if round_depth or square_depth or brace_depth:
        raise FrameworkSourceError(f"{path}: unclosed delimiter")
    if start is not None and text[start:].strip():
        where = f"{path}:{start_line}:{start_column}"
        raise FrameworkSourceError(f"{where}: statement is missing its final '.'")
    return statements


def _outside_strings(text: str) -> str:
    result: list[str] = []
    quote = escaped = False
    for char in text:
        if quote:
            result.append(" ")
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quote = False
        else:
            if char == '"':
                quote = True
                result.append(" ")
            else:
                result.append(char)
    return "".join(result)


def _ground(term: str) -> bool:
    visible = _outside_strings(term)
    return re.search(r"(?<![A-Za-z0-9_])[A-Z_][A-Za-z0-9_]*", visible) is None


def _split_top_level(text: str, separator: str) -> list[str]:
    pieces: list[str] = []
    start = 0
    depth = 0
    quote = escaped = False
    for index, char in enumerate(text):
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quote = False
            continue
        if char == '"':
            quote = True
        elif char in "([":
            depth += 1
        elif char in ")]":
            depth -= 1
        elif char == separator and depth == 0:
            pieces.append(text[start:index].strip())
            start = index + 1
    pieces.append(text[start:].strip())
    return pieces


def _fact_arity_alternatives(arguments: str | None) -> list[int]:
    if arguments is None:
        return [0]
    alternatives = _split_top_level(arguments, ";")
    result: list[int] = []
    for alternative in alternatives:
        if not alternative:
            result.append(0)
        else:
            result.append(len(_split_top_level(alternative, ",")))
    return result


def _validate_statement(statement: Statement, path: Path, policy: dict) -> str | None:
    text = statement.text.strip()
    location = _location(path, statement)

    include = re.fullmatch(r'#include\s+"([^"\\]+)"', text, flags=re.DOTALL)
    if include:
        return include.group(1)

    const = re.fullmatch(r"#const\s+([a-z][A-Za-z0-9_]*)\s*=\s*(.+)", text, flags=re.DOTALL)
    if const:
        name = const.group(1)
        if name in set(policy["reservedConstants"]):
            raise FrameworkSourceError(
                f"{location}: #const {name} would rewrite an implementation term and is reserved"
            )
        value = const.group(2).strip()
        if not value or not _ground(value):
            raise FrameworkSourceError(f"{location}: #const values must be ground")
        visible = _outside_strings(value)
        if any(token in visible for token in (":-", ":~", "{", "}", "@")):
            raise FrameworkSourceError(f"{location}: unsupported construct in #const value")
        return None

    if text.startswith("#"):
        directive = text.split(None, 1)[0]
        raise FrameworkSourceError(
            f"{location}: directive {directive!r} is not accepted; only #const and #include "
            "belong to framework data"
        )

    visible = _outside_strings(text)
    if any(token in visible for token in (":-", ":~")):
        raise FrameworkSourceError(
            f"{location}: ASP rules and constraints are not accepted; encode ABA rules as "
            "ground head/2 and body/2 facts"
        )
    if any(token in visible for token in ("{", "}", "|", "@", "[", "]", ":")):
        raise FrameworkSourceError(
            f"{location}: choice, disjunctive, conditional, external, and aggregate facts "
            "are not accepted"
        )

    fact = re.fullmatch(
        r"([a-z][A-Za-z0-9_]*)\s*(?:\((.*)\))?", text, flags=re.DOTALL
    )
    if fact is None:
        raise FrameworkSourceError(f"{location}: expected a ground data fact")
    predicate, arguments = fact.group(1), fact.group(2)
    if not _ground(arguments or ""):
        raise FrameworkSourceError(f"{location}: data facts must be ground (variables are not accepted)")

    framework_predicates = policy["frameworkPredicates"]
    if predicate in framework_predicates:
        expected = int(framework_predicates[predicate])
        actual = _fact_arity_alternatives(arguments)
        if any(arity != expected for arity in actual):
            rendered = ", ".join(str(arity) for arity in sorted(set(actual)))
            raise FrameworkSourceError(
                f"{location}: {predicate} expects arity {expected}, but this pool contains "
                f"arity {rendered}"
            )
    elif predicate in set(policy["reservedPredicates"]):
        raise FrameworkSourceError(
            f"{location}: {predicate} is a reserved implementation predicate and cannot be "
            "authored by a framework"
        )
    else:
        allowed = ", ".join(sorted(framework_predicates))
        raise FrameworkSourceError(
            f"{location}: {predicate} is not a framework predicate; accepted facts are "
            f"exactly {allowed}"
        )
    return None


def validate_framework_sources(framework: Path, root: Path) -> None:
    """Validate a root file and each transitive include against the data-only policy."""
    policy = load_policy(root)
    pending = [framework.resolve()]
    seen: set[Path] = set()
    while pending:
        current = pending.pop()
        if current in seen:
            continue
        seen.add(current)
        try:
            source = current.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as exc:
            raise FrameworkSourceError(f"could not read included framework source {current}: {exc}") from exc
        for statement in _scan_statements(source, current):
            included = _validate_statement(statement, current, policy)
            if included is None:
                continue
            include_path = (current.parent / included).resolve()
            if not include_path.is_file():
                raise FrameworkSourceError(
                    f"{_location(current, statement)}: included source does not exist: {included}"
                )
            pending.append(include_path)
