#!/usr/bin/env python3
"""No-kernel exact-transform and explicit-cleanup audit for CF300 V4."""

from __future__ import annotations

from pathlib import Path


HERE = Path(__file__).resolve().parent
HELPER_HASH = "e9601949653a14337dbe00aead48e1a173a53d4006d516a035105497afc06a8f"


def expected_v4(
    v3: str,
    old_context: str,
    new_context: str,
    old_clear: str,
    new_clear: str,
    old_exit: str,
    bootstrap_exit: str,
    prefix: str,
) -> str:
    old_top = f'''BeginPackage["{old_context}"];
Begin["`Private`"];
Quiet[ClearAll["{old_clear}*"]];
{old_exit}[code_Integer] :=
  (End[]; EndPackage[]; System`Exit[code]);
SetAttributes[{old_exit.removesuffix("Exit")}CanonicalRuntime, HoldAll];
{old_exit.removesuffix("Exit")}CanonicalRuntime[expression_] :=
  Internal`InheritedBlock[{{Global`x, Global`y, Global`eps}},
    Quiet[Unprotect[Global`x, Global`y, Global`eps]];
    Quiet[ClearAll[Global`x, Global`y, Global`eps]];
    If[! And @@ ((OwnValues[#1] === {{}} && DownValues[#1] === {{}} &&
          UpValues[#1] === {{}} && SubValues[#1] === {{}} &&
          Attributes[#1] === {{}}) & /@
        Unevaluated[{{Global`x, Global`y, Global`eps}}]),
      Print["{prefix} FAIL canonical symbol isolation"];
      {old_exit}[63]];
    Block[{{$Context = "Global`",
      $ContextPath = DeleteDuplicates[
        Join[{{"System`", "Global`"}}, $ContextPath]]}}, expression]];
{old_exit.removesuffix("Exit")}CanonicalRuntime[
'''
    new_top = f'''BeginPackage["{new_context}"];
Begin["`Private`"];
Quiet[ClearAll["{new_clear}*"]];
{bootstrap_exit}[code_Integer] :=
  (End[]; EndPackage[]; System`Exit[code]);
canonicalRuntimeFile = FileNameJoin[{{DirectoryName[$InputFileName],
  "CanonicalGlobalArtifactRuntimeV1.wl"}}];
expectedCanonicalRuntimeHash =
  "{HELPER_HASH}";
If[! FileExistsQ[canonicalRuntimeFile] ||
    FileHash[canonicalRuntimeFile, "SHA256", "HexString"] =!=
      expectedCanonicalRuntimeHash,
  Print["{prefix} FAIL canonical runtime bootstrap pin"];
  {bootstrap_exit}[62]];
canonicalRuntimeLoad = Quiet[Check[Get[canonicalRuntimeFile], $Failed]];
If[canonicalRuntimeLoad === $Failed ||
    DownValues[CodexCanonicalGlobalArtifactRuntimeV1`CGARRun] === {{}},
  Print["{prefix} FAIL canonical runtime bootstrap load"];
  {bootstrap_exit}[62]];
{old_exit}[code_Integer] :=
  CodexCanonicalGlobalArtifactRuntimeV1`CGARRequestExit[code];
canonicalRuntimeOutcome =
  CodexCanonicalGlobalArtifactRuntimeV1`CGARRun[
'''
    assert v3.count(old_top) == 1
    transformed = v3.replace(old_top, new_top, 1)
    files_anchor = (
        '  "AtomicHelper" -> FileNameJoin[{directDirectory,\n'
        '    "DirectDiscriminatorAtomicCheckpointV2.wl"}],\n'
    )
    assert transformed.count(files_anchor) == 1
    transformed = transformed.replace(
        files_anchor,
        files_anchor + '  "CanonicalRuntime" -> canonicalRuntimeFile,\n',
        1,
    )
    hashes_anchor = (
        '  "AtomicHelper" ->\n'
        '    "dbd36f7f078f08ed329490dd6b91bef950d977a1d70474ce2ccd6d8617fcad30",\n'
    )
    assert transformed.count(hashes_anchor) == 1
    transformed = transformed.replace(
        hashes_anchor,
        hashes_anchor
        + '  "CanonicalRuntime" -> expectedCanonicalRuntimeHash,\n',
        1,
    )
    old_tail = f'''{old_exit}[0];
]
'''
    new_tail = f'''{old_exit}[0];
];
canonicalRuntimeCode = If[
  AssociationQ[canonicalRuntimeOutcome] &&
    TrueQ[canonicalRuntimeOutcome["DefinitionsRestoredQ"]] &&
    TrueQ[canonicalRuntimeOutcome["ContextRestoredQ"]] &&
    TrueQ[canonicalRuntimeOutcome["ContextPathRestoredQ"]],
  Lookup[canonicalRuntimeOutcome, "Code", 99],
  99];
Print["{prefix} canonical_runtime_cleanup=",
  InputForm[canonicalRuntimeOutcome]];
End[];
EndPackage[];
System`Exit[canonicalRuntimeCode];
'''
    assert transformed.count(old_tail) == 1
    return transformed.replace(old_tail, new_tail, 1)


