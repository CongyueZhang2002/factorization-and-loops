#!/usr/bin/env python3
"""Build the typed CF303 (25,2) exact-path exception record.

Assembly ranges and block-basis identities are extracted from the saved sector
state rather than copied from a handwritten table.  Acceptance files and the
source/checkpoint hashes are checked before either output is written.
"""

from __future__ import annotations

import argparse
import ast
import hashlib
import json
import re
from pathlib import Path
from typing import Any


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
SOURCE_RUNTIME = ROOT / "Runtime/CF303_exception14_continuation_2026-08-30"
SOURCE_INPUT = SOURCE_RUNTIME / "sector_CF303_standard/CF303_25_2_input.wl"
SOURCE_CHECKPOINT = (
    SOURCE_RUNTIME / "sector_CF303_standard/CF303_25_strip_state.wl"
)
SECTOR_STATE = SOURCE_RUNTIME / "sector_state_CF303_standard.wl"
UNSOLVED = SOURCE_RUNTIME / "sector_CF303_standard/CF303_25_2_unsolved.wl"
COMMON_PATH = ROOT / "Diagnostics/Artifacts/cf303_u3_common_path_contract.wl"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_integer_lists(text: str) -> list[list[int]]:
    return ast.literal_eval(text.replace("{", "[").replace("}", "]"))


def sector_layout() -> tuple[list[list[int]], list[list[int]]]:
    snippet: list[str] = []
    collecting = False
    with SECTOR_STATE.open() as stream:
        for line in stream:
            if '"Ranges" ->' in line:
                if collecting:
                    raise RuntimeError("duplicate Ranges field in sector state")
                collecting = True
            if collecting:
                snippet.append(line)
                if '"ChartFingerprint" ->' in line:
                    break
    joined = "".join(snippet)
    match = re.search(
        r'"Ranges"\s*->\s*(\{\{.*?\}\})\s*,\s*"Blocks"\s*->\s*'
        r'(\{\{.*?\}\})\s*,\s*"ChartFingerprint"',
        joined, re.DOTALL,
    )
    if match is None:
        raise RuntimeError("cannot extract Ranges/Blocks from sector state")
    ranges = parse_integer_lists(match.group(1))
    blocks = parse_integer_lists(match.group(2))
    if len(ranges) != 25 or len(blocks) != 25:
        raise RuntimeError("sector-state layout does not contain 25 blocks")
    return ranges, blocks


def input_ranges() -> tuple[list[int], list[int]]:
    text = SOURCE_INPUT.read_text()
    row = re.search(r'"RowIndices"\s*->\s*\{([^}]*)\}', text)
    column = re.search(r'"ColumnIndices"\s*->\s*\{([^}]*)\}', text)
    if row is None or column is None:
        raise RuntimeError("source input does not expose row/column indices")
    parse = lambda match: [int(item.strip()) for item in match.group(1).split(",")]
    return parse(row), parse(column)


