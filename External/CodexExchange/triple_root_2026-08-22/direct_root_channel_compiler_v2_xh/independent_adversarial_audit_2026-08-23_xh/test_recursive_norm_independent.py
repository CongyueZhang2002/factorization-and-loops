#!/usr/bin/env python3
"""Independent exact-arithmetic check of the V2 tower-norm formula.

This is deliberately not a Wolfram test and imports no project code.  It
compares the recursive conjugate/norm inverse against independent dense
Gaussian elimination in the same bit-mask basis for ranks zero through three.
"""

from fractions import Fraction
import random


def multiply(left, right, deltas):
    dimension = 1 << len(deltas)
    result = [Fraction(0) for _ in range(dimension)]
    for left_mask, left_value in enumerate(left):
        for right_mask, right_value in enumerate(right):
            common = left_mask & right_mask
            factor = Fraction(1)
            for root_index, delta in enumerate(deltas):
                if (common >> root_index) & 1:
                    factor *= delta
            result[left_mask ^ right_mask] += left_value * right_value * factor
    return result


def recursive_inverse(value, deltas):
    if not deltas:
        return None if value[0] == 0 else [1 / value[0]]
    half = len(value) // 2
    lower_deltas = deltas[:-1]
    lower, upper = value[:half], value[half:]
    lower_square = multiply(lower, lower, lower_deltas)
    upper_square = multiply(upper, upper, lower_deltas)
    norm = [
        a - deltas[-1] * b for a, b in zip(lower_square, upper_square)
    ]
    norm_inverse = recursive_inverse(norm, lower_deltas)
    if norm_inverse is None:
        return None
    candidate = multiply(lower, norm_inverse, lower_deltas) + [
        -entry for entry in multiply(upper, norm_inverse, lower_deltas)
    ]
    unit = [Fraction(1)] + [Fraction(0)] * (len(value) - 1)
    return candidate if multiply(value, candidate, deltas) == unit else None


def dense_inverse(value, deltas):
    dimension = len(value)
    augmented = []
    for row in range(dimension):
        augmented.append(
            [
                multiply(
                    value,
                    [Fraction(int(index == column)) for index in range(dimension)],
                    deltas,
                )[row]
                for column in range(dimension)
            ]
            + [Fraction(int(row == 0))]
        )
    for column in range(dimension):
        pivot = next(
            (row for row in range(column, dimension) if augmented[row][column]),
            None,
        )
        if pivot is None:
            return None
        augmented[column], augmented[pivot] = augmented[pivot], augmented[column]
        pivot_value = augmented[column][column]
        augmented[column] = [entry / pivot_value for entry in augmented[column]]
        for row in range(dimension):
            if row == column or not augmented[row][column]:
                continue
            multiplier = augmented[row][column]
            augmented[row] = [
                entry - multiplier * pivot_entry
                for entry, pivot_entry in zip(augmented[row], augmented[column])
            ]
    return [augmented[index][-1] for index in range(dimension)]


def main():
    random_source = random.Random(20260823)
    checks = 0
    invertible = 0
    singular = 0
    for rank in range(4):
        for _ in range(250):
            deltas = [
                Fraction(random_source.choice([2, 3, 5, 6, 7, 10, 11]))
                for _ in range(rank)
            ]
            value = [
                Fraction(random_source.randint(-4, 4))
                for _ in range(1 << rank)
            ]
            recursive = recursive_inverse(value, deltas)
            dense = dense_inverse(value, deltas)
            assert (recursive is None) == (dense is None)
            if recursive is not None:
                invertible += 1
                assert recursive == dense
                assert multiply(value, recursive, deltas) == [Fraction(1)] + [
                    Fraction(0)
                ] * ((1 << rank) - 1)
            else:
                singular += 1
            checks += 1
    assert recursive_inverse([Fraction(1), Fraction(1)], [Fraction(1)]) is None
    assert recursive_inverse(
        [Fraction(1), Fraction(0), Fraction(1), Fraction(0)],
        [Fraction(2), Fraction(1)],
    ) is None
    assert recursive_inverse(
        [Fraction(1), Fraction(0), Fraction(0), Fraction(0),
         Fraction(1), Fraction(0), Fraction(0), Fraction(0)],
        [Fraction(2), Fraction(3), Fraction(1)],
    ) is None
    print(
        "PASS independent recursive-vs-dense exact algebra "
        f"cases={checks} invertible={invertible} singular={singular} "
        "explicit_zero_divisors=3"
    )


if __name__ == "__main__":
    main()
