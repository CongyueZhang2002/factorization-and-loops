#!/usr/bin/env python3
"""No-kernel adversarial audit for the CF300 sector-12 RAD9 driver."""

from __future__ import annotations

import hashlib
import itertools
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
DRIVER = HERE / "run_cf300_sector12_repeated_pole_rad9_screen_v1.wls"
text = DRIVER.read_text(encoding="utf-8")
checks: list[tuple[str, bool]] = []


def check(name: str, condition: bool) -> None:
    checks.append((name, bool(condition)))


def strip_wl(source: str) -> str:
    out: list[str] = []
    i = 0
    depth = 0
    in_string = False
    while i < len(source):
        if in_string:
            if source[i] == "\\" and i + 1 < len(source):
                i += 2
            elif source[i] == '"':
                in_string = False
                out.append(" ")
                i += 1
            else:
                i += 1
        elif depth:
            if source.startswith("(*", i):
                depth += 1
                i += 2
            elif source.startswith("*)", i):
                depth -= 1
                i += 2
            else:
                i += 1
        elif source.startswith("(*", i):
            depth = 1
            i += 2
        elif source[i] == '"':
            in_string = True
            out.append(" ")
            i += 1
        else:
            out.append(source[i])
            i += 1
    if in_string or depth:
        raise AssertionError(("unterminated", in_string, depth))
    return "".join(out)


def balanced(source: str) -> bool:
    clean = strip_wl(source)
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[str] = []
    i = 0
    while i < len(clean):
        if clean.startswith("<|", i):
            stack.append("<|")
            i += 2
        elif clean.startswith("|>", i):
            if not stack or stack.pop() != "<|":
                return False
            i += 2
        elif clean[i] in "([{":
            stack.append(clean[i])
            i += 1
        elif clean[i] in ")]}":
            if not stack or stack.pop() != pairs[clean[i]]:
                return False
            i += 1
        else:
            i += 1
    return not stack


check("driver exists", DRIVER.is_file())
check("delimiter balance", balanced(text))
check("single BeginPackage/EndPackage",
      text.count("BeginPackage[") == 1 and text.count("EndPackage[]") == 1)
check("dedicated artifact context literal",
      text.count("CodexCF300RepeatedPoleRad9ArtifactV1") >= 4)
check("private driver namespace",
      'BeginPackage["CodexCF300RepeatedPoleRad9DriverV1\u0060"]' in text)
check("no old Galois runtime identifiers",
      not re.search(r"GaloisOrbit|GALOIS_ORBIT|maxAssembly|maxPreparation", text))
check("no hardcoded-Global public reader", "DRCAReadCompiledArtifact[" not in text)
check("raw message-tolerant hydration", "Quiet[CheckAbort[Get[file], $Aborted]]" in text)
check("Global absent from runtime path diagnostic",
      '"GlobalContextPresentInRuntimePath"' in text)
check("no irreversible/unsafe symbol mutation",
      all(token not in text for token in
          ("InheritedBlock", "Unlock[", "Unprotect[", "ClearAll[Global")))
check("no Wolfram parallel entry points",
      all(token not in text for token in
          ("LaunchKernels", "ParallelSubmit", "ParallelTable",
           "ParallelMap", "DistributeDefinitions")))
check("no process control",
      all(token not in text for token in
          ("KillProcess", "StartProcess", "ProcessStatus", "RunProcess[")))
check("six/seven argument ABI",
      "MemberQ[{6, 7}, Length[arguments]]" in text)
check("census positional argument",
      "censusFile = ExpandFileName[arguments[[4]]]" in text)
check("explicit certificate/RAD9 modes",
      all(token in text for token in
          ('allowedRunModes = {"CERTIFICATE", "RAD9"}',
           'runMode === "CERTIFICATE"',
           '"RAD9FallbackNotRun" -> True')))
check("certificate exits before fallback rebind",
      text.index('runMode === "CERTIFICATE"') <
      text.index("DRCARebindAnsatz["))
check("fresh output guard",
      "FileExistsQ[outputFile]" in text and "OverwriteTarget -> False" in text)
check("all inputs source-stability guarded",
      all(token in text for token in
          ("hashes[] === sourceHashesBefore",
           "expectedPreparationHash", "expectedCacheHash",
           "expectedCensusHash", "driverHashBefore")))
check("exact artifact hashes",
      all(h in text for h in (
          "6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4",
          "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be",
          "c4bd5ceaceba7738d6fbd99e26498967b0f2864c76025b9ba3d74332dfccf29a")))
check("exact/compiled semantic fingerprints",
      all(h in text for h in (
          "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d",
          "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7")))
check("nine factor fingerprints",
      len(re.findall(r'"[0-9a-f]{64}"', text[text.index(
          "expectedFactorFingerprints"):text.index(
          "factorCatalog =", text.index("expectedFactorFingerprints"))])) == 9)
check("exact catalog size contract", "Length[factorCatalog] =!= 9" in text)
check("gauge reconstruction contract",
      "reconstructedGaugeDenominator - baseDenominator" in text)
check("RAD9 target is base times exact radical",
      "targetDenominator = Expand[baseDenominator radicalMultiplier]" in text)
check("target-first single rebind",
      text.count("DRCARebindAnsatz[") == 1)
check("target dimensions contract",
      all(token in text for token in
          ("radicalDegrees =!= {9, 7}", "targetDegrees =!= {13, 12}",
           "targetSupportCount =!= 182", "unknownCount =!= 3056",
           "pointCount =!= 97")))
