#!/usr/bin/env python3
"""No-kernel adversarial models for the pinned CF300 exact witness design."""

from __future__ import annotations

import hashlib
import copy
from fractions import Fraction
from pathlib import Path


HERE = Path(__file__).resolve().parent
HELPER = HERE / "CF300ExactQepsLeftObstruction.wl"
RECONSTRUCTION = HERE / "CF300ModularQepsWitnessReconstruction.wl"
DRIVER = HERE / "run_cf300_sector12_exact_qeps_left_obstruction_v1.wls"


def fp(values: object) -> str:
    return hashlib.sha256(repr(values).encode()).hexdigest()


def safe_nonzero_indices(values: list[int]) -> list[int]:
    return [index for index, value in enumerate(values, start=1) if value != 0]


def has_split_context_marker(text: str) -> bool:
    return any(line.rstrip().endswith("`") for line in text.splitlines())


def buggy_head_traversal_indices(values: list[int]) -> list[int]:
    # Model the observed V6d metadata: list head contributes index 0.
    return [0] + safe_nonzero_indices(values)


def balanced(value: int, prime: int) -> int:
    value %= prime
    return value - prime if 2 * value > prime else value


def rational_lift(residue: int, prime: int) -> Fraction:
    bound = int(prime**0.5)
    candidates: list[tuple[tuple[int, int, int, int], Fraction]] = []
    for denominator in range(1, bound + 1):
        numerator = balanced(residue * denominator, prime)
        value = Fraction(numerator, denominator)
        numerator, denominator = value.numerator, value.denominator
        if denominator <= bound and (numerator - residue * denominator) % prime == 0:
            key = (max(abs(numerator), denominator), abs(numerator) + denominator,
                   denominator, numerator)
            candidates.append((key, value))
    return min(candidates)[1]


def valid_partition(pivots: list[int], free: list[int], width: int) -> bool:
    return (
        len(set(pivots)) == len(pivots)
        and len(set(free)) == len(free)
        and sorted(pivots + free) == list(range(1, width + 1))
    )


def validate_toy_plan(plan: dict[str, list[int]], rows: int, columns: int) -> bool:
    cp = plan.get("cp", [])
    cf = plan.get("cf", [])
    cr = plan.get("cr", [])
    ap = plan.get("ap", [])
    af = plan.get("af", [])
    ar = plan.get("ar", [])
    return (
        valid_partition(cp, cf, columns)
        and valid_partition(ap, af, columns + 1)
        and sorted(set(ap) - set(cp)) == [columns + 1]
        and af == cf
        and len(set(cr)) == len(cr)
        and len(set(ar)) == len(ar)
        and all(1 <= value <= rows for value in cr + ar)
    )


def validate_capture_model(capture: dict[str, object]) -> bool:
    residues = capture.get("residues")
    lifts = capture.get("lifts")
    records = capture.get("records")
    flags = capture.get("flags")
    if (
        capture.get("status") != "CF300V6dExactLiftPrerequisiteV1"
        or capture.get("v6d") != "v6d-pin"
        or capture.get("core") != "core-pin"
        or capture.get("assembly") != "assembly-pin"
        or not isinstance(residues, list)
        or not isinstance(lifts, list)
        or not isinstance(records, list)
        or len(residues) != 30
        or len(lifts) != 30
        or len(records) != 60
        or len(set(residues)) != 30
        or len(set(lifts)) != 30
        or flags != (True, True, True, True, True)
    ):
        return False
    expected_lifts = [tuple(rational_lift(value, 10007) for value in point)
                      for point in residues]
    if lifts != expected_lifts:
        return False
    for point_index in range(30):
        for coordinate_index in range(2):
            record = records[2 * point_index + coordinate_index]
            value = lifts[point_index][coordinate_index]
            residue = residues[point_index][coordinate_index]
            if record != {
                "point": point_index + 1,
                "coordinate": coordinate_index + 1,
                "residue": residue,
                "numerator": value.numerator,
                "denominator": value.denominator,
                "height": max(abs(value.numerator), value.denominator),
                "reduction": residue,
                "matches": True,
            }:
                return False
    return True


