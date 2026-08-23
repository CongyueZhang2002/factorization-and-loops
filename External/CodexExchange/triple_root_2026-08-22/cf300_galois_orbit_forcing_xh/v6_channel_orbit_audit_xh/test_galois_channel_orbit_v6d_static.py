#!/usr/bin/env python3
"""No-Wolfram structural/adversarial gate for V6d and its helpers."""

from __future__ import annotations

import hashlib
import pathlib
import re
import sys


HERE = pathlib.Path(__file__).resolve().parent
CORE = HERE / "GaloisChannelOrbitCoreV6d.wl"
INTEGRATION = HERE / "V6_DRIVER_INTEGRATION_BLOCK.wl"
EXACT_REBIND = HERE / "DirectRootChannelExactOneFormRebindV6.wl"
ADAPTER = HERE.parent.parent / "TripleRootStripAdapter.wl"
FROZEN_V6_DRIVER = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v6.wls"
FROZEN_V6A_DRIVER = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v6a.wls"
FROZEN_V6B_DRIVER = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v6b.wls"
FROZEN_V6C_DRIVER = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v6c.wls"
DRIVER = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v6d.wls"
PARSE_GATE = HERE / "diagnose_wolfram_parse_target_v1.wls"
V5 = HERE.parent / "run_cf300_sector12_galois_orbit_forcing_screen_v5.wls"
TOTAL = 0


def check(name: str, condition: bool, failures: list[str]) -> None:
    global TOTAL
    TOTAL += 1
    print(f"{'PASS' if condition else 'FAIL'} {name}")
    if not condition:
        failures.append(name)


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def balanced_wolfram_delimiters(text: str) -> bool:
    """Conservative lexer: strip nested comments and strings, then balance."""
    clean: list[str] = []
    depth = 0
    in_string = False
    escaped = False
    i = 0
    while i < len(text):
        pair = text[i : i + 2]
        if depth:
            if pair == "(*":
                depth += 1
                i += 2
            elif pair == "*)":
                depth -= 1
                i += 2
            else:
                i += 1
            continue
        if in_string:
            if escaped:
                escaped = False
            elif text[i] == "\\":
                escaped = True
            elif text[i] == '"':
                in_string = False
            i += 1
            continue
        if pair == "(*":
            depth = 1
            i += 2
        elif text[i] == '"':
            in_string = True
            i += 1
        else:
            clean.append(text[i])
            i += 1
    if depth or in_string:
        return False
    stack: list[str] = []
    pairs = {"]": "[", ")": "(", "}": "{"}
    for char in clean:
        if char in "[({":
            stack.append(char)
        elif char in "])}":
            if not stack or stack.pop() != pairs[char]:
                return False
    return not stack


def wolfram_context_marks_are_lexically_joined(text: str) -> bool:
    """Reject whitespace between a Wolfram context mark and symbol name."""
    code: list[str] = []
    comment_depth = 0
    in_string = False
    escaped = False
    index = 0
    while index < len(text):
        pair = text[index:index + 2]
        if comment_depth:
            if pair == "(*":
                comment_depth += 1
                index += 2
            elif pair == "*)":
                comment_depth -= 1
                index += 2
            else:
                index += 1
            code.append(" ")
            continue
        if in_string:
            if escaped:
                escaped = False
            elif text[index] == "\\":
                escaped = True
            elif text[index] == '"':
                in_string = False
            code.append(" ")
            index += 1
            continue
        if pair == "(*":
            comment_depth = 1
            code.append(" ")
            index += 2
        elif text[index] == '"':
            in_string = True
            code.append(" ")
            index += 1
        else:
            code.append(text[index])
            index += 1
    split_context_symbol = re.compile(
        r"[A-Za-z$][A-Za-z0-9$]*`[ \t\r\n]+[A-Za-z$]")
    return split_context_symbol.search("".join(code)) is None


def extract(text: str, start: str, end: str) -> str:
    left = text.index(start)
    right = text.index(end, left)
    return text[left:right]


def count_contract(occurrences: int, sources: int, aliases: int,
                   metadata_unique: int, candidates: int,
                   sign_masks: int) -> bool:
    """Minimal model of the runtime-derived V6d cardinality contract."""
    return (
        occurrences == sources + aliases
        and sources == metadata_unique
        and candidates == sources * sign_masks
    )


