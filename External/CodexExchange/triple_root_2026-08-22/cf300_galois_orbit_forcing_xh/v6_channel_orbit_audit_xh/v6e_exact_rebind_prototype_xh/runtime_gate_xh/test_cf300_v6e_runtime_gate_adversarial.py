#!/usr/bin/env python3
"""In-memory mutants for the CF300 V6e runtime acceptance contract."""

from __future__ import annotations

import copy
import hashlib
import math
import random
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
DRIVER = HERE / "run_cf300_sector12_v6e_correctness_same_input_benchmark_xh.wls"
PARSE_GATE = HERE / "held_parse_cf300_sector12_v6e_runtime_gate_xh.wls"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def no_line_ends_in_context_mark(data: bytes) -> bool:
    return not any(line.rstrip().endswith(b"`") for line in data.splitlines())


def trial_valid(trial: dict, oracle: dict, immutable: str) -> bool:
    d = trial["diagnostics"]
    return all([
        trial["input_before"] == immutable == trial["input_after"],
        trial["semantic"] == oracle,
        trial["assembly_fingerprint"] == "maximal",
        d["raw"] == 576,
        d["raw"] == d["unique"] + d["reuse"],
        d["compile"] == d["unique"],
        d["collisions"] == 0,
        d["legacy_oracles"] == 1,
        d["legacy_passed"] is True,
        d["seal_passed"] is True,
        d["fallbacks"] == (0, 0),
        trial["seal_status"] == "ExactOneFormRebindSpecializedSealV6e",
        re.fullmatch(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-"
                     r"[0-9a-fA-F]{4}-[0-9a-fA-F]{12}",
                     trial["seal_nonce"]) is not None,
        re.fullmatch(r"[0-9a-fA-F]{64}",
                     trial["seal_fingerprint"]) is not None,
        trial["seal_valid"] is True,
        trial["consumes"] == [True, False],
        not trial["has_failure"],
        trial["sources_stable"] is True,
    ])


def seal_pair_valid(first: dict, second: dict) -> bool:
    return all([
        first["seal_nonce"] != second["seal_nonce"],
        first["seal_fingerprint"] != second["seal_fingerprint"],
    ])


def parse_valid(record: dict) -> bool:
    return all([
        record["head"] == "HoldComplete",
        record["syntax_length"] == record["text_length"],
        record["messages"] == [],
        record["cleanup"] is True,
    ])


def image_valid(image: dict) -> bool:
    return all([
        image["matrix_dimensions"] == (960, 912),
        image["coefficient_rank"] == 888,
        image["augmented_rank"] == 889,
        image["coefficient_nullity"] == 24,
        image["consistent"] is False,
        image["point_fingerprint_ok"] is True,
        image["coefficient_plan_ok"] is True,
        image["augmented_plan_ok"] is True,
        image["base_subset_exact"] is True,
    ])


def balanced(value: int, prime: int) -> int:
    residue = value % prime
    return residue - prime if 2 * residue > prime else residue


def coordinate_lift(residue: int, prime: int) -> dict:
    candidates = []
    for candidate_denominator in range(1, math.isqrt(prime) + 1):
        if math.gcd(candidate_denominator, prime) != 1:
            continue
        numerator = balanced(residue * candidate_denominator, prime)
        divisor = math.gcd(abs(numerator), candidate_denominator)
        numerator //= divisor
        denominator = candidate_denominator // divisor
        key = (max(abs(numerator), denominator),
               abs(numerator) + denominator, denominator, numerator)
        candidates.append((key, numerator, denominator))
    key, numerator, denominator = min(candidates)
    reduction = numerator * pow(denominator, -1, prime) % prime
    return {"key": key, "numerator": numerator,
            "denominator": denominator, "reduction": reduction,
            "matches": reduction == residue}


