#!/usr/bin/env python3
"""Report AssociateTo calls whose top-level argument count is not two."""

from pathlib import Path
import sys


def sanitize(text):
    output = list(text)
    index = 0
    comment_depth = 0
    in_string = False
    escaped = False
    while index < len(text):
        char = text[index]
        nxt = text[index + 1] if index + 1 < len(text) else ""
        if comment_depth:
            if char == "(" and nxt == "*":
                output[index] = output[index + 1] = " "
                comment_depth += 1
                index += 2
                continue
            if char == "*" and nxt == ")":
                output[index] = output[index + 1] = " "
                comment_depth -= 1
                index += 2
                continue
            if char != "\n":
                output[index] = " "
            index += 1
            continue
        if in_string:
            if char != "\n":
                output[index] = " "
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            index += 1
            continue
        if char == "(" and nxt == "*":
            output[index] = output[index + 1] = " "
            comment_depth = 1
            index += 2
            continue
        if char == '"':
            output[index] = " "
            in_string = True
        index += 1
    return "".join(output)


def calls(text):
    clean = sanitize(text)
    needle = "AssociateTo["
    offset = 0
    while True:
        start = clean.find(needle, offset)
        if start < 0:
            return
        body_start = start + len(needle)
        stack = ["["]
        commas = 0
        index = body_start
        pairs = {")": "(", "]": "[", "}": "{"}
        while index < len(clean) and stack:
            char = clean[index]
            if char in "[({":
                stack.append(char)
            elif char in ")]}":
                if stack[-1] != pairs[char]:
                    raise ValueError(f"delimiter mismatch at offset {index}")
                stack.pop()
            elif char == "," and len(stack) == 1:
                commas += 1
            index += 1
        if stack:
            raise ValueError(f"unterminated AssociateTo at offset {start}")
        line = text.count("\n", 0, start) + 1
        yield line, commas + 1
        offset = index


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: audit_associateto_arity.py <Wolfram-source>")
    path = Path(sys.argv[1])
    violations = [(line, arity) for line, arity in calls(
        path.read_text(encoding="utf-8")) if arity != 2]
    if violations:
        for line, arity in violations:
            print(f"FAIL AssociateTo top-level arity={arity} line={line}")
        raise SystemExit(1)
    print("PASS every AssociateTo call has two top-level arguments")


if __name__ == "__main__":
    main()