def main() -> int:
    failures: list[str] = []
    core = CORE.read_text()
    integration = INTEGRATION.read_text()
    exact_rebind = EXACT_REBIND.read_text()
    adapter = ADAPTER.read_text()
    driver = DRIVER.read_text()
    frozen_v6_driver = FROZEN_V6_DRIVER.read_text()
    frozen_v6a_driver = FROZEN_V6A_DRIVER.read_text()
    frozen_v6b_driver = FROZEN_V6B_DRIVER.read_text()
    frozen_v6c_driver = FROZEN_V6C_DRIVER.read_text()
    parse_gate = PARSE_GATE.read_text()
    v5 = V5.read_text()

    check("core exists and is nontrivial", len(core) > 20_000, failures)
    check("integration exists and is nontrivial", len(integration) > 2_000,
          failures)
    check("core delimiters balance", balanced_wolfram_delimiters(core), failures)
    check("integration delimiters balance",
          balanced_wolfram_delimiters(integration), failures)
    check("exact-channel rebind delimiters balance",
          balanced_wolfram_delimiters(exact_rebind), failures)
    check("full V6 driver delimiters balance",
          balanced_wolfram_delimiters(driver), failures)
    check("V6d context-qualified symbols are lexically joined",
          wolfram_context_marks_are_lexically_joined(driver), failures)
    check("V6d core context-qualified symbols are lexically joined",
          wolfram_context_marks_are_lexically_joined(core), failures)
    split_context_mutant = driver.replace(
        "CodexDirectRootChannelExactOneFormRebindV6`DRCARebindExactOneFormChannels",
        "CodexDirectRootChannelExactOneFormRebindV6`\n"
        "DRCARebindExactOneFormChannels", 1)
    check("context-split mutant is rejected",
          not wolfram_context_marks_are_lexically_joined(
              split_context_mutant), failures)
    check("superseded V6 artifact remains frozen at announced hash",
          sha256(FROZEN_V6_DRIVER) ==
          "e6d0dd17378d3e7662f5926abaa97a6feef370bf6cb24b1ba26534c2e2385ba3",
          failures)
    check("parse-invalid V6a artifact remains frozen at announced hash",
          sha256(FROZEN_V6A_DRIVER) ==
          "9465f690d0b46ef31d8c5b5dc378b94becf677cd2036155e80a98522db62bc29",
          failures)
    check("superseded V6b artifact remains frozen at announced hash",
          sha256(FROZEN_V6B_DRIVER) ==
          "225f0e96627b37259da27af21067f1a742f9f74389b8ab714ea6f88d3250ac3c",
          failures)
    check("superseded V6c artifact remains frozen at announced hash",
          sha256(FROZEN_V6C_DRIVER) ==
          "86bd849d1e129be5db7c788cf99fc99069a52732b90fb04e423a9321e504b0fc",
          failures)
    check("V6d explicitly records the superseded V6c hash",
          sha256(FROZEN_V6C_DRIVER) in driver, failures)
    check("V6d explicitly records the fail-closed V6c artifact hash",
          "087515b1374ef33d6a7d5b947a55a45e732f2c63a724ec0cdfca0623f3489803"
          in driver, failures)
    check("pool-safe actual Wolfram parser target is structurally sound",
          balanced_wolfram_delimiters(parse_gate) and
          wolfram_context_marks_are_lexically_joined(parse_gate) and
          "ToExpression[parseText, InputForm, HoldComplete]" in parse_gate and
          "SyntaxLength[parseText]" in parse_gate and
          "Head[parsed] === HoldComplete" in parse_gate,
          failures)
    check("package context is dedicated",
          'BeginPackage["CodexCF300GaloisChannelOrbitV6d`"' in core,
          failures)
    check("public builder is exported", "GCOBuildOrbitBasis::usage" in core,
          failures)
    check("base BBar channels are reused",
          'Lookup[exactForms, "BBar"' in core, failures)
    check("base one-form channels are reused",
          'Lookup[exactForms, "OneForms"' in core, failures)
    check("source cores are memoized",
          "sourceCoreCache = <||>" in core and
          "AssociateTo[sourceCoreCache, potentialFingerprint -> sourceCore]"
          in core, failures)
    source_dedup = extract(core,
                           "potentialOccurrenceCount = Length[potentialSources]",
                           "(* ORBIT HOT LOOP:")
    check("sampled potential occurrences are deduplicated before orbit",
          "potentialSourceGroups = GatherBy[potentialSources" in
          source_dedup and
          "potentialSources = Map[Function[localSourceGroup" in
          source_dedup and
          core.index("potentialSources = Map[Function[localSourceGroup") <
          core.index("(* V6_ORBIT_HOT_LOOP_BEGIN *)"), failures)
    check("potential fingerprint groups are collision checked exactly",
          "sourceGroupCollisionFree = AllTrue[potentialSourceGroups" in
          source_dedup and
          'SameQ[#1["SourcePotentialFieldChannels"]' in source_dedup,
          failures)
    check("all occurrence provenance survives unique-source reduction",
          all(token in source_dedup for token in (
              '"SourceOccurrenceCount" -> Length[localSourceGroup]',
              '"SourceAliasCount" -> Length[localSourceGroup] - 1',
              '"SourceOccurrenceProvenance" -> sourceProvenance',
              'Total[Lookup[potentialSources, "SourceOccurrenceCount"]]')),
          failures)
    check("adapter metadata is explicitly unique sampled-function count",
          adapter.index("functions = DeleteDuplicates[") <
          adapter.index('"ForcingDLogCandidates" -> Length[dlogs]'),
          failures)
    check("unique-source count is bound to adapter metadata",
          '"ForcingDLogCandidates", $Failed' in source_dedup and
          "expectedSourceCount =!= metadataUniqueSourceCount" in
          source_dedup, failures)
    check("dlog orbit cores are memoized",
          "formOrbitCache = <||>" in core and
          "AssociateTo[formOrbitCache, formOrbitKey -> formOrbitCore]"
          in core, failures)
    check("potential orbit cores are memoized",
          "potentialOrbitCache = <||>" in core and
          "AssociateTo[potentialOrbitCache," in core, failures)
    check("source dlog uses channel derivative",
          "CodexTripleRoot`TRDerivative" in core, failures)
    check("source dlog uses channel field inverse",
          "CodexTripleRootStrip`TRFieldInverse" in core, failures)
    check("source dlog uses channel multiplication",
          "CodexTripleRoot`TRMultiply" in core, failures)
    check("character action uses grade-mask parity",
          "BitAnd[mask, grade]" in core and "BitGet" in core, failures)
    check("finite exact character certificates are present",
          all(token in core for token in (
              '"InvolutionExact"', '"XorCompositionExact"',
              '"FieldMultiplicationEquivarianceExact"',
              '"GradeDiagonalDerivativeEquivarianceExact"')),
          failures)

    hot = extract(core, "(* V6_ORBIT_HOT_LOOP_BEGIN *)",
                  "(* V6_ORBIT_HOT_LOOP_END *)")
    forbidden = {
        "algebraic branch substitution": "TRApplyRootBranches",
        "field decomposition": "TRFieldDecompose",
        "field inversion": "TRFieldInverse",
        "symbolic Together": "Together[",
        "symbolic D": "D[",
    }
    for label, token in forbidden.items():
        check(f"hot loop excludes {label}", token not in hot, failures)

    source_core = extract(core, "gcoPotentialCore[potentialChannels_List",
                          "gcoOneFormRecordFromChannels")
    check("exactly one source-code field-inverse call",
          source_core.count("TRFieldInverse[") == 1, failures)
    check("candidate one-form expressions are composed only after dedup",
          "gcoOneFormRecordFromChannels[" in core and
          core.index("candidateGroups = GatherBy") <
          core.index("forcingLetterRecords = MapIndexed"), failures)
    check("source-orbit lookup is grouped, not repeated Select",
          "candidatesBySource = GroupBy" in core and
          "members = Select[conjugateCandidates" not in core, failures)
    check("candidate cardinality is derived exactly",
          "expectedCandidateCount = expectedSourceCount Length[signMasks]"
          in core, failures)
    check("candidate cache counters conserve the derived cardinality",
          "formOrbitBuildCount + formOrbitReuseCount =!=" in core and
          "potentialOrbitBuildCount + potentialOrbitReuseCount =!=" in core,
          failures)
    check("legacy expensive-call counters fail closed at zero",
          '"LegacyAlgebraicFieldDecomposeCallsInCensus" -> 0' in core and
          '"LegacyAlgebraicRootBranchSubstitutionsInCensus" -> 0' in core,
          failures)
    check("no Global context dependency", "Global`" not in core, failures)
    check("no process or kernel control", not re.search(
          r"\b(KillProcess|RunProcess|LaunchKernels|CloseKernels|Quit)\b",
          core), failures)

    check("integration emits pre-rebind census milestone",
          "milestone=channel_orbit_ready" in integration, failures)
    check("V6d driver removes magic 28/112 count comparisons",
          "potentialSourceCount =!= 28" not in driver and
          "conjugateCandidateCount =!= 112" not in driver and
          "expectedCandidateCount = potentialSourceCount signMaskCount"
          in driver, failures)
    check("V6d driver distinguishes occurrences, sources, and aliases",
          all(token in driver for token in (
              'potentialOccurrenceCount = orbitBuild["PotentialOccurrenceCount"]',
              'potentialSourceCount = orbitBuild["PotentialSourceCount"]',
              'potentialAliasCount = orbitBuild["PotentialAliasCount"]',
              "potentialOccurrenceCount === potentialSourceCount + potentialAliasCount",
              "potentialSourceCount === metadataUniqueSourceCount")),
          failures)
    check("V6d driver count postcondition is runtime-derived and fail-closed",
          "runtimeCountPostconditionsExact = TrueQ[" in driver and
          "If[! runtimeCountPostconditionsExact ||" in driver and
          '"RuntimeCountPostconditionsExact" ->' in driver and
          "DistinctDLogOrbitCoreCount" in driver and
          "PotentialOrbitCoreReuseCount" in driver, failures)
    check("32 occurrences / 28 unique / 4 aliases contract is accepted",
          count_contract(32, 28, 4, 28, 112, 4), failures)
    check("32-as-unique / 128-candidate mutant is rejected",
          not count_contract(32, 32, 0, 28, 128, 4), failures)
    check("integration requires zero legacy algebraic calls",
          "LegacyAlgebraicFieldDecomposeCallsInCensus" in integration and
          "LegacyAlgebraicRootBranchSubstitutionsInCensus" in integration,
          failures)
    check("integration uses exact-channel rebind",
          "DRCARebindExactOneFormChannels" in integration and
          "DRCARebindAnsatz[" not in integration, failures)
    check("exact rebind pins assembler source",
          "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6"
          in exact_rebind, failures)
    check("exact rebind validates target channel composition",
          "AppendedChannelsDoNotComposeToTargetSuffix" in exact_rebind,
          failures)
    check("exact rebind compiles rational leaves directly",
          "Private`drcaCompileRational" in exact_rebind, failures)
    check("exact rebind never decomposes a field expression",
          "TRFieldDecompose" not in exact_rebind, failures)
    check("exact rebind never applies root branches",
          "TRApplyRootBranches" not in exact_rebind, failures)
    check("exact rebind preserves and validates equation core",
          "$drceEquationCoreKeys" in exact_rebind and
          "EquationCoreChangedDuringExactChannelRebind" in exact_rebind and
          "DRCAAssemblyPreparationValidQ" in exact_rebind, failures)
    check("full V6 driver contains no stale V5 label", "V5" not in driver,
          failures)
    check("full V6 driver resolves nested exchange paths correctly",
          "v6Directory = driverDirectory;" in driver and
          "galoisDirectory = DirectoryName[v6Directory];" in driver and
          "exchangeDirectory = DirectoryName[galoisDirectory];" in driver,
          failures)
    check("full V6 driver pins both new helper hashes",
          sha256(CORE) in driver and sha256(EXACT_REBIND) in driver, failures)
    check("full V6d driver loads both new helpers",
          '"OrbitCoreV6d", "ExactChannelRebindV6"' in driver, failures)
    check("full V6 driver exposes helper contexts in isolated scope",
          '"CodexCF300GaloisChannelOrbitV6d`"' in driver and
          '"CodexDirectRootChannelExactOneFormRebindV6`"' in driver,
          failures)
    driver_census = extract(driver,
                            "{censusSeconds, orbitBuild} = AbsoluteTiming[",
                            "gaugeCount = baseGaugeCount;")
    check("full V6 driver census delegates to rational-channel core",
          "GCOBuildOrbitBasis" in driver_census, failures)
    check("full V6 driver census contains no legacy symbolic builder",
          all(token not in driver_census for token in (
              "buildConjugateCandidate", "TRApplyRootBranches",
              "TRFieldDecompose", "Together[D[")), failures)
    check("full V6 driver reports census before rebind",
          driver.index("milestone=channel_orbit_ready") <
          driver.index("DRCARebindExactOneFormChannels"), failures)
    check("full V6 driver retains four image specifications",
          all(image_id in driver for image_id in
              ('"I00"', '"I01"', '"I10"', '"I11"')), failures)
    check("full V6 driver retains source and artifact stability gate",
          "stableInputsQ[]" in driver and
          "SourceOrArtifactChangedDuringScreen" in driver, failures)
    check("full V6 driver remains bound to pinned pre-existing input",
          "6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4"
          in driver and
          "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be"
          in driver, failures)
    certificate = extract(driver, '"SubsetEmbeddingCertificate" -> <|',
                          '"Scope" ->')
    check("V6d certificate renames integer residue-column field",
          '"ResidueColumnsPerLetter" -> residueColumnsPerLetter' in
          certificate and
          "EachAppendedLetterOccupiesResidueColumns" not in certificate,
          failures)
    check("V6d computes appended-only residue structure",
          "appendedOnlyResidueColumnStructureExact = TrueQ[" in driver and
          '"AppendedOnlyResidueColumnStructureExact" ->' in certificate,
          failures)
    check("V6d exact structure uses counts, layout and rebind seal",
          all(token in driver for token in (
              'maxAssembly["ResidueUnknownCount"] ===',
              'maxAssembly["UnknownCount"] ===',
              'maxAssembly["ColumnOrder", "Residue"] ===',
              '"EquationCorePreservedExactly", False')),
          failures)
    check("V6d computes every-image prefix containment",
          "everyImageBaseColumnPrefixContainedExactly = AllTrue[imageResults"
          in driver and
          '"EveryImageBaseColumnPrefixContainedExactly" ->' in certificate,
          failures)
    check("V6d column-deletion implication is derived, not hardcoded",
          "columnDeletionImplicationExact = TrueQ[" in driver and
          '"ColumnDeletionImplicationExact" ->\n      columnDeletionImplicationExact'
          in certificate and
          '"ColumnDeletionImplicationExact" -> True' not in certificate,
          failures)
    check("V6d fails closed on certificate construction",
          "AppendedOnlyResidueColumnStructureInvalid" in driver and
          "SubsetEmbeddingCertificateInvalid" in driver, failures)

    pre_milestone = v5[: v5.index(
        'Print["CF300_GALOIS_ORBIT milestone=target_ready')]
    check("audit premise: V5 first milestone follows orbit Table",
          pre_milestone.index("buildConjugateCandidate") <
          pre_milestone.index("DRCARebindAnsatz"), failures)
    check("audit premise: V5 performs algebraic branch transforms",
          "TRApplyRootBranches" in pre_milestone, failures)
    check("audit premise: V5 recomputes sourceForm in candidate builder",
          "sourceForm = {Together[D[sourcePotential, x]/sourcePotential]"
          in pre_milestone, failures)
    check("audit premise: V5 performs 16 compositions per source",
          "{left, signMasks}, {right, signMasks}" in pre_milestone,
          failures)

    print(f"INFO core_sha256={sha256(CORE)}")
    print(f"INFO integration_sha256={sha256(INTEGRATION)}")
    print(f"INFO exact_rebind_sha256={sha256(EXACT_REBIND)}")
    print(f"INFO driver_sha256={sha256(DRIVER)}")
    print(f"SUMMARY passed={TOTAL - len(failures)} total={TOTAL} failures={len(failures)}")
    if failures:
        print("FAILED " + ", ".join(failures))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
