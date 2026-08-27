#!/usr/bin/env python3
"""No-Wolfram static/adversarial source gate for the isolated V6e prototype."""

from __future__ import annotations

import hashlib
import pathlib
import re
import sys


HERE = pathlib.Path(__file__).resolve().parent
PARENT = HERE.parent
HELPER = HERE / "DirectRootChannelExactOneFormRebindV6e.wl"
INTEGRATION = HERE / "V6E_DRIVER_INTEGRATION_BLOCK.wl"
PLAN = PARENT / "V6E_EXACT_REBIND_OPTIMIZATION_PLAN_2026-08-23_XH.md"
V6D_CORE = PARENT / "GaloisChannelOrbitCoreV6d.wl"
V6D_DRIVER = PARENT / "run_cf300_sector12_galois_orbit_forcing_screen_v6d.wls"
TOTAL = 0


def check(name: str, condition: bool, failures: list[str]) -> None:
    global TOTAL
    TOTAL += 1
    print(f"{'PASS' if condition else 'FAIL'} {name}")
    if not condition:
        failures.append(name)


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def code_without_comments_or_strings(text: str) -> str:
    out: list[str] = []
    comment_depth = 0
    in_string = False
    escaped = False
    i = 0
    while i < len(text):
        pair = text[i:i + 2]
        if comment_depth:
            if pair == "(*":
                comment_depth += 1
                i += 2
            elif pair == "*)":
                comment_depth -= 1
                i += 2
            else:
                i += 1
            out.append(" ")
            continue
        if in_string:
            if escaped:
                escaped = False
            elif text[i] == "\\":
                escaped = True
            elif text[i] == '"':
                in_string = False
            out.append(" ")
            i += 1
            continue
        if pair == "(*":
            comment_depth = 1
            out.append(" ")
            i += 2
        elif text[i] == '"':
            in_string = True
            out.append(" ")
            i += 1
        else:
            out.append(text[i])
            i += 1
    if comment_depth or in_string:
        raise ValueError("unterminated Wolfram comment or string")
    return "".join(out)


def balanced_wolfram_delimiters(text: str) -> bool:
    try:
        code = code_without_comments_or_strings(text)
    except ValueError:
        return False
    stack: list[str] = []
    pairs = {"]": "[", ")": "(", "}": "{"}
    for char in code:
        if char in "[({":
            stack.append(char)
        elif char in "])}":
            if not stack or stack.pop() != pairs[char]:
                return False
    return not stack


def context_marks_joined(text: str) -> bool:
    code = code_without_comments_or_strings(text)
    return re.search(
        r"[A-Za-z$][A-Za-z0-9$]*`[ \t\r\n]+[A-Za-z$]", code
    ) is None


def implementation_contract(text: str) -> bool:
    required = (
        '"BaseValidation"',
        '"TargetABIValidation"',
        '"SuffixCompositionEquality"',
        '"CanonicalLeafGrouping"',
        '"UniqueLeafCompilation"',
        '"ExactCompiledJoins"',
        '"LegacyFingerprintConstruction"',
        '"OneLegacyWholeResultOracle"',
        '"SpecializedValidationSealConstruction"',
        "GatherBy[localRecords",
        "SameQ[#1[\"Pair\"], First[group][\"Pair\"]]",
        "drceCanonicalPairValidQ",
        "canonicalPairsMatchChannels",
        "AssociationThread[",
        "drcaCompilePolynomial",
        "drcaCompileRational",
        "rawLeafCount =!= uniqueLeafCount + cacheReuseCount",
        '"CollisionGroupCount" -> collisionGroupCount',
        '"LegacyWholeResultOracleCount" -> 1',
        '"Nonce" -> CreateUUID[]',
        "KeyExistsQ[$drceConsumedNonces, nonce]",
        "drceSpecializedSealValidQ[assembly, target, result, seal]",
        "KeyDrop[result, $drceResultChangedKeys]",
        "KeyDrop[assembly, $drceResultChangedKeys]",
        "sourceHashesAfter === sourceHashesBefore",
    )
    return all(token in text for token in required)


