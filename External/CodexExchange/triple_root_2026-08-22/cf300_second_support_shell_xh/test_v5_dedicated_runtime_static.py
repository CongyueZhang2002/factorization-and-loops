#!/usr/bin/env python3
"""Static, no-kernel audit of the two dedicated-context V5 drivers."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
CONTEXTUAL = HERE / "run_cf300_sector12_contextual_denominator_closure_screen_v5.wls"
SECOND = HERE / "run_cf300_sector12_second_support_shell_screen_v5.wls"
EXPECTED = {
    CONTEXTUAL.name: "3f3427253250c54662c3ae80e93ef31540a95a9de19f1bf1e2e60c16bac228a5",
    SECOND.name: "57d32b11e636d1e9d99acfcdbe8ea3e8acc82059983b947152996fa5ef52e4b6",
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


allowed_global_read = re.compile(
    r"(?:OwnValues|DownValues|UpValues|SubValues|NValues|"
    r"DefaultValues|FormatValues|Attributes)\[Global`(?:x|y|eps)\]"
)
for path, package, artifact_context, prefix in (
    (
        CONTEXTUAL,
        "CodexCF300ContextualDenominatorClosureDriverV5`",
        "CodexCF300ContextualArtifactSymbolsV5`",
        "CF300_CONTEXT_DENOM",
    ),
    (
        SECOND,
        "CodexCF300SecondSupportShellDriverV5`",
        "CodexCF300SecondShellArtifactSymbolsV5`",
        "CF300_SECOND_SHELL",
    ),
):
    source = path.read_text()
    assert sha256(path) == EXPECTED[path.name]
    assert f'BeginPackage["{package}"]' in source
    assert f'artifactContext = "{artifact_context}";' in source
    assert source.index("dedicatedRuntimeCode = CheckAbort[") < source.index(
        "arguments = Rest[$ScriptCommandLine]"
    )
    assert '$Context = artifactContext' in source
    assert '"System`", artifactContext' in source
    assert 'MemberQ[$ContextPath, "Global`")]' not in source
    assert 'MemberQ[$ContextPath, "Global`"]' in source
    assert "DRCAReadCompiledArtifact" not in source
    assert "Internal`InheritedBlock" not in source
    assert "CanonicalGlobalArtifactRuntime" not in source
    assert "CGARRun" not in source
    assert 'artifactReadTelemetry = <||>;' in source
    assert "Quiet[CheckAbort[Get[file], $Aborted]]" in source
    artifact_reader = source.split("artifactRead[file_String]", 1)[1].split(
        "loadSource[file_String]", 1
    )[0]
    assert "Check[Get[file]" not in artifact_reader
    assert "compiledArtifact = compiledArtifactRaw;" in source
    assert '"PublicHardcodedGlobalReaderCalledQ" -> False' in source
    assert '"ExactFingerprintMatchesStoredQ"' in source
    assert '"CompiledFingerprintMatchesStoredQ"' in source
    assert "DRCACompiledArtifactValidQ[" in source
    assert "DRCAAssemblyPreparationValidQ[" in source
    assert 'expectedDedicatedNames[] := {"eps", "v", "w", "x", "y"};' in source
    assert 'unqualifiedName[name_String] := Last[StringSplit[name, "`"]]' in source
    assert "SetAttributes[definitionFreeHeldQ, HoldAll]" in source
    assert "Function[heldSymbol, definitionFreeHeldQ[heldSymbol], HoldAll]" in source
    assert "Apply[Remove, names]" in source
    assert 'Remove[artifactContext <> "*"]' not in source
    assert '"DedicatedContextRemovedQ" -> dedicatedContextRemovedQ' in source
    assert '"GlobalStateUnchangedQ" -> globalStateUnchangedQ' in source
    assert "parseUnsignedInteger" in source
    assert not re.search(r"ToExpression\[arguments", source)
    global_occurrences = re.findall(r"Global`(?:x|y|eps)", source)
    global_lines = re.findall(r"(?m)^.*Global`(?:x|y|eps).*$", source)
    assert len(global_occurrences) == 24
    assert all(
        len(allowed_global_read.findall(line)) == line.count("Global`")
        for line in global_lines
    )
    assert not re.search(
        r"(?:Clear|ClearAll|Remove|Unprotect|Protect|SetAttributes)\s*\["
        r"[^\]]*Global`(?:x|y|eps)",
        source,
    )
    assert source.count("System`Exit[") == 1
    assert not re.search(r"(?<!System`)\bExit\[", source)
    assert source.index(f'Print["{prefix} artifact_diagnostics="') < source.index(
        f'Print["{prefix} FAIL pinned artifacts invalid"]'
    )
    assert source.index("finalCommit = ") < source.index(
        "dedicatedContextRemovedQ = removeDedicatedContext[]"
    )
    for forbidden in (
        "LaunchKernels",
        "ParallelSubmit",
        "StartProcess",
        "KillProcess",
        "SetProcessorAffinity",
    ):
        assert forbidden not in source
    assert not re.search(r"`[ \t]+$", source, flags=re.MULTILINE)
    assert not re.search(r"[ \t]+$", source, flags=re.MULTILINE)

contextual = CONTEXTUAL.read_text()
assert 'selectedFingerprints = Switch[candidateSelector,' in contextual
assert contextual.index('selectedFingerprints = Switch[candidateSelector,') < (
    contextual.index("{targetBuildSeconds, target} = AbsoluteTiming[buildTarget[]]")
)
assert '"SubsetCount" -> 31' in contextual
assert '"MAX5", {{10, 8}, 99, 1728, 55}' in contextual
assert 'milestone=image_checkpoint_committed selector=' in contextual

second = SECOND.read_text()
assert '"SecondShellSupportCount" -> 56' in second
assert '"SecondShellUnknownCount" -> 1040' in second
assert '"SecondShellPointCount" -> 34' in second
assert 'projectedAS = targetScreenMatrix[[All, asColumnMap]]' in second
assert 'milestone=image_checkpoint_committed image=' in second

print("CF300_V5_DEDICATED_RUNTIME_STATIC PASS 91/91")
