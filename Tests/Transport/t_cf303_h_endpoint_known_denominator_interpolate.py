#!/usr/bin/env python3
"""Focused exact test of CF303 known-denominator interpolation."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path


REPOSITORY = Path(__file__).resolve().parents[2]
SCRIPT = (
    REPOSITORY
    / "Scripts/Transport/CF303/cf303_h_endpoint_known_denominator_interpolate.py"
)
PRIME = 2_305_843_009_213_641_971
KEY = "1:-3:44:-2"
PROFILE_STATUS = (
    "CF303NormalPathGaugeMovingBoundaryLaurentGermKnownDenominatorsEstablished"
)


def write_profile(path: Path, factor: list[int]) -> None:
    path.write_text(json.dumps({
        "DataType":
            "CF303NormalPathGaugeMovingBoundaryLaurentGermKnownDenominatorProfile",
        "SchemaVersion": 2,
        "Status": PROFILE_STATUS,
        "Coordinates": [{
            "Key": KEY,
            "DenominatorFactors": [{
                "Coefficients": factor, "Multiplicity": 1,
            }],
            "NumeratorDegreeBound": 2,
        }],
    }))


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="cf303-known-denominator-test-") as raw:
        directory = Path(raw)
        samples = directory / "samples"
        samples.mkdir()
        for point in range(2, 10):
            numerator = (2 * point * point + 3) % PRIME
            value = numerator * pow(point + 1, -1, PRIME) % PRIME
            (samples / f"p{point}.json").write_text(json.dumps({
                "DataType": "CF303NormalPathGaugeAtMovingBoundaryFiniteFieldPoint",
                "SchemaVersion": 2,
                "Status":
                    "CF303NormalPathGaugeAtMovingBoundaryFiniteFieldPointValidated",
                "Prime": PRIME, "TangentialPoint": [point, 1],
                "Records": [{
                    "InheritedModeIndex": 1, "EpsilonOrder": -3,
                    "TargetMasterIntegralRow": 44,
                    "NormalCoordinatePower": -2, "Value": value,
                }],
            }))
        profile = directory / "profile.json"
        output = directory / "fit.json"
        write_profile(profile, [1, 1])
        completed = subprocess.run([
            sys.executable, str(SCRIPT), "--sample-directory", str(samples),
            "--denominator-profile", str(profile), "--held-out-count", "3",
            "--output", str(output),
        ], capture_output=True, text=True, check=False)
        assert completed.returncode == 0, completed.stdout + completed.stderr
        fit = json.loads(output.read_text())
        coordinate = fit["Coordinates"][0]
        assert coordinate["NumeratorCoefficientsModuloPrime"] == [3, 0, 2]
        assert coordinate["IndependentValidationImageCount"] == 5
        assert all(fit["Validation"].values())

        write_profile(profile, [2, 1])
        refused = subprocess.run([
            sys.executable, str(SCRIPT), "--sample-directory", str(samples),
            "--denominator-profile", str(profile), "--held-out-count", "3",
            "--output", str(output),
        ], capture_output=True, text=True, check=False)
        refusal = json.loads(refused.stdout)
        assert refused.returncode == 2
        assert refusal["Status"] == (
            "CF303KnownDenominatorProfileRejectedAtFiniteFieldImages"
        )
    print("PASS: known denominator clearing, bounded numerator interpolation, "
          "held-out replay, and wrong-denominator refusal")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
