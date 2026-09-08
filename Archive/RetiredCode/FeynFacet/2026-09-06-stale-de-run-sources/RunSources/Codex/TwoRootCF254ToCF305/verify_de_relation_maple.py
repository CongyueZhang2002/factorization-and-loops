#!/usr/bin/env python3
"""Verify the crossed CF254/CF305 differential relation with exact Maple algebra."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import NoReturn


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
DE_DIRECTORY = (
    ROOT
    / "ppHX_NNLO_DoubleReal"
    / "Results"
    / "UU_08_10_canonical"
    / "DifferentialEquations"
)
SOURCE_FILE = DE_DIRECTORY / "nnlo_de_CF254.wl"
TARGET_FILE = DE_DIRECTORY / "nnlo_de_CF305.wl"
PAIR_DIRECTORY = DE_DIRECTORY.parent / "Pairs"
SOURCE_PAIR_FILE = PAIR_DIRECTORY / "F19_C26.wl"
TARGET_PAIR_FILE = PAIR_DIRECTORY / "F21_C35.wl"
RESULT_FILE = HERE / "MapleExactVerification.json"
TRANSFER_FILE = HERE / "CF254ToCF305Transfer.json"
MAPLE = Path("/home/maxzhang/.local/bin/maple")

MASTER_POSITIONS = [
    32, 6, 10, 28, 7, 11, 12, 21, 22, 23, 29, 30,
    13, 31, 15, 16, 25, 17, 18, 26, 19, 27, 20,
]


def fail(message: str) -> NoReturn:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def extract_balanced(text: str, start: int, opener: str, closer: str) -> str:
    if text[start] != opener:
        fail(f"Expected {opener!r} at byte {start}")
    depth = 0
    in_string = False
    escaped = False
    for position in range(start, len(text)):
        character = text[position]
        if in_string:
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                in_string = False
            continue
        if character == '"':
            in_string = True
        elif character == opener:
            depth += 1
        elif character == closer:
            depth -= 1
            if depth == 0:
                return text[start : position + 1]
    fail(f"Unclosed {opener!r} beginning at byte {start}")


def extract_field(text: str, key: str) -> str:
    marker = f'"{key}" ->'
    position = text.find(marker)
    if position < 0:
        fail(f"Missing field {key!r}")
    position += len(marker)
    while position < len(text) and text[position].isspace():
        position += 1
    if position >= len(text) or text[position] != "{":
        fail(f"Field {key!r} is not a list")
    return extract_balanced(text, position, "{", "}")


def split_list(source: str) -> list[str]:
    source = source.strip()
    if not (source.startswith("{") and source.endswith("}")):
        fail("Expected a Wolfram list")
    items: list[str] = []
    start = 1
    round_depth = 0
    square_depth = 0
    brace_depth = 0
    association_depth = 0
    in_string = False
    escaped = False
    position = 1
    while position < len(source) - 1:
        character = source[position]
        next_two = source[position : position + 2]
        if in_string:
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                in_string = False
            position += 1
            continue
        if character == '"':
            in_string = True
        elif next_two == "<|":
            association_depth += 1
            position += 1
        elif next_two == "|>":
            association_depth -= 1
            position += 1
        elif character == "(":
            round_depth += 1
        elif character == ")":
            round_depth -= 1
        elif character == "[":
            square_depth += 1
        elif character == "]":
            square_depth -= 1
        elif character == "{":
            brace_depth += 1
        elif character == "}":
            brace_depth -= 1
        elif (
            character == ","
            and round_depth == 0
            and square_depth == 0
            and brace_depth == 0
            and association_depth == 0
        ):
            items.append(source[start:position].strip())
            start = position + 1
        position += 1
    final = source[start:-1].strip()
    if final:
        items.append(final)
    return items


def parse_matrix(text: str, key: str) -> list[list[str]]:
    rows = [split_list(row) for row in split_list(extract_field(text, key))]
    dimensions = {len(row) for row in rows}
    if dimensions != {len(rows)}:
        fail(f"Field {key!r} is not square: {len(rows)} rows, widths {dimensions}")
    return rows


def parse_basis(text: str, family: str) -> list[tuple[int, ...]]:
    field = extract_field(text, "BlockBasis")
    matches = re.findall(r'gli\["' + family + r'",\s*\{([^}]*)\}\]', field)
    vectors = [tuple(int(value.strip()) for value in match.split(",")) for match in matches]
    if not vectors or any(len(vector) != 9 for vector in vectors):
        fail(f"Could not read the nine-index {family} basis")
    return vectors


def map_indices_254_to_305(vector: tuple[int, ...]) -> tuple[int, ...]:
    a1, a2, a3, a4, a5, a6, a7, a8, a9 = vector
    if a9 != 0:
        fail(f"CF254 basis vector has nonzero ISP power: {vector}")
    return (a1, a2, a6, a7, a3, 0, a4, a5, a8)


def add_vectors(*vectors: tuple[int, ...]) -> tuple[int, ...]:
    return tuple(sum(vector[index] for vector in vectors) for index in range(5))


def scale_vector(factor: int, vector: tuple[int, ...]) -> tuple[int, ...]:
    return tuple(factor * entry for entry in vector)


def quadratic_signature(vector: tuple[int, ...]) -> tuple[int, ...]:
    coefficients: list[int] = []
    for left in range(5):
        for right in range(left, 5):
            if left == right:
                coefficients.append(0 if left < 3 else vector[left] ** 2)
            else:
                coefficients.append(2 * vector[left] * vector[right])
    return tuple(coefficients)


def bilinear_signature(
    left_vector: tuple[int, ...], right_vector: tuple[int, ...]
) -> tuple[int, ...]:
    coefficients: list[int] = []
    for left in range(5):
        for right in range(left, 5):
            if left == right:
                coefficients.append(
                    0 if left < 3 else left_vector[left] * right_vector[left]
                )
            else:
                coefficients.append(
                    left_vector[left] * right_vector[right]
                    + left_vector[right] * right_vector[left]
                )
    return tuple(coefficients)


def add_signatures(*signatures: tuple[int, ...]) -> tuple[int, ...]:
    return tuple(
        sum(signature[index] for signature in signatures)
        for index in range(len(signatures[0]))
    )


def scale_signature(factor: int, signature: tuple[int, ...]) -> tuple[int, ...]:
    return tuple(factor * entry for entry in signature)


def topology_prefix(pair_text: str) -> str:
    start = pair_text.find('"Topologies" ->')
    if start < 0:
        fail("Pair record has no Topologies field")
    end = pair_text.find('"BaseGLI" ->', start)
    if end < 0:
        fail("Pair topology has no BaseGLI field")
    return pair_text[start:end]


def static_exact_checks(
    source_pair_text: str, target_pair_text: str
) -> dict[str, bool]:
    ka = (1, 0, 0, 0, 0)
    kb = (0, 1, 0, 0, 0)
    kc = (0, 0, 1, 0, 0)
    ke = (0, 0, 0, 1, 0)
    kf = (0, 0, 0, 0, 1)
    source_ka = scale_vector(-1, kc)
    source_kb = kb
    source_kc = scale_vector(-1, ka)
    source_ke = ke
    source_kf = kf

    source_momenta = [
        source_kf,
        source_ke,
        add_vectors(scale_vector(-1, source_ka), source_ke),
        add_vectors(scale_vector(-1, source_ka), source_ke, source_kf),
        add_vectors(
            scale_vector(-1, source_ka), source_kc, source_ke, source_kf
        ),
        add_vectors(scale_vector(-1, source_kc), scale_vector(-1, source_kf)),
        add_vectors(source_ka, scale_vector(-1, source_kc), scale_vector(-1, source_kf)),
        add_vectors(
            source_ka,
            source_kb,
            scale_vector(-1, source_kc),
            scale_vector(-1, source_ke),
            scale_vector(-1, source_kf),
        ),
    ]
    target_momenta = [
        kf,
        ke,
        add_vectors(scale_vector(-1, ka), kf),
        add_vectors(scale_vector(-1, ka), kc, kf),
        add_vectors(scale_vector(-1, kc), scale_vector(-1, ke)),
        add_vectors(scale_vector(-1, ka), scale_vector(-1, kb), kc, kf),
        add_vectors(scale_vector(-1, kc), scale_vector(-1, ke), scale_vector(-1, kf)),
        add_vectors(ka, scale_vector(-1, kc), scale_vector(-1, ke), scale_vector(-1, kf)),
        add_vectors(ka, kb, scale_vector(-1, kc), scale_vector(-1, ke), scale_vector(-1, kf)),
    ]
    denominator_image = [1, 2, 5, 7, 8, 3, 4, 9]
    momentum_signs = [1, 1, -1, -1, -1, -1, -1, 1]
    momentum_identity = all(
        source == scale_vector(sign, target_momenta[image - 1])
        for source, image, sign in zip(
            source_momenta, denominator_image, momentum_signs, strict=True
        )
    )
    denominator_identity = all(
        quadratic_signature(source) == quadratic_signature(target_momenta[image - 1])
        for source, image in zip(source_momenta, denominator_image, strict=True)
    )
    target_denominators = [quadratic_signature(momentum) for momentum in target_momenta]
    isp_right = add_signatures(
        target_denominators[5],
        scale_signature(-1, target_denominators[3]),
        target_denominators[7],
        scale_signature(-1, target_denominators[8]),
    )
    isp_identity = scale_signature(2, bilinear_signature(kb, ke)) == isp_right

    source_cut_indices = [2, 8, 1]
    target_cut_indices = [2, 9, 1]
    cut_index_identity = [denominator_image[index - 1] for index in source_cut_indices] == target_cut_indices
    source_total_cut = add_vectors(
        source_ka,
        source_kb,
        scale_vector(-1, source_kc),
        scale_vector(-1, source_ke),
        scale_vector(-1, source_kf),
    )
    target_total_cut = add_vectors(
        ka, kb, scale_vector(-1, kc), scale_vector(-1, ke), scale_vector(-1, kf)
    )
    cut_momentum_identity = [source_ke, source_total_cut, source_kf] == [
        ke,
        target_total_cut,
        kf,
    ]
    cut_sign_identity = [momentum_signs[index - 1] for index in source_cut_indices] == [1, 1, 1]

    source_topology = topology_prefix(source_pair_text)
    target_topology = topology_prefix(target_pair_text)
    compact_source_pair = re.sub(r"\s+", "", source_pair_text)
    compact_target_pair = re.sub(r"\s+", "", target_pair_text)
    phase_space_expression = '"PhaseSpace"->-((dD[ke]*dD[kf])/Pi^D)'
    source_causal_count = len(re.findall(r",\s*\{1,\s*1\}\]\]", source_topology))
    target_causal_count = len(re.findall(r",\s*\{1,\s*1\}\]\]", target_topology))
    checks = {
        "MomentumMapWithSigns": momentum_identity,
        "QuadraticDenominatorIdentity": denominator_identity,
        "SourceISPLinearIdentity": isp_identity,
        "CutIndexImage": cut_index_identity,
        "CutMomentumIdentity": cut_momentum_identity,
        "CutMomentumSignsPositive": cut_sign_identity,
        "SourcePairFamily": "FCTopology[CF254" in source_topology,
        "TargetPairFamily": "FCTopology[CF305" in target_topology,
        "SourceCutMetadata": bool(
            re.search(r'"CutIndices"\s*->\s*\{2,\s*8,\s*1\}', source_pair_text)
            and re.search(r'"CutDirections"\s*->\s*\{1,\s*1,\s*1\}', source_pair_text)
        ),
        "TargetCutMetadata": bool(
            re.search(r'"CutIndices"\s*->\s*\{2,\s*9,\s*1\}', target_pair_text)
            and re.search(r'"CutDirections"\s*->\s*\{1,\s*1,\s*1\}', target_pair_text)
        ),
        "FamilyCoefficientIdentity": (
            '"FamilyCoefficient" -> 1' in source_pair_text
            and '"FamilyCoefficient" -> 1' in target_pair_text
        ),
        "PhaseSpaceMeasureIdentity": (
            phase_space_expression in compact_source_pair
            and phase_space_expression in compact_target_pair
        ),
        "OrdinaryCausalTagsAreFeynman": source_causal_count == 9 and target_causal_count == 9,
        "CutConventionIdentity": all(
            '"CutConvention" -> "OrientedPositiveEnergyDelta"' in text
            for text in (source_pair_text, target_pair_text)
        ),
        "Gamma5SchemeIdentity": all(
            '"Gamma5Scheme" -> "BMHV"' in text
            for text in (source_pair_text, target_pair_text)
        ),
        "DimensionRuleIdentity": all(
            '"DimensionRule"->D->4-2*Global`Epsilon' in compact
            for compact in (compact_source_pair, compact_target_pair)
        ),
    }
    return checks


def maple_expression(expression: str, source_variables: bool = False) -> str:
    expression = re.sub(r"\s+", "", expression)
    identifiers = set(re.findall(r"[A-Za-z$][A-Za-z0-9$]*", expression))
    if not identifiers <= {"eps", "v", "w"}:
        fail(f"Unrecognized identifiers in DE entry: {sorted(identifiers)}")
    if source_variables:
        expression = re.sub(r"\bv\b", "u", expression)
        expression = re.sub(r"\bw\b", "z", expression)
    return expression


def build_maple_program(
    source_basis: list[tuple[int, ...]],
    source_av: list[list[str]],
    source_aw: list[list[str]],
    target_av: list[list[str]],
    target_aw: list[list[str]],
) -> tuple[str, dict[str, int]]:
    source_dimension = len(source_basis)
    target_dimension = len(target_av)
    selected = [position - 1 for position in MASTER_POSITIONS]
    complement = sorted(set(range(target_dimension)) - set(selected))
    lines = [
        "restart:",
        "Ddim := 4-2*eps:",
        "u := -v/w:",
        "z := 1/w:",
        "Ymap := y/(y-1):",
        "Smap := -(s*y+s-5*y+3)/(s*y-s-y+1):",
        "X13 := (1+S)*(-3+S+2*Y)/(-1+S^2+4*Y-4*Y^2):",
        "V13 := X13*Y:",
        "W13 := (1-X13)*(1-Y):",
        "R13a := X13-Y:",
        "R13b := (1-Y)+S*(X13-1):",
        "X23 := (-3+s)*(1+s-2*y)/(-1+s^2):",
        "V23 := -X23*y:",
        "W23 := (1-X23)*(1-y):",
        "R23a := X23-y:",
        "R23b := (1+y)+s*(X23-1):",
        "failureCount := 0:",
    ]
    scalar_checks = [
        (
            "ChartPhysicalV",
            "subs({Y=Ymap,S=Smap},V13)+V23/W23",
        ),
        (
            "ChartPhysicalW",
            "subs({Y=Ymap,S=Smap},W13)-1/W23",
        ),
        (
            "ChartInverseY",
            "subs({Y=Ymap,S=Smap},Y/(Y-1))-y",
        ),
        (
            "ChartInverseS",
            "subs({Y=Ymap,S=Smap},(S+2*Y+3)/(S+2*Y-1))-s",
        ),
        (
            "ChartForwardY",
            "subs({y=Y/(Y-1),s=(S+2*Y+3)/(S+2*Y-1)},y/(y-1))-Y",
        ),
        (
            "ChartForwardS",
            "subs({y=Y/(Y-1),s=(S+2*Y+3)/(S+2*Y-1)},"
            "-(s*y+s-5*y+3)/(s*y-s-y+1))-S",
        ),
        (
            "KallenRootFirst",
            "subs({Y=Ymap,S=Smap},R13a)+R23a/W23",
        ),
        (
            "KallenRootSecond",
            "subs({Y=Ymap,S=Smap},R13b)-R23b/W23",
        ),
        (
            "KallenSquareFirst",
            "((1-u-z)^2-4*u*z)-((1+v-w)^2+4*v*w)/w^2",
        ),
        (
            "KallenSquareSecond",
            "((1-u+z)^2+4*u*z)-((1-v+w)^2+4*v*w)/w^2",
        ),
    ]
    for name, expression in scalar_checks:
        lines.extend(
            [
                f"residual := normal({expression}):",
                "if residual <> 0 then",
                f'  printf("SCALAR {name}: %a\\n", residual):',
                "  failureCount := failureCount+1:",
                "end if:",
            ]
        )
    closure_checks = 0
    transformed_checks = 0

    for direction, matrix in (("v", target_av), ("w", target_aw)):
        for source_row, target_row in enumerate(selected, start=1):
            for target_column in complement:
                expression = maple_expression(matrix[target_row][target_column])
                closure_checks += 1
                if expression == "0":
                    continue
                lines.extend(
                    [
                        f"residual := normal({expression}):",
                        "if residual <> 0 then",
                        f'  printf("CLOSURE {direction} row {source_row} target-column {target_column + 1}: %a\\n", residual):',
                        "  failureCount := failureCount+1:",
                        "end if:",
                    ]
                )

    powers = [sum(vector) for vector in source_basis]
    for direction, target_matrix in (("v", target_av), ("w", target_aw)):
        for row in range(source_dimension):
            for column in range(source_dimension):
                source_v = maple_expression(source_av[row][column], source_variables=True)
                source_w = maple_expression(source_aw[row][column], source_variables=True)
                target = maple_expression(target_matrix[selected[row]][selected[column]])
                ratio = powers[column] - powers[row]
                if direction == "v":
                    predicted = f"(-w)^({ratio})*(-1/w)*({source_v})"
                else:
                    diagonal = f"(Ddim-{powers[row]})/w" if row == column else "0"
                    predicted = (
                        f"({diagonal})+(-w)^({ratio})*"
                        f"((v/w^2)*({source_v})-(1/w^2)*({source_w}))"
                    )
                transformed_checks += 1
                if target == "0" and source_v == "0" and source_w == "0" and row != column:
                    continue
                lines.extend(
                    [
                        f"residual := normal(({target})-({predicted})):",
                        "if residual <> 0 then",
                        f'  printf("CONNECTION {direction} row {row + 1} column {column + 1}: %a\\n", residual):',
                        "  failureCount := failureCount+1:",
                        "end if:",
                    ]
                )

    lines.extend(
        [
            'printf("MAPLE_FAILURE_COUNT=%d\\n", failureCount):',
            'printf("MAPLE_SCALAR_CHECKS=%d\\n", '
            + str(len(scalar_checks))
            + "): ",
            'printf("MAPLE_CLOSURE_CHECKS=%d\\n", '
            + str(closure_checks)
            + "): ",
            'printf("MAPLE_TRANSFORMED_CHECKS=%d\\n", '
            + str(transformed_checks)
            + "): ",
            "quit:",
        ]
    )
    counts = {
        "ScalarIdentities": len(scalar_checks),
        "ClosureEntries": closure_checks,
        "TransformedConnectionEntries": transformed_checks,
    }
    return "\n".join(lines) + "\n", counts


def write_json_atomic(path: Path, record: dict[str, object]) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n")
    temporary.replace(path)


def main() -> None:
    print(
        "Acceptance criterion: every denominator, ISP, cut, chart, root, "
        "closure, and transformed-connection residual is exactly zero."
    )
    if not MAPLE.is_file():
        fail(f"Maple executable not found: {MAPLE}")
    for path in (SOURCE_FILE, TARGET_FILE, SOURCE_PAIR_FILE, TARGET_PAIR_FILE):
        if not path.is_file():
            fail(f"Required DE file not found: {path}")

    for path in (RESULT_FILE, TRANSFER_FILE):
        if path.exists():
            path.unlink()

    source_text = SOURCE_FILE.read_text()
    target_text = TARGET_FILE.read_text()
    source_pair_text = SOURCE_PAIR_FILE.read_text()
    target_pair_text = TARGET_PAIR_FILE.read_text()
    static_checks = static_exact_checks(source_pair_text, target_pair_text)
    failed_static_checks = [name for name, value in static_checks.items() if not value]
    if failed_static_checks:
        fail(f"Static exact checks failed: {failed_static_checks}")

    source_basis = parse_basis(source_text, "CF254")
    target_basis = parse_basis(target_text, "CF305")
    if len(source_basis) != 23 or len(target_basis) != 32:
        fail(f"Unexpected basis dimensions: {len(source_basis)} and {len(target_basis)}")

    mapped = [map_indices_254_to_305(vector) for vector in source_basis]
    derived_positions: list[int] = []
    for vector in mapped:
        hits = [position + 1 for position, target in enumerate(target_basis) if target == vector]
        if len(hits) != 1:
            fail(f"Mapped vector occurs {len(hits)} times in CF305: {vector}")
        derived_positions.append(hits[0])
    if derived_positions != MASTER_POSITIONS:
        fail(f"Derived master positions differ: {derived_positions}")

    source_av = parse_matrix(source_text, "Av")
    source_aw = parse_matrix(source_text, "Aw")
    target_av = parse_matrix(target_text, "Av")
    target_aw = parse_matrix(target_text, "Aw")
    if (len(source_av), len(target_av)) != (23, 32):
        fail(f"Unexpected matrix dimensions: {len(source_av)} and {len(target_av)}")

    program, counts = build_maple_program(
        source_basis, source_av, source_aw, target_av, target_aw
    )
    completed = subprocess.run(
        [str(MAPLE), "-q"],
        input=program,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.stdout:
        print(completed.stdout, end="")
    if completed.stderr:
        print(completed.stderr, file=sys.stderr, end="")
    if (
        completed.returncode != 0
        or completed.stderr.strip()
        or "MAPLE_FAILURE_COUNT=0" not in completed.stdout
    ):
        fail(f"Exact Maple calculation failed with exit code {completed.returncode}")

    record = {
        "Format": "CF254ToCF305MapleExactVerification",
        "FormatVersion": 1,
        "Arithmetic": "Exact rational functions over Q(eps,v,w)",
        "SourceFamily": "CF254",
        "TargetFamily": "CF305",
        "SourceDimension": len(source_basis),
        "TargetDimension": len(target_basis),
        "SourceToTargetPositions": derived_positions,
        "ComplementaryTargetPositions": sorted(
            set(range(1, len(target_basis) + 1)) - set(derived_positions)
        ),
        "PhysicalVariableMap": {"v254": "-v305/w305", "w254": "1/w305"},
        "HomogeneityGauge": (
            "H_ii=Exp[(4-2 eps-sum(a_i)) CrossedFeynmanLog[-w305]]"
        ),
        "StaticExactChecks": static_checks,
        "ClosureCriterionSatisfied": True,
        "TransformedConnectionIdentitySatisfied": True,
        "CheckedEntryCounts": counts,
        "SourceDESHA256": sha256(SOURCE_FILE),
        "TargetDESHA256": sha256(TARGET_FILE),
        "SourcePairSHA256": sha256(SOURCE_PAIR_FILE),
        "TargetPairSHA256": sha256(TARGET_PAIR_FILE),
    }
    transfer_record = {
        "Format": "FeynFacetExactFamilyTransfer",
        "FormatVersion": 1,
        "Type": "ExactPoweredIntegralClosedSubsectorEmbedding",
        "SourceFamily": "CF254",
        "TargetFamily": "CF305",
        "Classification": (
            "The complete 23-master CF254 system embeds in the closed D6=0 "
            "subsector of the 32-master CF305 system. The complete powered "
            "families are not equivalent for arbitrary CF254 ISP power."
        ),
        "TargetPhysicalRegion": "0<v305, 0<w305, v305+w305<1",
        "DimensionfulExternalMap": {
            "ka254": "-kc305",
            "kb254": "kb305",
            "kc254": "-ka305",
        },
        "LoopMomentumMap": {"ke254": "ke305", "kf254": "kf305"},
        "LoopJacobian": 1,
        "LoopMeasure": "-d^D ke d^D kf/Pi^D",
        "FamilyCoefficient": 1,
        "DimensionRule": "D=4-2 eps",
        "DenominatorImage": {
            "D254[1]": "D305[1]",
            "D254[2]": "D305[2]",
            "D254[3]": "D305[5]",
            "D254[4]": "D305[7]",
            "D254[5]": "D305[8]",
            "D254[6]": "D305[3]",
            "D254[7]": "D305[4]",
            "D254[8]": "D305[9]",
        },
        "DenominatorMomentumSigns": [1, 1, -1, -1, -1, -1, -1, 1],
        "SourceISPIdentity": "2 D254[9]=D305[6]-D305[4]+D305[8]-D305[9]",
        "TargetAdditionalDenominator": 6,
        "PoweredCondition": "a9=0",
        "PoweredIndexMap": (
            "(a1,a2,a3,a4,a5,a6,a7,a8,0)->"
            "(a1,a2,a6,a7,a3,0,a4,a5,a8)"
        ),
        "DimensionfulPoweredIntegralIdentity": (
            "I254[(a1,a2,a3,a4,a5,a6,a7,a8,0);(-kc,kb,-ka);"
            "(ke,kf);D;+i0;delta+]=I305[(a1,a2,a6,a7,a3,0,a4,a5,a8);"
            "(ka,kb,kc);(ke,kf);D;+i0;delta+]"
        ),
        "CutIndexMap": "(2,8,1)->(2,9,1)",
        "CutMomenta": ["ke", "ka+kb-kc-ke-kf", "kf"],
        "CutDirections": [1, 1, 1],
        "CutConvention": "OrientedPositiveEnergyDelta",
        "OrdinaryCausalTag": [1, 1],
        "Gamma5Scheme": "BMHV",
        "NormalizedPhysicalVariableMap": {
            "v254": "-v305/w305",
            "w254": "1/w305",
        },
        "CrossedSourceRegion": "v254<0, w254>1",
        "ScaleRatio": "S254/S305=-w305",
        "NormalizedScaleGauge": "H_ii=Exp[(4-2 eps-A_i) CrossedFeynmanLog[-w305]]",
        "ScaleBranch": (
            "CrossedFeynmanLog is inherited from the dimensionful identity "
            "with unchanged +i0 tags and remains unevaluated. The rational "
            "DE identity uses only d Log(-w305)=dw305/w305."
        ),
        "SourceChart": "Kallen13",
        "TargetChart": "Kallen23",
        "ChartMapTargetToSource": {
            "y254": "y305/(y305-1)",
            "s254": (
                "-(s305*y305+s305-5*y305+3)/"
                "(s305*y305-s305-y305+1)"
            ),
        },
        "ChartMapSourceToTarget": {
            "y305": "y254/(y254-1)",
            "s305": "(s254+2*y254+3)/(s254+2*y254-1)",
        },
        "KallenRootBranchRules": {
            "r1_CF254": "-r2_CF305/w305",
            "r3_CF254": "r3_CF305/w305",
        },
        "SourceToTargetPositions": derived_positions,
        "ComplementaryTargetPositions": sorted(
            set(range(1, len(target_basis) + 1)) - set(derived_positions)
        ),
        "DifferentialOneFormCriterion": (
            "S Omega305=(dH H^(-1)+H Phi^*(Omega254) H^(-1)) S"
        ),
        "ClosureCriterion": "S A305_mu Q^T=0 for mu in {v305,w305}",
        "SelectedConnectionAv": (
            "Bv=H[-A254_v(Phi)/w305]H^(-1)"
        ),
        "SelectedConnectionAw": (
            "Bw=diag((D-A_i)/w305)+H[(v305/w305^2)A254_v(Phi)-"
            "A254_w(Phi)/w305^2]H^(-1)"
        ),
        "ExactChecks": {
            **static_checks,
            "MasterMapDerivedExactly": True,
            "ChartAndRootIdentities": True,
            "SelectedRowsClosed": True,
            "TransformedConnectionIdentity": True,
        },
        "CheckedEntryCounts": counts,
        "InputFiles": {
            str(SOURCE_FILE): sha256(SOURCE_FILE),
            str(TARGET_FILE): sha256(TARGET_FILE),
            str(SOURCE_PAIR_FILE): sha256(SOURCE_PAIR_FILE),
            str(TARGET_PAIR_FILE): sha256(TARGET_PAIR_FILE),
        },
    }
    write_json_atomic(RESULT_FILE, record)
    write_json_atomic(TRANSFER_FILE, transfer_record)
    print("Acceptance criterion satisfied: all exact residuals are zero.")
    print(f"Exact result record: {RESULT_FILE}")
    print(f"Transfer record: {TRANSFER_FILE}")


if __name__ == "__main__":
    main()
