#!/usr/bin/env python3
"""Adversarial finite-field jet model for the V6 channel/Galois algebra.

This test launches no Wolfram process.  Second-order bivariate jets over two
primes model exact rational-function values and derivatives.  They test the
same multiplication, root-log derivative, field inverse, dlog, closure, and
Galois character identities used by GaloisChannelOrbitCoreV6.wl.
"""

from __future__ import annotations

from dataclasses import dataclass
import random
import sys


@dataclass(frozen=True)
class Jet:
    p: int
    v: int = 0
    dx: int = 0
    dy: int = 0
    dxx: int = 0
    dxy: int = 0
    dyy: int = 0

    def __post_init__(self) -> None:
        for name in ("v", "dx", "dy", "dxx", "dxy", "dyy"):
            object.__setattr__(self, name, getattr(self, name) % self.p)

    @classmethod
    def c(cls, p: int, value: int) -> "Jet":
        return cls(p, value)

    @classmethod
    def x(cls, p: int, value: int) -> "Jet":
        return cls(p, value, dx=1)

    @classmethod
    def y(cls, p: int, value: int) -> "Jet":
        return cls(p, value, dy=1)

    def coerce(self, other: int | "Jet") -> "Jet":
        if isinstance(other, Jet):
            if other.p != self.p:
                raise ValueError("mixed characteristics")
            return other
        return Jet.c(self.p, other)

    def __add__(self, other: int | "Jet") -> "Jet":
        b = self.coerce(other)
        return Jet(self.p, self.v + b.v, self.dx + b.dx, self.dy + b.dy,
                   self.dxx + b.dxx, self.dxy + b.dxy,
                   self.dyy + b.dyy)

    __radd__ = __add__

    def __neg__(self) -> "Jet":
        return Jet(self.p, -self.v, -self.dx, -self.dy, -self.dxx,
                   -self.dxy, -self.dyy)

    def __sub__(self, other: int | "Jet") -> "Jet":
        return self + (-self.coerce(other))

    def __rsub__(self, other: int | "Jet") -> "Jet":
        return self.coerce(other) - self

    def __mul__(self, other: int | "Jet") -> "Jet":
        b = self.coerce(other)
        return Jet(
            self.p,
            self.v * b.v,
            self.dx * b.v + self.v * b.dx,
            self.dy * b.v + self.v * b.dy,
            self.dxx * b.v + 2 * self.dx * b.dx + self.v * b.dxx,
            self.dxy * b.v + self.dx * b.dy + self.dy * b.dx
            + self.v * b.dxy,
            self.dyy * b.v + 2 * self.dy * b.dy + self.v * b.dyy,
        )

    __rmul__ = __mul__

    def inverse(self) -> "Jet":
        if self.v == 0:
            raise ZeroDivisionError("nonunit jet")
        p = self.p
        iv = pow(self.v, -1, p)
        iv2 = iv * iv
        iv3 = iv2 * iv
        return Jet(
            p,
            iv,
            -self.dx * iv2,
            -self.dy * iv2,
            2 * self.dx * self.dx * iv3 - self.dxx * iv2,
            2 * self.dx * self.dy * iv3 - self.dxy * iv2,
            2 * self.dy * self.dy * iv3 - self.dyy * iv2,
        )

    def __truediv__(self, other: int | "Jet") -> "Jet":
        return self * self.coerce(other).inverse()

    def __rtruediv__(self, other: int | "Jet") -> "Jet":
        return self.coerce(other) / self

    def diff(self, axis: int) -> "Jet":
        if axis == 0:
            return Jet(self.p, self.dx, self.dxx, self.dxy)
        if axis == 1:
            return Jet(self.p, self.dy, self.dxy, self.dyy)
        raise ValueError(axis)

    def first_equal(self, other: "Jet") -> bool:
        return (self.v, self.dx, self.dy) == (other.v, other.dx, other.dy)


def bit_parity(value: int) -> int:
    return value.bit_count() & 1


def char_sign(mask: int, grade: int) -> int:
    return -1 if bit_parity(mask & grade) else 1


def action(channels: list[Jet], mask: int) -> list[Jet]:
    return [char_sign(mask, grade) * value
            for grade, value in enumerate(channels)]


