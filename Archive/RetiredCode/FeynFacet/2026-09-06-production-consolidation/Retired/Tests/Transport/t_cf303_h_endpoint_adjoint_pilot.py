#!/usr/bin/env python3
"""Focused regression for the CF303 endpoint adjoint and mode-5 factors."""

from __future__ import annotations

from fractions import Fraction
import importlib.util
from pathlib import Path
import sys


REPOSITORY = Path(__file__).resolve().parents[2]
SCRIPTS = REPOSITORY / "Scripts/Transport/CF303"
sys.path.insert(0, str(SCRIPTS))

import cf303_h_endpoint_adjoint_pilot as adjoint
import cf303_h_endpoint_factorwise_fit as factorwise


def load(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    assert specification is not None and specification.loader is not None
    module = importlib.util.module_from_spec(specification)
    sys.modules[name] = module
    specification.loader.exec_module(module)
    return module


prime = 2_305_843_009_213_641_971
evaluator = load("cf303_factor_test_evaluator", factorwise.EVALUATOR)
helper = evaluator.load_module(
    "cf303_factor_test_polynomial", evaluator.RATIONAL_HELPER
)
regulator, factor_records = factorwise.block_endpoint_regulator(
    evaluator, helper, prime, (21, 22)
)
assert len(regulator) - 1 == 5
assert any(
    "p + 1" in record["TangentialDenominatorFactors"]
    for record in factor_records
)

pilot = adjoint.run_pilot(
    prime, Fraction(10), adjoint.DEFAULT_DECK, -2
)
assert pilot["Status"] == "CF303RegularizedEndpointHermiteAdjointPilotValidated"
assert pilot["Validation"] == {
    "AdjointEquationReplayed": True,
    "ExactAgreementWithFullPrimitivePilotOracle": True,
    "EndpointFunctionalOnly": True,
}
assert [
    (record["HermiteEquationCount"], record["HermiteUnknownCount"],
     record["PrimitiveUnknownCount"], record["RemainderUnknownCount"])
    for record in pilot["Records"]
] == [(41, 33, 18, 15), (41, 33, 18, 15)]
assert all(not record["FullPrimitiveConstructedByAdjointPath"]
           for record in pilot["Records"])

print("CF303 endpoint adjoint/factor-source tests passed (12/12).")
