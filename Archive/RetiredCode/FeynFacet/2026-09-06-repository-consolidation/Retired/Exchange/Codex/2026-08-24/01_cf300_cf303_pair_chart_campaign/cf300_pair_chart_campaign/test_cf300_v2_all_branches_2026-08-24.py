#!/usr/bin/env python3
"""Independent exact-rational branch oracle for the CF300 V2 pair chart."""

from fractions import Fraction as Q
from itertools import product


def forward(p: Q, q: Q):
    k = p * (1 - p)
    d = q * q + 4 * k
    if d == 0:
        raise ZeroDivisionError("forward chart divisor d=0")
    a = (4 * k - 2 * q) / d
    x = a * p
    y = -(1 - a) * (1 - p)
    root_a = a - p
    root_b = 1 + q * a
    return x, y, root_a, root_b, a, d


def inverse(x: Q, y: Q, root_a: Q, root_b: Q):
    a = (1 + x + y + root_a) / 2
    if a == 0:
        raise ZeroDivisionError("inverse chart divisor a=0")
    p = (1 + x + y - root_a) / 2
    q = (root_b - 1) / a
    return p, q


def inverse_mutant(x: Q, y: Q, root_a: Q, root_b: Q):
    """Deliberately wrong q sign; the adversarial oracle must reject it."""
    a = (1 + x + y + root_a) / 2
    if a == 0:
        raise ZeroDivisionError("inverse chart divisor a=0")
    p = (1 + x + y - root_a) / 2
    q = (root_b + 1) / a
    return p, q


def root_squares(x: Q, y: Q):
    rad_a = 1 - 2 * x + x * x + 2 * y + 2 * x * y + y * y
    rad_b = 1 - 4 * x * y
    return rad_a, rad_b


SEEDS = [
    (Q(1, 3), Q(2, 5)),
    (Q(2, 7), Q(-3, 4)),
    (Q(-1, 2), Q(5, 6)),
    (Q(4, 5), Q(1, 7)),
    (Q(7, 6), Q(-2, 9)),
    (Q(-3, 8), Q(-5, 11)),
]


def main():
    branch_checks = 0
    mutant_rejections = 0
    for p0, q0 in SEEDS:
        x, y, ra, rb, _, _ = forward(p0, q0)
        rad_a, rad_b = root_squares(x, y)
        assert ra * ra == rad_a
        assert rb * rb == rad_b

        for sign_a, sign_b in product((Q(1), Q(-1)), repeat=2):
            target_ra = sign_a * ra
            target_rb = sign_b * rb
            p1, q1 = inverse(x, y, target_ra, target_rb)
            x1, y1, ra1, rb1, _, _ = forward(p1, q1)
            assert (x1, y1, ra1, rb1) == (x, y, target_ra, target_rb)
            branch_checks += 1

            try:
                pm, qm = inverse_mutant(x, y, target_ra, target_rb)
                mutant = forward(pm, qm)
                mutant_passed = mutant[:4] == (x, y, target_ra, target_rb)
            except ZeroDivisionError:
                mutant_passed = False
            assert not mutant_passed
            mutant_rejections += 1

    print(
        f"PASS seeds={len(SEEDS)} branch_checks={branch_checks} "
        f"wrong_q_sign_mutants_rejected={mutant_rejections}"
    )


if __name__ == "__main__":
    main()