def mask_factor(mask: int, values: list[Jet]) -> Jet:
    out = Jet.c(values[0].p, 1)
    for bit, value in enumerate(values):
        if (mask >> bit) & 1:
            out *= value
    return out


def multiply(a: list[Jet], b: list[Jet], deltas: list[Jet]) -> list[Jet]:
    rank = len(deltas)
    size = 1 << rank
    out = [Jet.c(deltas[0].p, 0) for _ in range(size)]
    for left in range(size):
        for right in range(size):
            term = a[left] * b[right] * mask_factor(left & right, deltas)
            out[left ^ right] += term
    return out


def derivative(a: list[Jet], deltas: list[Jet], axis: int) -> list[Jet]:
    p = deltas[0].p
    half = Jet.c(p, pow(2, -1, p))
    out: list[Jet] = []
    for grade, coefficient in enumerate(a):
        log_derivative = Jet.c(p, 0)
        for bit, delta in enumerate(deltas):
            if (grade >> bit) & 1:
                log_derivative += delta.diff(axis) / delta
        out.append(coefficient.diff(axis) +
                   coefficient * half * log_derivative)
    return out


def solve(matrix: list[list[Jet]], right: list[Jet]) -> list[Jet]:
    n = len(right)
    augmented = [row[:] + [right[i]] for i, row in enumerate(matrix)]
    for col in range(n):
        pivot = next((row for row in range(col, n)
                      if augmented[row][col].v != 0), None)
        if pivot is None:
            raise ZeroDivisionError("singular field multiplication matrix")
        augmented[col], augmented[pivot] = augmented[pivot], augmented[col]
        inv = augmented[col][col].inverse()
        augmented[col] = [entry * inv for entry in augmented[col]]
        for row in range(n):
            if row == col:
                continue
            factor = augmented[row][col]
            if factor.v or factor.dx or factor.dy or factor.dxx or \
                    factor.dxy or factor.dyy:
                augmented[row] = [a - factor * b for a, b in
                                  zip(augmented[row], augmented[col])]
    return [augmented[row][-1] for row in range(n)]


def field_inverse(a: list[Jet], deltas: list[Jet]) -> list[Jet]:
    size = len(a)
    p = deltas[0].p
    columns = []
    for col in range(size):
        unit = [Jet.c(p, int(row == col)) for row in range(size)]
        columns.append(multiply(a, unit, deltas))
    matrix = [[columns[col][row] for col in range(size)]
              for row in range(size)]
    right = [Jet.c(p, int(row == 0)) for row in range(size)]
    return solve(matrix, right)


def compose(channels: list[Jet], roots: list[Jet]) -> Jet:
    out = Jet.c(roots[0].p, 0)
    for grade, coefficient in enumerate(channels):
        out += coefficient * mask_factor(grade, roots)
    return out


def random_function(rng: random.Random, x: Jet, y: Jet) -> Jet:
    p = x.p
    c = [rng.randrange(1, p) for _ in range(8)]
    numerator = (c[0] + c[1] * x + c[2] * y + c[3] * x * y
                 + c[4] * x * x + c[5] * y * y)
    denominator = c[6] + x + c[7] * y + x * y
    if denominator.v == 0:
        denominator += 1
    return numerator / denominator


def equal_vectors(a: list[Jet], b: list[Jet]) -> bool:
    return a == b


def unit_vector(p: int, size: int) -> list[Jet]:
    return [Jet.c(p, int(index == 0)) for index in range(size)]