def solve_2x2(matrix: list[list[Fraction]], rhs: list[Fraction]) -> list[Fraction]:
    a, b = matrix[0]
    c, d = matrix[1]
    determinant = a * d - b * c
    if determinant == 0:
        raise ZeroDivisionError("singular")
    return [
        (rhs[0] * d - b * rhs[1]) / determinant,
        (a * rhs[1] - rhs[0] * c) / determinant,
    ]


def mod_nullspace(matrix: list[list[int]], prime: int) -> list[list[int]]:
    work = [[value % prime for value in row] for row in matrix]
    row_count, column_count = len(work), len(work[0])
    pivots: list[int] = []
    pivot_row = 0
    for column in range(column_count):
        found = next((row for row in range(pivot_row, row_count)
                      if work[row][column]), None)
        if found is None:
            continue
        work[pivot_row], work[found] = work[found], work[pivot_row]
        inverse = pow(work[pivot_row][column], -1, prime)
        work[pivot_row] = [(value * inverse) % prime
                           for value in work[pivot_row]]
        for row in range(row_count):
            if row != pivot_row and work[row][column]:
                factor = work[row][column]
                work[row] = [(left - factor * right) % prime
                             for left, right in zip(work[row], work[pivot_row])]
        pivots.append(column)
        pivot_row += 1
        if pivot_row == row_count:
            break
    free = [column for column in range(column_count) if column not in pivots]
    basis: list[list[int]] = []
    for free_column in free:
        vector = [0] * column_count
        vector[free_column] = 1
        for row, pivot in enumerate(pivots):
            vector[pivot] = (-work[row][free_column]) % prime
        basis.append(vector)
    return basis


def poly_trim(poly: list[int], prime: int) -> list[int]:
    result = [value % prime for value in poly]
    while len(result) > 1 and result[-1] == 0:
        result.pop()
    return result


def poly_divmod(numerator: list[int], denominator: list[int],
                prime: int) -> tuple[list[int], list[int]]:
    numerator = poly_trim(numerator, prime)
    denominator = poly_trim(denominator, prime)
    if denominator == [0]:
        raise ZeroDivisionError
    quotient = [0] * max(1, len(numerator) - len(denominator) + 1)
    inverse = pow(denominator[-1], -1, prime)
    while numerator != [0] and len(numerator) >= len(denominator):
        shift = len(numerator) - len(denominator)
        coefficient = numerator[-1] * inverse % prime
        quotient[shift] = coefficient
        for index, value in enumerate(denominator):
            numerator[index + shift] = (
                numerator[index + shift] - coefficient * value) % prime
        numerator = poly_trim(numerator, prime)
    return poly_trim(quotient, prime), numerator


def poly_gcd(left: list[int], right: list[int], prime: int) -> list[int]:
    left, right = poly_trim(left, prime), poly_trim(right, prime)
    while right != [0]:
        _, remainder = poly_divmod(left, right, prime)
        left, right = right, remainder
    inverse = pow(left[-1], -1, prime)
    return [(value * inverse) % prime for value in left]


def poly_eval(poly: list[int], value: int, prime: int) -> int:
    result = 0
    for coefficient in reversed(poly):
        result = (result * value + coefficient) % prime
    return result


def reduce_pair(vector: list[int], degree: int,
                prime: int) -> tuple[tuple[int, ...], tuple[int, ...]] | None:
    numerator = poly_trim(vector[:degree + 1], prime)
    denominator = poly_trim(vector[degree + 1:], prime)
    if denominator == [0]:
        return None
    divisor = poly_gcd(numerator, denominator, prime)
    numerator, numerator_remainder = poly_divmod(numerator, divisor, prime)
    denominator, denominator_remainder = poly_divmod(denominator, divisor, prime)
    if numerator_remainder != [0] or denominator_remainder != [0]:
        return None
    normalization = pow(denominator[-1], -1, prime)
    return (
        tuple(value * normalization % prime for value in numerator),
        tuple(value * normalization % prime for value in denominator),
    )


