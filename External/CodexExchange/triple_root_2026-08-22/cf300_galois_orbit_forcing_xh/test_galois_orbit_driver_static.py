#!/usr/bin/env python3
"""Adversarial no-kernel contract checks for the CF300 orbit driver."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[3]
DRIVER = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v1.wls"
text = DRIVER.read_text()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


expected = {
    PROJECT / "Addon/Load/LoadFACET.wl":
        "e324b5f6c30d34a70248b691183abb1904d1a27fd745e3c4b8b0b381122e6164",
    HERE.parent / "TripleRootAlgebra.wl":
        "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab",
    HERE.parent / "TripleRootStripAdapter.wl":
        "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5",
    HERE.parent / "TripleRootAffinePilot.wl":
        "283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90",
    HERE.parent / "TripleRootReconstructionPrototype.wl":
        "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43",
    HERE.parent / "direct_root_channel_assembler_xh/DirectRootChannelAssembler.wl":
        "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6",
    HERE.parent / "direct_root_channel_assembler_xh/DirectRootChannelCompiledArtifact.wl":
        "8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557",
    HERE.parent / "cf300_sector12_next_ansatz_xh/DirectRootChannelAnsatzRebind.wl":
        "8b0f8d7fdab72d9660836d1f2a92e7f03be5eb1adcbd7082b327ed4bb8b8e907",
    HERE.parent / "flint_affine_rref_wl_xh/FlintAffineRREFAdapter.wl":
        "d5dbc6542ee21f6390963c57698e56992df9a04612464bc54f562398a1d78605",
    HERE.parent / "cf300_sector12_next_ansatz_xh/AffineInconsistencyWitness.wl":
        "6d2ea56523cbee20c71efc265150ebd001d701421cac08dc69bb77296dafe79f",
    HERE.parent / "flint_affine_rref_xh/bin/flint_affine_rref":
        "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5",
}

assertions = 0

for path, digest in expected.items():
    assert path.is_file(), path
    assert sha256(path) == digest, path
    assert digest in text, path
    assertions += 3

assert 'BeginPackage["CodexCF300GaloisOrbitForcingDriverV1`"]' in text
assert 'Begin["`Private`"]' in text
assert 'ClearAll["CodexCF300GaloisOrbitForcingDriverV1`Private`*"]' in text
assert text.index("BeginPackage[") < text.index("arguments =")
assert text.count("System`Exit[") == 1
assert not re.search(r"(?<!System`)\bExit\[", text)
assert not re.search(r"Global`[A-Za-z$][A-Za-z0-9$]*", text)
assertions += 7

# Rank-2 means the orbit is the full Klein four group, never one branch.
assert "signMasks = Range[0, 3];" in text
assert "{mask, signMasks}" in text
assert '"ObservedSignMasks" -> masks' in text
assert '#1["ObservedSignMasks"] === signMasks' in text
assert '"BranchSigns" -> signs' in text
assertions += 5

# Every accepted potential carries entry/epsilon identity and exact expressions.
for key in (
    "SourcePotentialID",
    "DerivativeComponent",
    "Upper",
    "Lower",
    "EpsilonValue",
    "SourcePotential",
    "ConjugatedPotential",
    "PotentialFieldChannels",
    "Provenance",
):
    assert f'"{key}"' in text
    assertions += 1

# Fail closed unless conjugation, field round trips, dlog identities and closure
# all hold exactly before any finite-field sample is assembled.
assert "conjugatePotential[potential, mask] - sourcePotential" in text
assert "potential #1 - D[potential, #2]" in text
assert "D[form[[2]], x] - D[form[[1]], y]" in text
assert "TRFieldDecompose[potential, roots]" in text
assert "TRFieldCompose[" in text
assert '"DLogIdentityExact"' in text
assert '"OrbitDLogExact"' in text
assert '"ClosedOneFormExact"' in text
assert "BitXor[left, right]" in text
assert '"KleinFourCompositionExact"' in text
assertions += 10

# Deduplication is by canonical exact field channels with an equality check
# inside each hash bucket, not by textual potential identity.
assert "candidateGroups = GatherBy[conjugateCandidates" in text
assert '"CanonicalFieldChannels"' in text
assert "SameQ[#1[\"CanonicalFieldChannels\"]" in text
assert 'finish["ForcingChannelFingerprintCollision"' in text
assertions += 4

# The old ansatz is a literal prefix.  Hence any appended-letter subset is a
# column submatrix of the maximal target; the live screen verifies this again.
assert "maxOneForms = Join[baseOneForms" in text
assert "Take[maxOneForms, Length[baseOneForms]] =!= baseOneForms" in text
assert "Take[targetScreenMatrix, All, baseUnknownCount] =!=" in text
assert '"BaseColumnPrefixContainedExactly" -> True' in text
assert '"ExactColumnSubsetEmbeddingV1"' in text
assert "Length[forcingLetterRecords] > 112" in text
assert "Length[maxOneForms] > 120" in text
assert "unknownCount > 960 || pointCount > 31" in text
assertions += 8

# Witness short circuit plus independent FLINT coefficient/augmented ranks.
assert "AIWConstruct[" in text
assert "AIWScoreColumns[" in text
assert 'Missing["RejectedByBaseLeftWitness"]' in text
assert "rankImage[targetSample[\"Matrix\"]" in text
assert text.count('"ImageID" -> "I') == 4
assertions += 5

# Inputs are pinned both before and after the run, and output is exclusive +
# read-back checked.  The driver cannot start nested Wolfram/helper pools.
assert "stableInputsQ[]" in text
assert "SourceOrArtifactChangedDuringScreen" in text
assert "OverwriteTarget -> False" in text
assert "SameQ[reread, value]" in text
assert "LaunchKernels" not in text
assert "ParallelSubmit" not in text
assert "RunProcess" not in text
assertions += 7

# The artifact explicitly limits what the finite-field result proves.
assert "finite-field image rejection is not by itself a lifted " in text
assert "characteristic-zero obstruction certificate" in text
assertions += 2

print(
    f"CF300_GALOIS_ORBIT_STATIC PASS {assertions}/{assertions} "
    f"driver_sha256={sha256(DRIVER)}"
)
