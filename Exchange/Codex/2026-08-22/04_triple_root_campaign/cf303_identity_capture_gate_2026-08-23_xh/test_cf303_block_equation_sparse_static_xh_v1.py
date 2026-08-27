#!/usr/bin/env python3
"""No-kernel fail-closed audit of the staged CF303 blockEquation patch."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


ROOT = Path("/home/maxzhang/factorization-and-loops")
HERE = ROOT / (
    "External/CodexExchange/triple_root_2026-08-22/"
    "cf303_identity_capture_gate_2026-08-23_xh"
)
DRIVER = ROOT / "Scripts/family_epsform_sector.wls"
RESUME = ROOT / "FeynFacet/Private/FamilyRowGaugeResume.wl"
PATCH = HERE / "cf303_block_equation_sparse_xh_v1.patch"
ADVERSARIAL = HERE / "test_cf303_block_equation_sparse_xh_v1.wls"

EXPECTED = {
    DRIVER: "6786d5ee1ccefe101f6d70d1f8a977cd5de039b8673e20d54062f8b4915895f1",
    RESUME: "816fa4d544806115181b3c3fe2d6ee3de89fff1d3d999e6412b6a745b010fc2b",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def strip_wolfram_comments_and_strings(text: str) -> str:
    output: list[str] = []
    index = 0
    comment_depth = 0
    in_string = False
    while index < len(text):
        pair = text[index : index + 2]
        char = text[index]
        if comment_depth:
            if pair == "(*":
                comment_depth += 1
                output.extend("  ")
                index += 2
            elif pair == "*)":
                comment_depth -= 1
                output.extend("  ")
                index += 2
            else:
                output.append("\n" if char == "\n" else " ")
                index += 1
        elif in_string:
            if char == "\\" and index + 1 < len(text):
                output.extend("  ")
                index += 2
            elif char == '"':
                in_string = False
                output.append(" ")
                index += 1
            else:
                output.append("\n" if char == "\n" else " ")
                index += 1
        elif pair == "(*":
            comment_depth = 1
            output.extend("  ")
            index += 2
        elif char == '"':
            in_string = True
            output.append(" ")
            index += 1
        else:
            output.append(char)
            index += 1
    assert comment_depth == 0, "unterminated Wolfram comment"
    assert not in_string, "unterminated Wolfram string"
    return "".join(output)


def assert_balanced(code: str) -> None:
    pairs = {"[": "]", "{": "}", "(": ")"}
    closing = {right: left for left, right in pairs.items()}
    stack: list[str] = []
    for char in code:
        if char in pairs:
            stack.append(char)
        elif char in closing:
            assert stack and stack.pop() == closing[char], f"mismatched {char}"
    assert not stack, f"unclosed delimiter {stack[-1] if stack else None}"


def main() -> None:
    checks = 0
    for path, expected in EXPECTED.items():
        assert path.is_file(), f"missing pinned source: {path}"
        assert sha256(path) == expected, f"active source drift: {path}"
        checks += 1

    patch_text = PATCH.read_text()
    assert patch_text.startswith(
        "diff --git a/Scripts/family_epsform_sector.wls "
        "b/Scripts/family_epsform_sector.wls\n"
    )
    assert patch_text.count("diff --git ") == 1
    assert "FeynFacet/Private/" not in patch_text
    checks += 3

    required_patch_tokens = [
        "blockEquationSparseDot[left_List, right_List]",
        "Position[#, Except[0], {1}, Heads -> False]",
        "Intersection[leftSupport[[i]], rightSupport[[j]]]",
        "higher = Select[Keys[solved], j < # < k &]",
        "A[[mu, rk, rj]] - Total[products]",
        "Map[Together, A[[mu, rk, rj]] - Total[products], {2}]",
        "If[MemberQ[products, $Failed], Return[$Failed]]",
    ]
    for token in required_patch_tokens:
        assert token in patch_text, f"missing exactness token: {token}"
        checks += 1

    forbidden = [
        "TimeConstrained", "Timeout", "N[", "Chop[", "PossibleZeroQ",
        "Random", "Modulus", "Interpolation", "Parallel", "RunProcess",
        "StartProcess", "LaunchKernels", "Quit[",
    ]
    added = "\n".join(
        line[1:] for line in patch_text.splitlines()
        if line.startswith("+") and not line.startswith("+++")
    )
    added_code = strip_wolfram_comments_and_strings(added)
    for token in forbidden:
        assert token not in added_code, f"forbidden staged behavior: {token}"
        checks += 1

    # The legacy package oracle must remain untouched.  It is deliberately
    # retained for independent SameQ replay of every resumed strip input.
    resume_text = RESUME.read_text()
    assert "Source-identical semantics to the sector driver's blockEquation" in resume_text
    assert "Sum[solvedBlocks[m] ." in resume_text
    assert "If[! SameQ[input[\"Strip\"], expectedStrip]" in resume_text
    checks += 3

    test_text = ADVERSARIAL.read_text()
    test_code = strip_wolfram_comments_and_strings(test_text)
    assert_balanced(test_code)
    assert "legacyBlockEquation" in test_text
    assert "sparseBlockEquation" in test_text
    assert "AllBlockEquationSameQ" in test_text
    assert "AllBlockEquationResidualsZero" in test_text
    assert "MalformedInnerDimensionFailsClosed" in test_text
    assert not re.search(r"(?<![A-Za-z0-9`])(Exit|Quit|Abort|TimeConstrained)\s*\[", test_code)
    checks += 6

    print(f"PASS: {checks} staged sparse-blockEquation static assertions")
    print(f"driver_sha256={sha256(DRIVER)}")
    print(f"resume_oracle_sha256={sha256(RESUME)}")
    print(f"patch_sha256={sha256(PATCH)}")
    print(f"adversarial_sha256={sha256(ADVERSARIAL)}")


if __name__ == "__main__":
    main()