def rational_interpolation_model(data: list[tuple[int, int]], degree: int,
                                 prime: int) -> dict[str, object]:
    if len(data) != 2 * degree + 1 or len({x for x, _ in data}) != len(data):
        return {"status": "invalid"}
    if all(y % prime == 0 for _, y in data):
        return {"status": "ok", "pair": ((0,), (1,)), "nullity": None}
    matrix = [
        [pow(x, power, prime) for power in range(degree + 1)]
        + [(-y * pow(x, power, prime)) % prime
           for power in range(degree + 1)]
        for x, y in data
    ]
    basis = mod_nullspace(matrix, prime)
    reduced = [reduce_pair(vector, degree, prime) for vector in basis]
    if None in reduced or len(set(reduced)) != 1:
        return {"status": "basis-inconsistent", "nullity": len(basis)}
    numerator, denominator = reduced[0]  # type: ignore[misc]
    reduced_degrees = (len(numerator) - 1, len(denominator) - 1)
    if sum(reduced_degrees) > degree:
        return {"status": "spurious-dd", "degrees": reduced_degrees,
                "nullity": len(basis)}
    expected_nullity = min(degree - reduced_degrees[0],
                           degree - reduced_degrees[1]) + 1
    if len(basis) != expected_nullity:
        return {"status": "nullity-mismatch", "nullity": len(basis),
                "expected": expected_nullity}
    if any(poly_eval(list(denominator), x, prime) == 0 for x, _ in data):
        return {"status": "denominator-zero"}
    if any((poly_eval(list(numerator), x, prime)
            - y * poly_eval(list(denominator), x, prime)) % prime
           for x, y in data):
        return {"status": "residual"}
    return {"status": "ok", "pair": reduced[0],
            "degrees": reduced_degrees, "nullity": len(basis),
            "expected": expected_nullity}


