#!/usr/bin/env python3
"""Build a conservative pinned Global-name census for family_epsform_sector.wls.

Every bare Wolfram identifier in executable source is included, not merely
assignment LHS names. Exact identifier-valued strings and explicit Global`
symbol strings are also included. This intentionally over-approximates the
driver's Global read/write set so a runtime definition-free preflight cannot
miss a source-visible dependency.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


EXPECTED_DRIVER_SHA256 = (
    "6786d5ee1ccefe101f6d70d1f8a977cd5de039b8673e20d54062f8b4915895f1"
)
IDENTIFIER = re.compile(r"[A-Za-z$][A-Za-z0-9$]*")
BARE_TOKEN = re.compile(r"(?<![A-Za-z0-9$])([A-Za-z$][A-Za-z0-9$]*)")
EXPLICIT_GLOBAL = re.compile(r"^Global`([A-Za-z$][A-Za-z0-9$]*)$")
OBSERVED_LOADER_HAZARDS = {"$LoadFeynArts", "$LoadAddOns", "A0"}
REQUIRED_DRIVER_GLOBALS = {
    "tau", "s", "u", "p", "x", "y", "eps", "v", "w",
    "Eps", "epsilon", "Epsilon", "ep", "t", "sqrtLambda", "gli",
    "nb", "xhat", "yhat",
}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def split_source(source: str) -> tuple[str, list[str]]:
    """Replace strings/comments by spaces while returning decoded strings."""
    code: list[str] = []
    strings: list[str] = []
    current_string: list[str] = []
    in_string = False
    comment_depth = 0
    i = 0
    while i < len(source):
        if comment_depth:
            if source.startswith("(*", i):
                comment_depth += 1
                code.extend("  ")
                i += 2
            elif source.startswith("*)", i):
                comment_depth -= 1
                code.extend("  ")
                i += 2
            else:
                code.append("\n" if source[i] == "\n" else " ")
                i += 1
            continue
        if in_string:
            if source[i] == "\\" and i + 1 < len(source):
                escape = source[i + 1]
                decoded = {"n": "\n", "r": "\r", "t": "\t"}.get(escape, escape)
                current_string.append(decoded)
                code.extend("  ")
                i += 2
            elif source[i] == '"':
                strings.append("".join(current_string))
                current_string = []
                in_string = False
                code.append(" ")
                i += 1
            else:
                current_string.append(source[i])
                code.append("\n" if source[i] == "\n" else " ")
                i += 1
            continue
        if source.startswith("(*", i):
            comment_depth = 1
            code.extend("  ")
            i += 2
        elif source[i] == '"':
            in_string = True
            current_string = []
            code.append(" ")
            i += 1
        else:
            code.append(source[i])
            i += 1
    if in_string or comment_depth:
        raise ValueError("unterminated Wolfram string or comment")
    return "".join(code), strings


def assignment_lhs_tokens(code: str) -> set[str]:
    pattern = re.compile(
        r"(?<![A-Za-z0-9$])([A-Za-z$][A-Za-z0-9$]*)"
        r"(?:\s*\[[^;\n]*?\])?\s*(?::=|(?<![=!<>])=(?!=))"
    )
    return {match.group(1) for match in pattern.finditer(code)}


def build(driver: Path) -> dict[str, object]:
    raw = driver.read_bytes()
    digest = sha256_bytes(raw)
    if digest != EXPECTED_DRIVER_SHA256:
        raise ValueError(f"driver hash drift: {digest}")
    source = raw.decode("utf-8")
    code, strings = split_source(source)
    code_tokens = {match.group(1) for match in BARE_TOKEN.finditer(code)}
    literal_identifiers = {value for value in strings if IDENTIFIER.fullmatch(value)}
    explicit_global_bases = {
        match.group(1)
        for value in strings
        if (match := EXPLICIT_GLOBAL.fullmatch(value)) is not None
    }
    lhs_tokens = assignment_lhs_tokens(code)
    bases = (
        code_tokens
        | literal_identifiers
        | explicit_global_bases
        | OBSERVED_LOADER_HAZARDS
        | REQUIRED_DRIVER_GLOBALS
    )
    if not lhs_tokens <= bases:
        raise AssertionError("assignment LHS escaped conservative census")
    if not REQUIRED_DRIVER_GLOBALS <= bases:
        raise AssertionError("required explicit/dynamic Global name absent")
    qualified = sorted(f"Global`{name}" for name in bases)
    return {
        "Schema": "FACETFamilySectorDriverGlobalCensusV1",
        "DriverPath": str(driver),
        "DriverSHA256": digest,
        "DriverBytes": len(raw),
        "Extraction": {
            "ExecutableBareIdentifiers": "all ASCII bare identifiers outside strings/comments",
            "IdentifierValuedStrings": "all full-string ASCII identifiers",
            "ExplicitGlobalStrings": "basenames of full Global`name strings",
            "AssignmentLHSCoveredQ": True,
            "ConservativeSupersetQ": True,
        },
        "ExecutableBareIdentifierCount": len(code_tokens),
        "IdentifierValuedStringCount": len(literal_identifiers),
        "ExplicitGlobalStringCount": len(explicit_global_bases),
        "AssignmentLHSTokenCount": len(lhs_tokens),
        "ObservedLoaderHazards": sorted(OBSERVED_LOADER_HAZARDS),
        "RequiredDriverGlobals": sorted(REQUIRED_DRIVER_GLOBALS),
        "GlobalBaseNameCount": len(bases),
        "GlobalBaseNames": sorted(bases),
        "QualifiedGlobalNameCount": len(qualified),
        "QualifiedGlobalNames": qualified,
        "AssignmentLHSTokens": sorted(lhs_tokens),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--driver", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = build(args.driver.resolve())
    text = json.dumps(result, indent=2, sort_keys=True) + "\n"
    args.output.write_text(text, encoding="utf-8")
    reread = json.loads(args.output.read_text(encoding="utf-8"))
    if reread != result:
        raise RuntimeError("written census did not round-trip")
    print(
        f"GLOBAL_CENSUS_V1 PASS names={result['QualifiedGlobalNameCount']} "
        f"lhs={result['AssignmentLHSTokenCount']} output={args.output}"
    )


if __name__ == "__main__":
    main()
