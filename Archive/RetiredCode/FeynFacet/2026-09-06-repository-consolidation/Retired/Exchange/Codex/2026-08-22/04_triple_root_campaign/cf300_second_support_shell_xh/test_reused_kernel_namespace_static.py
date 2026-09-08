#!/usr/bin/env python3
"""No-kernel proofs for reused-kernel namespace and hydration hardening."""

from __future__ import annotations

import re
from pathlib import Path


HERE = Path(__file__).resolve().parent


def expected_v2(v1: str, context: str, exit_helper: str) -> str:
    transformed = v1.replace("Exit[", f"{exit_helper}[")
    needle = "$HistoryLength = 0;\n"
    package_context = context.removesuffix("Private`")
    insertion = (
        needle
        + f'BeginPackage["{package_context}"];\n'
        + 'Begin["`Private`"];\n'
        + f'Quiet[ClearAll["{context}*"]];\n'
        + f"{exit_helper}[code_Integer] :=\n"
        + "  (End[]; EndPackage[]; System`Exit[code]);\n"
    )
    assert transformed.count(needle) == 1
    return transformed.replace(needle, insertion, 1)


fixture = (HERE / "reused_kernel_global_poison_fixture.wl").read_text()
poisoned_symbols = sorted(set(re.findall(r"Global`([A-Za-z$][A-Za-z0-9$]*)", fixture)))
assert "checkpointFile" in poisoned_symbols
assert re.search(r"Global`checkpointFile\s*=\s*\n?\s*\"/tmp/", fixture)
assert "SetAttributes[Global`fingerprint, {Protected, Locked}]" in fixture
assert "SetAttributes[Global`writeCheckpoint, Protected]" in fixture

cases = [
    (
        "run_cf300_sector12_contextual_denominator_closure_screen.wls",
        "run_cf300_sector12_contextual_denominator_closure_screen_v2.wls",
        "CodexCF300ContextualDenominatorClosureDriverV2`Private`",
        "cf300ContextualDriverV2Exit",
    ),
    (
        "run_cf300_sector12_second_support_shell_screen.wls",
        "run_cf300_sector12_second_support_shell_screen_v2.wls",
        "CodexCF300SecondSupportShellDriverV2`Private`",
        "cf300SecondShellDriverV2Exit",
    ),
]

assertion_count = 4
for v1_name, v2_name, context, exit_helper in cases:
    v1 = (HERE / v1_name).read_text()
    v2 = (HERE / v2_name).read_text()
    assert v2 == expected_v2(v1, context, exit_helper)
    assertion_count += 1
    package_context = context.removesuffix("Private`")
    assert v2.index(f'BeginPackage["{package_context}"]') < v2.index("arguments =")
    assertion_count += 1
    assert v2.index('Begin["`Private`"]') < v2.index("arguments =")
    assertion_count += 1
    assert f'ClearAll["{context}*"]' in v2
    assertion_count += 1
    assert (
        f"{exit_helper}[code_Integer] :=\n"
        "  (End[]; EndPackage[]; System`Exit[code]);"
    ) in v2
    assertion_count += 1
    assert re.search(r"(?m)^checkpointFile\[image_Association\] :=", v2)
    assertion_count += 1
    assert not any(f"Global`{symbol}" in v2 for symbol in poisoned_symbols)
    assertion_count += 1
    assert v2.count("System`Exit[") == 1
    assertion_count += 1
    assert not re.search(r"(?<!System`)\bExit\[", v2)
    assertion_count += 1
    for symbol in poisoned_symbols:
        # Unqualified occurrences after Begin resolve in the V2 private
        # context.  The fixture may poison own values, downvalues or
        # attributes of the homonymous Global` symbol without collision.
        if symbol in {"x", "y", "image", "prior", "fullRank"}:
            assert re.search(rf"\b{re.escape(symbol)}\b", v2)
    assertion_count += 1

v3_cases = [
    (
        "run_cf300_sector12_contextual_denominator_closure_screen_v3.wls",
        "CodexCF300ContextualDenominatorClosureDriverV3`Private`",
        "cf300ContextualDriverV3Exit",
        "CF300_CONTEXT_DENOM",
        True,
    ),
    (
        "run_cf300_sector12_second_support_shell_screen_v3.wls",
        "CodexCF300SecondSupportShellDriverV3`Private`",
        "cf300SecondShellDriverV3Exit",
        "CF300_SECOND_SHELL",
        False,
    ),
]

for v3_name, context, exit_helper, prefix, has_census in v3_cases:
    v3 = (HERE / v3_name).read_text()
    package_context = context.removesuffix("Private`")
    assert v3.index(f'BeginPackage["{package_context}"]') < v3.index("arguments =")
    assertion_count += 1
    assert f'ClearAll["{context}*"]' in v3
    assertion_count += 1
    assert "Internal`InheritedBlock[{Global`x, Global`y, Global`eps}" in v3
    assertion_count += 1
    assert "Quiet[Unprotect[Global`x, Global`y, Global`eps]]" in v3
    assertion_count += 1
    assert "Quiet[ClearAll[Global`x, Global`y, Global`eps]]" in v3
    assertion_count += 1
    assert 'Join[{"System`", "Global`"}, $ContextPath]' in v3
    assertion_count += 1
    assert v3.index("compiledArtifactRaw = artifactRead[cacheFile]") < v3.index(
        "DRCAReadCompiledArtifact["
    )
    assertion_count += 1
    assert "DRCACompiledArtifactValidQ[" in v3
    assertion_count += 1
    assert '"ReaderSameAsRawQ" -> SameQ[compiledArtifact, compiledArtifactRaw]' in v3
    assertion_count += 1
    assert v3.index(f'Print["{prefix} artifact_diagnostics="') < v3.index(
        f'Print["{prefix} FAIL pinned artifacts invalid"]'
    )
    assertion_count += 1
    assert v3.index(f'Print["{prefix} base_contract_diagnostics="') < v3.index(
        f'Print["{prefix} FAIL base '
    )
    assertion_count += 1
    assert '"PreparationVariablesCanonicalQ"' in v3
    assert '"PreparationRegulatorCanonicalQ"' in v3
    assertion_count += 2
    assert ('"CensusStatus"' in v3) is has_census
    assertion_count += 1
    assert not any(
        f"Global`{symbol}" in v3
        for symbol in poisoned_symbols
        if symbol not in {"x", "y", "eps"}
    )
    assertion_count += 1
    assert v3.count("System`Exit[") == 1
    assert not re.search(r"(?<!System`)\bExit\[", v3)
    assertion_count += 2

# Model the precise serializer instability demonstrated by the reused-kernel
# probe: InputForm may omit Global` only when Global` is on $ContextPath.
canonical_exact_forms = "{{x + y, eps*x}, {1/(1 - x), y^2}}"
isolated_exact_forms = (
    "{{Global`x + Global`y, Global`eps*Global`x}, "
    "{1/(1 - Global`x), Global`y^2}}"
)
assert canonical_exact_forms != isolated_exact_forms
assert __import__("hashlib").sha256(canonical_exact_forms.encode()).hexdigest() != (
    __import__("hashlib").sha256(isolated_exact_forms.encode()).hexdigest()
)
assertion_count += 2

print(f"CF300_REUSED_KERNEL_NAMESPACE_STATIC PASS {assertion_count}/{assertion_count}")