def run_trial(rng: random.Random, p: int) -> None:
    x = Jet.x(p, rng.randrange(2, p - 1))
    y = Jet.y(p, rng.randrange(2, p - 1))
    roots = [random_function(rng, x, y), random_function(rng, x, y)]
    if any(root.v == 0 for root in roots):
        raise ZeroDivisionError("zero sampled root")
    deltas = [root * root for root in roots]
    potential = [random_function(rng, x, y) for _ in range(4)]
    inverse = field_inverse(potential, deltas)
    assert equal_vectors(multiply(potential, inverse, deltas),
                         unit_vector(p, 4))
    derivatives = [derivative(potential, deltas, axis) for axis in (0, 1)]
    dlog = [multiply(inverse, item, deltas) for item in derivatives]
    for axis in (0, 1):
        assert equal_vectors(multiply(potential, dlog[axis], deltas),
                             derivatives[axis])
    closure = [a - b for a, b in zip(
        derivative(dlog[1], deltas, 0),
        derivative(dlog[0], deltas, 1))]
    assert all(value.v == 0 for value in closure)

    direct = compose(potential, roots)
    for axis in (0, 1):
        direct_dlog = direct.diff(axis) / direct
        channel_dlog = compose(dlog[axis], roots)
        assert direct_dlog.first_equal(channel_dlog)

    for mask in range(4):
        sigma_p = action(potential, mask)
        sigma_inverse = action(inverse, mask)
        assert equal_vectors(field_inverse(sigma_p, deltas), sigma_inverse)
        for axis in (0, 1):
            assert equal_vectors(derivative(sigma_p, deltas, axis),
                                 action(derivatives[axis], mask))
            sigma_dlog = action(dlog[axis], mask)
            assert equal_vectors(
                multiply(sigma_p, sigma_dlog, deltas),
                action(derivatives[axis], mask))
            signed_roots = [char_sign(mask, 1 << bit) * root
                            for bit, root in enumerate(roots)]
            direct_sigma = compose(potential, signed_roots)
            channel_sigma = compose(sigma_p, roots)
            assert direct_sigma == channel_sigma
            direct_sigma_dlog = direct_sigma.diff(axis) / direct_sigma
            assert direct_sigma_dlog.first_equal(
                compose(sigma_dlog, roots))
        assert equal_vectors(action(action(potential, mask), mask), potential)

    for left in range(4):
        for right in range(4):
            assert equal_vectors(action(action(potential, left), right),
                                 action(potential, left ^ right))
            assert equal_vectors(
                action(multiply(potential, dlog[0], deltas), left),
                multiply(action(potential, left), action(dlog[0], left),
                         deltas))


def exact_character_census() -> int:
    checks = 0
    for rank in (1, 2, 3):
        size = 1 << rank
        for mask in range(size):
            for grade in range(size):
                assert char_sign(mask, grade) ** 2 == 1
                checks += 1
            for left in range(size):
                for right in range(size):
                    assert (char_sign(mask, left) * char_sign(mask, right)
                            == char_sign(mask, left ^ right))
                    checks += 1
        for left_mask in range(size):
            for right_mask in range(size):
                for grade in range(size):
                    assert (char_sign(left_mask, grade)
                            * char_sign(right_mask, grade)
                            == char_sign(left_mask ^ right_mask, grade))
                    checks += 1
    # An overlap/non-parity implementation must be rejected: grade 3 under
    # mask 3 has two sign flips and therefore positive character.
    wrong_sign = lambda mask, grade: -1 if (mask & grade) else 1
    assert wrong_sign(3, 3) != char_sign(3, 3)
    assert wrong_sign(3, 1) * wrong_sign(3, 2) != wrong_sign(3, 3)
    return checks + 2


def stabilizer_adversaries(p: int) -> int:
    zero = Jet.c(p, 0)
    one = Jet.c(p, 1)
    grade_zero = [one, zero, zero, zero]
    assert len({tuple(action(grade_zero, mask)) for mask in range(4)}) == 1
    product_grade = [one, zero, zero, one]
    orbit = {tuple(action(product_grade, mask)) for mask in range(4)}
    assert len(orbit) == 2
    singleton_grade = [one, one, zero, zero]
    orbit = {tuple(action(singleton_grade, mask)) for mask in range(4)}
    assert len(orbit) == 2
    return 3


def exact_channel_rebind_model(
        base_channels: list[list[list[Jet]]],
        target_forms: list[list[Jet]],
        appended_channels: list[list[list[Jet]]],
        roots: list[Jet],
        equation_core: tuple[object, ...]) -> tuple[
            list[list[list[Jet]]], tuple[object, ...]]:
    """Small semantic oracle for the specialized one-form-only rebind."""
    base_count = len(base_channels)
    if len(target_forms) != base_count + len(appended_channels):
        raise ValueError("shape")
    for offset, channels in enumerate(appended_channels):
        if len(channels) != 2 or any(len(component) != 4
                                     for component in channels):
            raise ValueError("channel shape")
        composed = [compose(component, roots) for component in channels]
        target = target_forms[base_count + offset]
        if not all(left.first_equal(right)
                   for left, right in zip(composed, target)):
            raise ValueError("composition mismatch")
    return base_channels + appended_channels, equation_core


