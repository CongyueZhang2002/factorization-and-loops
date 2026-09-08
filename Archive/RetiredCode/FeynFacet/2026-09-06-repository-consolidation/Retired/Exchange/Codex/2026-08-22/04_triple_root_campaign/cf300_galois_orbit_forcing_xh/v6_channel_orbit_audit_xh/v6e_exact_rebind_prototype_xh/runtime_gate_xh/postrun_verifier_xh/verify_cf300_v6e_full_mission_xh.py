#!/usr/bin/env python3
"""Read-only, Mathematica-independent verifier for the frozen CF300 V6e mission.

The verifier deliberately does not evaluate Wolfram Language.  It indexes only
literal Association/List structure in Put-generated artifacts, recomputes every
filesystem SHA-256, and checks the redundant certificates emitted by the driver.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import mmap
import os
import re
import statistics
import sys
from dataclasses import dataclass, field
from fractions import Fraction
from pathlib import Path
from typing import Dict, Iterable, List, Mapping, MutableMapping, Sequence, Tuple


Span = Tuple[int, int]
HEX64 = re.compile(r"^[0-9a-f]{64}$")
UUID = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
    re.IGNORECASE,
)


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


class WLDocument:
    """A non-evaluating structural view of a Put-generated WL expression."""

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
        data = self.data
        while position < end:
            if data[position] in b" \t\r\n":
                position += 1
                continue
            if position + 1 < end and data[position : position + 2] == b"(*":
                position = self._skip_comment(position, end)
                continue
            break
        return position

    def _skip_comment(self, position: int, end: int) -> int:
        data = self.data
        depth = 0
        while position < end:
            token = data[position : position + 2]
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
        data = self.data
        if data[position] != ord('"'):
            fail("internal string scanner misuse")
        position += 1
        while position < end:
            byte = data[position]
            if byte == ord("\\"):
                position += 2
            elif byte == ord('"'):
                return position + 1
            else:
                position += 1
        fail(f"unterminated WL string in {self.file_path}")

    def _split_items(self, start: int, end: int, closing: bytes) -> List[Span]:
        data = self.data
        position = self._skip_ws(start, end)
        item_start = position
        stack: List[bytes] = []
        items: List[Span] = []
        openers = {b"<|": b"|>", b"{": b"}", b"[": b"]", b"(": b")"}
        while position < end:
            if data[position] == ord('"'):
                position = self._skip_string(position, end)
                continue
            token2 = data[position : position + 2]
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
                if closing != b"|>":
                    fail(f"unexpected association close in {self.file_path}")
                if self._skip_ws(position + 2, end) != end:
                    fail(f"trailing expression after association in {self.file_path}")
                if self._skip_ws(item_start, position) < position:
                    items.append((item_start, position))
                return items
            byte_token = bytes((data[position],))
            if byte_token in (b"{", b"[", b"("):
                stack.append(openers[byte_token])
                position += 1
                continue
            if byte_token in (b"}", b"]", b")"):
                if stack:
                    if stack[-1] != byte_token:
                        fail(f"mismatched WL delimiter in {self.file_path}")
                    stack.pop()
                    position += 1
                    continue
                if byte_token != closing:
                    fail(f"unexpected WL close delimiter in {self.file_path}")
                if self._skip_ws(position + 1, end) != end:
                    fail(f"trailing expression after list in {self.file_path}")
                if self._skip_ws(item_start, position) < position:
                    items.append((item_start, position))
                return items
            if data[position] == ord(",") and not stack:
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
        rules = self._split_items(start + 2, end, b"|>")
        result: Dict[str, Span] = {}
        for rule in rules:
            rs, re_ = self._trim(rule)
            if self.data[rs] != ord('"'):
                fail(f"non-string Association key at byte {rs} in {self.file_path}")
            key_end = self._skip_string(rs, re_)
            arrow = self._skip_ws(key_end, re_)
            if self.data[arrow : arrow + 2] != b"->":
                fail(f"non-immediate rule at byte {arrow} in {self.file_path}")
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
            fail(f"expected string, got {raw[:80]!r} in {self.file_path}")
        out = bytearray()
        position = 1
        while position < len(raw) - 1:
            byte = raw[position]
            if byte != ord("\\"):
                out.append(byte)
                position += 1
                continue
            position += 1
            if position >= len(raw) - 1:
                fail(f"dangling string escape in {self.file_path}")
            escaped = raw[position]
            if escaped == 10:
                position += 1
                continue
            if escaped == 13 and position + 1 < len(raw) - 1 and raw[position + 1] == 10:
                position += 2
                continue
            replacements = {ord('"'): ord('"'), ord("\\"): ord("\\"),
                            ord("n"): 10, ord("r"): 13, ord("t"): 9}
            out.append(replacements.get(escaped, escaped))
            position += 1
        try:
            return out.decode("utf-8")
        except UnicodeDecodeError as error:
            fail(f"non-UTF-8 string in {self.file_path}: {error}")

    def as_bool(self, span: Span) -> bool:
        raw = self.raw(span)
        if raw == b"True":
            return True
        if raw == b"False":
            return False
        fail(f"expected Boolean, got {raw[:80]!r} in {self.file_path}")

    def as_int(self, span: Span) -> int:
        raw = self.raw(span)
        if not re.fullmatch(rb"[+-]?\d+", raw):
            fail(f"expected integer, got {raw[:80]!r} in {self.file_path}")
        return int(raw)

    def as_number(self, span: Span) -> float:
        raw = self.raw(span).decode("ascii")
        if re.fullmatch(r"[+-]?\d+/[1-9]\d*", raw):
            return float(Fraction(raw))
        raw = re.sub(r"`(?:\d+(?:\.\d*)?)?", "", raw).replace("*^", "e")
        try:
            value = float(raw)
        except ValueError:
            fail(f"expected real number, got {raw!r} in {self.file_path}")
        if not math.isfinite(value):
            fail(f"non-finite number in {self.file_path}")
        return value

    def as_int_list(self, span: Span) -> List[int]:
        return [self.as_int(item) for item in self.list_items(span)]

    def as_pair_list(self, span: Span, number: bool = False) -> List[Tuple[float, float] | Tuple[int, int]]:
        result = []
        for item in self.list_items(span):
            pair = self.list_items(item)
            if len(pair) != 2:
                fail(f"expected pair list in {self.file_path}")
            converter = self.as_number if number else self.as_int
            result.append((converter(pair[0]), converter(pair[1])))
        return result

    def contains_raw(self, needle: bytes) -> bool:
        return self.data.find(needle) >= 0


EXPECTED_SOURCE_HASHES: Mapping[str, str] = {
    "TripleRootAlgebra": "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab",
    "TripleRootStripAdapter": "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5",
    "TripleRootAffinePilot": "283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90",
    "TripleRootReconstructionPrototype": "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43",
    "Assembler": "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6",
    "ArtifactHelper": "8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557",
    "AnsatzRebind": "8b0f8d7fdab72d9660836d1f2a92e7f03be5eb1adcbd7082b327ed4bb8b8e907",
    "NativeAdapter": "d5dbc6542ee21f6390963c57698e56992df9a04612464bc54f562398a1d78605",
    "OrbitCoreV6d": "7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed",
    "ExactChannelRebindV6": "2fceb1511c7084b5047b748820460b763e96ff902935ba488255a8c3ae21be44",
    "ExactChannelRebindV6e": "2fea1e07c691ade811162f47db1d71d82a385dd01d07afd20beaa3aa0262f2e8",
    "V6eIntegrationReference": "7ea7a437cd25a440e4713040d0882947977a71f092510f0c02c940d8d02f0dbe",
    "ExactLiftPrerequisiteSchema": "909bc658858dc701cf05643e943655ea69fe301240f13272c70cc560c5506b45",
    "ExactLiftConsumerHelper": "e055bb88e0884c33edb51c3b52f26943b93e69f27317caead8b0d462b580325b",
    "NativeBinary": "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5",
}

PREPARATION_SHA = "6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4"
CACHE_SHA = "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be"
V6D_SHA = "20823fde76827c8d8a9db66e617eacde276c9bdac0871ccdba80aad1d5aeb1cf"
DRIVER_SHA = "2f83b12a6d33e5f8f34afb56bc349471580913bc4269c265f6a919c3e1ccc884"
MISSION_WRAPPER_SHA = "04ed1f5df890acff7fbebfcb743b8e80d93f71bf69713189b833d450add70e56"
PROJECT_ROOT = "/home/maxzhang/factorization-and-loops"
ASSEMBLY_FP = "32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7"
EXACT_FORMS_FP = "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d"
COMPILED_FORMS_FP = "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7"
POINTS_FP = "f4ac00e6c1636c2f20028a2de449ea66a816ea017a84de6874dd63e54e155b50"
COEFF_PIVOT_FP = "ccc7fa776fdcf55017e98e8d57ee2480690db3c27e0dc8f8625acebd79bfe377"
FREE_FP = "2c25a885fd903d2e0f828c13ecd6e2a9a36babfbe6decb4f4f3af3335cdc9534"
COEFF_ROWS_FP = "9924c7eef76fea745d5451876be6012810e205e7ca28e021dd99cb2c720d9914"
AUG_PIVOT_FP = "8a9731fd7c345e781d71102d9cb3f8f0d745de3b17264e11b62ef538af0cb761"
AUG_ROWS_FP = "3f35c25a1819c8c11ee28d300e252c47beda7f8213bcd45ac54f417fba3023a7"
V6D_SECONDS = 485.843061
MAX_BYTES = 1 << 30


@dataclass(frozen=True)
class Policy:
    source_hashes: Mapping[str, str] = field(default_factory=lambda: EXPECTED_SOURCE_HASHES)
    preparation_sha: str = PREPARATION_SHA
    cache_sha: str = CACHE_SHA
    v6d_sha: str = V6D_SHA
    mission_wrapper_sha: str = MISSION_WRAPPER_SHA
    project_root: str = PROJECT_ROOT


def production_source_paths(driver: Path) -> Mapping[str, Path]:
    runtime = driver.parent
    prototype = runtime.parent
    v6 = prototype.parent
    exchange = v6.parent.parent
    exact = v6 / "exact_qeps_left_obstruction_xh"
    direct = exchange / "direct_root_channel_assembler_xh"
    support = exchange / "cf300_sector12_next_ansatz_xh"
    adapter = exchange / "flint_affine_rref_wl_xh"
    native = exchange / "flint_affine_rref_xh"
    return {
        "TripleRootAlgebra": exchange / "TripleRootAlgebra.wl",
        "TripleRootStripAdapter": exchange / "TripleRootStripAdapter.wl",
        "TripleRootAffinePilot": exchange / "TripleRootAffinePilot.wl",
        "TripleRootReconstructionPrototype": exchange / "TripleRootReconstructionPrototype.wl",
        "Assembler": direct / "DirectRootChannelAssembler.wl",
        "ArtifactHelper": direct / "DirectRootChannelCompiledArtifact.wl",
        "AnsatzRebind": support / "DirectRootChannelAnsatzRebind.wl",
        "NativeAdapter": adapter / "FlintAffineRREFAdapter.wl",
        "OrbitCoreV6d": v6 / "GaloisChannelOrbitCoreV6d.wl",
        "ExactChannelRebindV6": v6 / "DirectRootChannelExactOneFormRebindV6.wl",
        "ExactChannelRebindV6e": prototype / "DirectRootChannelExactOneFormRebindV6e.wl",
        "V6eIntegrationReference": prototype / "V6E_DRIVER_INTEGRATION_BLOCK.wl",
        "ExactLiftPrerequisiteSchema": exact / "CF300_V6D_EXACT_LIFT_PREREQUISITE_SCHEMA.wl",
        "ExactLiftConsumerHelper": exact / "CF300ExactQepsLeftObstruction.wl",
        "NativeBinary": native / "bin" / "flint_affine_rref",
    }


def require_regular(path: Path, label: str) -> None:
    if not path.exists() or not path.is_file() or path.is_symlink():
        fail(f"{label} is not a non-symlink regular file: {path}")


def require_hex(value: str, label: str) -> None:
    if not HEX64.fullmatch(value):
        fail(f"{label} is not lowercase SHA-256 hex: {value!r}")


def verify_manifest(path: Path, required_file: Path) -> Mapping[str, str]:
    require_regular(path, "manifest")
    entries: Dict[str, str] = {}
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"([0-9a-f]{64})[ \t]+\*?(.+?)\s*", line)
        if not match:
            fail(f"malformed manifest line {number}: {line!r}")
        digest, name = match.groups()
        entry = Path(name)
        resolved = (entry if entry.is_absolute() else path.parent / entry).resolve()
        key = str(resolved)
        if key in entries:
            fail(f"duplicate manifest path: {resolved}")
        require_regular(resolved, "manifest entry")
        actual = sha256_file(resolved)
        if actual != digest:
            fail(f"manifest hash mismatch for {resolved}: {actual} != {digest}")
        entries[key] = digest
    required = str(required_file.resolve())
    if required not in entries:
        fail(f"driver absent from manifest: {required_file}")
    return entries


def verify_status_and_log(status_path: Path, log_path: Path) -> Mapping[str, object]:
    require_regular(status_path, "mission status")
    require_regular(log_path, "mission log")
    with WLDocument(status_path) as status:
        if status.as_string(status.path("Status")) != "OK":
            fail("pool mission status is not OK")
        if status.as_bool(status.path("HadMessages")):
            fail("pool mission recorded messages")
        if status.as_int(status.path("Kernel")) != 24:
            fail("pool mission did not run on K24")
        mission = status.as_string(status.path("Mission"))
    log = log_path.read_text(encoding="utf-8")
    forbidden = ("During evaluation", "KPSUBMIT TARGET", "Syntax::", "General::", " FAIL ")
    for marker in forbidden:
        if marker in log:
            fail(f"mission log contains forbidden marker {marker!r}")
    if "MISSION " not in log or " kernel 24 start " not in log or " status OK" not in log:
        fail("mission log lacks exact K24 start/end OK inventory")
    return {"mission": mission, "status_sha256": sha256_file(status_path),
            "log_sha256": sha256_file(log_path)}


WL_STRING_LITERAL = re.compile(r'"(?:\\.|[^"\\])*"')
SCRIPT_COMMAND_LINE_ASSIGNMENT = re.compile(
    r'(?<![A-Za-z0-9_`])\$ScriptCommandLine\s*=\s*\{(?P<body>[^{}]*)\}\s*;',
    re.DOTALL,
)


def parse_literal_wl_string_list(body: str) -> List[str]:
    """Parse only a comma-separated list of quoted string literals."""
    position = 0
    values: List[str] = []
    value_required = False
    while True:
        whitespace = re.match(r"\s*", body[position:])
        assert whitespace is not None
        position += whitespace.end()
        if position == len(body):
            if value_required:
                fail("$ScriptCommandLine literal list has a trailing comma")
            return values
        match = WL_STRING_LITERAL.match(body, position)
        if match is None:
            fail("$ScriptCommandLine contains a nonliteral argument")
        try:
            value = json.loads(match.group(0))
        except json.JSONDecodeError as error:
            fail(f"$ScriptCommandLine contains an invalid string literal: {error}")
        if not isinstance(value, str):
            fail("$ScriptCommandLine contains a non-string literal")
        values.append(value)
        value_required = False
        position = match.end()
        whitespace = re.match(r"\s*", body[position:])
        assert whitespace is not None
        position += whitespace.end()
        if position == len(body):
            return values
        if body[position] != ",":
            fail("$ScriptCommandLine literal arguments are not comma-separated")
        position += 1
        value_required = True


def wl_quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def verify_mission_wrapper(path: Path, expected_argv: Sequence[str],
                           expected_sha: str) -> Mapping[str, object]:
    """Verify the moved KernelPool wrapper without evaluating Wolfram code."""
    require_regular(path, "final moved mission wrapper")
    actual_sha = sha256_file(path)
    if actual_sha != expected_sha:
        fail(f"mission wrapper hash mismatch: {actual_sha} != {expected_sha}")
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError as error:
        fail(f"mission wrapper is not UTF-8 text: {error}")

    assignments = list(SCRIPT_COMMAND_LINE_ASSIGNMENT.finditer(text))
    if len(assignments) != 1:
        fail(f"mission wrapper has {len(assignments)} literal $ScriptCommandLine assignments, expected one")
    argv = parse_literal_wl_string_list(assignments[0].group("body"))
    if len(argv) != 8:
        fail(f"mission wrapper has {len(argv)} command-line entries, expected target plus seven arguments")
    if argv[-1] != "4":
        fail(f"mission wrapper native thread count is {argv[-1]!r}, expected '4'")
    if argv[0] != expected_argv[0]:
        fail(f"mission wrapper target mismatch: {argv[0]!r} != {expected_argv[0]!r}")
    if argv[1:7] != list(expected_argv[1:7]):
        fail(f"mission wrapper ordered argument/path linkage mismatch: {argv[1:7]!r}")
    if argv != list(expected_argv):
        fail("mission wrapper command-line inventory mismatch")

    helper_symbol = "KernelPoolMission`$TaskBrokerMaxHelpers"
    helper_binding = re.compile(
        r"Block\s*\[\s*\{\s*KernelPoolMission`\$TaskBrokerMaxHelpers\s*=\s*0\s*\}\s*,"
    )
    if text.count(helper_symbol) != 1 or len(helper_binding.findall(text)) != 1:
        fail("mission wrapper helper ceiling is not exactly one literal zero binding")

    target_literal = re.escape(wl_quote(expected_argv[0]))
    target_directory_literal = re.escape(
        wl_quote(str(Path(expected_argv[0]).parent))
    )
    exact_calls = {
        "target Import": re.compile(r"Import\s*\[\s*" + target_literal + r"\s*,\s*\"Text\"\s*\]"),
        "target Get": re.compile(r"Get\s*\[\s*" + target_literal + r"\s*\]"),
        "target SetDirectory": re.compile(
            r"SetDirectory\s*\[\s*" + target_directory_literal + r"\s*\]"
        ),
    }
    for label, pattern in exact_calls.items():
        count = len(pattern.findall(text))
        if count != 1:
            fail(f"mission wrapper exact target/path linkage failed for {label}: count={count}")
    return {"path": str(path), "sha256": actual_sha,
            "target": argv[0], "arguments": argv[1:], "native_threads": 4,
            "helper_ceiling": 0}


def assoc_scalars(doc: WLDocument, span: Span) -> Mapping[str, bool]:
    result = {}
    for key, value in doc.assoc(span).items():
        result[key] = doc.as_bool(value)
    return result


def verify_trial(doc: WLDocument, span: Span, label: str) -> Mapping[str, object]:
    if doc.as_string(doc.get(span, "Status")) != "CF300V6eSameInputTrialPassed":
        fail(f"{label} did not pass")
    if doc.as_string(doc.get(span, "Label")) != label:
        fail(f"{label} label mismatch")
    seconds = doc.as_number(doc.get(span, "Seconds"))
    if not seconds > 0.0:
        fail(f"{label} timing is not positive")
    gates = assoc_scalars(doc, doc.get(span, "Gates"))
    required_gates = {
        "StatusExact", "InputIdentityStable", "ExactOracleIdentity",
        "MaximalAssemblyFingerprintExact", "LegacyOraclePassed",
        "SpecializedSealPassed", "SpecializedSealValidBeforeConsume",
        "SealStatusExact", "SealNonceUUIDShaped",
        "SealFingerprintSHA256Shaped", "FreshThenReplayConsumeExact",
        "NoAlgebraicFallback", "NoFailureOrMissing", "SourcesStable",
    }
    missing = required_gates - gates.keys()
    if missing or not all(gates.values()):
        fail(f"{label} gates invalid; missing={sorted(missing)}, false={sorted(k for k,v in gates.items() if not v)}")
    if doc.as_string(doc.get(span, "AssemblyFingerprint")) != ASSEMBLY_FP:
        fail(f"{label} assembly fingerprint mismatch")
    if doc.as_string(doc.get(span, "ExactFormsFingerprint")) != EXACT_FORMS_FP:
        fail(f"{label} exact-forms fingerprint mismatch")
    if doc.as_string(doc.get(span, "CompiledFormsFingerprint")) != COMPILED_FORMS_FP:
        fail(f"{label} compiled-forms fingerprint mismatch")
    shape_fp = doc.as_string(doc.get(span, "CompiledShapeFingerprint"))
    require_hex(shape_fp, f"{label} compiled-shape fingerprint")
    nonce = doc.as_string(doc.get(span, "SealNonce"))
    seal_fp = doc.as_string(doc.get(span, "SealFingerprint"))
    if doc.as_string(doc.get(span, "SealStatus")) != "ExactOneFormRebindSpecializedSealV6e":
        fail(f"{label} seal status mismatch")
    if not UUID.fullmatch(nonce) or not HEX64.fullmatch(seal_fp):
        fail(f"{label} seal nonce/fingerprint shape invalid")
    for field in ("SealValidBeforeConsume", "FreshConsumePassed", "ReplayConsumeRejected"):
        if not doc.as_bool(doc.get(span, field)):
            fail(f"{label} seal evidence failed: {field}")
    return {"seconds": seconds, "nonce": nonce, "seal_fp": seal_fp,
            "shape_fp": shape_fp}


def verify_rank_certificate(doc: WLDocument, span: Span, augmented: bool) -> Mapping[str, object]:
    expected_columns = 913 if augmented else 912
    expected_rank = 889 if augmented else 888
    expected_pivot_fp = AUG_PIVOT_FP if augmented else COEFF_PIVOT_FP
    expected_rows_fp = AUG_ROWS_FP if augmented else COEFF_ROWS_FP
    if doc.as_string(doc.get(span, "Status")) != "VerifiedNativeRankWithStablePlanV1":
        fail("native stable-rank certificate status mismatch")
    dimensions = doc.as_int_list(doc.get(span, "MatrixDimensions"))
    if dimensions != [960, expected_columns]:
        fail(f"native rank dimensions mismatch: {dimensions}")
    if doc.as_int(doc.get(span, "Rank")) != expected_rank or doc.as_int(doc.get(span, "Nullity")) != 24:
        fail("native rank/nullity mismatch")
    pivots = doc.as_int_list(doc.get(span, "PivotColumns"))
    free = doc.as_int_list(doc.get(span, "FreeColumns"))
    rows = doc.as_int_list(doc.get(span, "IndependentEquationRows"))
    if len(pivots) != expected_rank or pivots != sorted(set(pivots)):
        fail("pivot plan is not canonical")
    if len(free) != 24 or free != sorted(set(free)):
        fail("free-column plan is not canonical")
    if set(pivots) | set(free) != set(range(1, expected_columns + 1)) or set(pivots) & set(free):
        fail("pivot/free columns do not partition the matrix columns")
    if len(rows) != expected_rank or rows != sorted(set(rows)) or not all(1 <= row <= 960 for row in rows):
        fail("independent-row plan is not canonical")
    expected_fps = {
        "PivotFingerprint": expected_pivot_fp,
        "FreeColumnFingerprint": FREE_FP,
        "RowWitnessFingerprint": expected_rows_fp,
    }
    for key, expected in expected_fps.items():
        if doc.as_string(doc.get(span, key)) != expected:
            fail(f"rank certificate {key} mismatch")
    return {"pivots": pivots, "free": free, "rows": rows}


def verify_images(doc: WLDocument) -> Tuple[Mapping[str, Mapping[str, object]], List[Tuple[str, int, float]]]:
    expected = [("I00", 10007, 1 / 21), ("I01", 10007, 1 / 11),
                ("I10", 10039, 1 / 21), ("I11", 10039, 1 / 11)]
    declared = []
    for span in doc.list_items(doc.path("FiniteFieldImages")):
        declared.append((doc.as_string(doc.get(span, "ImageID")),
                         doc.as_int(doc.get(span, "Prime")),
                         doc.as_number(doc.get(span, "EpsilonValue"))))
    if len(declared) != 4 or any(a[:2] != b[:2] or not math.isclose(a[2], b[2], rel_tol=0, abs_tol=1e-15)
                                  for a, b in zip(declared, expected)):
        fail(f"finite-field image declaration mismatch: {declared}")
    results = doc.list_items(doc.path("FiniteFieldImageResults"))
    if len(results) != 4:
        fail("finite-field result count is not four")
    plans: Dict[str, Mapping[str, object]] = {}
    matrix_fps, rhs_fps = set(), set()
    for span, expected_image in zip(results, expected):
        image_id, prime, epsilon = expected_image
        if doc.as_string(doc.get(span, "ImageID")) != image_id or doc.as_int(doc.get(span, "Prime")) != prime:
            fail(f"image identity mismatch for {image_id}")
        if not math.isclose(doc.as_number(doc.get(span, "EpsilonValue")), epsilon, rel_tol=0, abs_tol=1e-15):
            fail(f"epsilon mismatch for {image_id}")
        if doc.as_int(doc.get(span, "PointCount")) != 30:
            fail(f"point count mismatch for {image_id}")
        points = doc.as_pair_list(doc.get(span, "AcceptedPoints"))
        if len(points) != 30 or len(set(points)) != 30 or any(not (0 <= x < prime and 0 <= y < prime) for x, y in points):
            fail(f"accepted-point inventory invalid for {image_id}")
        point_fp = doc.as_string(doc.get(span, "AcceptedPointsFingerprint"))
        require_hex(point_fp, f"{image_id} accepted-point fingerprint")
        if image_id == "I00" and point_fp != POINTS_FP:
            fail("I00 accepted-point fingerprint mismatch")
        for fp_key, inventory in (("MatrixFingerprint", matrix_fps), ("RightHandSideFingerprint", rhs_fps)):
            value = doc.as_string(doc.get(span, fp_key))
            require_hex(value, f"{image_id} {fp_key}")
            inventory.add(value)
        if not doc.as_bool(doc.get(span, "BaseColumnPrefixContainedExactly")) or not doc.as_bool(doc.get(span, "FrozenRankCertificateExact")):
            fail(f"subset/rank exactness failed for {image_id}")
        full = doc.get(span, "FullRank")
        if doc.as_string(doc.get(full, "Status")) != "CertifiedAffineConsistencyByTwoStableRanksV1":
            fail(f"full rank status mismatch for {image_id}")
        if doc.as_bool(doc.get(full, "Consistent")):
            fail(f"maximal ansatz unexpectedly consistent for {image_id}")
        if [doc.as_int(doc.get(full, key)) for key in ("CoefficientRank", "AugmentedRank", "CoefficientNullity")] != [888, 889, 24]:
            fail(f"full rank tuple mismatch for {image_id}")
        coeff = verify_rank_certificate(doc, doc.get(full, "CoefficientCertificate"), False)
        aug = verify_rank_certificate(doc, doc.get(full, "AugmentedCertificate"), True)
        plans[image_id] = {"coefficient": coeff, "augmented": aug, "points": points}
    if len(matrix_fps) != 4 or len(rhs_fps) != 4:
        fail("four finite-field images do not have distinct matrix/RHS fingerprints")
    baseline = plans["I00"]
    for image_id, plan in plans.items():
        if plan["coefficient"] != baseline["coefficient"] or plan["augmented"] != baseline["augmented"]:
            fail(f"cross-image plan differs at {image_id}")
    if not doc.as_bool(doc.path("AllFourFrozenImageCertificatesExact")) or not doc.as_bool(doc.path("CrossImageStablePlanExact")):
        fail("top-level four-image/stable-plan gate failed")
    return plans, declared


def verify_prerequisite(doc: WLDocument, output: WLDocument, prerequisite_path: Path,
                        plans: Mapping[str, Mapping[str, object]], policy: Policy) -> Mapping[str, object]:
    if doc.as_string(doc.path("Status")) != "CF300V6dExactLiftPrerequisiteV1":
        fail("exact-lift prerequisite status mismatch")
    if doc.as_string(doc.path("SourceV6dArtifactSHA256")) != policy.v6d_sha:
        fail("prerequisite V6d hash mismatch")
    if doc.as_string(doc.path("OrbitCoreV6dSHA256")) != policy.source_hashes["OrbitCoreV6d"]:
        fail("prerequisite orbit-core hash mismatch")
    if doc.as_string(doc.path("MaximalAssemblyFingerprint")) != ASSEMBLY_FP:
        fail("prerequisite assembly fingerprint mismatch")
    if doc.as_string(doc.path("MaximalAssembly", "AssemblyFingerprint")) != ASSEMBLY_FP:
        fail("captured maximal assembly fingerprint mismatch")
    if (doc.as_string(doc.path("AnchorImageID")), doc.as_int(doc.path("AnchorPrime"))) != ("I00", 10007):
        fail("prerequisite anchor identity mismatch")
    if not math.isclose(doc.as_number(doc.path("AnchorEpsilonValue")), 1 / 21, rel_tol=0, abs_tol=1e-15):
        fail("prerequisite anchor epsilon mismatch")
    residues = doc.as_pair_list(doc.path("AnchorAcceptedPointResidues"))
    alias = doc.as_pair_list(doc.path("AnchorAcceptedPoints"))
    if residues != alias or residues != plans["I00"]["points"]:
        fail("prerequisite anchor residue linkage mismatch")
    if doc.as_string(doc.path("AnchorAcceptedPointsFingerprint")) != POINTS_FP:
        fail("prerequisite anchor point fingerprint mismatch")
    lifts = doc.as_pair_list(doc.path("ExactRationalPointLifts"), number=True)
    if len(lifts) != 30 or len(set(lifts)) != 30:
        fail("exact rational point-lift inventory invalid")
    certificate = doc.path("PointLiftCertificate")
    if doc.as_string(doc.get(certificate, "Status")) != "CertifiedBalancedRationalPointLiftV1":
        fail("point-lift certificate status mismatch")
    if doc.as_int(doc.get(certificate, "Prime")) != 10007 or doc.as_int(doc.get(certificate, "SearchDenominatorBound")) != 100:
        fail("point-lift prime/bound mismatch")
    for field in ("AllDenominatorsInvertible", "AllReductionsExact", "ExactPointsDistinctOverQ",
                  "AnchorLiftedPointsNonsingularModuloPrimeAtEpsilon",
                  "CapturedPlanRevalidatedAtLiftedResidues"):
        if not doc.as_bool(doc.get(certificate, field)):
            fail(f"point-lift certificate failed: {field}")
    if doc.as_string(doc.get(certificate, "ResidueFingerprint")) != POINTS_FP:
        fail("point-lift residue fingerprint mismatch")
    stable = doc.path("StablePlan")
    if doc.as_int_list(doc.get(stable, "MatrixDimensions")) != [960, 912]:
        fail("prerequisite stable-plan dimensions mismatch")
    if [doc.as_int(doc.get(stable, key)) for key in ("CoefficientRank", "AugmentedRank")] != [888, 889]:
        fail("prerequisite stable-plan ranks mismatch")
    plan_fields = {
        "CoefficientPivotColumns": ("coefficient", "pivots"),
        "CoefficientFreeColumns": ("coefficient", "free"),
        "CoefficientIndependentEquationRows": ("coefficient", "rows"),
        "AugmentedPivotColumns": ("augmented", "pivots"),
        "AugmentedFreeColumns": ("augmented", "free"),
        "AugmentedIndependentEquationRows": ("augmented", "rows"),
    }
    for field, (kind, key) in plan_fields.items():
        if doc.as_int_list(doc.get(stable, field)) != plans["I00"][kind][key]:
            fail(f"prerequisite stable-plan linkage mismatch: {field}")
    expected_fps = {
        "CoefficientPivotFingerprint": COEFF_PIVOT_FP,
        "CoefficientFreeFingerprint": FREE_FP,
        "CoefficientIndependentRowFingerprint": COEFF_ROWS_FP,
        "AugmentedPivotFingerprint": AUG_PIVOT_FP,
        "AugmentedFreeFingerprint": FREE_FP,
        "AugmentedIndependentRowFingerprint": AUG_ROWS_FP,
    }
    for field, expected in expected_fps.items():
        if doc.as_string(doc.get(stable, field)) != expected:
            fail(f"prerequisite stable-plan fingerprint mismatch: {field}")
    revalidation = doc.path("AnchorPlanRevalidation")
    if doc.as_string(doc.get(revalidation, "Status")) != "CF300V6dI00StablePlanRevalidatedV1":
        fail("anchor plan revalidation status mismatch")
    for field in ("PlanArraysRevalidated", "FullResidualRevalidated",
                  "AllFrozenFingerprintsExact", "CrossImagePlanFingerprintStable"):
        if not doc.as_bool(doc.get(revalidation, field)):
            fail(f"anchor revalidation failed: {field}")
    policy_span = doc.path("CapturePolicy")
    expected_policy = {
        "ReproduceOriginalV6dSeedAndCandidateOrder": True,
        "CompareRecoveredPointFingerprintBeforeLift": True,
        "CompareAllPlanArrayFingerprintsBeforeLift": True,
        "RequireCrossImageFingerprintStability": True,
        "AllowPlanRediscoveryInExactDriver": False,
        "ConsumeV6dScoreColumnIndices": False,
        "ExactRationalPointsNonsingularOverQepsClaimed": False,
    }
    for field, expected in expected_policy.items():
        if doc.as_bool(doc.get(policy_span, field)) is not expected:
            fail(f"capture policy mismatch: {field}")
    validation = output.path("LiftPrerequisiteConsumerValidation")
    if not output.as_bool(output.get(validation, "Passed")) or output.as_number(output.get(validation, "Seconds")) < 0:
        fail("exact-lift consumer validation metadata failed")
    if doc.contains_raw(b"$Failed") or doc.contains_raw(b"Missing["):
        fail("prerequisite contains failure/missing sentinels")
    return {"status": "valid", "lift_count": len(lifts),
            "sha256": sha256_file(prerequisite_path)}


def verify(args: argparse.Namespace, policy: Policy = Policy(),
           source_paths: Mapping[str, Path] | None = None) -> Mapping[str, object]:
    paths = {name: Path(getattr(args, name)).resolve() for name in
             ("driver", "output", "prerequisite", "preparation", "cache", "v6d",
              "mission_wrapper", "mission_status", "mission_log", "manifest")}
    for name, path in paths.items():
        require_regular(path, name.replace("_", " "))
    if paths["output"] == paths["prerequisite"]:
        fail("benchmark and prerequisite outputs alias")
    if os.path.samefile(paths["output"], paths["prerequisite"]):
        fail("benchmark and prerequisite outputs share an inode")
    if paths["mission_wrapper"].parent != paths["mission_status"].parent or \
            paths["mission_wrapper"].parent.name != "done":
        fail("mission wrapper is not the final moved wrapper beside the done status")
    project_root = str(Path(policy.project_root).resolve())
    expected_wrapper_argv = [
        str(paths["driver"]), project_root, str(paths["preparation"]),
        str(paths["cache"]), str(paths["v6d"]), str(paths["output"]),
        str(paths["prerequisite"]), "4",
    ]
    wrapper = verify_mission_wrapper(paths["mission_wrapper"],
                                     expected_wrapper_argv,
                                     policy.mission_wrapper_sha)
    manifest = verify_manifest(paths["manifest"], paths["driver"])
    source_paths = production_source_paths(paths["driver"]) if source_paths is None else source_paths
    if set(source_paths) != set(policy.source_hashes):
        fail("source-path inventory differs from pinned source inventory")
    source_actual = {}
    for name, expected in policy.source_hashes.items():
        path = Path(source_paths[name]).resolve()
        require_regular(path, f"source {name}")
        actual = sha256_file(path)
        if actual != expected:
            fail(f"live source hash mismatch for {name}: {actual} != {expected}")
        source_actual[name] = actual
    input_expected = {"preparation": policy.preparation_sha, "cache": policy.cache_sha, "v6d": policy.v6d_sha}
    for name, expected in input_expected.items():
        actual = sha256_file(paths[name])
        if actual != expected:
            fail(f"live input hash mismatch for {name}: {actual} != {expected}")
    status = verify_status_and_log(paths["mission_status"], paths["mission_log"])
    if status["mission"] != paths["mission_wrapper"].name:
        fail("pool status mission does not name the final moved mission wrapper")
    driver_sha = sha256_file(paths["driver"])
    if driver_sha != DRIVER_SHA:
        fail(f"frozen runtime driver hash mismatch: {driver_sha} != {DRIVER_SHA}")
    with WLDocument(paths["output"]) as output, WLDocument(paths["prerequisite"]) as prerequisite:
        if output.as_string(output.path("Status")) != "CF300Sector12V6eCorrectnessSameInputBenchmarkPassedXH":
            fail("runtime gate did not meet correctness and performance acceptance")
        if output.as_int(output.path("ExpectedDispatchKernelID")) != 24 or output.as_int(output.path("DispatchKernelID")) != 24:
            fail("runtime artifact K24 identity mismatch")
        if output.as_int(output.path("TaskBrokerMaxHelpers")) != 0:
            fail("runtime helper ceiling was not zero")
        if output.as_int(output.path("NestedKernelCount")) != 0 or output.list_items(output.path("NestedKernelsAtEntry")):
            fail("runtime artifact observed nested kernels")
        if output.as_int(output.path("OuterPoolKernelCount")) != 8:
            fail("runtime artifact outer pool inventory is not eight")
        artifact_sources = output.assoc(output.path("SourceHashes"))
        if set(artifact_sources) != set(policy.source_hashes):
            fail("artifact source-hash inventory mismatch")
        for name, expected in policy.source_hashes.items():
            if output.as_string(artifact_sources[name]) != expected:
                fail(f"artifact source hash mismatch for {name}")
        artifact_hash_fields = {
            "PreparationSHA256": policy.preparation_sha,
            "CacheSHA256": policy.cache_sha,
            "FrozenV6dArtifactSHA256": policy.v6d_sha,
            "DriverSHA256": driver_sha,
        }
        for field, expected in artifact_hash_fields.items():
            if output.as_string(output.path(field)) != expected:
                fail(f"artifact hash linkage mismatch: {field}")
        trial1 = verify_trial(output, output.path("Trial1"), "same-input-1")
        trial2 = verify_trial(output, output.path("Trial2"), "same-input-2")
        if trial1["nonce"] == trial2["nonce"] or trial1["seal_fp"] == trial2["seal_fp"]:
            fail("two trials reused a seal nonce/fingerprint")
        if trial1["shape_fp"] != trial2["shape_fp"]:
            fail("two trials changed compiled shape")
        for field in ("RepeatFingerprintsExact", "TrialSealEvidenceValid", "TrialSealNoncesDistinct",
                      "TrialSealFingerprintsDistinct", "PerformanceAcceptancePassed"):
            if not output.as_bool(output.path(field)):
                fail(f"top-level trial/performance gate failed: {field}")
        times = [trial1["seconds"], trial2["seconds"]]
        listed_times = [output.as_number(item) for item in output.list_items(output.path("V6eTrialSeconds"))]
        median = statistics.median(times)
        if len(listed_times) != 2 or any(not math.isclose(x, y, rel_tol=1e-12, abs_tol=1e-12) for x, y in zip(times, listed_times)):
            fail("trial timing inventory mismatch")
        if not math.isclose(output.as_number(output.path("V6eMedianSeconds")), median, rel_tol=1e-12, abs_tol=1e-12):
            fail("reported V6e median mismatch")
        if not math.isclose(output.as_number(output.path("FrozenV6dRebindSeconds")), V6D_SECONDS, rel_tol=0, abs_tol=1e-9):
            fail("frozen V6d timing mismatch")
        if not median < V6D_SECONDS:
            fail("V6e performance acceptance not met")
        speedup = output.as_number(output.path("ObservedSpeedupFactor"))
        if not math.isclose(speedup, V6D_SECONDS / median, rel_tol=1e-10, abs_tol=1e-12):
            fail("reported speedup factor mismatch")
        oracle = output.path("FrozenV6CorrectnessOracle")
        if output.as_string(output.get(oracle, "AssemblyFingerprint")) != ASSEMBLY_FP or output.as_number(output.get(oracle, "Seconds")) <= 0:
            fail("V6 oracle evidence mismatch")
        plans, images = verify_images(output)
        if not output.as_bool(output.path("PrerequisiteCaptureRequested")):
            fail("full mission omitted prerequisite capture")
        if Path(output.as_string(output.path("LiftPrerequisiteOutputFile"))).resolve() != paths["prerequisite"]:
            fail("prerequisite output path linkage mismatch")
        prerequisite_sha = sha256_file(paths["prerequisite"])
        if output.as_string(output.path("LiftPrerequisiteOutputSHA256")) != prerequisite_sha:
            fail("prerequisite output SHA linkage mismatch")
        if output.as_string(output.path("LiftPrerequisiteStatus")) != "CF300V6dExactLiftPrerequisiteV1":
            fail("prerequisite output status linkage mismatch")
        prerequisite_size = paths["prerequisite"].stat().st_size
        if output.as_int(output.path("LiftPrerequisiteFileByteCount")) != prerequisite_size:
            fail("prerequisite file-byte-count linkage mismatch")
        if not (0 < output.as_int(output.path("LiftPrerequisiteByteCount")) <= MAX_BYTES):
            fail("prerequisite in-memory byte count invalid")
        if output.as_int(output.path("MaximumAtomicOutputBytes")) != MAX_BYTES:
            fail("maximum atomic-output policy mismatch")
        atomic = output.path("AtomicOutputSizePolicy")
        if output.as_int(output.get(atomic, "MaximumBytes")) != MAX_BYTES or output.as_bool(output.get(atomic, "OverwriteTarget")):
            fail("atomic-output policy mismatch")
        if not output.as_bool(output.get(atomic, "TemporaryCleanupRequired")):
            fail("atomic temporary-cleanup policy disabled")
        prerequisite_result = verify_prerequisite(prerequisite, output, paths["prerequisite"], plans, policy)
    output_size = paths["output"].stat().st_size
    prerequisite_size = paths["prerequisite"].stat().st_size
    if not (0 < output_size <= MAX_BYTES and 0 < prerequisite_size <= MAX_BYTES):
        fail("output size policy violated")
    stale = []
    for target in (paths["output"], paths["prerequisite"]):
        stale.extend(target.parent.glob(target.name + ".tmp-*"))
    if stale:
        fail(f"stale atomic temporary files remain: {stale}")
    return {
        "status": "CF300V6eFullMissionPostRunVerifiedXH",
        "kernel": 24,
        "helper_ceiling": 0,
        "nested_kernels": 0,
        "native_threads": wrapper["native_threads"],
        "source_count": len(source_actual),
        "manifest_entry_count": len(manifest),
        "driver_sha256": driver_sha,
        "output": {"path": str(paths["output"]), "bytes": output_size,
                   "sha256": sha256_file(paths["output"])},
        "prerequisite": {"path": str(paths["prerequisite"]), "bytes": prerequisite_size,
                         "sha256": prerequisite_result["sha256"]},
        "trial_seconds": times,
        "median_seconds": median,
        "speedup": V6D_SECONDS / median,
        "image_inventory": images,
        "mission_wrapper": wrapper,
        "pool": status,
    }


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    for name in ("driver", "output", "prerequisite", "preparation", "cache", "v6d",
                 "mission-wrapper", "mission-status", "mission-log", "manifest"):
        result.add_argument("--" + name, required=True)
    return result


def main(argv: Sequence[str] | None = None) -> int:
    try:
        report = verify(parser().parse_args(argv))
    except (VerificationError, OSError, UnicodeError) as error:
        print(json.dumps({"status": "CF300V6eFullMissionPostRunVerificationFailedXH",
                          "error": str(error)}, sort_keys=True))
        return 1
    print(json.dumps(report, sort_keys=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
