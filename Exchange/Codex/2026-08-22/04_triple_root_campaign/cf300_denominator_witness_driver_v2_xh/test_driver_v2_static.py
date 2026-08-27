#!/usr/bin/env python3
"""No-kernel contract tests for the adjacent CF300 witness driver V2."""

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
EXCHANGE = HERE.parent
V1 = EXCHANGE / "cf300_sector12_next_ansatz_xh/run_cf300_sector12_denominator_witness_screen.wls"
V2 = HERE / "run_cf300_sector12_denominator_witness_screen_v2.wls"

EXPECTED_FINGERPRINTS = [
    "2d711642b726b04401627ca9fbac32f5c8530fb1903cc4db02258717921a4881",
    "c799eabc0695b12beeccf7a2edfa9702dc5efaddfdec7bf64437b73807eff7ed",
    "ce44a483203b0cde640e984643bcf415afd24ea95df2b50ee87ae72e232be10e",
]
EXPECTED_MASKS = {
    "MASK:011": (1, 2),
    "MASK:101": (0, 2),
    "MASK:110": (0, 1),
    "MASK:111": (0, 1, 2),
}
FACTOR_BIDEGREES = [(1, 0), (2, 2), (1, 0)]
EXPECTED_PRODUCT_SIZES = {
    "MASK:011": (64, 1168, 38),
    "MASK:101": (42, 816, 27),
    "MASK:110": (64, 1168, 38),
    "MASK:111": (72, 1296, 42),
}


def require(condition, label):
    if not condition:
        raise AssertionError(label)
    print(f"PASS {label}")


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def assignment(text, name, next_name):
    pattern = rf"{re.escape(name)}\s*=(.*?)(?=\n{re.escape(next_name)}\s*=)"
    match = re.search(pattern, text, re.DOTALL)
    if match is None:
        raise AssertionError(f"assignment not found: {name}")
    return re.sub(r"\s+", "", match.group(1))


def main():
    v1 = V1.read_text()
    v2 = V2.read_text()
    require(sha256(V1) ==
            "7d27f59d30675f0291f929b4d5f0e8b18e40d7b40047bb53c4a824850ca7b5a6",
            "audited V1 snapshot remains pinned")
    require(assignment(v1, "expectedHashes", "expectedPreparationHash") ==
            assignment(v2, "expectedHashes", "expectedPreparationHash"),
            "source hash pins preserved byte-for-byte semantically")
    require(assignment(v1, "expectedPreparationHash", "expectedCacheHash") ==
            assignment(v2, "expectedPreparationHash", "expectedCacheHash"),
            "preparation artifact pin preserved")
    require(assignment(v1, "expectedCacheHash", "expectedCensusHash") ==
            assignment(v2, "expectedCacheHash", "expectedCensusHash"),
            "compiled-cache artifact pin preserved")
    require(assignment(v1, "expectedCensusHash", "expectedCandidateFingerprints") ==
            assignment(v2, "expectedCensusHash", "expectedCandidateFingerprints"),
            "denominator-census artifact pin preserved")
    require("supportDirectory" in v2 and
            '"cf300_sector12_next_ansatz_xh"' in v2,
            "adjacent V2 resolves pinned V1 support helpers explicitly")

    for fingerprint in EXPECTED_FINGERPRINTS:
        require(fingerprint in v2, f"legacy fingerprint selector retained: {fingerprint[:8]}")
    require('selector === "ALL"' in v2,
            "legacy ALL selector retained")
    require("CF300Sector12DenominatorWitnessScreenPassed" in v2 and
            "CF300Sector12DenominatorWitnessTargetedScreenPassed" in v2,
            "legacy success statuses retained")

    require('catalog = SortBy[candidates, #1["FactorFingerprint"] &]' in v2,
            "mask catalog has deterministic fingerprint order")
    for selector, positions in EXPECTED_MASKS.items():
        require(f'"{selector}"' in v2, f"product mask accepted: {selector}")
        bits = selector.removeprefix("MASK:")
        require(tuple(i for i, bit in enumerate(bits) if bit == "1") == positions,
                f"product mask model is deterministic: {selector}")
        factor_degree = tuple(
            sum(FACTOR_BIDEGREES[index][axis] for index in positions)
            for axis in range(2)
        )
        support_count = (4 + factor_degree[0] + 1) * (5 + factor_degree[1] + 1)
        unknown_count = 16 * support_count + 144
        point_count = (unknown_count + 32 + 31) // 32
        require((support_count, unknown_count, point_count) ==
                EXPECTED_PRODUCT_SIZES[selector],
                f"pinned bidegree size model: {selector}")
    require('factor = Times @@ Lookup[members, "Factor"]' in v2,
            "pair/triple factor is deterministic catalog product")
    require('If[Length[members] === 1,\n    candidate = First[members]' in v2,
            "legacy singleton reuses original census candidate")
    require('"CF300DenominatorWitnessPureSupersetV1"' in v2 and
            '"CF300DenominatorWitnessProductPureSupersetV2"' in v2,
            "legacy and product metadata schemas are separated")
    require('"FactorFingerprint" -> fingerprint[factor]' in v2,
            "product factor receives content fingerprint")
    require('"CatalogFactorFingerprints" -> memberFingerprints' in v2,
            "product provenance retains component fingerprints")

    select_at = v2.index("targetSpecifications = resolveCandidateSelector")
    build_at = v2.index("buildTarget /@ targetSpecifications")
    require(select_at < build_at,
            "candidate selection precedes target construction")
    require("buildTarget /@ candidates" not in v2,
            "targeted mode never constructs all catalog targets")
    require('Length[targetSpecifications] =!=' in v2 and
            'If[candidateSelector === "ALL", 3, 1]' in v2,
            "selector cardinality fails closed")
    require('FileHash[$InputFileName, "SHA256", "HexString"] =!=' in v2,
            "driver self-hash completion gate retained")
    require('"CandidateCatalogBitOrder" -> expectedCandidateFingerprints' in v2 and
            '"SelectedCatalogMasks"' in v2,
            "output publishes mask ABI and resolved mask")


if __name__ == "__main__":
    main()
