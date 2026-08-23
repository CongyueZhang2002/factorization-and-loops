#!/usr/bin/env python3
"""No-kernel structural audit of the proposed large-identity regression."""

from pathlib import Path


HERE = Path(__file__).resolve().parent
REGRESSION = (HERE / "proposed_large_identity_regression.wls").read_text()
ADAPTER = (HERE.parent / "flint_affine_rref_wl_xh/FlintAffineRREFAdapter.wl").read_text()


def require(condition, label):
    if not condition:
        raise AssertionError(label)
    print(f"PASS {label}")


def main():
    require("size = 1028" in REGRESSION, "regression exercises CF300 rank")
    require("denseIdentity = Normal[automaticIdentity]" in REGRESSION,
            "regression materializes the automatic identity")
    require('"GoodDenseInverseAccepted"' in REGRESSION,
            "regression requires valid inverse acceptance")
    require('"CorruptInverseRejected"' in REGRESSION and
            '"CorruptMatrixRejected"' in REGRESSION,
            "regression requires two corruption rejections")
    require("identity = Normal[IdentityMatrix[size]]" in ADAPTER,
            "active verifier uses representation-safe identity")
    require("Normal[Mod[matrix . inverse, prime]] === identity" in ADAPTER and
            "Normal[Mod[inverse . matrix, prime]] === identity" in ADAPTER,
            "active verifier checks both normalized products")


if __name__ == "__main__":
    main()
