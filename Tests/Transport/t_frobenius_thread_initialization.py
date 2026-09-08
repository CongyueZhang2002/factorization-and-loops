#!/usr/bin/env python3
"""Check first-use complex-ball arithmetic in fresh parallel native processes."""
from decimal import Decimal, localcontext
from pathlib import Path
import os
import subprocess

root = Path(__file__).resolve().parents[2]
executable = root / "FeynFacet/Backends/flint/bin/frobenius_taylor"
dimension = 64
number = lambda value: f"{value} exact 0/1 exact"
entries = "".join(f"{i} {i}\n1\n0 1 {number('1/1')}\n1\n0 0 {number('1/1')}\n" for i in range(dimension))
seed = "\n".join(number("1/1" if k == 0 else "0/1") for k in range(3) for _ in range(dimension))
def request(threads):
    return f"FFFR1 240 {threads} 48 2 {dimension} {dimension} 1 1\n{number('1/8')}\n{number('1/32')}\n" + entries + seed + "\n"

def evaluate(threads):
    process = subprocess.run([str(executable)], input=request(threads), text=True, capture_output=True, timeout=15)
    assert process.returncode == 0, process.stderr
    lines = process.stdout.splitlines()
    assert lines[0] == f"FFFO1 {dimension} 2 48"
    values = [list(map(int, line.split())) for line in lines[1:]]
    assert len(values) == dimension * 3 and all(len(v) == 16 for v in values)
    return values

with localcontext() as context:
    context.prec = 70
    exact = [Decimal(1), Decimal("1.25").ln(), Decimal("1.25").ln() ** 2 / 2]
    # Separate executable invocations reproduce the lazy initialization race.
    for trial in range(32):
        values = evaluate(1 if trial == 0 else 8)
        for k in range(3):
            for value in values[k*dimension:(k+1)*dimension]:
                midpoint = Decimal(value[0]) * Decimal(2) ** value[1]
                imag = Decimal(value[4]) * Decimal(2) ** value[5]
                assert abs(midpoint-exact[k]) < Decimal("1e-28") and abs(imag) < Decimal("1e-28")
print("PASS 32 fresh native processes: one/eight-thread Taylor coefficients agree with log(5/4)")
