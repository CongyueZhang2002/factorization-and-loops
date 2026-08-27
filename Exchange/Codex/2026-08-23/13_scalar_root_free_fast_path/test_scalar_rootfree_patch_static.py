#!/usr/bin/env python3
"""No-kernel, fail-closed audit for the scalar-local root-free patch."""

from __future__ import annotations

import hashlib
import itertools
import pathlib
import re
import subprocess
import sys
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[3]
SOURCE = ROOT / (
    "External/CodexExchange/triple_root_2026-08-22/"
    "direct_root_channel_compiler_v2_xh/DirectRootChannelCompilerV2.wl"
)
PATCH = pathlib.Path(__file__).with_name(
    "0001-scalar-local-root-free-fast-path.patch"
)
LEXICAL_GUARD = ROOT / (
    "External/CodexExchange/triple_root_2026-08-22/"
    "direct_root_channel_assembler_xh/check_wl_no_kernel_parse_guard.pl"
)
EXPECTED_SOURCE_SHA256 = (
    "79749c288c95e46f6956b0722087abce041f7f240a3e6eb110a0fd6699d2b153"
)


def require(condition: bool, label: str) -> None:
    if not condition:
        raise AssertionError(label)


def hadamard_recompose(channels: list[int], roots: list[int], prime: int) -> list[int]:
    rank = len(roots)
    require(len(channels) == 1 << rank, "model-grade-count")
    output = []
    for branch in range(1 << rank):
        value = 0
        for mask, coefficient in enumerate(channels):
            product = coefficient
            for index, root in enumerate(roots):
                if (mask >> index) & 1:
                    signed = -root if (branch >> index) & 1 else root
                    product = (product * signed) % prime
            value = (value + product) % prime
        output.append(value)
    return output


def direct_fast_path_contract(text: str) -> bool:
    start = text.find("drcav2DecomposeCanonical[expression_, roots_List")
    end = text.find(
        'AssociateTo[statistics, "AlgebraicPathCount"', start)
    if start < 0 or end < 0:
        return False
    direct = text[start:end]
    return all(needle in direct for needle in [
        'FreeQ[rational, Alternatives @@ symbols]',
        'channels = PadRight[{rational}, 2^rank, 0]',
        'TRFieldCompose[channels, roots]',
        'Together[reconstructed - expression] === 0',
        'Return[<|"Channels" -> channels',
    ])


def main() -> int:
    require(SOURCE.is_file(), "source-missing")
    require(PATCH.is_file(), "patch-missing")
    require(LEXICAL_GUARD.is_file(), "lexical-guard-missing")
    original = SOURCE.read_text(encoding="utf-8")
    source_sha = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    require(re.fullmatch(r"[0-9a-f]{64}", source_sha) is not None,
            "source-sha")
    require(source_sha == EXPECTED_SOURCE_SHA256, "source-sha-drift")

    with tempfile.TemporaryDirectory(prefix="drcav2-rootfree-") as directory:
        work = pathlib.Path(directory)
        target = work / SOURCE.relative_to(ROOT)
        target.parent.mkdir(parents=True)
        target.write_text(original, encoding="utf-8")
        result = subprocess.run(
            ["git", "apply", "--unsafe-paths", "--directory", str(work),
             str(PATCH)],
            cwd=ROOT, text=True, capture_output=True, check=False,
        )
        require(result.returncode == 0,
                "patch-apply: " + result.stderr.strip())
        patched = target.read_text(encoding="utf-8")
        lexical = subprocess.run(
            ["perl", str(LEXICAL_GUARD), str(target)], cwd=ROOT,
            text=True, capture_output=True, check=False,
        )
        require(lexical.returncode == 0,
                "lexical-guard: " + lexical.stderr.strip())

    required = [
        'replaced = If[rank === 0, expression,',
        'If[replaced === $Failed || ! FreeQ[replaced,',
        'FreeQ[rational, Alternatives @@ symbols]',
        'channels = PadRight[{rational}, 2^rank, 0]',
        'TRFieldCompose[channels, roots]',
        'Together[reconstructed - expression] === 0',
        'pairs = drcav2CanonicalPair /@ channels',
        '"Channels" -> channels',
    ]
    for needle in required:
        require(needle in patched, "missing-contract: " + needle)
    require(direct_fast_path_contract(patched), "direct-fast-path-contract")
    require(patched.count('AssociateTo[statistics, "AlgebraicPathCount"') == 1,
            "algebraic-counter-duplicated")
    require(patched.index('FreeQ[rational, Alternatives @@ symbols]') <
            patched.index('AssociateTo[statistics, "AlgebraicPathCount"'),
            "fast-path-after-algebraic-counter")
    require(patched.index('Together[reconstructed - expression] === 0') <
            patched.index('Return[<|"Channels" -> channels'),
            "unchecked-return")

    # Independent quotient-basis model: a grade-zero vector must retain the
    # full 2^r shape and evaluate to the same scalar on every sign branch.
    primes = [101, 103, 1_000_003]
    for rank, prime, scalar in itertools.product(range(4), primes, [0, 1, 7, 98]):
        roots = [2 + index for index in range(rank)]
        channels = [scalar % prime] + [0] * ((1 << rank) - 1)
        values = hadamard_recompose(channels, roots, prime)
        require(values == [scalar % prime] * (1 << rank),
                f"grade-zero-recompose-r{rank}-p{prime}-s{scalar}")

    # Adversarial source mutations must be rejected by the contract audit.
    mutants = {
        "short-grade-vector": patched.replace(
            'PadRight[{rational}, 2^rank, 0]', '{rational}', 1),
        "missing-compose-check": patched.replace(
            'Together[reconstructed - expression] === 0', 'True', 1),
        "blind-rank-fast-path": patched.replace(
            'rank === 0 || FreeQ[rational, Alternatives @@ symbols]',
            'rank >= 0', 1),
    }
    for name, mutant in mutants.items():
        require(not direct_fast_path_contract(mutant),
                "mutant-accepted: " + name)

    print("PASS scalar-local root-free patch static/adversarial audit")
    print("source_sha256", source_sha)
    print("checks", len(required) + 4 + 4 * len(primes) * 4 + len(mutants))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print("FAIL", error, file=sys.stderr)
        raise