def exact_rebind_adversaries(p: int) -> int:
    x = Jet.x(p, 17)
    y = Jet.y(p, 29)
    roots = [2 + x + y, 5 + x * y]
    zero = Jet.c(p, 0)
    one = Jet.c(p, 1)
    base = [[[one, zero, zero, zero],
             [zero, one, zero, zero]]]
    suffix_a = [[x, y, one, zero], [y, x, zero, one]]
    suffix_b = [[x * y, one, x, y], [one, x * y, y, x]]
    appended = [suffix_a, suffix_b]
    base_forms = [[compose(component, roots) for component in base[0]]]
    suffix_forms = [[compose(component, roots) for component in item]
                    for item in appended]
    target = base_forms + suffix_forms
    core = ("E", "C", "BBar", "roots", "denominator")
    rebound, returned_core = exact_channel_rebind_model(
        base, target, appended, roots, core)
    assert rebound[:len(base)] == base
    assert rebound[len(base):] == appended
    assert returned_core is core
    checks = 3

    mutated = [[component[:] for component in item] for item in appended]
    mutated[0][0][3] += 1
    try:
        exact_channel_rebind_model(base, target, mutated, roots, core)
        raise AssertionError("mutated channel accepted")
    except ValueError as error:
        assert str(error) == "composition mismatch"
        checks += 1
    try:
        exact_channel_rebind_model(base, target,
                                   list(reversed(appended)), roots, core)
        raise AssertionError("reordered channels accepted")
    except ValueError as error:
        assert str(error) == "composition mismatch"
        checks += 1
    try:
        exact_channel_rebind_model(base, target,
                                   [[[one], [one]]], roots, core)
        raise AssertionError("bad channel shape accepted")
    except ValueError as error:
        assert str(error) in {"shape", "channel shape"}
        checks += 1
    return checks


def build_occurrence_source_certificate(
        fingerprints: list[int], *, metadata_unique: int = 28,
        sign_masks: int = 4) -> dict[str, object]:
    ordered_unique = list(dict.fromkeys(fingerprints))
    occurrence_counts = [fingerprints.count(value)
                         for value in ordered_unique]
    occurrences = len(fingerprints)
    sources = len(ordered_unique)
    aliases = occurrences - sources
    candidates = sources * sign_masks
    return {
        "PotentialOccurrenceCount": occurrences,
        "PotentialSourceCount": sources,
        "PotentialAliasCount": aliases,
        "MetadataUniqueSourceCount": metadata_unique,
        "GaloisSignMaskCount": sign_masks,
        "ConjugateCandidateCount": candidates,
        "DistinctPotentialCoreCount": sources,
        "PotentialCoreReuseCount": aliases,
        "DistinctDLogOrbitCoreCount": candidates,
        "DLogOrbitCoreReuseCount": 0,
        "DistinctPotentialOrbitCoreCount": candidates,
        "PotentialOrbitCoreReuseCount": 0,
        "SourceOccurrenceCounts": occurrence_counts,
    }