def wl_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def wl_list(values: list[int]) -> str:
    return "{" + ", ".join(map(str, values)) + "}"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--runtime-directory", type=Path, required=True)
    parser.add_argument("--record", type=Path, required=True)
    parser.add_argument("--basis-evidence", type=Path, required=True)
    args = parser.parse_args()
    artifact = args.runtime_directory / "cf303_25_2_exact_structured_path.wl"
    report_file = args.runtime_directory / "cf303_25_2_exact_path_report.json"
    unseen_file = args.runtime_directory / "cf303_25_2_exact_path_unseen_prime.json"
    coefficient_file = args.runtime_directory / "cf303_25_2_exact_path_coefficients.json"
    campaign_checkpoint = (
        args.runtime_directory / "cf303_25_2_path_campaign_checkpoint.json"
    )
    path_degree = (
        args.runtime_directory /
        "cf303_25_2_common_path_degree_p2147483423_e11.json"
    )
    epsilon_degree = (
        args.runtime_directory /
        "cf303_25_2_common_epsilon_degree_p2147483423_z27.json"
    )
    required = (
        SOURCE_INPUT, SOURCE_CHECKPOINT, SECTOR_STATE, UNSOLVED, COMMON_PATH,
        artifact, report_file, unseen_file, coefficient_file,
        campaign_checkpoint, path_degree, epsilon_degree,
    )
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise RuntimeError(f"missing record inputs: {missing}")
    report = json.loads(report_file.read_text())
    unseen = json.loads(unseen_file.read_text())
    path_probe = json.loads(path_degree.read_text())
    epsilon_probe = json.loads(epsilon_degree.read_text())
    if (
        report.get("status") != "CF303Block2ExactPathReadyV1"
        or report.get("acceptance") != "ExactPathForcingAccepted"
        or unseen.get("status") != "CF303Block2ExactPathUnseenPrimeAcceptedV1"
        or path_probe.get("status") != "CF303Block2CommonPathCompatibleV1"
        or epsilon_probe.get("status") != "CF303Block2CommonPathCompatibleV1"
    ):
        raise RuntimeError("path acceptance evidence is incomplete")

    ranges, blocks = sector_layout()
    row_range, column_range = input_ranges()
    row_position = ranges.index(row_range)
    column_position = ranges.index(column_range)
    if row_position != 24 or column_position != 1:
        raise RuntimeError(
            f"unexpected assembly positions row={row_position+1} "
            f"column={column_position+1}"
        )
    row_basis = blocks[row_position]
    column_basis = blocks[column_position]
    if row_basis != [5, 6] or column_basis != [39]:
        raise RuntimeError(
            f"unexpected checkpoint basis row={row_basis} column={column_basis}"
        )

    basis_evidence: dict[str, Any] = {
        "status": "CF303Block2CheckpointBasisDerivedV1",
        "sector_state": str(SECTOR_STATE),
        "sector_state_sha256": sha256(SECTOR_STATE),
        "strip_checkpoint": str(SOURCE_CHECKPOINT),
        "strip_checkpoint_sha256": sha256(SOURCE_CHECKPOINT),
        "source_input": str(SOURCE_INPUT),
        "source_input_sha256": sha256(SOURCE_INPUT),
        "hard_sector": 25, "lower_sector": 2,
        "row_block_position": row_position + 1,
        "column_block_position": column_position + 1,
        "row_range": row_range, "column_range": column_range,
        "row_block_basis": row_basis, "column_block_basis": column_basis,
        "derivation": (
            "matched DeferredPreparation RowIndices/ColumnIndices to the "
            "same-position Ranges/Blocks lists in the saved sector state"
        ),
    }
    args.basis_evidence.parent.mkdir(parents=True, exist_ok=True)
    args.basis_evidence.write_text(json.dumps(basis_evidence, indent=2) + "\n")

    evidence = [
        path_degree, epsilon_degree, report_file, unseen_file,
        campaign_checkpoint, args.basis_evidence,
    ]
    lines = [
        "<|",
        '  "Status" -> "ExactPathTransportExceptionReadyV1",',
        '  "Family" -> "CF303", "Sector" -> 25, "HardSector" -> 25,',
        '  "LowerSector" -> 2,',
        '  "Method" -> "ExactRationalPathTransportException",',
        '  "Gauge" -> "LiteralZero", "Installed" -> False,',
        '  "ExactDLog" -> False,',
        f'  "ArtifactFile" -> {wl_string(str(artifact.resolve()))},',
        '  "ArtifactStatus" -> "CF303Block2ExactStructuredPathV1",',
        f'  "SourceInput" -> {wl_string(str(SOURCE_INPUT))},',
        f'  "SourceCheckpoint" -> {wl_string(str(SOURCE_CHECKPOINT))},',
        f'  "SourceInputSHA256" -> {wl_string(sha256(SOURCE_INPUT))},',
        f'  "SourceCheckpointSHA256" -> {wl_string(sha256(SOURCE_CHECKPOINT))},',
        f'  "RowRange" -> {wl_list(row_range)},',
        f'  "ColumnRange" -> {wl_list(column_range)},',
        f'  "RowBlockBasis" -> {wl_list(row_basis)},',
        f'  "ColumnBlockBasis" -> {wl_list(column_basis)},',
        '  "SourceDimensions" -> {2, 2, 1}, "Dimensions" -> {2, 2, 1},',
        '  "PathDimensions" -> {2, 1},',
        f'  "BasisDerivationEvidence" -> {wl_string(str(args.basis_evidence.resolve()))},',
        '  "Path" -> <|',
        '    "Chart" -> "Kallen2Bilinear115",',
        '    "ArtifactIdentity" -> <|"Chart" -> "Kallen2Bilinear115",',
        '      "FrozenChartU" -> 3|>,',
        '    "Coordinate" -> "p", "FrozenCoordinate" -> <|"u" -> 3|>,',
        '    "SourceMap" ->',
        '      "a=(4 p (1-p)-6)/(9+4 p (1-p)); x=-a p; y=(1-a)(1-p)",',
        '    "BranchRoots" -> {"a-p", "1+3a"},',
        '    "EndpointContract" ->',
        '      "p(tau)=p0+tau (p1-p0), tau in [0,1], u=3",',
        '    "Reparameterization" ->',
        '      "B_tau(tau,eps)=(p1-p0) B_p(p0+tau(p1-p0),eps)"',
        '  |>,',
        '  "PathExtension" -> <|"Type" -> "None"|>,',
        f'  "CommonPathContract" -> {wl_string(str(COMMON_PATH))},',
        '  "ConstantConvention" ->',
        '    "derive final c25 from authoritative complete PrevD/current A at the eventual row endpoint: c25=Inverse[Phi25[p0]].(I25[p0]-Sum[D25m[p0].Im[p0],{m,1,24}]); D25,2=0",',
        '  "ExactContent" ->',
        '    "accepted-gauge B_(25,2) contracted with dp on the declared fixed path; the literal-zero gauge contribution is additive",',
        '  "Acceptance" -> "ExactPathForcingAccepted",',
        '  "Consumer" ->',
        '    "CodexDiagnostics`ExactPathTransportException`InstallExactPathTransportExceptionIntoAhat",',
        '  "InstallationStage" ->',
        '    "after every other coupling has been restricted to the same path and before masterTransportDepthBudget/masterTransportBlockwiseSolve",',
        '  "AssemblyRequirement" ->',
        '    "the caller must supply a complete path connection without eagerly materializing this exceptional source block",',
        '  "GaugeScreenDisposition" ->',
        '    "31-form conservative-superset GaugeImageObstruction at two images is ansatz-relative motivation only and is not promoted to a global obstruction",',
        '  "ClaimBoundary" ->',
        '    "exact accepted-gauge forcing only on the fixed u=3 path; ExactPathForcingAccepted, not EpsFormObstructionCertified, global no-eps-form, or a family epsilon-form certificate",',
        '  "AcceptanceEvidence" -> {',
        *(f"    {wl_string(str(path.resolve()))}" +
          ("," if index + 1 < len(evidence) else "")
          for index, path in enumerate(evidence)),
        '  }',
        '|>',
        "",
    ]
    args.record.parent.mkdir(parents=True, exist_ok=True)
    args.record.write_text("\n".join(lines))
    print(json.dumps({
        "status": "CF303Block2ExceptionRecordBuiltV1",
        "record": str(args.record),
        "basis_evidence": str(args.basis_evidence),
        "row_range": row_range, "column_range": column_range,
        "row_block_basis": row_basis, "column_block_basis": column_basis,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