cases = [
    (
        "run_cf300_sector12_contextual_denominator_closure_screen_v3.wls",
        "run_cf300_sector12_contextual_denominator_closure_screen_v4.wls",
        "CodexCF300ContextualDenominatorClosureDriverV3`",
        "CodexCF300ContextualDenominatorClosureDriverV4`",
        "CodexCF300ContextualDenominatorClosureDriverV3`Private`",
        "CodexCF300ContextualDenominatorClosureDriverV4`Private`",
        "cf300ContextualDriverV3Exit",
        "cf300ContextualDriverV4BootstrapExit",
        "CF300_CONTEXT_DENOM",
    ),
    (
        "run_cf300_sector12_second_support_shell_screen_v3.wls",
        "run_cf300_sector12_second_support_shell_screen_v4.wls",
        "CodexCF300SecondSupportShellDriverV3`",
        "CodexCF300SecondSupportShellDriverV4`",
        "CodexCF300SecondSupportShellDriverV3`Private`",
        "CodexCF300SecondSupportShellDriverV4`Private`",
        "cf300SecondShellDriverV3Exit",
        "cf300SecondShellDriverV4BootstrapExit",
        "CF300_SECOND_SHELL",
    ),
]

assertion_count = 0
for case in cases:
    v3_name, v4_name, *arguments = case
    v3 = (HERE / v3_name).read_text()
    v4 = (HERE / v4_name).read_text()
    assert v4 == expected_v4(v3, *arguments)
    assertion_count += 1
    assert HELPER_HASH in v4
    assert v4.count('"CanonicalRuntime" -> canonicalRuntimeFile') == 1
    assert v4.count('"CanonicalRuntime" -> expectedCanonicalRuntimeHash') == 1
    assertion_count += 3
    assert "Internal`InheritedBlock" not in v4
    assert "CodexCanonicalGlobalArtifactRuntimeV1`CGARRun[" in v4
    assert "CodexCanonicalGlobalArtifactRuntimeV1`CGARRequestExit[code]" in v4
    assertion_count += 3
    assert v4.index("canonicalRuntimeOutcome =") < v4.index("arguments =")
    assert v4.rindex("System`Exit[canonicalRuntimeCode]") > v4.rindex(
        "canonical_runtime_cleanup="
    )
    assertion_count += 2

helper = (HERE / "CanonicalGlobalArtifactRuntimeV1.wl").read_text()
for component in (
    "OwnValues",
    "DownValues",
    "UpValues",
    "SubValues",
    "NValues",
    "DefaultValues",
    "FormatValues",
    "Attributes",
):
    assert f'"{component}" ->' in helper
    assertion_count += 1
assert "Internal`InheritedBlock" not in helper
assert "Internal`WithLocalSettings" not in helper
assert "System`Exit[" not in helper
assert "SetAttributes[CGARRun, HoldAll]" in helper
assert "SetAttributes[CGARDefinitionSnapshot, HoldFirst]" in helper
assert "SetAttributes[CGARRestoreDefinitionState, HoldFirst]" in helper
assert "CheckAbort[" in helper
assert "Catch[" in helper
assert helper.index("caught = If[") < helper.index("restoration = <|")
assert helper.index("restoration = <|") < helper.index("definitionsRestoredQ =")
assert '"ContextRestoredQ" -> contextRestoredQ' in helper
assert '"ContextPathRestoredQ" -> contextPathRestoredQ' in helper
assert '"CanonicalGlobalArtifactRuntimeRestorationFailedV1"' in helper
assert "Unlock[symbol]" in helper
assert "Unprotect[symbol]" in helper
assert "Lock[symbol]" in helper
assert "Protect[symbol]" in helper
assertion_count += 17

model = (HERE / "run_canonical_runtime_artifact_poison_model_v1.wls").read_text()
assert HELPER_HASH in model
assert '"OwnValues" -> {HoldPattern[Global`x] :> 31337}' in model
assert '"DownValues" -> {' in model
assert '"Attributes" -> {Locked, Protected}' in model
assert '"Attributes" -> {Listable, Locked, Protected}' in model
assert '"Attributes" -> {Locked, NumericFunction, Protected}' in model
assert model.count("CodexCanonicalGlobalArtifactRuntimeV1`CGARRun[") == 2
assert '"FirstDefinitionComparisons"' in model
assert '"SecondDefinitionComparisons"' in model
assert '"FirstCallerContextPathRestoredQ"' in model
assert '"SecondCallerContextPathRestoredQ"' in model
assert '"RawCacheValidatorQ"' in model
assert '"ReaderCacheValidatorQ"' in model
assert '"RawReaderSameQ"' in model
assert '"ExactFingerprintQ"' in model
assert '"CompiledFingerprintQ"' in model
assert '"OriginalDefinitionsRestoredQ"' in model
assert model.rindex("System`Exit[finalCode]") > model.rindex(
    '"OriginalDefinitionsRestoredQ"'
)
assertion_count += 18

print(f"CF300_V4_EXPLICIT_CLEANUP_STATIC PASS {assertion_count}/{assertion_count}")