def main() -> int:
    failures: list[str] = []
    helper = HELPER.read_text()
    integration = INTEGRATION.read_text()
    plan = PLAN.read_text()
    v6d_core = V6D_CORE.read_text()
    v6d_driver = V6D_DRIVER.read_text()
    helper_code = code_without_comments_or_strings(helper)
    integration_code = code_without_comments_or_strings(integration)

    check("helper is nontrivial", len(helper) > 25_000, failures)
    check("integration block is nontrivial", len(integration) > 4_000,
          failures)
    check("helper delimiters balance", balanced_wolfram_delimiters(helper),
          failures)
    check("integration delimiters balance",
          balanced_wolfram_delimiters(integration), failures)
    check("helper context marks are joined", context_marks_joined(helper),
          failures)
    check("integration context marks are joined",
          context_marks_joined(integration), failures)
    check("dedicated V6e package context",
          'BeginPackage["CodexDirectRootChannelExactOneFormRebindV6e`"'
          in helper, failures)
    check("public rebind exported",
          "DRCARebindExactOneFormRecordsV6e::usage" in helper, failures)
    check("public seal validator exported",
          "DRCAExactOneFormRebindSealValidQ::usage" in helper, failures)
    check("single-use seal consumer exported",
          "DRCAConsumeExactOneFormRebindSealV6e::usage" in helper,
          failures)
    check("implementation contract present",
          implementation_contract(helper), failures)
    check("V6e pins exact assembler source",
          "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6"
          in helper, failures)
    check("helper has exactly base and one result whole validators",
          helper_code.count("DRCAAssemblyPreparationValidQ[") == 2,
          failures)
    check("integration makes no whole-result validator call",
          "DRCAAssemblyPreparationValidQ[" not in integration_code,
          failures)
    check("integration consumes specialized seal",
          "DRCAConsumeExactOneFormRebindSealV6e[" in integration,
          failures)
    check("integration pins the exact V6e helper hash",
          sha256(HELPER) in integration and
          "__V6E_HELPER_SHA256_TO_BE_FROZEN__" not in integration,
          failures)
    check("integration derives exact records without simplification",
          "SelectFirst[forcingLetterRecords" in integration and
          "SameQ[Lookup[#1, \"OneFormChannels\"" in integration and
          "Together[" not in integration_code, failures)
    check("integration rejects record reordering and duplicates",
          'Lookup[additionalLetterRecordsV6e, "OneFormChannels"] =!='
          in integration and
          "DuplicateFreeQ[Lookup[additionalLetterRecordsV6e" in integration,
          failures)
    check("integration enforces raw/unique/cache conservation",
          '"RawLeafCount", -1] =!=' in integration and
          '"UniqueCompiledLeafCount", -2] +' in integration and
          '"CompileCacheReuseCount", -3]' in integration, failures)
    check("integration enforces exactly one legacy oracle",
          '"LegacyWholeResultOracleCount", -1] =!= 1' in integration,
          failures)
    check("helper never decomposes an algebraic field expression",
          "TRFieldDecompose" not in helper_code, failures)
    check("helper never applies algebraic root branches",
          "TRApplyRootBranches" not in helper_code, failures)
    check("helper directly compiles canonical polynomial pairs",
          helper_code.count("Private`drcaCompilePolynomial[") == 2,
          failures)
    check("legacy rational compiler is audit-only",
          helper_code.count("Private`drcaCompileRational[") == 1 and
          "legacyAuditCompiled" in helper, failures)
    check("pair validator rejects zero denominators",
          "denominator === 0" in helper, failures)
    check("pair validator enforces reduced canonical Together pair",
          "Expand[Numerator[rational]] === numerator" in helper and
          "Expand[Denominator[rational]] === denominator" in helper,
          failures)
    check("pair validator enforces exact polynomial coefficients",
          "CoefficientRules[numerator, vars]" in helper and
          "drceExactCoefficientQ" in helper, failures)
    check("collision groups compare exact pairs",
          "collisionFree = AllTrue[leafGroups" in helper and
          "SameQ[#1[\"Pair\"], First[group][\"Pair\"]]" in helper,
          failures)
    check("canonical pairs are rebound to every raw exact leaf",
          '"CanonicalLeafValidation"' in helper and
          "canonicalPairsMatchChannels" in helper and
          "And @@ MapThread[" in helper and
          "channel - pair[[1]]/pair[[2]]" in helper, failures)
    seal_validator_start = helper.index(
        "drceSpecializedSealValidQ[assembly_Association")
    seal_validator = helper[seal_validator_start:helper.index(
        "DRCAExactOneFormRebindSealValidQ[assembly_Association",
        seal_validator_start)]
    check("seal uses bound suffix fingerprints without recomposition",
          'drceFingerprint[exactSuffix] ===' in seal_validator and
          'drceFingerprint[canonicalPairs] ===' in seal_validator and
          "Together[" not in seal_validator, failures)
    check("compiled suffix retains exact rational ABI",
          'Lookup[#1, "Type", None] === "DRCARationalExactV1"' in helper,
          failures)
    check("five deterministic leaves use legacy compile audit",
          "Ceiling[rawLeafCount/4]" in helper and
          "Ceiling[3 rawLeafCount/4]" in helper and
          "SameQ[legacyAuditCompiled, memoAuditCompiled]" in helper,
          failures)
    check("all nine requested phases have timers",
          all(label in helper for label in (
              '"BaseValidation"', '"TargetABIValidation"',
              '"SuffixCompositionEquality"', '"CanonicalLeafGrouping"',
              '"UniqueLeafCompilation"', '"ExactCompiledJoins"',
              '"LegacyFingerprintConstruction"',
              '"OneLegacyWholeResultOracle"',
              '"SpecializedValidationSealConstruction"')),
          failures)
    check("every measured phase records memory",
          '"BeforeBytes" -> before' in helper and
          '"AfterBytes" -> after' in helper and
          '"DeltaBytes" -> after - before' in helper, failures)
    check("fingerprint serialization counts are reused",
          '"InputFormCharacterCount" -> StringLength[serialized]' in helper
          and '"SerializedInputFormCharacterCounts"' in helper, failures)
    check("raw and unique expression byte counts recorded",
          '"CanonicalPairsRaw" -> ByteCount[canonicalPairs]' in helper and
          '"CanonicalPairsUnique" -> ByteCount[Lookup[' in helper,
          failures)
    check("seal binds base/result/target fingerprints",
          all(token in helper for token in (
              '"BaseAssemblyFingerprint"', '"ResultAssemblyFingerprint"',
              '"TargetABIFingerprint"')), failures)
    check("seal binds both equation cores and suffixes",
          all(token in helper for token in (
              '"ExactEquationCoreFingerprint"',
              '"CompiledEquationCoreFingerprint"',
              '"ExactSuffixChannelsFingerprint"',
              '"CanonicalSuffixPairsFingerprint"',
              '"CompiledSuffixFingerprint"')), failures)
    check("seal binds counts and column layout",
          all(token in helper for token in (
              '"GaugeUnknownCount"', '"ResidueUnknownCount"',
              '"UnknownCount"', '"ColumnOrderFingerprint"')), failures)
    check("seal validates all certificate fields as Boolean",
          "AllTrue[Values[booleanCertificates], BooleanQ]" in helper and
          "And @@ Values[booleanCertificates]" in helper, failures)
    check("source hashes checked before and after",
          '"SourceHashesBeforeConstruction"' in helper and
          '"SourceHashesAfterConstruction"' in helper and
          "sourceStableAfterOracle" in helper, failures)
    check("equation core exact comparisons retained",
          helper.count("$drceEquationCoreKeys") >= 5 and
          "EquationCoreChangedDuringV6eJoin" in helper, failures)
    check("specialized seal rejects extra exact/compiled form fields",
          'KeyDrop[result["ExactChannelForms"], "OneForms"] ===' in helper
          and 'KeyDrop[result["CompiledForms"], "OneForms"] ===' in helper,
          failures)
    check("specialized seal does not reserialize immutable equation cores",
          'drceFingerprint[KeyTake[result["ExactChannelForms"]' not in
          seal_validator and
          'drceFingerprint[KeyTake[result["CompiledForms"]' not in
          seal_validator, failures)
    check("all non-one-form result fields compared exactly",
          "changedKeysExact = TrueQ[" in helper and
          "KeyDrop[result, $drceResultChangedKeys] ===" in helper,
          failures)
    check("target non-one-form core rechecked by seal",
          "drceCoreCompatibleQ[assembly, target]" in helper, failures)
    check("target stored counts rechecked by seal",
          all(token in helper for token in (
              'target["GaugeUnknownCount"] === expectedGauge',
              'target["ResidueUnknownCount"] === expectedResidue',
              'target["UnknownCount"] === expectedUnknown',
              'target["EquationsPerPoint"] === gradeCount 2')),
          failures)
    check("certificate key set is exact",
          "$drceCertificateKeys" in helper and
          "Sort[Keys[booleanCertificates]] === Sort[$drceCertificateKeys]"
          in helper, failures)
    check("stale and replayed nonces rejected",
          "KeyExistsQ[$drceConsumedNonces, nonce]" in helper and
          "AssociateTo[$drceConsumedNonces" in helper, failures)
    check("success payload forbids Failed and Missing",
          "FreeQ[{result, seal}, $Failed | _Missing]" in helper, failures)
    check("pre, compile, and ready milestones emitted",
          all(token in helper for token in (
              "milestone=v6e_rebind_start",
              "milestone=v6e_suffix_composed",
              "milestone=v6e_unique_leaves_compiled",
              "milestone=v6e_rebind_ready")), failures)
    check("no process or kernel control in helper",
          not re.search(
              r"\b(KillProcess|RunProcess|StartProcess|LaunchKernels|"
              r"CloseKernels|Quit|Exit)\b", helper_code), failures)
    check("no filesystem writes in helper",
          not re.search(
              r"\b(Put|PutAppend|Export|DeleteFile|RenameFile|CopyFile)\b",
              helper_code), failures)
    check("no Global context dependency",
          "Global`" not in helper and "Global`" not in integration,
          failures)
    check("active V6d core remains frozen",
          sha256(V6D_CORE) ==
          "7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed",
          failures)
    check("active V6d driver remains frozen",
          sha256(V6D_DRIVER) ==
          "921422ec0f78c8a56a707fb487115d0b0a5debe6b84e5257e0d3df638e43988d",
          failures)
    check("V6e plan remains frozen",
          sha256(PLAN) ==
          "64a70f8d2083dc986e6ed31b1e4c824c1c97d86c0aef0bb21fb98d5f6765a521",
          failures)
    check("V6e helper is absent from V6d core",
          "V6e" not in v6d_core, failures)
    check("V6e helper is absent from active V6d driver",
          "V6e" not in v6d_driver, failures)
    check("plan explicitly forbids speedup claims from static counts",
          re.search(
              r"no\s+speedup should be claimed from static counts alone",
              plan) is not None,
          failures)

    collision_mutant = helper.replace(
        'SameQ[#1["Pair"], First[group]["Pair"]]', "True", 2)
    check("collision-check removal mutant is rejected",
          not implementation_contract(collision_mutant), failures)
    pair_binding_mutant = helper.replace(
        "canonicalPairsMatchChannels", "canonicalPairsAccepted")
    check("channel/pair binding removal mutant is rejected",
          not implementation_contract(pair_binding_mutant), failures)
    oracle_mutant = helper.replace(
        '"LegacyWholeResultOracleCount" -> 1',
        '"LegacyWholeResultOracleCount" -> 0', 1)
    check("legacy-oracle-count mutant is rejected",
          not implementation_contract(oracle_mutant), failures)
    nonce_mutant = helper.replace('"Nonce" -> CreateUUID[]',
                                  '"Nonce" -> "constant"', 1)
    check("constant-nonce mutant is rejected",
          not implementation_contract(nonce_mutant), failures)
    conservation_mutant = helper.replace(
        "rawLeafCount =!= uniqueLeafCount + cacheReuseCount",
        "rawLeafCount < uniqueLeafCount + cacheReuseCount", 1)
    check("cache-conservation mutant is rejected",
          not implementation_contract(conservation_mutant), failures)

    print(f"INFO helper_sha256={sha256(HELPER)}")
    print(f"INFO integration_sha256={sha256(INTEGRATION)}")
    print(f"SUMMARY passed={TOTAL - len(failures)} total={TOTAL} "
          f"failures={len(failures)}")
    if failures:
        print("FAILED " + ", ".join(failures))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
