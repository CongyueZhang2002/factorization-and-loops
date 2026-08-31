#!/usr/bin/env python3
"""Frozen left-null witnesses for the (25,11) ambient obstruction,
via ONE native affine solve per image: a witness of the inconsistency
of A x = b is any w with A^T w = 0 and b^T w = 1, i.e. the affine
system [A^T; b^T] w = (0,...,0,1) -- consistent exactly because the
recorded CFFR exit-5 certified b outside the column space of A.  The
same FLINT CFFR binary solves it in seconds; the witness is verified
directly (w.A = 0, w.b = 1) before it is stored."""

from __future__ import annotations

import json
import math
import subprocess
import tempfile
from pathlib import Path

import cf303_25_11_ambient_affine_solve as amb
import cf303_25_11_rank0_affine_solve as r0

OUTPUT = amb.ART / "cf303_25_11_ambient_witnesses.json"


def witness_for(image_config) -> dict:
    prime = image_config["prime"]
    epsilon = image_config["epsilon"]
    amb.set_prime(prime)
    letters = amb.mod_letters(prime)
    gauge, q_dense = amb.exact_gauge(prime)
    gauge_degrees = r0.poly_degrees(gauge)
    gauge_derivatives = (r0.poly_derivative(gauge, 0),
                         r0.poly_derivative(gauge, 1))
    data = {"kinematic_denominator": q_dense}
    support = [(i, j) for i in range(gauge_degrees[0] + 1)
               for j in range(gauge_degrees[1] + 1)]
    columns = 2 * len(support) + 2 * len(letters)
    point_count = max(16, math.ceil((columns + 4) / 4))
    points = r0.draw_points(point_count, 25_119_800, data, letters,
                            gauge)
    for point in points:
        point["epsilon"] = epsilon % prime
    diagonal, _ = r0.diagonal_images(points, amb.CPUS)
    with tempfile.TemporaryDirectory(prefix="cf303-witc-") as folder:
        work = Path(folder)
        if image_config["forcing"] == "tensor":
            tensor = json.loads(
                (amb.ART / "cf303_25_11_full_bbar_modp.json"
                 ).read_text())
            forcing = r0.bbar_values(tensor, points, epsilon)
        else:
            forcing = amb.native_forcing(points, epsilon, work)
        matrix, rhs = [], []
        for index, point in enumerate(points):
            rows, expected = r0.point_rows(
                index, point, diagonal, forcing, letters, gauge,
                gauge_derivatives, support, epsilon)
            matrix.extend(rows)
            rhs.extend(expected)
        n_rows = len(matrix)
        print(f"[witness-cffr] prime {prime}: A is {n_rows} x "
              f"{columns}", flush=True)
        # transposed affine system: (columns+1) equations in n_rows
        # unknowns; RHS = unit vector on the b^T row
        t_rows = columns + 1
        request = work / "witness.request"
        response = work / "witness.response"
        nonce = (2026, 831_500)

        def source():
            for col in range(columns):
                yield ([[matrix[r][col] for r in range(n_rows)]],
                       [0])
            yield ([[rhs[r] % prime for r in range(n_rows)]], [1])

        preference = list(range(n_rows))
        r0.write_cffr_request(request, t_rows, n_rows, source(),
                              preference, nonce)
        process = subprocess.run(
            ["taskset", "-c", amb.CPUS, str(r0.CFFR_BINARY),
             str(request), str(response), str(amb.THREADS)],
            text=True, capture_output=True, check=False)
        if process.returncode == 5:
            return {"prime": prime, "status": "NoWitnessFound"}
        if process.returncode:
            raise RuntimeError(process.stderr)
        witness, meta = r0.read_cffr_particular(response, t_rows,
                                                n_rows, nonce)
    # direct verification before storing
    for col in range(columns):
        if sum(witness[r] * matrix[r][col] for r in
               range(n_rows)) % prime:
            raise RuntimeError("witness fails w.A = 0")
    pairing = sum(witness[r] * rhs[r] for r in range(n_rows)) % prime
    if pairing != 1:
        raise RuntimeError("witness pairing is not one")
    print(f"[witness-cffr] prime {prime}: verified (rank "
          f"{meta['rank']})", flush=True)
    return {"prime": prime, "epsilon": epsilon,
            "transposed_rank": meta["rank"],
            "matrix_dimensions": [n_rows, columns],
            "point_seed": 25_119_800,
            "verified": {"WTransposeAZero": True, "WPairingB": 1},
            "points": [[p["t"], p["s"]] for p in points],
            "witness": witness}


def main() -> int:
    witnesses = []
    for cfg in amb.IMAGES:
        witnesses.append(witness_for(cfg))
        OUTPUT.write_text(json.dumps(
            {"status": "CF303Block11AmbientWitnessesV1",
             "method": "TransposedAffineSolve/CFFR1",
             "witnesses": witnesses}, indent=1))
    print(json.dumps([{k: w[k] for k in w
                       if k not in ("witness", "points")}
                      for w in witnesses], indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
