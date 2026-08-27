#!/usr/bin/env python3
"""No-Wolfram V2 assertion-cardinality, ABI, and finite-field gate."""

from __future__ import annotations

import hashlib
import importlib.util
import re
import sys
from pathlib import Path


ROOT = Path("/home/maxzhang/factorization-and-loops")
HERE = ROOT / (
    "External/CodexExchange/triple_root_2026-08-22/"
    "cf259_q4_rank3_oracle_2026-08-23_xh"
)
V1_TEST = HERE / "test_cf259_q4_rank3_oracle_static.py"
V1_DRIVER = HERE / "run_cf259_q4_rank3_oracle_xh_v1.wls"
V2_DRIVER = HERE / "run_cf259_q4_rank3_oracle_xh_v2.wls"
V1_POOL_SOURCE = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/pool/failed/"
    "cf259_q4_rank3_oracle_xh_v1.wl"
)
V1_POOL_STATUS = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/pool/failed/"
    "cf259_q4_rank3_oracle_xh_v1.status"
)
V1_LOG = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/pool/logs/"
    "cf259_q4_rank3_oracle_xh_v1.log"
)
V1_OUTPUT = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf259_q4_rank3_oracle_xh_v1.wl"
)
V2_OUTPUT = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf259_q4_rank3_oracle_xh_v2.wl"
)
EXPECTED = {
    V1_DRIVER: "0358739c35505923412fba0504dd9edce0eaf8daea142f7308ffcbbdeef9ee90",
    V1_TEST: "5e69088cb24a80c4fa1c6ce6cd999e6d9525ff58a9df2b842703100296884899",
    V2_DRIVER: "1812ee54af7c9f560484935a0f9fabe351874ec4fd5c8c0b34a66be95730a538",
    V1_POOL_SOURCE: "b6ff194e5f0bf5ffe7317f21732cc6a26fdbb99d427419bcb2db670ef218bf63",
    V1_POOL_STATUS: "37589830daadc68849cf907ab1ee17f0565644727889a5602b76baf9e6988ec4",
    V1_LOG: "1d05e92f130743fff78b2b0b50ac7cc5cc31a0f9a18ac5b1f17854754252dce8",
    V1_OUTPUT: "a4a3bfb9f62b15197a2cfd81599bcee30c76523a0c75833bca23583596ebc198",
}
EXPECTED_ROOT_FINGERPRINTS = [
    "d09a008f5f4a9236fea68564f9ac5c304701b788ed98380e0cb48b180ebc0d99",
    "ceb5ff034e85cb923ec5b8f122cf10057bf11654dd840b7b9db7b30faa44bd94",
    "4b6d5ab8768bb95919817d3305320d1b542db34bb3d78d16d08efad6ce5bfac5",
]
ASSERT_PATTERN = re.compile(
    r'(?<![A-Za-z0-9`])assert\[\s*"([^"]+)"\s*,', re.MULTILINE
)
EXPECTED_COUNT_PATTERN = re.compile(
    r"allPassed\s*=\s*Length\[checks\]\s*===\s*(\d+)"
)
RECORDED_COUNT_PATTERN = re.compile(
    r'"RuntimeAssertionCountExpected"\s*->\s*(\d+)'
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_v1_verifier_module():
    spec = importlib.util.spec_from_file_location("cf259_v1_static", V1_TEST)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def runtime_assertion_contract(text: str) -> tuple[bool, list[str], int, int]:
    names = ASSERT_PATTERN.findall(text)
    expected_matches = EXPECTED_COUNT_PATTERN.findall(text)
    recorded_matches = RECORDED_COUNT_PATTERN.findall(text)
    if len(expected_matches) != 1 or len(recorded_matches) != 1:
        return False, names, -1, -1
    expected = int(expected_matches[0])
    recorded = int(recorded_matches[0])
    valid = (
        len(names) == expected == recorded
        and len(set(names)) == len(names)
        and all(name.strip() == name and name for name in names)
    )
    return valid, names, expected, recorded


def main() -> int:
    v1 = load_v1_verifier_module()
    checks = 0

    for path, expected in EXPECTED.items():
        assert path.is_file(), f"missing frozen V1/V2 source: {path}"
        assert sha256(path) == expected, f"frozen artifact drift: {path}"
        checks += 1

    # Preserve and explain the V1 terminal evidence exactly.
    v1_log = V1_LOG.read_text()
    v1_status = V1_POOL_STATUS.read_text()
    v1_output = V1_OUTPUT.read_text()
    assert v1_log.count('"PASS "') == 11
    assert 'passed="11"/"\n  11"' in v1_log
    assert '"Status" -> "FAILED"' in v1_status
    assert '"Kernel" -> 145' in v1_status
    assert '"HadMessages" -> False' in v1_status
    assert '"Status" -> "CF259Q4Rank3OracleFailedV1"' in v1_output
    assert v1_output.count('"Pass" -> True') == 11
    assert all(fingerprint in v1_output for fingerprint in EXPECTED_ROOT_FINGERPRINTS)
    checks += 8

    text = V2_DRIVER.read_text()
    code = v1.strip_wolfram_comments_and_strings(text)
    v1.assert_balanced(code)
    assert not any(line.rstrip().endswith("`") for line in text.splitlines())
    assert re.findall(r"(?<![A-Za-z0-9`])(Exit|Quit)\s*\[", code) == []
    for token in [
        "RunProcess[", "StartProcess[", "LaunchKernels[", "CloseKernels[",
        "DeleteFile[", "Parallel",
    ]:
        assert token not in code, f"forbidden V2 token: {token}"
        checks += 1
    checks += 3

    valid, names, expected_count, recorded_count = runtime_assertion_contract(text)
    assert valid
    assert expected_count == recorded_count == 12
    assert len(names) == len(set(names)) == 12
    assert names == [
        "oracle_family_and_field",
        "all_seven_square_class_products_are_nonsquare",
        "q4_radical_derivatives",
        "prepared_rank3_q4_identity_frame_with_valid_abi",
        "canonical_cf259_root_order_abi_is_pinned_and_mutation_rejected",
        "expected_oracle_vector_uses_all_q4_grades",
        "forcing_exercises_all_eight_grades",
        "three_prime_exact_q4_reconstruction",
        "reconstruction_matches_constructed_oracle",
        "exact_characteristic_zero_channel_certificate",
        "all_eight_q4_sign_branches_at_unseen_prime",
        "q4_grade_corruption_is_rejected_exactly",
    ]
    checks += 4

    # The counter gate must reject missing, duplicate, and stale-count mutants.
    missing_mutant = text.replace(
        'assert["canonical_cf259_root_order_abi_is_pinned_and_mutation_rejected",',
        'ignoredAssertion["canonical_cf259_root_order_abi_is_pinned_and_mutation_rejected",',
        1,
    )
    duplicate_mutant = text.replace(
        '"canonical_cf259_root_order_abi_is_pinned_and_mutation_rejected"',
        '"oracle_family_and_field"',
        1,
    )
    expected_count_mutant = text.replace(
        "allPassed = Length[checks] === 12",
        "allPassed = Length[checks] === 11",
        1,
    )
    recorded_count_mutant = text.replace(
        '"RuntimeAssertionCountExpected" -> 12',
        '"RuntimeAssertionCountExpected" -> 13',
        1,
    )
    for mutant in [
        missing_mutant, duplicate_mutant, expected_count_mutant,
        recorded_count_mutant,
    ]:
        assert not runtime_assertion_contract(mutant)[0]
        checks += 1

    # Inspect the new assertion as an exact ABI/root-order check, not padding.
    new_start = text.index(
        'assert["canonical_cf259_root_order_abi_is_pinned_and_mutation_rejected"'
    )
    new_end = text.index("\n\n      expected =", new_start)
    new_assertion = text[new_start:new_end]
    for fingerprint in EXPECTED_ROOT_FINGERPRINTS:
        assert fingerprint in text
        checks += 1
    for token in [
        'Lookup[preparation, "RootSourceIndices", {}] === {1, 2, 3}',
        'Lookup[preparation, "RootFingerprints", {}]',
        'Lookup[preparation["ABIPayload"], "RootFingerprints", {}]',
        "TRPreparationABIValidQ[",
        "TRPreparationABICompatibleQ[",
        "rootOrderMutant",
    ]:
        assert token in new_assertion, f"weak/missing root-order token: {token}"
        checks += 1
    assert new_assertion.count("!") >= 2
    checks += 1

    # K145 remains a true pre-I/O hard gate; K146 and every type mutant fail.
    dispatch_index = text.index("$KernelID =!= 145")
    source_io_index = text.index("hashHex[sourceManifest]")
    output_io_index = text.index("FileExistsQ[outputFile]")
    assert dispatch_index < source_io_index < output_io_index
    checks += 1
    for wrong_kernel in [None, 0, 24, 141, 144, 146, "145"]:
        outcome, events = v1.modeled_dispatch_then_io(wrong_kernel)
        assert outcome == "$Failed" and events == []
        checks += 1
    assert v1.modeled_dispatch_then_io(145)[0] == "continue"
    checks += 1

    # Reuse the independently implemented finite-field model on all 24 split
    # points so V2's source-only changes cannot weaken the Q4 arithmetic gate.
    one = {(0, 0): 1}
    x_poly = {(1, 0): 1}
    y_poly = {(0, 1): 1}
    lambda1 = v1.add(
        v1.multiply(
            v1.add(v1.add(one, v1.scale(x_poly, -1)), v1.scale(y_poly, -1)),
            v1.add(v1.add(one, v1.scale(x_poly, -1)), v1.scale(y_poly, -1)),
        ),
        v1.scale(v1.multiply(x_poly, y_poly), -4),
    )
    lambda3 = v1.add(
        v1.multiply(
            v1.add(v1.add(one, v1.scale(x_poly, -1)), y_poly),
            v1.add(v1.add(one, v1.scale(x_poly, -1)), y_poly),
        ),
        v1.scale(v1.multiply(x_poly, y_poly), 4),
    )
    q4 = v1.add(v1.scale(x_poly, 4), v1.multiply(y_poly, y_poly))
    radicals = [lambda1, lambda3, q4]
    primes = [
        candidate for candidate in range(10000, 11000)
        if v1.is_prime(candidate) and candidate % 4 == 3
    ][:3]
    for prime_index, prime in enumerate(primes):
        points = v1.split_points(radicals, prime, 8)
        assert len(points) == 8
        checks += 1
        for point_index, (x_value, y_value) in enumerate(points):
            deltas = [
                v1.evaluate(poly, x_value, y_value, prime) for poly in radicals
            ]
            roots = [pow(value, (prime + 1) // 4, prime) for value in deltas]
            assert all(
                root and root * root % prime == value
                for root, value in zip(roots, deltas)
            )
            coefficients = [
                (41 * mask + 97 * point_index + 13 * prime_index + 7) % prime
                for mask in range(8)
            ]
            conjugates = v1.evaluate_conjugates(coefficients, roots, prime)
            assert v1.project_conjugates(conjugates, roots, prime) == coefficients
            checks += 2

    assert V1_OUTPUT.exists(), "V1 evidence was removed"
    assert not V2_OUTPUT.exists(), f"V2 output is not fresh: {V2_OUTPUT}"
    assert V2_OUTPUT.parent.is_dir()
    checks += 3

    print(f"PASS: {checks} CF259 Q4 V2 static/adversarial assertions")
    print(f"v2_driver_sha256={sha256(V2_DRIVER)}")
    print(f"v1_output_sha256={sha256(V1_OUTPUT)}")
    print(f"runtime_assertion_names={names}")
    print(f"fresh_v2_output={V2_OUTPUT}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
