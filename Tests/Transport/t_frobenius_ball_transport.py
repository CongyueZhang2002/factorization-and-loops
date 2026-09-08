#!/usr/bin/env python3
"""Preserve arithmetic uncertainty across native Taylor continuations."""
from fractions import Fraction
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[2]
exe = root / "FeynFacet/Backends/flint/bin/frobenius_taylor"

def run(seed, bits=240):
    # Zero connection isolates serialization from recurrence error.
    request = (f"FFFR2 {bits} 1 48 0 1 0 1 1\n"
               "1/8 exact 0/1 exact\n1/32 exact 0/1 exact\n"
               + " ".join(map(str, seed)) + "\n")
    return subprocess.run([str(exe)], input=request, capture_output=True,
                          text=True, timeout=15)

def parts(value):
    def dyadic(m, e):
        return Fraction(m) * Fraction(2) ** e
    return [(dyadic(*value[i:i+2]), dyadic(*value[i+2:i+4]))
            for i in (0, 4)]

initial = [123, -3, 536870911, -100, -7, -4, 536870911, -110]
state = initial[:]
for step in range(80):
    result = run(state)
    assert result.returncode == 0, result.stderr
    assert result.stdout.splitlines()[0] == "FFFO1 1 0 48"
    state = list(map(int, result.stdout.splitlines()[1].split()))[:8]
    assert state == initial, (step, state, initial)
print("PASS 80 complex-ball transfers preserve midpoint and radius exactly")

# Lower precision may enlarge a ball but must retain the original interval.
fine = [2**190 + 17, -188, 536870911, -220,
        -(2**170 + 9), -169, 536870911, -210]
result = run(fine, bits=96)
assert result.returncode == 0, result.stderr
coarse = list(map(int, result.stdout.splitlines()[1].split()))[:8]
for (m, radius), (old_m, old_radius) in zip(parts(coarse), parts(fine)):
    assert radius >= abs(m-old_m) + old_radius
print("PASS changing arithmetic precision retains input uncertainty")

# Increasing precision cannot remove uncertainty inherited from a coarse step.
refined = run(coarse, bits=300)
assert refined.returncode == 0, refined.stderr
refined_value = list(map(int, refined.stdout.splitlines()[1].split()))[:8]
for (m, radius), (old_m, old_radius) in zip(parts(refined_value), parts(coarse)):
    assert radius >= abs(m-old_m) + old_radius

for special in ([0, 0, 536870911, -120, 1, -300, 536870911, -400],
                [1, 0, 0, 0, -1, -3, 0, 0]):
    result = run(special)
    assert result.returncode == 0, result.stderr
    value = list(map(int, result.stdout.splitlines()[1].split()))[:8]
    assert parts(value) == parts(special)
print("PASS exact components, uncertain zeros and unequal complex scales")

for bad in ([1, 0, -1, -50, 0, 0, 0, 0],
            [1, 0, 1, -50, 0, 0],
            ["nan", 0, 1, -50, 0, 0, 0, 0]):
    result = run(bad)
    assert result.returncode != 0
    assert "Invalid native coefficient ball" in result.stderr
print("PASS negative radii, truncated balls, and nonfinite tokens rejected")
