#!/usr/bin/env python3
"""Static, no-Wolfram audit of the pinned CF300 sector-11 state.

The audit treats Mathematica arithmetic syntax structurally.  It proves the
epsilon/scalar multidegrees of every entry in the 22 x 22 completed prefix;
it does not numerically sample or simplify any algebraic expression.
"""

from __future__ import annotations

import argparse
import ast
import collections
import hashlib
import re
from pathlib import Path


EXPECTED_STATE_SHA256 = (
    "898e4283c39fcdb457b7857a4609e48b5ca0417b1d06cb07750779b187c33a12"
)
EXPECTED_STATE_BYTES = 33_012_365
DEFAULT_STATE = Path(
    "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/"
    "UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/"
    "CF300/sector_state_CF300_standard.wl"
)

P_PLUS = "(-2+13*eps-27*eps^2+18*eps^3)"
P_MINUS = "(2-13*eps+27*eps^2-18*eps^3)"
ROOT3 = "1-4*x*y"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def matching_delimiter(text: str, start: int) -> int:
    if text[start] != "{":
        raise ValueError("list must start with an opening brace")
    stack = ["}"]
    pairs = {"{": "}", "[": "]", "(": ")"}
    in_string = False
    comment_depth = 0
    index = start + 1
    while index < len(text):
        if comment_depth:
            if text.startswith("(*", index):
                comment_depth += 1
                index += 2
                continue
            if text.startswith("*)", index):
                comment_depth -= 1
                index += 2
                continue
            index += 1
            continue
        if in_string:
            if text[index] == "\\":
                index += 2
                continue
            if text[index] == '"':
                in_string = False
            index += 1
            continue
        if text.startswith("(*", index):
            comment_depth = 1
            index += 2
            continue
        character = text[index]
        if character == '"':
            in_string = True
        elif character in pairs:
            stack.append(pairs[character])
        elif character in "}])":
            if not stack or character != stack[-1]:
                raise ValueError(f"unbalanced delimiter at byte {index}")
            stack.pop()
            if not stack:
                return index
        index += 1
    raise ValueError("unterminated Wolfram list")


def split_wl_list(text: str) -> list[str]:
    opening = text.find("{")
    closing = matching_delimiter(text, opening)
    inner = text[opening + 1 : closing]
    pairs = {"{": "}", "[": "]", "(": ")"}
    stack: list[str] = []
    in_string = False
    comment_depth = 0
    values: list[str] = []
    value_start = 0
    index = 0
    while index < len(inner):
        if comment_depth:
            if inner.startswith("(*", index):
                comment_depth += 1
                index += 2
                continue
            if inner.startswith("*)", index):
                comment_depth -= 1
                index += 2
                continue
            index += 1
            continue
        if in_string:
            if inner[index] == "\\":
                index += 2
                continue
            if inner[index] == '"':
                in_string = False
            index += 1
            continue
        if inner.startswith("(*", index):
            comment_depth = 1
            index += 2
            continue
        character = inner[index]
        if character == '"':
            in_string = True
        elif character in pairs:
            stack.append(pairs[character])
        elif character in "}])":
            if not stack or character != stack[-1]:
                raise ValueError(f"unbalanced list entry at byte {index}")
            stack.pop()
        elif character == "," and not stack:
            values.append(inner[value_start:index].strip())
            value_start = index + 1
        index += 1
    tail = inner[value_start:].strip()
    if tail or inner.strip():
        values.append(tail)
    return values


def unique_list_value(state: str, key: str) -> str:
    needle = f'"{key}" ->'
    positions = [match.start() for match in re.finditer(re.escape(needle), state)]
    if len(positions) != 1:
        raise AssertionError(f"expected one top-level-like {key!r}, found {positions}")
    opening = state.index("{", positions[0] + len(needle))
    closing = matching_delimiter(state, opening)
    return state[opening : closing + 1]


def matrix_from_value(value: str) -> list[list[str]]:
    return [split_wl_list(row) for row in split_wl_list(value)]


def connection_from_value(value: str) -> list[list[list[str]]]:
    return [matrix_from_value(component) for component in split_wl_list(value)]


def wolfram_arithmetic_to_python(expression: str) -> str:
    compact = re.sub(r"\s+", "", expression)
    compact = compact.replace(P_PLUS, "(eps^2*q)")
    compact = compact.replace(P_MINUS, "(-eps^2*q)")
    compact = compact.replace("^", "**")
    compact = compact.replace("Sqrt[", "sqrt(").replace("]", ")")
    return compact


Degree = tuple[int, int]