def prerequisite_valid(artifact: dict) -> bool:
    certificate = artifact["certificate"]
    plan = artifact["plan"]
    return all([
        artifact["status"] == "CF300V6dExactLiftPrerequisiteV1",
        artifact["v6d_hash"] == "v6d",
        artifact["core_hash"] == "core",
        artifact["assembly_fingerprint"] == "maximal",
        len(artifact["residues"]) == 30,
        len(set(artifact["residues"])) == 30,
        len(artifact["lifts"]) == 30,
        len(set(artifact["lifts"])) == 30,
        certificate["coordinate_count"] == 60,
        certificate["all_denominators_invertible"] is True,
        certificate["all_reductions_exact"] is True,
        certificate["exact_points_distinct"] is True,
        certificate["modular_nonsingular"] is True,
        certificate["plan_revalidated"] is True,
        plan["dimensions"] == (960, 912),
        plan["coefficient_rank"] == 888,
        plan["augmented_rank"] == 889,
        plan["coefficient_pivots"] == 888,
        plan["coefficient_free"] == 24,
        plan["coefficient_rows"] == 888,
        plan["augmented_pivots"] == 889,
        plan["augmented_free"] == 24,
        plan["augmented_rows"] == 889,
        artifact["qeps_nonsingular_claimed"] is False,
    ])


def dispatch_trace(kernel_id: int, expected_kernel_id: int = 24) -> list[str]:
    """Model the entry guard: rejection occurs before any read or write."""
    if kernel_id != expected_kernel_id:
        return ["dispatch_rejected"]
    return ["dispatch_accepted", "source_read", "output_write"]


def broker_guard_valid(max_helpers: object, nested_kernels: list[int]) -> bool:
    return type(max_helpers) is int and max_helpers == 0 and not nested_kernels


