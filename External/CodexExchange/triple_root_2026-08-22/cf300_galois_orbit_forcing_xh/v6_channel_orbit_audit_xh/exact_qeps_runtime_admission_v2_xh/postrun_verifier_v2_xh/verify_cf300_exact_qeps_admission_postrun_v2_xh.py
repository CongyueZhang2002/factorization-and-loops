#!/usr/bin/env python3
"""Read-only, no-Wolfram post-run verifier for the exact-Q(eps) admission mission."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import mmap
import os
import re
import sys
from dataclasses import dataclass, field
from fractions import Fraction
from pathlib import Path
from typing import Dict, List, Mapping, MutableMapping, Sequence, Tuple


Span = Tuple[int, int]
HEX64 = re.compile(r"^[0-9a-f]{64}$")
MAX_CERTIFICATE_BYTES = 1 << 30
MAX_SMALL_OUTPUT_BYTES = 1 << 24
PROJECT_ROOT = "/home/maxzhang/factorization-and-loops"
TRANSFORMED_DRIVER_SHA = "35c3c32e6db5c1b5bb0accd62b7516b43b264191b664f6377e4d8d0d87f31ac8"
EXACT_MANIFEST_SHA = "642fb0b403c1c68e04e9943945e32b3b66b923265e50777c3fef3da85e451757"
ADMISSION_MANIFEST_SHA = "7db4c3cc751764a07ad0a7134578ec59459bd0276b371c04a4d8ac03b1ee0c80"
ORBIT_CORE_SHA = "7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed"
V6D_SHA = "20823fde76827c8d8a9db66e617eacde276c9bdac0871ccdba80aad1d5aeb1cf"
ASSEMBLY_FP = "32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7"
POINTS_FP = "f4ac00e6c1636c2f20028a2de449ea66a816ea017a84de6874dd63e54e155b50"
COEFF_PIVOT_FP = "ccc7fa776fdcf55017e98e8d57ee2480690db3c27e0dc8f8625acebd79bfe377"
FREE_FP = "2c25a885fd903d2e0f828c13ecd6e2a9a36babfbe6decb4f4f3af3335cdc9534"
COEFF_ROWS_FP = "9924c7eef76fea745d5451876be6012810e205e7ca28e021dd99cb2c720d9914"
AUG_PIVOT_FP = "8a9731fd7c345e781d71102d9cb3f8f0d745de3b17264e11b62ef538af0cb761"
AUG_ROWS_FP = "3f35c25a1819c8c11ee28d300e252c47beda7f8213bcd45ac54f417fba3023a7"


EXACT_SOURCE_HASHES: Mapping[str, str] = {
    "LoadFACET": "e324b5f6c30d34a70248b691183abb1904d1a27fd745e3c4b8b0b381122e6164",
    "TripleRootAlgebra": "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab",
    "TripleRootStripAdapter": "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5",
    "TripleRootAffinePilot": "283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90",
    "TripleRootReconstructionPrototype": "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43",
    "Assembler": "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6",
    "WitnessReference": "6d2ea56523cbee20c71efc265150ebd001d701421cac08dc69bb77296dafe79f",
    "OrbitCoreV6d": ORBIT_CORE_SHA,
    "ExactWitnessHelper": "e055bb88e0884c33edb51c3b52f26943b93e69f27317caead8b0d462b580325b",
    "ModularReconstruction": "0c50fe48adc4bd28181e0954a2191a8c49452779a134405e1c27b6cd27def1ce",
    "FiniteFieldStripSolve": "8721847e5964986a952bb52c2551ed1099b24b255999344f38c5efa848cf4c70",
    "NativeFixedSquareBinary": "e2d7d3ee375f712a20c62b31c4510b9cdac2fa13f7cce5256bb05733bee9d46b",
}
HELD_SOURCE_HASHES: Mapping[str, str] = {
    "AdmissionDriver": "7e57344560dbf102b84f95640b32000455060c5d933d96f35c294e1f3c6c7630",
    "FrozenDriver": "446da75743811e2c3d1e2a438205a74786883fa7a4363304c37d911685bfa174",
    "ExactHelper": EXACT_SOURCE_HASHES["ExactWitnessHelper"],
    "ModularReconstruction": EXACT_SOURCE_HASHES["ModularReconstruction"],
    "PrerequisiteSchema": "909bc658858dc701cf05643e943655ea69fe301240f13272c70cc560c5506b45",
}
ADMISSION_RUNTIME_HASHES: Mapping[str, str] = {
    "FrozenDriver": HELD_SOURCE_HASHES["FrozenDriver"],
    "ExactHelper": HELD_SOURCE_HASHES["ExactHelper"],
    "ModularReconstruction": HELD_SOURCE_HASHES["ModularReconstruction"],
    "PrerequisiteSchema": HELD_SOURCE_HASHES["PrerequisiteSchema"],
    "FrozenManifest": EXACT_MANIFEST_SHA,
    "KpSubmit": "138315a11149c14fc3491a008e6e7ad4d23623d29a2228fbdea31d4384707ddc",
    "V6dArtifact": V6D_SHA,
}


class VerificationError(RuntimeError):
    pass


def fail(message: str) -> None:
    raise VerificationError(message)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(8 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require_regular(path: Path, label: str) -> None:
    if not path.exists() or not path.is_file() or path.is_symlink():
        fail(f"{label} is not a non-symlink regular file: {path}")


class WLDocument:
    """Non-evaluating structural view of one Put-generated WL expression."""

    def __init__(self, path: Path):
        self.file_path = path
        self._stream = path.open("rb")
        self.data = mmap.mmap(self._stream.fileno(), 0, access=mmap.ACCESS_READ)
        self.root: Span = (0, len(self.data))
        self._assoc_cache: MutableMapping[Span, Dict[str, Span]] = {}
        self._list_cache: MutableMapping[Span, List[Span]] = {}

    def close(self) -> None:
        self.data.close()
        self._stream.close()

    def __enter__(self) -> "WLDocument":
        return self

    def __exit__(self, *_: object) -> None:
        self.close()

    def _skip_ws(self, position: int, end: int) -> int:
        while position < end:
            if self.data[position] in b" \t\r\n":
                position += 1
            elif self.data[position : position + 2] == b"(*":
                position = self._skip_comment(position, end)
            else:
                break
        return position

    def _skip_comment(self, position: int, end: int) -> int:
        depth = 0
        while position < end:
            token = self.data[position : position + 2]
            if token == b"(*":
                depth += 1
                position += 2
            elif token == b"*)":
                depth -= 1
                position += 2
                if depth == 0:
                    return position
            else:
                position += 1
        fail(f"unterminated WL comment in {self.file_path}")

    def _skip_string(self, position: int, end: int) -> int:
        if self.data[position] != ord('"'):
            fail("internal string scanner misuse")
        position += 1
        while position < end:
            if self.data[position] == ord("\\"):
                position += 2
            elif self.data[position] == ord('"'):
                return position + 1
            else:
                position += 1
        fail(f"unterminated WL string in {self.file_path}")

    def _split_items(self, start: int, end: int, closing: bytes) -> List[Span]:
        position = self._skip_ws(start, end)
        item_start = position
        stack: List[bytes] = []
        items: List[Span] = []
        openers = {b"<|": b"|>", b"{": b"}", b"[": b"]", b"(": b")"}
        while position < end:
            if self.data[position] == ord('"'):
                position = self._skip_string(position, end)
                continue
            token2 = self.data[position : position + 2]
            if token2 == b"(*":
                position = self._skip_comment(position, end)
                continue
            if token2 == b"<|":
                stack.append(b"|>")
                position += 2
                continue
            if token2 == b"|>":
                if stack:
                    if stack[-1] != b"|>":
                        fail(f"mismatched WL delimiter in {self.file_path}")
                    stack.pop()
                    position += 2
                    continue
                if closing != b"|>" or self._skip_ws(position + 2, end) != end:
                    fail(f"invalid association close in {self.file_path}")
                if self._skip_ws(item_start, position) < position:
                    items.append((item_start, position))
                return items
            token1 = bytes((self.data[position],))
            if token1 in (b"{", b"[", b"("):
                stack.append(openers[token1])
                position += 1
                continue
            if token1 in (b"}", b"]", b")"):
                if stack:
                    if stack[-1] != token1:
                        fail(f"mismatched WL delimiter in {self.file_path}")
                    stack.pop()
                    position += 1
                    continue
                if token1 != closing or self._skip_ws(position + 1, end) != end:
                    fail(f"invalid list close in {self.file_path}")
                if self._skip_ws(item_start, position) < position:
                    items.append((item_start, position))
                return items
            if self.data[position] == ord(",") and not stack:
                if self._skip_ws(item_start, position) >= position:
                    fail(f"empty WL item in {self.file_path}")
                items.append((item_start, position))
                position = self._skip_ws(position + 1, end)
                item_start = position
                continue
            position += 1
        fail(f"unterminated WL container in {self.file_path}")

    def _trim(self, span: Span) -> Span:
        start, end = span
        start = self._skip_ws(start, end)
        while end > start and self.data[end - 1] in b" \t\r\n":
            end -= 1
        return start, end

    def raw(self, span: Span) -> bytes:
        start, end = self._trim(span)
        return self.data[start:end]

    def assoc(self, span: Span | None = None) -> Dict[str, Span]:
        span = self.root if span is None else self._trim(span)
        if span in self._assoc_cache:
            return self._assoc_cache[span]
        start, end = span
        if self.data[start : start + 2] != b"<|":
            fail(f"expected Association at byte {start} in {self.file_path}")
        result: Dict[str, Span] = {}
        for rule in self._split_items(start + 2, end, b"|>"):
            rs, re_ = self._trim(rule)
            if self.data[rs] != ord('"'):
                fail(f"non-string Association key in {self.file_path}")
            key_end = self._skip_string(rs, re_)
            arrow = self._skip_ws(key_end, re_)
            if self.data[arrow : arrow + 2] != b"->":
                fail(f"non-immediate Association rule in {self.file_path}")
            key = self.as_string((rs, key_end))
            if key in result:
                fail(f"duplicate Association key {key!r} in {self.file_path}")
            value_start = self._skip_ws(arrow + 2, re_)
            if value_start >= re_:
                fail(f"empty value for key {key!r} in {self.file_path}")
            result[key] = (value_start, re_)
        self._assoc_cache[span] = result
        return result

    def list_items(self, span: Span) -> List[Span]:
        span = self._trim(span)
        if span in self._list_cache:
            return self._list_cache[span]
        start, end = span
        if self.data[start : start + 1] != b"{":
            fail(f"expected List at byte {start} in {self.file_path}")
        items = self._split_items(start + 1, end, b"}")
        self._list_cache[span] = items
        return items

    def get(self, span: Span, key: str) -> Span:
        association = self.assoc(span)
        if key not in association:
            fail(f"missing key {key!r} in {self.file_path}")
        return association[key]

    def path(self, *keys: str) -> Span:
        span = self.root
        for key in keys:
            span = self.get(span, key)
        return span

    def as_string(self, span: Span) -> str:
        raw = self.raw(span)
        if len(raw) < 2 or raw[0] != ord('"') or raw[-1] != ord('"'):
            fail(f"expected string in {self.file_path}, got {raw[:80]!r}")
        output = bytearray()
        position = 1
        while position < len(raw) - 1:
            if raw[position] != ord("\\"):
                output.append(raw[position])
                position += 1
                continue
            position += 1
            if position >= len(raw) - 1:
                fail(f"dangling string escape in {self.file_path}")
            escaped = raw[position]
            replacements = {ord('"'): ord('"'), ord("\\"): ord("\\"),
                            ord("n"): 10, ord("r"): 13, ord("t"): 9}
            output.append(replacements.get(escaped, escaped))
            position += 1
        return output.decode("utf-8")

    def as_bool(self, span: Span) -> bool:
        raw = self.raw(span)
        if raw == b"True":
            return True
        if raw == b"False":
            return False
        fail(f"expected Boolean in {self.file_path}, got {raw[:80]!r}")

    def as_int(self, span: Span) -> int:
        raw = self.raw(span)
        if not re.fullmatch(rb"[+-]?\d+", raw):
            fail(f"expected integer in {self.file_path}, got {raw[:80]!r}")
        return int(raw)

    def as_number(self, span: Span) -> float:
        raw = self.raw(span).decode("ascii")
        if re.fullmatch(r"[+-]?\d+/[1-9]\d*", raw):
            return float(Fraction(raw))
        raw = re.sub(r"`(?:\d+(?:\.\d*)?)?", "", raw).replace("*^", "e")
        try:
            value = float(raw)
        except ValueError:
            fail(f"expected numeric literal in {self.file_path}, got {raw!r}")
        if not math.isfinite(value):
            fail(f"non-finite number in {self.file_path}")
        return value

    def as_int_list(self, span: Span) -> List[int]:
        return [self.as_int(item) for item in self.list_items(span)]

    def contains_raw(self, needle: bytes) -> bool:
        return self.data.find(needle) >= 0


@dataclass(frozen=True)
class Policy:
    project_root: str = PROJECT_ROOT
    exact_source_hashes: Mapping[str, str] = field(default_factory=lambda: EXACT_SOURCE_HASHES)
    held_source_hashes: Mapping[str, str] = field(default_factory=lambda: HELD_SOURCE_HASHES)
    admission_runtime_hashes: Mapping[str, str] = field(default_factory=lambda: ADMISSION_RUNTIME_HASHES)
    exact_manifest_sha: str = EXACT_MANIFEST_SHA
    admission_manifest_sha: str = ADMISSION_MANIFEST_SHA
    transformed_driver_sha: str = TRANSFORMED_DRIVER_SHA
    orbit_core_sha: str = ORBIT_CORE_SHA
    v6d_sha: str = V6D_SHA


@dataclass(frozen=True)
class Inventory:
    exact_sources: Mapping[str, Path]
    held_sources: Mapping[str, Path]
    admission_runtime_sources: Mapping[str, Path]
    held_gate: Path
    exact_manifest: Path
    admission_manifest: Path


def production_inventory(admission_driver: Path, project_root: Path,
                         v6d: Path) -> Inventory:
    admission = admission_driver.parent
    v6 = admission.parent
    exact = v6 / "exact_qeps_left_obstruction_xh"
    exchange = v6.parent.parent
    direct = exchange / "direct_root_channel_assembler_xh"
    support = exchange / "cf300_sector12_next_ansatz_xh"
    exact_sources = {
        "LoadFACET": project_root / "Addon" / "Load" / "LoadFACET.wl",
        "TripleRootAlgebra": exchange / "TripleRootAlgebra.wl",
        "TripleRootStripAdapter": exchange / "TripleRootStripAdapter.wl",
        "TripleRootAffinePilot": exchange / "TripleRootAffinePilot.wl",
        "TripleRootReconstructionPrototype": exchange / "TripleRootReconstructionPrototype.wl",
        "Assembler": direct / "DirectRootChannelAssembler.wl",
        "WitnessReference": support / "AffineInconsistencyWitness.wl",
        "OrbitCoreV6d": v6 / "GaloisChannelOrbitCoreV6d.wl",
        "ExactWitnessHelper": exact / "CF300ExactQepsLeftObstruction.wl",
        "ModularReconstruction": exact / "CF300ModularQepsWitnessReconstruction.wl",
        "FiniteFieldStripSolve": project_root / "FeynFacet" / "Private" / "FiniteFieldStripSolve.wl",
        "NativeFixedSquareBinary": project_root / "FeynFacet" / "Backends" / "flint" / "bin" / "flint_modular_solve",
    }
    held_sources = {
        "AdmissionDriver": admission_driver,
        "FrozenDriver": exact / "run_cf300_sector12_exact_qeps_left_obstruction_v1.wls",
        "ExactHelper": exact_sources["ExactWitnessHelper"],
        "ModularReconstruction": exact_sources["ModularReconstruction"],
        "PrerequisiteSchema": exact / "CF300_V6D_EXACT_LIFT_PREREQUISITE_SCHEMA.wl",
    }
    runtime_sources = {
        "FrozenDriver": held_sources["FrozenDriver"],
        "ExactHelper": held_sources["ExactHelper"],
        "ModularReconstruction": held_sources["ModularReconstruction"],
        "PrerequisiteSchema": held_sources["PrerequisiteSchema"],
        "FrozenManifest": exact / "SHA256SUMS_EXACT_QEPS_LEFT_OBSTRUCTION_V1",
        "KpSubmit": project_root / "Scripts" / "kpsubmit.sh",
        "V6dArtifact": v6d,
    }
    return Inventory(exact_sources, held_sources, runtime_sources,
                     admission / "held_parse_cf300_exact_qeps_runtime_admission_v2_xh.wls",
                     exact / "SHA256SUMS_EXACT_QEPS_LEFT_OBSTRUCTION_V1",
                     admission / "SHA256SUMS_CF300_EXACT_QEPS_RUNTIME_ADMISSION_V2_XH")


def verify_hash_map(paths: Mapping[str, Path], expected: Mapping[str, str],
                    label: str) -> Mapping[str, str]:
    if set(paths) != set(expected):
        fail(f"{label} path inventory differs from pinned hash inventory")
    actual: Dict[str, str] = {}
    for name, digest in expected.items():
        path = Path(paths[name]).resolve()
        require_regular(path, f"{label} {name}")
        observed = sha256_file(path)
        if observed != digest:
            fail(f"{label} hash mismatch for {name}: {observed} != {digest}")
        actual[name] = observed
    return actual


def verify_manifest(path: Path, expected_sha: str) -> Mapping[str, str]:
    require_regular(path, "source manifest")
    if sha256_file(path) != expected_sha:
        fail(f"source manifest hash mismatch: {path}")
    entries: Dict[str, str] = {}
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"([0-9a-f]{64})[ \t]+\*?(.+?)\s*", line)
        if not match:
            fail(f"malformed manifest line {number} in {path}")
        digest, name = match.groups()
        target = (Path(name) if Path(name).is_absolute() else path.parent / name).resolve()
        if str(target) in entries:
            fail(f"duplicate manifest path {target}")
        require_regular(target, "manifest entry")
        if sha256_file(target) != digest:
            fail(f"manifest entry hash mismatch for {target}")
        entries[str(target)] = digest
    if not entries:
        fail(f"empty source manifest: {path}")
    return entries


WL_STRING_LITERAL = re.compile(r'"(?:\\.|[^"\\])*"')
SCRIPT_ASSIGNMENT = re.compile(
    r'(?<![A-Za-z0-9_`])\$ScriptCommandLine\s*=\s*\{(?P<body>[^{}]*)\}\s*;',
    re.DOTALL,
)


def parse_literal_string_list(body: str) -> List[str]:
    values: List[str] = []
    position = 0
    require_value = False
    while True:
        whitespace = re.match(r"\s*", body[position:])
        assert whitespace is not None
        position += whitespace.end()
        if position == len(body):
            if require_value:
                fail("wrapper $ScriptCommandLine has a trailing comma")
            return values
        match = WL_STRING_LITERAL.match(body, position)
        if match is None:
            fail("wrapper $ScriptCommandLine contains a nonliteral argument")
        try:
            value = json.loads(match.group(0))
        except json.JSONDecodeError as error:
            fail(f"invalid wrapper string literal: {error}")
        values.append(value)
        require_value = False
        position = match.end()
        whitespace = re.match(r"\s*", body[position:])
        assert whitespace is not None
        position += whitespace.end()
        if position == len(body):
            return values
        if body[position] != ",":
            fail("wrapper literal arguments are not comma-separated")
        position += 1
        require_value = True


def wl_quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def verify_wrapper(path: Path, expected_sha: str,
                   expected_argv: Sequence[str]) -> Mapping[str, object]:
    require_regular(path, "final moved mission wrapper")
    if not HEX64.fullmatch(expected_sha):
        fail("explicit expected wrapper SHA-256 pin is not lowercase hex")
    actual_sha = sha256_file(path)
    if actual_sha != expected_sha:
        fail(f"mission wrapper hash mismatch: {actual_sha} != {expected_sha}")
    text = path.read_text(encoding="utf-8")
    assignments = list(SCRIPT_ASSIGNMENT.finditer(text))
    if len(assignments) != 1:
        fail(f"wrapper has {len(assignments)} literal $ScriptCommandLine assignments, expected one")
    argv = parse_literal_string_list(assignments[0].group("body"))
    if argv != list(expected_argv):
        fail(f"wrapper ordered target/argument linkage mismatch: {argv!r}")
    helper = "KernelPoolMission`$TaskBrokerMaxHelpers"
    helper_pattern = re.compile(
        r"Block\s*\[\s*\{\s*KernelPoolMission`\$TaskBrokerMaxHelpers\s*=\s*0\s*\}\s*,"
    )
    if text.count(helper) != 1 or len(helper_pattern.findall(text)) != 1:
        fail("wrapper helper ceiling is not exactly one literal zero binding")
    target = re.escape(wl_quote(expected_argv[0]))
    target_directory = re.escape(wl_quote(str(Path(expected_argv[0]).parent)))
    calls = {
        "Import": re.compile(r"Import\s*\[\s*" + target + r"\s*,\s*\"Text\"\s*\]"),
        "Get": re.compile(r"Get\s*\[\s*" + target + r"\s*\]"),
        "SetDirectory": re.compile(r"SetDirectory\s*\[\s*" + target_directory + r"\s*\]"),
    }
    for label, pattern in calls.items():
        if len(pattern.findall(text)) != 1:
            fail(f"wrapper exact target linkage failed for {label}")
    return {"path": str(path), "sha256": actual_sha, "argv": argv,
            "helper_ceiling": 0}


def verify_status_log(status_path: Path, log_path: Path, wrapper: Path,
                      certificate: Path, receipt: Path) -> Mapping[str, str]:
    require_regular(status_path, "mission status")
    require_regular(log_path, "mission log")
    with WLDocument(status_path) as status:
        if status.as_string(status.path("Status")) != "OK":
            fail("pool mission status is not OK")
        if status.as_bool(status.path("HadMessages")):
            fail("pool mission recorded messages")
        if status.as_int(status.path("Kernel")) != 24:
            fail("pool mission did not run on K24")
        if status.as_int(status.path("Result")) != 0:
            fail("pool mission result is not zero")
        mission = status.as_string(status.path("Mission"))
    if mission != wrapper.name:
        fail("pool status does not name the final moved wrapper")
    log = log_path.read_text(encoding="utf-8")
    for marker in ("During evaluation", "KPSUBMIT TARGET", "Syntax::", "General::", " FAIL "):
        if marker in log:
            fail(f"mission log contains forbidden marker {marker!r}")
    if f"MISSION {wrapper.name} kernel 24 start " not in log or " status OK" not in log:
        fail("mission log lacks exact K24 start/end OK inventory")
    success = f"CF300_EXACT_QEPS_ADMISSION PASS output={certificate} receipt={receipt}"
    if success not in log:
        fail("mission log lacks the exact admission PASS output/receipt marker")
    return {"mission": mission, "status_sha256": sha256_file(status_path),
            "log_sha256": sha256_file(log_path)}


def require_assoc_hashes(doc: WLDocument, span: Span, expected: Mapping[str, str],
                         label: str) -> None:
    association = doc.assoc(span)
    if set(association) != set(expected):
        fail(f"{label} key inventory mismatch")
    for key, digest in expected.items():
        if doc.as_string(association[key]) != digest:
            fail(f"{label} hash mismatch for {key}")


def require_empty_list(doc: WLDocument, span: Span, label: str) -> None:
    if doc.list_items(span):
        fail(f"{label} is not empty")


def verify_held_parse(path: Path, inventory: Inventory,
                      policy: Policy) -> Mapping[str, object]:
    require_regular(path, "held-parse artifact")
    size = path.stat().st_size
    if not 0 < size <= MAX_SMALL_OUTPUT_BYTES:
        fail("held-parse artifact violates the 16 MiB ceiling")
    expected_files = {key: str(Path(value).resolve()) for key, value in inventory.held_sources.items()}
    with WLDocument(path) as doc:
        if doc.as_string(doc.path("Status")) != "CF300ExactQepsRuntimeAdmissionHeldParsePassedV2XH":
            fail("held-parse artifact is failed or typed diagnostic status")
        if not doc.as_bool(doc.path("AllPassed")):
            fail("held-parse AllPassed gate is false")
        if [doc.as_int(doc.path(key)) for key in
                ("ExpectedDispatchKernelID", "DispatchKernelID", "TaskBrokerMaxHelpers",
                 "NestedKernelCountAtEntry", "MaximumOutputBytes")] != [24, 24, 0, 0, MAX_SMALL_OUTPUT_BYTES]:
            fail("held-parse K24/helper/nested/ceiling inventory mismatch")
        require_empty_list(doc, doc.path("NestedKernelsAtEntry"), "held-parse nested kernels")
        if doc.as_string(doc.path("SourceReadMode")) != "PinnedASCIIBytesPreserveTerminalLF":
            fail("held-parse source read mode mismatch")
        if doc.as_string(doc.path("GateSHA256")) != sha256_file(inventory.held_gate):
            fail("held-parse gate SHA linkage mismatch")
        require_assoc_hashes(doc, doc.path("SourceHashesBefore"), policy.held_source_hashes,
                             "held source hashes before")
        require_assoc_hashes(doc, doc.path("SourceHashesAfter"), policy.held_source_hashes,
                             "held source hashes after")
        records = doc.assoc(doc.path("ParseRecords"))
        if set(records) != set(policy.held_source_hashes):
            fail("held-parse record inventory mismatch")
        for key, span in records.items():
            if doc.as_string(doc.get(span, "Status")) != "CF300ExactQepsHeldParseRecordV2XH":
                fail(f"held-parse record status failed for {key}")
            if doc.as_string(doc.get(span, "Label")) != key:
                fail(f"held-parse record label mismatch for {key}")
            if Path(doc.as_string(doc.get(span, "File"))).resolve() != Path(expected_files[key]):
                fail(f"held-parse record path mismatch for {key}")
            if doc.as_string(doc.get(span, "SHA256")) != policy.held_source_hashes[key]:
                fail(f"held-parse record SHA mismatch for {key}")
            if doc.as_string(doc.get(span, "SourceReadMode")) != \
                    "PinnedASCIIBytesPreserveTerminalLF":
                fail(f"held-parse record read mode mismatch for {key}")
            for boolean in ("HoldCompleteExact", "SyntaxLengthExact",
                            "TerminalLFPresent", "ParseNamespaceCleanupPassed",
                            "Passed"):
                if not doc.as_bool(doc.get(span, boolean)):
                    fail(f"held-parse record gate failed: {key}.{boolean}")
            require_empty_list(doc, doc.get(span, "ParserMessages"), f"{key} parser messages")
            require_empty_list(doc, doc.get(span, "SplitContextMarkerLines"),
                               f"{key} split context markers")
    return {"sha256": sha256_file(path), "bytes": size, "status": "passed"}


def verify_prerequisite(path: Path, v6d: Path, policy: Policy) -> Mapping[str, object]:
    require_regular(path, "exact-lift prerequisite")
    size = path.stat().st_size
    if not 0 < size <= MAX_CERTIFICATE_BYTES:
        fail("prerequisite violates the 1 GiB atomic-output ceiling")
    with WLDocument(path) as doc:
        if doc.as_string(doc.path("Status")) != "CF300V6dExactLiftPrerequisiteV1":
            fail("prerequisite has failed or typed diagnostic status")
        if Path(doc.as_string(doc.path("SourceV6dArtifactFile"))).resolve() != v6d:
            fail("prerequisite V6d path linkage mismatch")
        if doc.as_string(doc.path("SourceV6dArtifactSHA256")) != policy.v6d_sha:
            fail("prerequisite V6d SHA linkage mismatch")
        if doc.as_string(doc.path("OrbitCoreV6dSHA256")) != policy.orbit_core_sha:
            fail("prerequisite orbit-core SHA mismatch")
        if doc.as_string(doc.path("MaximalAssemblyFingerprint")) != ASSEMBLY_FP or \
                doc.as_string(doc.path("MaximalAssembly", "AssemblyFingerprint")) != ASSEMBLY_FP:
            fail("prerequisite maximal-assembly fingerprint mismatch")
        if (doc.as_string(doc.path("AnchorImageID")), doc.as_int(doc.path("AnchorPrime"))) != ("I00", 10007):
            fail("prerequisite anchor identity mismatch")
        if not math.isclose(doc.as_number(doc.path("AnchorEpsilonValue")), 1 / 21,
                            rel_tol=0, abs_tol=1e-15):
            fail("prerequisite anchor epsilon mismatch")
        residues = doc.list_items(doc.path("AnchorAcceptedPointResidues"))
        lifts = doc.list_items(doc.path("ExactRationalPointLifts"))
        if len(residues) != 30 or len(lifts) != 30 or any(
                len(doc.list_items(pair)) != 2 for pair in residues + lifts):
            fail("prerequisite point inventory is not 30 ordered pairs")
        if doc.as_string(doc.path("AnchorAcceptedPointsFingerprint")) != POINTS_FP:
            fail("prerequisite anchor-point fingerprint mismatch")
        lift = doc.path("PointLiftCertificate")
        if doc.as_string(doc.get(lift, "Status")) != "CertifiedBalancedRationalPointLiftV1":
            fail("prerequisite point-lift certificate status mismatch")
        if doc.as_int(doc.get(lift, "Prime")) != 10007 or doc.as_int(doc.get(lift, "SearchDenominatorBound")) != 100:
            fail("prerequisite point-lift prime/bound mismatch")
        for key in ("AllDenominatorsInvertible", "AllReductionsExact",
                    "ExactPointsDistinctOverQ",
                    "AnchorLiftedPointsNonsingularModuloPrimeAtEpsilon",
                    "CapturedPlanRevalidatedAtLiftedResidues"):
            if not doc.as_bool(doc.get(lift, key)):
                fail(f"prerequisite point-lift gate failed: {key}")
        stable = doc.path("StablePlan")
        if doc.as_int_list(doc.get(stable, "MatrixDimensions")) != [960, 912] or \
                [doc.as_int(doc.get(stable, key)) for key in
                 ("CoefficientRank", "AugmentedRank")] != [888, 889]:
            fail("prerequisite stable-plan dimensions/ranks mismatch")
        plan_lengths = {
            "CoefficientPivotColumns": 888, "CoefficientFreeColumns": 24,
            "CoefficientIndependentEquationRows": 888,
            "AugmentedPivotColumns": 889, "AugmentedFreeColumns": 24,
            "AugmentedIndependentEquationRows": 889,
        }
        for key, length in plan_lengths.items():
            values = doc.as_int_list(doc.get(stable, key))
            if len(values) != length or values != sorted(set(values)):
                fail(f"prerequisite stable-plan array invalid: {key}")
        fingerprints = {
            "CoefficientPivotFingerprint": COEFF_PIVOT_FP,
            "CoefficientFreeFingerprint": FREE_FP,
            "CoefficientIndependentRowFingerprint": COEFF_ROWS_FP,
            "AugmentedPivotFingerprint": AUG_PIVOT_FP,
            "AugmentedFreeFingerprint": FREE_FP,
            "AugmentedIndependentRowFingerprint": AUG_ROWS_FP,
        }
        for key, expected in fingerprints.items():
            if doc.as_string(doc.get(stable, key)) != expected:
                fail(f"prerequisite stable-plan fingerprint mismatch: {key}")
        revalidation = doc.path("AnchorPlanRevalidation")
        if doc.as_string(doc.get(revalidation, "Status")) != "CF300V6dI00StablePlanRevalidatedV1":
            fail("prerequisite revalidation status mismatch")
        for key in ("PlanArraysRevalidated", "FullResidualRevalidated",
                    "AllFrozenFingerprintsExact", "CrossImagePlanFingerprintStable"):
            if not doc.as_bool(doc.get(revalidation, key)):
                fail(f"prerequisite revalidation failed: {key}")
        capture = doc.path("CapturePolicy")
        for key in ("ReproduceOriginalV6dSeedAndCandidateOrder",
                    "CompareRecoveredPointFingerprintBeforeLift",
                    "CompareAllPlanArrayFingerprintsBeforeLift",
                    "RequireCrossImageFingerprintStability"):
            if not doc.as_bool(doc.get(capture, key)):
                fail(f"prerequisite capture policy failed: {key}")
        for key in ("AllowPlanRediscoveryInExactDriver",
                    "ConsumeV6dScoreColumnIndices",
                    "ExactRationalPointsNonsingularOverQepsClaimed"):
            if doc.as_bool(doc.get(capture, key)):
                fail(f"prerequisite fail-closed capture policy violated: {key}")
        if doc.contains_raw(b"$Failed") or doc.contains_raw(b"Missing["):
            fail("prerequisite contains failure/missing sentinels")
    return {"sha256": sha256_file(path), "bytes": size, "status": "valid"}


def verify_modular_summary(doc: WLDocument, span: Span,
                           policy: Policy) -> Mapping[str, object]:
    if doc.as_string(doc.get(span, "Status")) != "ReconstructedCF300ExactQepsWitnessSupportV1":
        fail("modular reconstruction summary has failed/diagnostic status")
    if doc.as_string(doc.get(span, "Field")) != "Q(eps)" or \
            doc.as_int(doc.get(span, "SupportFunctionCount")) != 889:
        fail("modular reconstruction field/support count mismatch")
    for key in ("DegreeProfileStableAcrossTrainingPrimes",
                "RationalReconstructionBoundSatisfied",
                "PrefixReconstructionStable", "HeldOutPrimeImagesExact"):
        if not doc.as_bool(doc.get(span, key)):
            fail(f"modular reconstruction gate failed: {key}")
    if doc.as_string(doc.get(span, "Backend")) != "SourcePinnedCFFA4FLINTFixedSquare":
        fail("modular reconstruction backend mismatch")
    if doc.as_string(doc.get(span, "NativeBinarySHA256")) != policy.exact_source_hashes["NativeFixedSquareBinary"] or \
            doc.as_string(doc.get(span, "FiniteFieldStripSolveSHA256")) != policy.exact_source_hashes["FiniteFieldStripSolve"]:
        fail("modular reconstruction native/source SHA mismatch")
    if doc.as_int(doc.get(span, "NativeThreads")) != 4:
        fail("modular reconstruction native thread count is not four")
    training = doc.as_int(doc.get(span, "TrainingPrimeCount"))
    if not 4 <= training <= 12:
        fail("modular reconstruction training-prime count outside bounded schedule")
    held = doc.list_items(doc.get(span, "HeldOutPrimeCertificates"))
    if len(held) != 2:
        fail("modular reconstruction held-out certificate count is not two")
    attempts = doc.get(span, "ActualNativeSolveAttempts")
    values = [doc.as_int(doc.get(attempts, key)) for key in ("Training", "HeldOut", "Total")]
    if values[0] < 0 or values[1] < 0 or values[2] != values[0] + values[1] or values[2] > 3024:
        fail("modular reconstruction native solve telemetry invalid")
    return {"native_threads": 4, "training_primes": training,
            "native_solve_attempts": values[2]}


def verify_certificate(path: Path, prerequisite: Path, v6d: Path,
                       inventory: Inventory, policy: Policy) -> Mapping[str, object]:
    require_regular(path, "exact certificate")
    size = path.stat().st_size
    if not 0 < size <= MAX_CERTIFICATE_BYTES:
        fail("exact certificate violates the 1 GiB ceiling")
    with WLDocument(path) as doc:
        if doc.as_string(doc.path("Status")) != "CF300Sector12ExactQepsLeftObstructionCertifiedV1":
            fail("exact certificate has failed or typed diagnostic top-level status")
        if doc.as_string(doc.path("Field")) != "Q(eps)":
            fail("exact certificate field mismatch")
        if Path(doc.as_string(doc.path("V6dArtifactFile"))).resolve() != v6d or \
                doc.as_string(doc.path("V6dArtifactSHA256")) != policy.v6d_sha:
            fail("exact certificate V6d path/SHA linkage mismatch")
        if doc.as_string(doc.path("OrbitCoreV6dSHA256")) != policy.orbit_core_sha:
            fail("exact certificate orbit-core SHA mismatch")
        if Path(doc.as_string(doc.path("PrerequisiteFile"))).resolve() != prerequisite or \
                doc.as_string(doc.path("PrerequisiteSHA256")) != sha256_file(prerequisite):
            fail("exact certificate prerequisite path/SHA linkage mismatch")
        if doc.as_bool(doc.path("PlanDiscoveryPerformed")):
            fail("exact certificate reports forbidden plan discovery")
        if doc.as_string(doc.path("DriverSHA256")) != policy.held_source_hashes["FrozenDriver"]:
            fail("exact certificate frozen-driver SHA mismatch")
        require_assoc_hashes(doc, doc.path("SourceHashes"), policy.exact_source_hashes,
                             "exact certificate source hashes")
        requirements = doc.path("Requirements")
        if doc.as_string(doc.get(requirements, "Status")) != "CF300V6dExactLiftRequirementsV1" or \
                doc.as_int_list(doc.get(requirements, "MatrixDimensions")) != [960, 912] or \
                [doc.as_int(doc.get(requirements, key)) for key in
                 ("CoefficientRank", "AugmentedRank", "PointCount")] != [888, 889, 30]:
            fail("exact certificate requirement schema mismatch")
        modular = verify_modular_summary(doc, doc.path("ModularReconstructionSummary"), policy)
        sample = doc.path("ExactSampleSummary")
        if doc.as_string(doc.get(sample, "Status")) != "AssembledCF300ExactQepsSampleV1" or \
                doc.as_int_list(doc.get(sample, "MatrixDimensions")) != [960, 912] or \
                doc.as_int(doc.get(sample, "PointCount")) != 30 or \
                not doc.as_bool(doc.get(sample, "ExactRationalPointsNonsingularOverQeps")):
            fail("exact sample summary schema/gates failed")
        certificate = doc.path("Certificate")
        if doc.as_string(doc.get(certificate, "Status")) != "CertifiedCF300ExactQepsLeftObstructionV1" or \
                doc.as_string(doc.get(certificate, "Field")) != "Q(eps)" or \
                doc.as_int_list(doc.get(certificate, "MatrixDimensions")) != [960, 912]:
            fail("nested obstruction certificate status/field/shape mismatch")
        scalars = [doc.as_int(doc.get(certificate, key)) for key in
                   ("CoefficientRankFromPinnedPlan", "AugmentedRankFromPinnedPlan",
                    "LeftResidualCoordinateCount", "RightPairing")]
        if scalars != [888, 889, 912, 1]:
            fail("nested obstruction certificate rank/residual/pairing mismatch")
        if doc.as_int(doc.get(certificate, "WitnessSupportCount")) <= 0:
            fail("nested obstruction certificate has empty witness support")
        for key in ("LeftClearedNumeratorsAllZero", "RightClearedNumeratorZero"):
            if not doc.as_bool(doc.get(certificate, key)):
                fail(f"nested obstruction exact identity gate failed: {key}")
        right = doc.get(certificate, "RightClearedIdentityCertificate")
        if doc.as_string(doc.get(right, "Status")) != "ExactClearedDenominatorIdentityV1" or \
                not doc.as_bool(doc.get(right, "NumeratorZero")) or \
                not doc.as_bool(doc.get(right, "DenominatorNonzero")):
            fail("right cleared-denominator identity certificate failed")
        nested_reconstruction = doc.get(certificate, "ReconstructionCertificate")
        if doc.as_string(doc.get(nested_reconstruction, "Status")) != \
                "ReconstructedCF300ExactQepsWitnessSupportV1" or \
                doc.as_int(doc.get(nested_reconstruction, "NativeThreads")) != 4:
            fail("nested reconstruction certificate status/thread count mismatch")
        if doc.as_string(doc.get(certificate, "WitnessScoreIndexPolicy")) != \
                "Pick[Range[Length[values]],mask]; no Position head traversal":
            fail("witness score-index policy mismatch")
        if doc.contains_raw(b"$Failed") or doc.contains_raw(b"Missing["):
            fail("exact certificate contains failure/missing sentinels")
    return {"sha256": sha256_file(path), "bytes": size,
            "native_threads": modular["native_threads"],
            "native_solve_attempts": modular["native_solve_attempts"]}


def verify_receipt(path: Path, certificate: Path, prerequisite: Path,
                   held: Path, inventory: Inventory, policy: Policy) -> Mapping[str, object]:
    require_regular(path, "admission receipt")
    size = path.stat().st_size
    if not 0 < size <= MAX_SMALL_OUTPUT_BYTES:
        fail("admission receipt violates the 16 MiB ceiling")
    certificate_size = certificate.stat().st_size
    with WLDocument(path) as doc:
        if doc.as_string(doc.path("Status")) != "CF300ExactQepsRuntimeAdmissionPassedV2XH":
            fail("admission receipt has failed or typed diagnostic status")
        if not doc.as_bool(doc.path("AdmissionPassed")) or doc.raw(doc.path("FailureReason")) != b"None":
            fail("admission receipt pass/failure-reason gate mismatch")
        if [doc.as_int(doc.path(key)) for key in
                ("ExpectedDispatchKernelID", "DispatchKernelID", "TaskBrokerMaxHelpers",
                 "NestedKernelCountAtEntry")] != [24, 24, 0, 0]:
            fail("admission receipt K24/helper/nested inventory mismatch")
        require_empty_list(doc, doc.path("NestedKernelsAtEntry"), "receipt nested kernels")
        for key in ("AdmissionStateStable", "TransformedParseCleanupPassed",
                    "ContextBacktickSplitGuardPassed", "HeldParseEvidenceValid",
                    "PrerequisiteStable", "ImmutableSourcePinsStable"):
            if not doc.as_bool(doc.path(key)):
                fail(f"admission receipt gate failed: {key}")
        if doc.as_string(doc.path("FrozenDriverSHA256")) != policy.held_source_hashes["FrozenDriver"] or \
                doc.as_string(doc.path("TransformedDriverSHA256")) != policy.transformed_driver_sha or \
                doc.as_string(doc.path("AdmissionWrapperSHA256")) != policy.held_source_hashes["AdmissionDriver"]:
            fail("admission receipt driver/wrapper SHA linkage mismatch")
        if doc.as_string(doc.path("SourceReadMode")) != \
                "PinnedASCIIBytesPreserveTerminalLF" or \
                not doc.as_bool(doc.path("FrozenDriverTerminalLFPresent")) or \
                doc.as_string(doc.path("TypedDriverExitTag")) != \
                "CF300ExactQepsFrozenDriverExitV2":
            fail("receipt byte-exact read/typed-exit contract mismatch")
        transformed = doc.path("TransformedDriverHeldParse")
        for key in ("HoldCompleteExact", "SyntaxLengthExact"):
            if not doc.as_bool(doc.get(transformed, key)):
                fail(f"transformed-driver held parse failed: {key}")
        require_empty_list(doc, doc.get(transformed, "ParserMessages"),
                           "transformed-driver parser messages")
        require_empty_list(doc, doc.get(transformed, "SplitContextMarkerLines"),
                           "transformed-driver split-context markers")
        if Path(doc.as_string(doc.path("HeldParseArtifactFile"))).resolve() != held or \
                doc.as_string(doc.path("HeldParseArtifactSHA256")) != sha256_file(held) or \
                doc.as_string(doc.path("HeldParseGateSHA256")) != sha256_file(inventory.held_gate):
            fail("receipt held-parse path/SHA/gate linkage mismatch")
        if doc.as_int(doc.path("DriverCode")) != 0 or \
                Path(doc.as_string(doc.path("DriverOutputFile"))).resolve() != certificate or \
                doc.as_string(doc.path("DriverOutputStatus")) != \
                "CF300Sector12ExactQepsLeftObstructionCertifiedV1" or \
                doc.as_string(doc.path("DriverOutputSHA256")) != sha256_file(certificate) or \
                doc.as_int(doc.path("DriverOutputFileByteCount")) != certificate_size:
            fail("receipt driver-output status/path/SHA/size linkage mismatch")
        if doc.as_int(doc.path("MaximumCertificateBytes")) != MAX_CERTIFICATE_BYTES or \
                doc.as_int(doc.path("MaximumReceiptBytes")) != MAX_SMALL_OUTPUT_BYTES or \
                doc.as_bool(doc.path("OutputRollbackPerformed")):
            fail("receipt ceiling/rollback policy mismatch")
        if Path(doc.as_string(doc.path("PrerequisiteFile"))).resolve() != prerequisite or \
                doc.as_string(doc.path("PrerequisiteSHA256")) != sha256_file(prerequisite):
            fail("receipt prerequisite path/SHA linkage mismatch")
        require_assoc_hashes(doc, doc.path("SourceHashesBefore"),
                             policy.admission_runtime_hashes,
                             "receipt runtime source hashes before")
        require_assoc_hashes(doc, doc.path("SourceHashesAfter"),
                             policy.admission_runtime_hashes,
                             "receipt runtime source hashes after")
    return {"sha256": sha256_file(path), "bytes": size, "status": "passed"}


def verify_native_thread_source_chain(inventory: Inventory,
                                      policy: Policy) -> None:
    driver = Path(inventory.held_sources["FrozenDriver"])
    modular = Path(inventory.held_sources["ModularReconstruction"])
    driver_text = driver.read_text(encoding="utf-8")
    modular_text = modular.read_text(encoding="utf-8")
    literal = re.compile(r'"NativeThreads"\s*->\s*4\b')
    if len(literal.findall(driver_text)) != 1:
        fail("frozen exact driver does not contain exactly one native-thread literal four")
    if len(literal.findall(modular_text)) != 1:
        fail("modular source does not contain exactly one default native-thread literal four")
    if sha256_file(driver) != policy.held_source_hashes["FrozenDriver"] or \
            sha256_file(modular) != policy.held_source_hashes["ModularReconstruction"]:
        fail("native-thread source-chain hash pin changed")


def verify(args: argparse.Namespace, policy: Policy = Policy(),
           inventory: Inventory | None = None) -> Mapping[str, object]:
    names = ("admission_driver", "v6d", "prerequisite", "held_parse", "certificate",
             "receipt", "mission_wrapper", "mission_status", "mission_log")
    paths = {name: Path(getattr(args, name)).resolve() for name in names}
    project_root = Path(args.project_root).resolve()
    if project_root != Path(policy.project_root).resolve() or not project_root.is_dir():
        fail("project root differs from the pinned project root")
    for name, path in paths.items():
        require_regular(path, name.replace("_", " "))
    outputs = [paths[key] for key in ("held_parse", "prerequisite", "certificate", "receipt")]
    if len(set(outputs)) != len(outputs):
        fail("held/prerequisite/certificate/receipt paths alias")
    if any(os.path.samefile(left, right) for index, left in enumerate(outputs)
           for right in outputs[index + 1:]):
        fail("held/prerequisite/certificate/receipt files share an inode")
    if paths["mission_wrapper"].parent != paths["mission_status"].parent or \
            paths["mission_wrapper"].parent.name != "done":
        fail("mission wrapper is not the final moved wrapper beside its done status")
    inventory = production_inventory(paths["admission_driver"], project_root,
                                     paths["v6d"]) if inventory is None else inventory
    verify_hash_map(inventory.exact_sources, policy.exact_source_hashes, "exact source")
    verify_hash_map(inventory.held_sources, policy.held_source_hashes, "held source")
    verify_hash_map(inventory.admission_runtime_sources,
                    policy.admission_runtime_hashes, "admission runtime source")
    require_regular(inventory.held_gate, "held-parse gate")
    verify_manifest(inventory.exact_manifest, policy.exact_manifest_sha)
    verify_manifest(inventory.admission_manifest, policy.admission_manifest_sha)
    verify_native_thread_source_chain(inventory, policy)
    expected_argv = [
        str(paths["admission_driver"]), str(project_root), str(paths["v6d"]),
        str(paths["prerequisite"]), str(paths["held_parse"]),
        str(paths["certificate"]), str(paths["receipt"]),
    ]
    wrapper = verify_wrapper(paths["mission_wrapper"],
                             args.expected_wrapper_sha256, expected_argv)
    held = verify_held_parse(paths["held_parse"], inventory, policy)
    prerequisite = verify_prerequisite(paths["prerequisite"], paths["v6d"], policy)
    certificate = verify_certificate(paths["certificate"], paths["prerequisite"],
                                     paths["v6d"], inventory, policy)
    receipt = verify_receipt(paths["receipt"], paths["certificate"],
                             paths["prerequisite"], paths["held_parse"],
                             inventory, policy)
    pool = verify_status_log(paths["mission_status"], paths["mission_log"],
                             paths["mission_wrapper"], paths["certificate"],
                             paths["receipt"])
    stale = []
    for target in outputs:
        stale.extend(target.parent.glob(target.name + ".tmp-*"))
    if stale:
        fail(f"stale atomic temporary files remain: {stale}")
    return {
        "status": "CF300ExactQepsAdmissionPostRunVerifiedV2XH",
        "kernel": 24, "helper_ceiling": 0, "nested_kernels": 0,
        "native_flint_threads": certificate["native_threads"],
        "wrapper": wrapper, "held_parse": held,
        "prerequisite": prerequisite, "certificate": certificate,
        "receipt": receipt, "pool": pool,
    }


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    for name in ("project-root", "admission-driver", "v6d", "prerequisite",
                 "held-parse", "certificate", "receipt", "mission-wrapper",
                 "mission-status", "mission-log", "expected-wrapper-sha256"):
        result.add_argument("--" + name, required=True)
    return result


def main(argv: Sequence[str] | None = None) -> int:
    try:
        report = verify(parser().parse_args(argv))
    except (VerificationError, OSError, UnicodeError, ValueError) as error:
        print(json.dumps({"status": "CF300ExactQepsAdmissionPostRunVerificationFailedV2XH",
                          "error": str(error)}, sort_keys=True))
        return 1
    print(json.dumps(report, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