def valid_occurrence_source_certificate(
        certificate: dict[str, object]) -> bool:
    integer_keys = (
        "PotentialOccurrenceCount", "PotentialSourceCount",
        "PotentialAliasCount", "MetadataUniqueSourceCount",
        "GaloisSignMaskCount", "ConjugateCandidateCount",
        "DistinctPotentialCoreCount", "PotentialCoreReuseCount",
        "DistinctDLogOrbitCoreCount", "DLogOrbitCoreReuseCount",
        "DistinctPotentialOrbitCoreCount", "PotentialOrbitCoreReuseCount",
    )
    if not all(type(certificate.get(key)) is int for key in integer_keys):
        return False
    occurrences = certificate["PotentialOccurrenceCount"]
    sources = certificate["PotentialSourceCount"]
    aliases = certificate["PotentialAliasCount"]
    candidates = certificate["ConjugateCandidateCount"]
    masks = certificate["GaloisSignMaskCount"]
    counts = certificate.get("SourceOccurrenceCounts")
    return (
        type(counts) is list
        and occurrences > 0 and sources > 0 and aliases >= 0 and masks > 0
        and all(type(count) is int and count >= 1 for count in counts)
        and occurrences == sources + aliases
        and sources == certificate["MetadataUniqueSourceCount"]
        and candidates == sources * masks
        and certificate["DistinctPotentialCoreCount"] == sources
        and certificate["PotentialCoreReuseCount"] == aliases
        and (certificate["DistinctDLogOrbitCoreCount"]
             + certificate["DLogOrbitCoreReuseCount"] == candidates)
        and (certificate["DistinctPotentialOrbitCoreCount"]
             + certificate["PotentialOrbitCoreReuseCount"] == candidates)
        and len(counts) == sources
        and sum(counts) == occurrences
        and sum(count - 1 for count in counts) == aliases
    )


def occurrence_source_count_mutants() -> int:
    fingerprints = list(range(28)) + [0, 1, 2, 3]
    good = build_occurrence_source_certificate(fingerprints)
    assert good["PotentialOccurrenceCount"] == 32
    assert good["PotentialSourceCount"] == 28
    assert good["PotentialAliasCount"] == 4
    assert good["ConjugateCandidateCount"] == 112
    assert valid_occurrence_source_certificate(good)
    checks = 5

    def changed(**updates: object) -> dict[str, object]:
        result = dict(good)
        result.update(updates)
        return result

    mutants = [
        # The V6c mistake: occurrence count was treated as unique sources.
        changed(PotentialSourceCount=32, PotentialAliasCount=0,
                ConjugateCandidateCount=128,
                DistinctPotentialCoreCount=32,
                PotentialCoreReuseCount=0,
                DistinctDLogOrbitCoreCount=128,
                DistinctPotentialOrbitCoreCount=128,
                SourceOccurrenceCounts=[1] * 32),
        changed(ConjugateCandidateCount=128),
        changed(PotentialAliasCount=0),
        changed(MetadataUniqueSourceCount=32),
        changed(DistinctPotentialCoreCount=32),
        changed(PotentialCoreReuseCount=0),
        changed(DistinctDLogOrbitCoreCount=128),
        changed(DistinctPotentialOrbitCoreCount=128),
        changed(SourceOccurrenceCounts=[1] * 32),
        changed(SourceOccurrenceCounts=[1] * 27 + [4]),
        changed(PotentialOccurrenceCount=28, PotentialAliasCount=0),
    ]
    for mutant in mutants:
        assert not valid_occurrence_source_certificate(mutant)
        checks += 1
    return checks


def build_subset_certificate_model(
        *, upper: int = 2, lower: int = 2, appended: int = 12,
        base_gauge: int = 480, target_gauge: int = 480,
        base_residue: int = 144, target_residue: int = 192,
        base_unknown: int = 624, target_unknown: int = 672,
        base_prefix: bool = True, gauge_layout_equal: bool = True,
        residue_layout_equal: bool = True, equation_core_equal: bool = True,
        every_image_prefix: bool = True) -> dict[str, object]:
    columns = upper * lower
    gauge_exact = (target_gauge == base_gauge and gauge_layout_equal
                   and equation_core_equal)
    appended_exact = (
        type(columns) is int and columns == upper * lower
        and base_prefix and gauge_exact
        and target_residue == base_residue + appended * columns
        and target_unknown == base_unknown + appended * columns
        and residue_layout_equal
    )
    implication = appended_exact and every_image_prefix
    return {
        "Status": "ExactColumnSubsetEmbeddingV6d",
        "BaseOneFormsArePrefixExact": base_prefix,
        "GaugeColumnsUnchangedExact": gauge_exact,
        "ResidueColumnsPerLetter": columns,
        "AppendedOnlyResidueColumnStructureExact": appended_exact,
        "EveryImageBaseColumnPrefixContainedExactly": every_image_prefix,
        "ColumnDeletionImplicationExact": implication,
    }