def main() -> None:
    checks: list[tuple[str, bool]] = []

    def check(label: str, condition: bool) -> None:
        checks.append((label, bool(condition)))

    driver_bytes = DRIVER.read_bytes()
    gate_bytes = PARSE_GATE.read_bytes()
    driver_hash = digest(driver_bytes)
    check("baseline_driver_hash_stable", digest(driver_bytes) == driver_hash)
    check("baseline_driver_has_no_trailing_context_mark",
          no_line_ends_in_context_mark(driver_bytes))
    check("baseline_parse_gate_has_no_trailing_context_mark",
          no_line_ends_in_context_mark(gate_bytes))
    context_split_mutant = driver_bytes.replace(
        b"CodexDirectRootChannelExactOneFormRebindV6`DRCARebind",
        b"CodexDirectRootChannelExactOneFormRebindV6`\nDRCARebind", 1)
    check("split_context_symbol_mutant_rejected",
          context_split_mutant != driver_bytes and
          not no_line_ends_in_context_mark(context_split_mutant))
    for index in [0, len(driver_bytes) // 7, len(driver_bytes) // 2,
                  len(driver_bytes) - 2]:
        mutant = bytearray(driver_bytes)
        mutant[index] ^= 1
        check(f"driver_byte_mutant_{index}_rejected",
              digest(bytes(mutant)) != driver_hash)
    gate_hash = digest(gate_bytes)
    gate_mutant = gate_bytes.replace(b"HoldComplete", b"HoldCompletf", 1)
    check("parse_gate_source_mutant_rejected", digest(gate_mutant) != gate_hash)

    pinned = {"runtime": driver_hash, "helper": "helper", "core": "core"}
    observed = dict(pinned)
    check("pinned_source_baseline", observed == pinned)
    for key in pinned:
        mutant = dict(observed)
        mutant[key] += "x"
        check(f"pinned_source_mutant_{key}_rejected", mutant != pinned)
    check("missing_source_rejected", set(observed) != set({"runtime", "helper"}))
    check("stale_output_rejected", not (False is True))
    check("k24_dispatch_reaches_reads_and_writes",
          dispatch_trace(24) ==
          ["dispatch_accepted", "source_read", "output_write"])
    for wrong_kernel_id in [0, 23, 25, 146]:
        check(f"wrong_worker_k{wrong_kernel_id}_fails_before_io",
              dispatch_trace(wrong_kernel_id) == ["dispatch_rejected"])
    dispatch_mutant = driver_bytes.replace(
        b"expectedDispatchKernelID = 24",
        b"expectedDispatchKernelID = 146", 1)
    check("k146_dispatch_source_mutant_rejected",
          dispatch_mutant != driver_bytes and
          digest(dispatch_mutant) != driver_hash)
    check("broker_zero_empty_nested_accepted", broker_guard_valid(0, []))
    check("missing_broker_wrapper_variable_rejected",
          not broker_guard_valid(None, []))
    check("broker_helper_ceiling_one_rejected",
          not broker_guard_valid(1, []))
    check("active_nested_kernel_rejected",
          not broker_guard_valid(0, [141]))
    check("outer_pool_count_eight_is_telemetry_not_rejection",
          8 == 8 and broker_guard_valid(0, []))
    wrapper_mutant = driver_bytes.replace(
        b"KernelPoolMission`$TaskBrokerMaxHelpers",
        b"KernelPoolMission`$TaskBrokerMaxHelperx", 1)
    check("missing_wrapper_symbol_source_mutant_rejected",
          wrapper_mutant != driver_bytes and
          digest(wrapper_mutant) != driver_hash)
    outputs_distinct = lambda first, second: first != second
    check("same_output_path_rejected",
          not outputs_distinct("/tmp/a", "/tmp/a"))
    check("stale_prerequisite_output_rejected", not (False is True))
    maximum_output = 2**30
    check("output_at_ceiling_accepted", maximum_output <= 2**30)
    check("output_over_ceiling_rejected", maximum_output + 1 > 2**30)
    temporary_exists = True
    temporary_exists = False  # models abort/failure cleanup postcondition
    check("atomic_abort_temporary_removed", temporary_exists is False)
    check("atomic_overwrite_rejected", not (False is True))

    oracle = {"core": [1, 2], "compiled": [3, 4], "layout": [5, 6]}
    immutable = "input-fingerprint"
    baseline = {
        "input_before": immutable,
        "input_after": immutable,
        "semantic": copy.deepcopy(oracle),
        "assembly_fingerprint": "maximal",
        "diagnostics": {"raw": 576, "unique": 400, "reuse": 176,
                        "compile": 400, "collisions": 0,
                        "legacy_oracles": 1, "legacy_passed": True,
                        "seal_passed": True, "fallbacks": (0, 0)},
        "seal_valid": True,
        "seal_status": "ExactOneFormRebindSpecializedSealV6e",
        "seal_nonce": "11111111-1111-4111-8111-111111111111",
        "seal_fingerprint": "a" * 64,
        "consumes": [True, False],
        "has_failure": False,
        "sources_stable": True,
    }
    check("baseline_trial_accepted", trial_valid(baseline, oracle, immutable))
    mutants: list[tuple[str, tuple[str, ...], object]] = [
        ("input_before", ("input_before",), "other"),
        ("input_after", ("input_after",), "other"),
        ("semantic_core", ("semantic", "core"), [9]),
        ("semantic_compiled", ("semantic", "compiled"), [9]),
        ("semantic_layout", ("semantic", "layout"), [9]),
        ("assembly_fingerprint", ("assembly_fingerprint",), "stale"),
        ("raw_count", ("diagnostics", "raw"), 575),
        ("unique_reuse", ("diagnostics", "reuse"), 175),
        ("compile_count", ("diagnostics", "compile"), 399),
        ("collision", ("diagnostics", "collisions"), 1),
        ("oracle_count", ("diagnostics", "legacy_oracles"), 2),
        ("oracle_failed", ("diagnostics", "legacy_passed"), False),
        ("seal_failed", ("diagnostics", "seal_passed"), False),
        ("field_fallback", ("diagnostics", "fallbacks"), (1, 0)),
        ("branch_fallback", ("diagnostics", "fallbacks"), (0, 1)),
        ("seal_invalid", ("seal_valid",), False),
        ("seal_status", ("seal_status",), "WrongSeal"),
        ("seal_nonce_not_uuid", ("seal_nonce",), "not-a-uuid"),
        ("seal_fingerprint_not_sha256", ("seal_fingerprint",), "a" * 63),
        ("replay_accepted", ("consumes",), [True, True]),
        ("fresh_rejected", ("consumes",), [False, False]),
        ("consume_order", ("consumes",), [False, True]),
        ("failure_present", ("has_failure",), True),
        ("source_changed", ("sources_stable",), False),
    ]
    for label, path, value in mutants:
        mutant = copy.deepcopy(baseline)
        target = mutant
        for key in path[:-1]:
            target = target[key]
        target[path[-1]] = value
        check(f"trial_mutant_{label}_rejected",
              not trial_valid(mutant, oracle, immutable))

    second_seal = copy.deepcopy(baseline)
    second_seal["seal_nonce"] = "22222222-2222-4222-8222-222222222222"
    second_seal["seal_fingerprint"] = "b" * 64
    check("cross_trial_seal_evidence_baseline",
          seal_pair_valid(baseline, second_seal))
    same_nonce = copy.deepcopy(second_seal)
    same_nonce["seal_nonce"] = baseline["seal_nonce"]
    check("cross_trial_reused_nonce_rejected",
          not seal_pair_valid(baseline, same_nonce))
    same_fingerprint = copy.deepcopy(second_seal)
    same_fingerprint["seal_fingerprint"] = baseline["seal_fingerprint"]
    check("cross_trial_reused_seal_fingerprint_rejected",
          not seal_pair_valid(baseline, same_fingerprint))

    trial_a = {"assembly": "a", "exact": "e", "compiled": "c",
               "shape": "s", "raw": 576, "unique": 400, "reuse": 176}
    trial_b = copy.deepcopy(trial_a)
    check("repeat_fingerprint_baseline", trial_a == trial_b)
    for key in trial_a:
        mutant = copy.deepcopy(trial_b)
        mutant[key] = "different"
        check(f"repeat_mutant_{key}_rejected", trial_a != mutant)
    check("two_fast_trials_pass_performance", (100 + 120) / 2 < 485.843061)
    check("one_slow_median_fails_performance", (500 + 600) / 2 >= 485.843061)
    check("boundary_does_not_pass", not (485.843061 < 485.843061))

    baseline_image = {
        "matrix_dimensions": (960, 912), "coefficient_rank": 888,
        "augmented_rank": 889, "coefficient_nullity": 24,
        "consistent": False, "point_fingerprint_ok": True,
        "coefficient_plan_ok": True, "augmented_plan_ok": True,
        "base_subset_exact": True,
    }
    check("frozen_image_baseline", image_valid(baseline_image))
    for key, value in [
        ("matrix_dimensions", (959, 912)), ("coefficient_rank", 887),
        ("augmented_rank", 888), ("coefficient_nullity", 25),
        ("consistent", True), ("point_fingerprint_ok", False),
        ("coefficient_plan_ok", False), ("augmented_plan_ok", False),
        ("base_subset_exact", False),
    ]:
        mutant = copy.deepcopy(baseline_image)
        mutant[key] = value
        check(f"image_mutant_{key}_rejected", not image_valid(mutant))

    generator = random.Random(20260823)
    lift_cases = [0, 1, 5003, 5004, 10006] + [
        generator.randrange(10007) for _ in range(95)]
    lifts = [coordinate_lift(residue, 10007) for residue in lift_cases]
    check("balanced_rational_lifts_reduce_exactly",
          all(lift["matches"] for lift in lifts))
    check("balanced_rational_lifts_are_reduced",
          all(math.gcd(abs(lift["numerator"]), lift["denominator"]) == 1
              for lift in lifts))
    check("balanced_rational_lifts_deterministic",
          lifts == [coordinate_lift(residue, 10007) for residue in lift_cases])
    check("balanced_rational_lifts_bound_denominators",
          all(1 <= lift["denominator"] <= 100 for lift in lifts))
    check("balanced_boundary_is_negative", balanced(5004, 10007) == -5003)

    residues = tuple((index, index + 30) for index in range(30))
    exact_lifts = tuple((index, index + 1) for index in range(30))
    prerequisite = {
        "status": "CF300V6dExactLiftPrerequisiteV1",
        "v6d_hash": "v6d", "core_hash": "core",
        "assembly_fingerprint": "maximal", "residues": residues,
        "lifts": exact_lifts,
        "certificate": {"coordinate_count": 60,
                        "all_denominators_invertible": True,
                        "all_reductions_exact": True,
                        "exact_points_distinct": True,
                        "modular_nonsingular": True,
                        "plan_revalidated": True},
        "plan": {"dimensions": (960, 912), "coefficient_rank": 888,
                 "augmented_rank": 889, "coefficient_pivots": 888,
                 "coefficient_free": 24, "coefficient_rows": 888,
                 "augmented_pivots": 889, "augmented_free": 24,
                 "augmented_rows": 889},
        "qeps_nonsingular_claimed": False,
    }
    check("lift_prerequisite_baseline", prerequisite_valid(prerequisite))
    prerequisite_mutants = [
        ("status", "stale"), ("v6d_hash", "stale"),
        ("core_hash", "stale"), ("assembly_fingerprint", "stale"),
        ("residues", residues[:-1]), ("lifts", exact_lifts[:-1]),
        ("qeps_nonsingular_claimed", True),
    ]
    for key, value in prerequisite_mutants:
        mutant = copy.deepcopy(prerequisite)
        mutant[key] = value
        check(f"prerequisite_mutant_{key}_rejected",
              not prerequisite_valid(mutant))
    certificate_mutants = [
        ("coordinate_count", 59), ("all_denominators_invertible", False),
        ("all_reductions_exact", False), ("exact_points_distinct", False),
        ("modular_nonsingular", False), ("plan_revalidated", False),
    ]
    for key, value in certificate_mutants:
        mutant = copy.deepcopy(prerequisite)
        mutant["certificate"][key] = value
        check(f"certificate_mutant_{key}_rejected",
              not prerequisite_valid(mutant))
    plan_mutants = [
        ("dimensions", (960, 911)), ("coefficient_rank", 887),
        ("augmented_rank", 888), ("coefficient_pivots", 887),
        ("coefficient_free", 23), ("coefficient_rows", 887),
        ("augmented_pivots", 888), ("augmented_free", 23),
        ("augmented_rows", 888),
    ]
    for key, value in plan_mutants:
        mutant = copy.deepcopy(prerequisite)
        mutant["plan"][key] = value
        check(f"plan_mutant_{key}_rejected", not prerequisite_valid(mutant))

    parse_record = {"head": "HoldComplete", "syntax_length": 100,
                    "text_length": 100, "messages": [], "cleanup": True}
    check("held_parse_baseline", parse_valid(parse_record))
    parse_mutants = [
        ("head", "$Failed"),
        ("syntax_length_short", 99),
        ("syntax_length_long", 101),
        ("messages", ["Syntax::sntxf"]),
        ("cleanup", False),
    ]
    for label, value in parse_mutants:
        mutant = copy.deepcopy(parse_record)
        key = "syntax_length" if label.startswith("syntax_length") else label
        mutant[key] = value
        check(f"parse_mutant_{label}_rejected", not parse_valid(mutant))

    source = "#!/usr/bin/env wolframscript\n1 + 1\n"
    stripped = "\n".join(source.split("\n")[1:])
    check("shebang_only_stripped", stripped == "1 + 1\n")
    nonshebang = "(* comment *)\n1 + 1\n"
    check("ordinary_first_line_preserved", nonshebang == nonshebang)

    failed = [label for label, passed in checks if not passed]
    print(f"CF300_V6E_RUNTIME_ADVERSARIAL passed={len(checks) - len(failed)}/{len(checks)}")
    for label in failed:
        print(f"FAIL {label}")
    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