def main() -> None:
    helper = HELPER.read_text()
    reconstruction = RECONSTRUCTION.read_text()
    driver = DRIVER.read_text()
    checks: list[tuple[str, bool]] = []

    def check(name: str, condition: bool) -> None:
        checks.append((name, bool(condition)))

    scores = [1] * 288
    safe = safe_nonzero_indices(scores)
    buggy = buggy_head_traversal_indices(scores)
    check("safe_score_count_288", len(safe) == 288)
    check("safe_score_1_based", safe[0] == 1 and safe[-1] == 288)
    check("safe_score_has_no_zero", 0 not in safe)
    check("bug_model_count_289", len(buggy) == 289)
    check("bug_model_starts_zero", buggy[0] == 0)
    check("bug_model_matches_recorded_range", buggy == list(range(0, 289)))

    plan = {
        "cp": [1], "cf": [2], "cr": [1],
        "ap": [1, 3], "af": [2], "ar": [1, 2],
    }
    check("toy_plan_valid", validate_toy_plan(plan, rows=2, columns=2))
    mutant = {**plan, "ap": [1, 2]}
    check("reject_missing_augmented_rhs_pivot", not validate_toy_plan(mutant, 2, 2))
    mutant = {**plan, "af": [1]}
    check("reject_free_column_change", not validate_toy_plan(mutant, 2, 2))
    mutant = {**plan, "ar": [1, 1]}
    check("reject_duplicate_independent_row", not validate_toy_plan(mutant, 2, 2))
    mutant = {**plan, "ar": [1, 3]}
    check("reject_out_of_range_row", not validate_toy_plan(mutant, 2, 2))
    mutant = {**plan, "cp": [2], "cf": [2]}
    check("reject_overlapping_partition", not validate_toy_plan(mutant, 2, 2))

    # Exact canonical support solve for A={{1},{1}}, b={0,1}.
    # Augmented pivot block is [[1,0],[1,1]].  The helper solves its
    # transpose against e_b and obtains y=(-1,1).
    pivot_block = [
        [Fraction(1), Fraction(0)],
        [Fraction(1), Fraction(1)],
    ]
    transposed = [list(column) for column in zip(*pivot_block)]
    witness = solve_2x2(transposed, [Fraction(0), Fraction(1)])
    a_column = [Fraction(1), Fraction(1)]
    b_column = [Fraction(0), Fraction(1)]
    check("toy_witness_canonical", witness == [Fraction(-1), Fraction(1)])
    check("toy_left_identity", sum(y * a for y, a in zip(witness, a_column)) == 0)
    check("toy_right_pairing", sum(y * b for y, b in zip(witness, b_column)) == 1)

    interpolation_prime = 101
    interpolation_degree = 4
    interpolation_x = list(range(1, 2 * interpolation_degree + 2))
    # True pair 3/(1+2z+z^3): asymmetric (0,3) with two-dimensional
    # type-(4,4) kernel.  Its basis multiples all reduce to one pair.
    asymmetric_data = []
    for x_value in interpolation_x:
        denominator = (1 + 2 * x_value + x_value**3) % interpolation_prime
        assert denominator != 0
        asymmetric_data.append((x_value,
                                3 * pow(denominator, -1,
                                        interpolation_prime)
                                % interpolation_prime))
    asymmetric = rational_interpolation_model(
        asymmetric_data, interpolation_degree, interpolation_prime)
    check("rational_interpolation_asymmetric_accepts",
          asymmetric["status"] == "ok" and asymmetric["degrees"] == (0, 3))
    check("rational_interpolation_expected_nonunit_nullity",
          asymmetric["nullity"] == 2 and asymmetric["expected"] == 2)
    asymmetric_matrix = [
        [pow(x_value, power, interpolation_prime)
         for power in range(interpolation_degree + 1)]
        + [(-y_value * pow(x_value, power, interpolation_prime))
           % interpolation_prime
           for power in range(interpolation_degree + 1)]
        for x_value, y_value in asymmetric_data
    ]
    asymmetric_basis = mod_nullspace(asymmetric_matrix, interpolation_prime)
    asymmetric_reduced = [reduce_pair(vector, interpolation_degree,
                                      interpolation_prime)
                          for vector in asymmetric_basis]
    check("rational_interpolation_basis_order_independent",
          len(set(asymmetric_reduced)) == 1 and
          reduce_pair(list(reversed(asymmetric_basis))[0],
                      interpolation_degree, interpolation_prime)
          == asymmetric_reduced[0])
    cached_pair = asymmetric_reduced[0]
    cached_numerator, cached_denominator = cached_pair
    extra_x = 10
    extra_denominator = poly_eval(list(cached_denominator), extra_x,
                                  interpolation_prime)
    extra_y = (poly_eval(list(cached_numerator), extra_x,
                         interpolation_prime)
               * pow(extra_denominator, -1, interpolation_prime)
               % interpolation_prime)
    cache_extended = asymmetric_data + [(extra_x, extra_y)]
    cache_alias_mutant = asymmetric_data + [(
        extra_x, (extra_y + 1) % interpolation_prime)]
    pair_fits = lambda pair, data: all(
        (poly_eval(list(pair[0]), x_value, interpolation_prime)
         - y_value * poly_eval(list(pair[1]), x_value,
                               interpolation_prime))
        % interpolation_prime == 0 and
        poly_eval(list(pair[1]), x_value, interpolation_prime) != 0
        for x_value, y_value in data)
    check("lower_degree_cache_revalidates_new_images",
          pair_fits(cached_pair, cache_extended))
    check("lower_degree_alias_cache_rejected",
          not pair_fits(cached_pair, cache_alias_mutant))
    origin_work = {"kernel": 1, "gcd": 1}
    cache_hit_work = {**origin_work, "kernel": 0, "gcd": 0}
    check("cache_hit_telemetry_not_double_counted",
          sum(record["kernel"] for record in
              [origin_work, cache_hit_work]) == 1 and
          sum(record["gcd"] for record in
              [origin_work, cache_hit_work]) == 1)

    constant_data = [(x_value, 7) for x_value in interpolation_x]
    constant = rational_interpolation_model(
        constant_data, interpolation_degree, interpolation_prime)
    check("rational_interpolation_underdetermined_multiples_accept",
          constant["status"] == "ok" and constant["nullity"] == 5)

    spurious_degree = 2
    spurious_x = list(range(1, 2 * spurious_degree + 2))
    spurious_data = [(x_value, pow(x_value, 5, interpolation_prime))
                     for x_value in spurious_x]
    spurious = rational_interpolation_model(
        spurious_data, spurious_degree, interpolation_prime)
    check("rational_interpolation_spurious_type_dd_rejected",
          spurious["status"] == "spurious-dd")
    check("rational_interpolation_denominator_zero_guard_model",
          any(poly_eval([-1, 1], x_value, interpolation_prime) == 0
              for x_value in spurious_x))
    check("rational_interpolation_extra_kernel_mutant_rejected",
          asymmetric["nullity"] + 1 != asymmetric["expected"])

    points = [(i + 2, 2 * i + 3) for i in range(30)]
    check("thirty_distinct_points", len(points) == 30 and len(set(points)) == 30)
    check("duplicate_point_mutant_rejected", len(set(points + [points[0]])) != 31)
    check("point_order_fingerprint_changes", fp(points) != fp(list(reversed(points))))
    check("point_value_fingerprint_changes", fp(points) != fp(points[:-1] + [(999, 999)]))

    lifted = [rational_lift(residue, 10007) for residue in [0, 1, 2, 5003, 5004, 10006]]
    check("balanced_lifts_reduce_exactly", all(
        (value.numerator - residue * value.denominator) % 10007 == 0
        for residue, value in zip([0, 1, 2, 5003, 5004, 10006], lifted)
    ))
    check("balanced_lift_denominator_bound", all(value.denominator <= 100 for value in lifted))
    check("balanced_lift_reduces_height", max(abs(lifted[3].numerator), lifted[3].denominator) < 5003)

    capture_residues = [(10 + 2 * index, 11 + 2 * index) for index in range(30)]
    capture_lifts = [tuple(rational_lift(value, 10007) for value in point)
                     for point in capture_residues]
    capture_records = []
    for point_index, point in enumerate(capture_lifts, start=1):
        for coordinate_index, value in enumerate(point, start=1):
            residue = capture_residues[point_index - 1][coordinate_index - 1]
            capture_records.append({
                "point": point_index, "coordinate": coordinate_index,
                "residue": residue, "numerator": value.numerator,
                "denominator": value.denominator,
                "height": max(abs(value.numerator), value.denominator),
                "reduction": residue, "matches": True,
            })
    capture = {
        "status": "CF300V6dExactLiftPrerequisiteV1",
        "v6d": "v6d-pin", "core": "core-pin", "assembly": "assembly-pin",
        "residues": capture_residues, "lifts": capture_lifts,
        "records": capture_records, "flags": (True, True, True, True, True),
    }
    check("strict_capture_model_accepts_fixture", validate_capture_model(capture))
    for label, mutate in [
        ("status", lambda value: value.update(status="wrong")),
        ("v6d_pin", lambda value: value.update(v6d="stale")),
        ("core_pin", lambda value: value.update(core="stale")),
        ("assembly_pin", lambda value: value.update(assembly="stale")),
        ("duplicate_point", lambda value: value["residues"].__setitem__(1, value["residues"][0])),
        ("wrong_lift", lambda value: value["lifts"].__setitem__(
            0, (Fraction(999), value["lifts"][0][1]))),
        ("record_order", lambda value: value["records"].__setitem__(slice(0, 2), list(reversed(value["records"][0:2])))),
        ("record_reduction", lambda value: value["records"][0].update(reduction=999)),
        ("record_match", lambda value: value["records"][0].update(matches=False)),
        ("capture_flag", lambda value: value.update(flags=(True, True, False, True, True))),
    ]:
        mutant = copy.deepcopy(capture)
        mutate(mutant)
        check(f"strict_capture_rejects_{label}", not validate_capture_model(mutant))

    plan_arrays = tuple(range(1, 890))
    check("plan_order_fingerprint_changes", fp(plan_arrays) != fp(tuple(reversed(plan_arrays))))
    check("plan_value_fingerprint_changes", fp(plan_arrays) != fp(plan_arrays[:-1] + (999,)))

    check("driver_missing_capture_is_terminal_status",
          "CF300ExactQepsWitnessPrerequisiteCaptureRequiredV1" in driver)
    check("driver_never_discovers_plan",
          '"PlanDiscoveryForbiddenInThisDriver" -> True' in driver and
          '"PlanDiscoveryPerformed" -> False' in driver)
    check("driver_requires_all_six_arrays",
          all(name in driver for name in [
              "CoefficientPivotColumns", "CoefficientFreeColumns",
              "CoefficientIndependentEquationRows", "AugmentedPivotColumns",
              "AugmentedFreeColumns", "AugmentedIndependentEquationRows",
          ]))
    check("helper_requires_point_hash",
          'EQWFingerprint[points]' in helper)
    check("helper_requires_plan_hashes",
          helper.count("EQWFingerprint[") >= 12)
    check("helper_requires_last_augmented_column",
          "Complement[augmentedPivots, coefficientPivots] ===" in helper and
          "{columns + 1}" in helper)
    check("helper_verifies_every_left_coordinate",
          "AllTrue[leftCertificates" in helper)
    check("helper_verifies_right_coordinate",
          'Lookup[rightCertificate, "NumeratorZero", False]' in helper)
    check("helper_no_modular_success_as_exact_success",
          "CertifiedCF300ExactQepsLeftObstructionV1" in helper and
          "ExactClearedDenominatorResidualFailed" in helper)
    check("helper_uses_explicit_safe_index_mask",
          "Pick[Range[Length[values]]" in helper)
    check("no_large_symbolic_solve", "LinearSolve[" not in helper and "LinearSolve[" not in reconstruction)
    check("source_pinned_cffa4", "CFFA4V1\\000" in reconstruction and "CFFA4X1\\000" in reconstruction)
    check("modular_full_residual", "FullModularWitnessResidualFailed" in reconstruction)
    check("degree_profile_required", "DegreeProfileStableAcrossTrainingPrimes" in reconstruction)
    check("rational_reconstruction_bound_required", "RationalReconstructionBoundSatisfied" in reconstruction)
    check("no_apriori_height_overclaim", '"APrioriCoefficientHeightBoundCertified" -> False' in reconstruction)
    check("adaptive_training_primes", '"MinimumTrainingPrimeCount" -> 4' in reconstruction and '"MaximumTrainingPrimeCount" -> 12' in reconstruction)
    check("prefix_stability_required", "PrefixReconstructionNotStable" in reconstruction)
    check("two_heldout_primes_required", '"HeldOutPrimeCount" -> 2' in reconstruction)
    check("seven_heldout_epsilon_values", '"HeldOutEpsilonValues" -> {163, 167, 173, 179, 181, 191, 193}' in reconstruction)
    check("heldout_values_disjoint",
          "Intersection[epsilonCandidates, heldOutEpsilonValues] =!= {}" in reconstruction)
    training_eps = [Fraction(1, 21), Fraction(1, 11),
                    *map(Fraction, range(2, 161))]
    heldout_eps = list(map(Fraction, [163, 167, 173, 179, 181, 191, 193]))
    modular_disjoint = True
    for image_prime in [10007, 10039, 1000003, 1000033]:
        reduce_fraction = lambda value: (
            value.numerator * pow(value.denominator, -1, image_prime)
        ) % image_prime
        training_residues = {reduce_fraction(value) for value in training_eps}
        heldout_residues = [reduce_fraction(value) for value in heldout_eps]
        modular_disjoint &= (len(set(heldout_residues)) == 7 and
                             set(heldout_residues).isdisjoint(training_residues))
    check("heldout_values_modularly_disjoint_fixture", modular_disjoint)
    check("heldout_modular_overlap_guard",
          "HeldOutTrainingEpsilonResidueOverlap" in reconstruction)
    check("single_basis_derivative_assignment", helper.count("basisDerivatives = Table[") == 1)
    check("single_training_terminal_association",
          reconstruction.count('"TrainingPrimeImagesExact" -> True|>') == 1)
    check("hard_solve_schedule",
          '"MaximumTotalNativeSolveAttempts" -> 3024' in reconstruction)
    check("degree_80_pilot_not_a_theorem",
          '"MaximumTotalEpsilonDegree" -> 80' in reconstruction and
          '"DegreeBoundDerivedFromMatrix" -> False' in reconstruction)
    check("degree_cap_skips_replayed_primes",
          "ExploratoryDegreeCapReachedAtFirstQualifiedPrime" in reconstruction and
          '"FurtherTrainingPrimesSkipped" -> True' in reconstruction)
    check("degree_evidence_uses_safe_indices",
          "failedCoordinates = Pick[Range[Length[interpolations]]" in reconstruction)
    check("one_kernel_call_per_nonzero_coordinate_stage",
          reconstruction.count("NullSpace[") == 1 and
          '"MaximumInterpolationKernelCallsPerPrime" -> 6223' in reconstruction)
    check("one_basis_reduction_per_nonzero_coordinate_stage",
          '"MaximumBasisPairReductionsPerPrime" -> 6223' in reconstruction and
          '"BasisPairReductionCount" -> 1' in reconstruction)
    check("kernel_multiple_dimension_proves_canonical_pair",
          '"KernelEqualsPolynomialMultipleSubspace" -> True' in reconstruction and
          "RationalInterpolationNullityMismatch" in reconstruction)
    check("kernel_expected_nullity_certified",
          '"ExpectedKernelNullity" -> expectedNullity' in reconstruction)
    check("kernel_does_not_assume_unit_nullity",
          "Length[nullspace] =!= 1" not in reconstruction)
    check("cache_hit_source_zeroes_work_counts",
          '"CacheRevalidatedAtDegree" -> degree' in reconstruction and
          '"KernelCallCount" -> 0' in reconstruction and
          '"BasisPairReductionCount" -> 0' in reconstruction)
    profile_fixture = ["unlucky", "generic", "generic"]
    profile_counts = {profile: profile_fixture.count(profile)
                      for profile in set(profile_fixture)}
    profile_consensus = [profile for profile, count in profile_counts.items()
                         if count >= 2]
    check("degree_profile_consensus_rejects_first_unlucky",
          profile_consensus == ["generic"])
    check("degree_profile_consensus_source_gate",
          "TwoMatchingProfilesWithinThreeQualifiedPrimes" in reconstruction and
          "ProvisionalDegreeProfileMinorityRejected" in reconstruction)
    check("actual_solve_count_telemetry", "ActualNativeSolveAttempts" in reconstruction)
    check("nonassociation_runprocess_rejected",
          '! AssociationQ[process]' in reconstruction and "NativeProcessDidNotReturnAssociation" in reconstruction)

    # Text mutants: each removes a fail-closed invariant and therefore must
    # no longer satisfy the corresponding source signature.
    no_capture_gate = driver.replace(
        "CF300ExactQepsWitnessPrerequisiteCaptureRequiredV1", "Mutated", 1)
    check("detect_capture_gate_mutant",
          "CF300ExactQepsWitnessPrerequisiteCaptureRequiredV1" not in no_capture_gate)
    discovery_mutant = driver.replace(
        '"PlanDiscoveryPerformed" -> False', '"PlanDiscoveryPerformed" -> True', 1)
    check("detect_discovery_mutant",
          '"PlanDiscoveryPerformed" -> False' not in discovery_mutant)
    score_mutant = helper.replace(
        "Pick[Range[Length[values]]", "Position[values", 1)
    check("detect_position_mutant", "Position[values" in score_mutant)
    residual_mutant = helper.replace(
        "right.witness - 1", "right.witness", 1)
    check("detect_normalization_mutant", "right.witness - 1" not in residual_mutant)
    transpose_mutant = reconstruction.replace(
        "eqmrNativeSolve[Transpose[selectedBlock], pivotRight",
        "eqmrNativeSolve[selectedBlock, pivotRight", 1)
    check("detect_orientation_mutant",
          "eqmrNativeSolve[Transpose[selectedBlock], pivotRight" not in transpose_mutant)
    zero_fill_mutant = helper.replace(
        "SparseArray[Thread[independentRows -> supportSolution], rows]",
        "supportSolution", 1)
    check("detect_zero_fill_mutant",
          "SparseArray[Thread[independentRows -> supportSolution], rows]" not in zero_fill_mutant)
    duplicate_assignment_mutant = helper.replace(
        "basisDerivatives = Table[", "basisDerivatives = Table[\n    basisDerivatives = Table[", 1)
    check("detect_duplicate_assignment_mutant",
          duplicate_assignment_mutant.count("basisDerivatives = Table[") == 2)
    cffa4_mutant = reconstruction.replace("CFFA4X1\\000", "CFFA4BAD", 1)
    check("detect_cffa4_magic_mutant", "CFFA4X1\\000" not in cffa4_mutant)
    bound_mutant = reconstruction.replace(
        "maximumHeight > reconstructionBound", "maximumHeight > modulus", 1)
    check("detect_reconstruction_bound_mutant",
          "maximumHeight > reconstructionBound" not in bound_mutant)
    heldout_mutant = reconstruction.replace(
        '"HeldOutPrimeCount" -> 2', '"HeldOutPrimeCount" -> 0', 1)
    check("detect_heldout_count_mutant",
          '"HeldOutPrimeCount" -> 2' not in heldout_mutant)
    terminal_line = '    "TrainingPrimeImagesExact" -> True|>'
    duplicate_terminal_mutant = reconstruction.replace(
        terminal_line, terminal_line + "\n" + terminal_line, 1)
    check("detect_duplicate_terminal_association_mutant",
          duplicate_terminal_mutant.count('"TrainingPrimeImagesExact" -> True|>') == 2)
    runprocess_mutant = reconstruction.replace(
        '! AssociationQ[process]', 'False', 1)
    check("detect_runprocess_type_guard_mutant",
          '! AssociationQ[process]' not in runprocess_mutant)
    split_context_mutant = driver.replace(
        "CodexCF300ExactQepsLeftObstruction`EQWPrerequisiteValidQ",
        "CodexCF300ExactQepsLeftObstruction`\nEQWPrerequisiteValidQ", 1)
    check("detect_split_context_marker_mutant",
          has_split_context_marker(split_context_mutant) and
          not has_split_context_marker(driver))

    failures = [name for name, ok in checks if not ok]
    if failures:
        raise SystemExit(f"FAIL {len(failures)}/{len(checks)}: {', '.join(failures)}")
    print(f"PASS {len(checks)}/{len(checks)} adversarial no-kernel checks")


if __name__ == "__main__":
    main()
