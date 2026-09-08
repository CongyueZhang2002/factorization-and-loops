#!/usr/bin/env python3
"""Fast closure checks for the repository-local CF303 normal-factor bundle."""

from __future__ import annotations

import gzip
import importlib.util
import json
import re
import sys
from pathlib import Path


REPOSITORY = Path(__file__).resolve().parents[2]
BUNDLE = (
    REPOSITORY
    / "Scripts/Transport/CF303/data/normal_factor_exact_circuit"
)
FORBIDDEN = (
    re.compile(r"factorization-and-loops-codex"),
    re.compile(r"/(?:home|Users|tmp)/"),
    re.compile(r"[A-Za-z]:\\"),
)


def read_text(path: Path) -> str:
    if path.suffix == ".gz":
        with gzip.open(path, "rt") as stream:
            return stream.read()
    return path.read_text()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    manifest = json.loads((BUNDLE / "bundle_manifest.json").read_text())
    require(
        manifest["DataType"] == "CF303NormalFactorExactCircuitBundle"
        and manifest["SchemaVersion"] == 2,
        "bundle manifest type/schema mismatch",
    )
    require(
        manifest["Status"] == "CF303NormalFactorExactCircuitBundleIncomplete"
        and manifest["DefinitionClosure"][
            "CharacteristicZeroHermiteNodeClosure"
        ] is False
        and manifest["DefinitionClosure"][
            "FreshPrimeFullNinetyEntryReplayValidated"
        ] is True
        and manifest["DefinitionClosure"][
            "TangentialIntertwiningIdentityValidated"
        ] is False,
        "bundle must preserve the two independent completion blockers",
    )
    references = [
        *manifest["ExactMathematicalInputs"].values(),
        *manifest["EvaluationSemantics"].values(),
        *manifest["ValidationPointEvidence"],
        *manifest["FiniteFieldValidationInputs"]["FixedPointEpsilonLifts"],
        *manifest["FiniteFieldValidationInputs"]["UnusedPrimeLaurentDecks"],
        manifest["FiniteFieldValidationInputs"]["JunctionDefaultLaurentDeck"],
    ]
    require(all(not Path(reference).is_absolute() for reference in references),
            "manifest contains an absolute reference")
    require(all((BUNDLE / reference).is_file() for reference in references),
            "manifest reference does not resolve inside the bundle")

    bundle_files = [
        path for path in BUNDLE.rglob("*")
        if path.is_file() and "__pycache__" not in path.parts
    ]
    for path in bundle_files:
        text = read_text(path)
        require(not any(pattern.search(text) for pattern in FORBIDDEN),
                f"nonportable path text in {path.relative_to(BUNDLE)}")

    circuit = json.loads((BUNDLE / "cf303_block1_full_exact_circuit.json").read_text())
    circuit_references = []
    for node in circuit["nodes"]:
        for key in ("path", "source"):
            reference = node.get(key)
            if isinstance(reference, str):
                circuit_references.append(reference)
        if node.get("type") == "CompositeBaselineInputs":
            circuit_references.append(node["base_76"]["path"])
            circuit_references.extend(
                item["path"] for item in node["exception_inputs"]
            )
    require(all(not Path(reference).is_absolute()
                for reference in circuit_references),
            "block-1 DAG contains an absolute leaf reference")
    require(all((BUNDLE / reference).is_file()
                for reference in circuit_references),
            "block-1 DAG leaf reference does not close inside the bundle")
    split_nodes = [
        node for node in circuit["nodes"]
        if node.get("op") == "FixedRationalHermiteSplit"
    ]
    require(len(split_nodes) == 14 and all(
        node.get("exact_semantics") == "cf303_exact_hermite_semantics.py"
        for node in split_nodes
    ), "not every block-1 Hermite node names the candidate exact semantics")

    evaluator_path = BUNDLE / "cf303_hybrid_baseline_modular_circuit.py"
    specification = importlib.util.spec_from_file_location(
        "cf303_bundle_evaluator", evaluator_path
    )
    require(specification is not None and specification.loader is not None,
            "cannot load bundle evaluator")
    evaluator = importlib.util.module_from_spec(specification)
    sys.modules[specification.name] = evaluator
    specification.loader.exec_module(evaluator)
    inputs = evaluator.parse_inputs()
    require(len(inputs["entries"]) == 90, "merged transfer is not 90-entry")
    require(len(inputs["source_entries"]) == 86,
            "merged transfer source-entry count changed")
    exception_targets = [
        tuple(map(int, entry[0])) for entry in inputs["entries"][76:88]
    ]
    require(exception_targets == [
        (44, 2), (45, 2), (44, 12), (45, 12),
        (44, 21), (44, 22), (45, 21), (45, 22),
        (44, 29), (44, 30), (45, 29), (45, 30),
    ], "merged entries 77..88 do not directly supply the exception leaves")
    require(all(entry[3] for entry in inputs["entries"][76:88]),
            "an exception entry has no exact letter terms")

    print(
        "PASS CF303 normal-factor bundle path closure; "
        f"files={len(bundle_files)} entries={len(inputs['entries'])} "
        "exceptionLeaves=12"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