check("exact local epsilon gate",
      all(token in text for token in
          ("diagonalKernelsEpsilonFreeQ",
           "DiagonalMaximumDenominatorExponent",
           "rootValuationMatrix",
           "rootValuationContractQ",
           "epsilonZeroSpectrum = -targetK + gradeValuations/2",
           '"DeterminantEpsilonConstantTerm"',
           "localResonanceCertificateExact")))
check("modular constant-term checks",
      'modExact[determinantConstant, #1] &, {10007, 10039}' in text)
check("512-profile exact census",
      "Length[profileRecords] === 512" in text and
      "2^Length[factorCatalog] - 1" in text)
check("convolution support certificate",
      all(token in text for token in
          ("ComplementMultiplierNonzero",
           "ConvolutionSupportContainedInRAD9",
           "SubsetQ[targetSupport, embeddedSupport]")))
check("image-dependent exact coefficient embedding",
      all(token in text for token in
          ("embeddingAtImage[prime_Integer, epsilonValue_]",
           "radicalMultiplier /. epsilon -> epsilonValue",
           "modRational[Last[#1], prime]")))
check("residue identity embedding",
      "{gaugeCount + residue, baseGaugeCount + residue} -> 1" in text)
check("common-point base projection",
      all(token in text for token in
          ('"CandidatePoints" -> screenPoints',
           "SparseArray[targetScreenMatrix].embedding",
           'projectedBaseMatrix =!= baseSample["Matrix"]')))
check("necessary witness before full ranks",
      text.index("AIWScoreColumns[") < text.index("rankImage[targetSample"))
check("all target columns scored",
      "AIWScoreColumns[\n    witness, SparseArray[targetScreenMatrix]]" in text)
check("independent coefficient/augmented ranks",
      text.count("nativeRank[") >= 3 and
      '"CertifiedAffineConsistencyByTwoRanksV1"' in text)
check("four cross images",
      all(token in text for token in
          ('"I00"', '"I01"', '"I10"', '"I11"',
           '"Prime" -> 10007', '"Prime" -> 10039',
           '"EpsilonValue" -> 1/21', '"EpsilonValue" -> 1/11')))
check("maximal implication qualified",
      "finite-field image rejection is not by itself" in text)
check("sharp RAD9 interpretation",
      "cannot be attributed to a genuine positive-order local resonance pole" in text)
check("literal context cleanup",
      'Remove["CodexCF300RepeatedPoleRad9ArtifactV1\u0060*"]' in text)
check("post-scope state gates",
      all(token in text for token in
          ("artifactNamespaceExactAfterScope",
           "artifactSymbolsDefinitionFreeAfterScope",
           "callerContextRestoredAfterScope",
           "artifactContextRemovedAfterScope")))

# Independent support/count model.  Each support is the exact exponent support
# of the corresponding canonical census factor in (x,y).
factor_supports = [
    {(0, 0), (1, 1)},                       # 1-4xy
    {(1, 0)},                               # x
    {(0, 0), (1, 0), (0, 1)},              # 1+x+y
    {(0, 1)},                               # y
    {(0, 0), (1, 0), (0, 1), (1, 1)},      # eps-dependent bilinear
    {(0, 0), (1, 0), (2, 0), (0, 1),
     (1, 1), (0, 2)},                       # Q
    {(0, 0), (1, 0)},                       # 1+x
    {(0, 0), (1, 0)},                       # 1-x
    {(0, 0), (1, 0), (0, 1)},              # 1-x-y
]


def minkowski(left, right):
    return {(a + c, b + d) for a, b in left for c, d in right}


rad = {(0, 0)}
for support in factor_supports:
    rad = minkowski(rad, support)
check("independent radical bidegree",
      (max(a for a, _ in rad), max(b for _, b in rad)) == (9, 7))
check("independent target counts",
      (13 + 1) * (12 + 1) == 182 and
      16 * 182 + 144 == 3056 and
      (3056 + 32 + 31) // 32 == 97)

all_profiles_contained = True
for mask in range(1 << 9):
    selected_degree = [4, 5]
    complement = {(0, 0)}
    for i, support in enumerate(factor_supports):
        if mask & (1 << i):
            selected_degree[0] += max(a for a, _ in support)
            selected_degree[1] += max(b for _, b in support)
        else:
            complement = minkowski(complement, support)
    subset_rectangle = {
        (a, b)
        for a in range(selected_degree[0] + 1)
        for b in range(selected_degree[1] + 1)
    }
    embedded = minkowski(subset_rectangle, complement)
    all_profiles_contained &= all(a <= 13 and b <= 12 for a, b in embedded)
check("independent 512-profile containment", all_profiles_contained)

current_orders = [2, 0, 0, 1, 1, 0, 0, 0, 1]
root_valuations = [
    (0, 1), (0, 0), (0, 0), (0, 0), (0, 0),
    (1, 0), (0, 0), (0, 0), (0, 0),
]
local_constants = []
for order, (nu0, nu1) in zip(current_orders, root_valuations):
    k = order + 1
    grade_nu = (0, nu0, nu1, nu0 + nu1)
    numerator = 1
    denominator = 1
    for nu in grade_nu:
        numerator *= (-2 * k + nu) ** 4
        denominator *= 2 ** 4
    local_constants.append((numerator, denominator))
check("independent half-root local constants nonzero",
      all(num != 0 and
          (num * pow(den, -1, p)) % p != 0
          for num, den in local_constants for p in (10007, 10039)))

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(f"{'PASS' if ok else 'FAIL'} {name}")
print("DRIVER_SHA256", hashlib.sha256(DRIVER.read_bytes()).hexdigest())
print(f"RAD9_STATIC {len(checks) - len(failed)}/{len(checks)}")
if failed:
    print("FAILED:", ", ".join(failed), file=sys.stderr)
    raise SystemExit(1)