def valid_subset_certificate_schema(certificate: dict[str, object]) -> bool:
    integer_key = "ResidueColumnsPerLetter"
    boolean_keys = (
        "BaseOneFormsArePrefixExact",
        "GaugeColumnsUnchangedExact",
        "AppendedOnlyResidueColumnStructureExact",
        "EveryImageBaseColumnPrefixContainedExactly",
        "ColumnDeletionImplicationExact",
    )
    return (
        certificate.get("Status") == "ExactColumnSubsetEmbeddingV6d"
        and "EachAppendedLetterOccupiesResidueColumns" not in certificate
        and type(certificate.get(integer_key)) is int
        and certificate[integer_key] > 0
        and all(type(certificate.get(key)) is bool for key in boolean_keys)
        and all(certificate[key] for key in boolean_keys)
        and certificate["ColumnDeletionImplicationExact"]
        == (certificate["AppendedOnlyResidueColumnStructureExact"]
            and certificate["EveryImageBaseColumnPrefixContainedExactly"])
    )


def subset_certificate_mutants() -> int:
    good = build_subset_certificate_model()
    assert valid_subset_certificate_schema(good)
    checks = 1

    mutants: list[dict[str, object]] = []
    old_integer_under_boolean_name = dict(good)
    old_integer_under_boolean_name.pop("ResidueColumnsPerLetter")
    old_integer_under_boolean_name[
        "EachAppendedLetterOccupiesResidueColumns"] = 4
    mutants.append(old_integer_under_boolean_name)

    unresolved_symbol = dict(good)
    unresolved_symbol["ResidueColumnsPerLetter"] = "upper lower"
    mutants.append(unresolved_symbol)

    boolean_as_integer = dict(good)
    boolean_as_integer["AppendedOnlyResidueColumnStructureExact"] = 4
    mutants.append(boolean_as_integer)

    missing_boolean = dict(good)
    missing_boolean.pop("GaugeColumnsUnchangedExact")
    mutants.append(missing_boolean)

    hardcoded_implication = build_subset_certificate_model(
        every_image_prefix=False)
    hardcoded_implication["ColumnDeletionImplicationExact"] = True
    mutants.append(hardcoded_implication)

    mutants.extend([
        build_subset_certificate_model(target_gauge=481),
        build_subset_certificate_model(target_residue=191),
        build_subset_certificate_model(target_unknown=671),
        build_subset_certificate_model(base_prefix=False),
        build_subset_certificate_model(gauge_layout_equal=False),
        build_subset_certificate_model(residue_layout_equal=False),
        build_subset_certificate_model(equation_core_equal=False),
        build_subset_certificate_model(every_image_prefix=False),
    ])
    for mutant in mutants:
        assert not valid_subset_certificate_schema(mutant)
        checks += 1
    return checks


def main() -> int:
    exact_checks = exact_character_census()
    stabilizer_checks = sum(stabilizer_adversaries(p)
                            for p in (10007, 10039))
    exact_rebind_checks = sum(exact_rebind_adversaries(p)
                              for p in (10007, 10039))
    occurrence_source_checks = occurrence_source_count_mutants()
    subset_certificate_checks = subset_certificate_mutants()
    completed = 0
    retries = 0
    for prime in (10007, 10039):
        rng = random.Random(2026082306 + prime)
        while completed < (80 if prime == 10007 else 160):
            try:
                run_trial(rng, prime)
                completed += 1
            except ZeroDivisionError:
                retries += 1
                if retries > 500:
                    raise
    print(f"PASS exact_character_checks={exact_checks}")
    print(f"PASS stabilizer_adversaries={stabilizer_checks}")
    print(f"PASS exact_channel_rebind_adversaries={exact_rebind_checks}")
    print(f"PASS occurrence_vs_unique_source_schema_and_mutants="
          f"{occurrence_source_checks}")
    print(f"PASS subset_certificate_schema_and_mutants="
          f"{subset_certificate_checks}")
    print(f"PASS finite_field_second_order_jet_trials={completed}")
    print(f"INFO singular_sample_retries={retries}")
    print("SUMMARY passed=all failures=0 wolfram_kernels_launched=0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