def multidegrees(node: ast.AST) -> set[Degree]:
    """Return formal degrees in (eps, q), with all kinematics degree zero."""

    if isinstance(node, ast.Expression):
        return multidegrees(node.body)
    if isinstance(node, ast.Constant):
        return {(0, 0)}
    if isinstance(node, ast.Name):
        if node.id == "eps":
            return {(1, 0)}
        if node.id == "q":
            return {(0, 1)}
        return {(0, 0)}
    if isinstance(node, ast.UnaryOp):
        return multidegrees(node.operand)
    if isinstance(node, ast.Call):
        argument_degrees = set().union(
            *(multidegrees(argument) for argument in node.args)
        )
        if argument_degrees != {(0, 0)}:
            raise AssertionError("a radical/function argument depends on eps or q")
        return {(0, 0)}
    if isinstance(node, ast.BinOp):
        left = multidegrees(node.left)
        right = multidegrees(node.right)
        if isinstance(node.op, (ast.Add, ast.Sub)):
            return left | right
        if isinstance(node.op, ast.Mult):
            return {
                (left_eps + right_eps, left_q + right_q)
                for left_eps, left_q in left
                for right_eps, right_q in right
            }
        if isinstance(node.op, ast.Div):
            if len(right) != 1:
                raise AssertionError("denominator is not homogeneous in eps and q")
            right_eps, right_q = next(iter(right))
            return {
                (left_eps - right_eps, left_q - right_q)
                for left_eps, left_q in left
            }
        if isinstance(node.op, ast.Pow):
            if isinstance(node.right, ast.Constant) and isinstance(
                node.right.value, int
            ):
                power = node.right.value
            elif (
                isinstance(node.right, ast.UnaryOp)
                and isinstance(node.right.op, ast.USub)
                and isinstance(node.right.operand, ast.Constant)
                and isinstance(node.right.operand.value, int)
            ):
                power = -node.right.operand.value
            else:
                raise AssertionError("nonintegral formal power")
            if power < 0:
                if len(left) != 1:
                    raise AssertionError("negative power of inhomogeneous expression")
                eps_degree, q_degree = next(iter(left))
                return {(power * eps_degree, power * q_degree)}
            result = {(0, 0)}
            for _ in range(power):
                result = {
                    (a_eps + b_eps, a_q + b_q)
                    for a_eps, a_q in result
                    for b_eps, b_q in left
                }
            return result
    raise AssertionError(f"unsupported Python AST node {type(node).__name__}")


def expression_multidegrees(expression: str) -> tuple[Degree, ...] | str:
    if expression.strip() == "0":
        return "zero"
    tree = ast.parse(wolfram_arithmetic_to_python(expression), mode="eval")
    return tuple(sorted(multidegrees(tree)))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("state", nargs="?", type=Path, default=DEFAULT_STATE)
    args = parser.parse_args()
    state_path = args.state.resolve()
    assert state_path.is_file(), state_path
    assert state_path.stat().st_size == EXPECTED_STATE_BYTES
    assert sha256(state_path) == EXPECTED_STATE_SHA256

    state = state_path.read_text(encoding="utf-8")
    connection = connection_from_value(unique_list_value(state, "A"))
    s_matrix = matrix_from_value(unique_list_value(state, "S"))
    sinverse_matrix = matrix_from_value(unique_list_value(state, "SInverse"))

    assert len(connection) == 2
    assert all(len(component) == 24 for component in connection)
    assert all(len(row) == 24 for component in connection for row in component)
    assert len(s_matrix) == len(sinverse_matrix) == 24
    assert all(len(row) == 24 for row in s_matrix + sinverse_matrix)

    counts: collections.Counter[tuple[str, tuple[Degree, ...] | str]] = (
        collections.Counter()
    )
    lower_left_expressions: list[str] = []
    for component in connection:
        for row in range(22):
            for column in range(22):
                if row < 20 and column < 20:
                    region = "old_20x20"
                elif row < 20:
                    region = "upper_right_20x2"
                elif column < 20:
                    region = "new_lower_left_2x20"
                else:
                    region = "new_diagonal_2x2"
                expression = component[row][column]
                degree = expression_multidegrees(expression)
                counts[(region, degree)] += 1
                if region == "new_lower_left_2x20" and expression != "0":
                    lower_left_expressions.append(expression)

    expected_counts = {
        ("old_20x20", "zero"): 516,
        ("old_20x20", ((1, 0),)): 284,
        ("upper_right_20x2", "zero"): 80,
        ("new_lower_left_2x20", "zero"): 54,
        ("new_lower_left_2x20", ((0, 1),)): 26,
        ("new_diagonal_2x2", ((1, 0),)): 8,
    }
    assert dict(counts) == expected_counts, counts

    compact_lower_left = [re.sub(r"\s+", "", item) for item in lower_left_expressions]
    radical_arguments = {
        argument
        for expression in compact_lower_left
        for argument in re.findall(r"Sqrt\[([^\[\]]+)\]", expression)
    }
    assert radical_arguments == {ROOT3}, radical_arguments

    assert [index + 1 for index, row in enumerate(s_matrix) if row[20] != "0"] == [21]
    assert [index + 1 for index, row in enumerate(s_matrix) if row[21] != "0"] == [22]
    assert s_matrix[20][20] == s_matrix[21][21] == "1"
    sinverse_row_support = {
        row + 1: [column + 1 for column, value in enumerate(sinverse_matrix[row]) if value != "0"]
        for row in (20, 21)
    }
    assert sinverse_row_support == {
        21: [1, 2, 5, 16, 17, 21],
        22: [1, 2, 5, 10, 11, 16, 17, 22],
    }

    assert '"Sector" -> 11' in state[:64]
    assert '"Status" -> "NeedsMultiquadraticRegulatorFactorization"' in state[-512:]
    assert '"Rows" -> 11' in state[-512:]
    assert '"RootIndices" -> {1, 2, 3}' in state[-512:]

    print("CF300_SECTOR11_REGULATOR_STATIC PASS")
    print(f"state_sha256={EXPECTED_STATE_SHA256}")
    print("prefix=22 old_prefix=20 new_subspace_dimension=2")
    print("formal_scalar q=P/eps^2; P=(2 eps-1)(3 eps-1)(3 eps-2)")
    print("transformation_scalar t=q/eps=P/eps^3")
    for key, value in sorted(counts.items(), key=str):
        print(f"{key}={value}")
    print("full_dense_unknowns=484 reduced_scalar_unknowns=1 exact_changed_channels=26")
    print(f"sinverse_row_support={sinverse_row_support}")


if __name__ == "__main__":
    main()
