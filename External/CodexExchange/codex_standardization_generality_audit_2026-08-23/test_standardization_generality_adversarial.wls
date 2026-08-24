#!/usr/bin/env wolframscript
(* External red-team audit for the standardized multiquadratic finite-field
   implementation.  This file is copied into External/CodexExchange; it is
   deliberately not a package regression because the strict generality
   requirements at the end document current design boundaries as failures. *)

projectRoot = FixedPoint[
  If[FileExistsQ[FileNameJoin[{#1, "FeynFacet", "FeynFacet.m"}]], #1,
    DirectoryName[#1]] &,
  DirectoryName[ExpandFileName[$InputFileName]]
];
Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_String, condition_] := If[TrueQ[condition],
  pass++; Print["PASS  ", label],
  fail++; Print["FAIL  ", label]
];
status[value_] := If[AssociationQ[value], Lookup[value, "Status", None],
  Head[value]];
private[name_String] := Symbol["FeynFacet`Private`" <> name];

{prepare, compile, solve, certificate} = private /@ {
  "multiquadraticStripPrepare", "multiquadraticStripCompile",
  "solveEpsFormStripMultiquadratic", "familyCertificateModular"
};

Clear[s, t, u, eta, cs, ct, a, b, ep, ca, cb, cu];

(* Treat u as dependent.  This is the two-independent-variable Mandelstam
   use case promised by the current package design. *)
uRule = u -> 1 - s - t;
rootSquaresST = {s, t, u} /. uRule;
frameST = FeynFacet`BuildAlgebraicTransportFrame[
  rootSquaresST, {s, t}, {cs, ct}];
check["an exact rank-three frame accepts generic Mandelstam names after u is eliminated",
  AssociationQ[frameST] && frameST["Status"] === "ExactFrame" &&
    Length[frameST["Roots"]] === 3 &&
    frameST["ChartCertificate", "RootIdentities"] === {True, True, True}];

denominatorST = 1 - s - t;
gaugeST = Sqrt[s] Sqrt[t] Sqrt[denominatorST]/denominatorST;
zeroDiagonal = {{{0}}, {{0}}};
forcingST = Table[{{Together[D[gaugeST, {s, t}[[mu]]]]}}, {mu, 2}];
recordST = <|
  "Family" -> "ARBITRARY_PROCESS_ALPHA",
  "Sector" -> <|"OpaqueLabel" -> "not-an-integer"|>,
  "LowerSector" -> Missing["NotApplicable"],
  "Variables" -> {s, t}, "Regulator" -> eta,
  "Strip" -> {zeroDiagonal, zeroDiagonal, forcingST}
|>;

prepareOptions = Sequence[
  "OneForms" -> {}, "GaugeDenominator" -> denominatorST,
  "Support" -> {{0, 0}}
];
preparedST = prepare[recordST, frameST, prepareOptions];
check["the generic s,t rank-three strip prepares without a family catalog",
  status[preparedST] === "PreparedMultiquadraticStripV1" &&
    preparedST["RootCount"] === 3 && preparedST["GradeCount"] === 8];

compiledST = If[AssociationQ[preparedST], compile[preparedST], $Failed];
check["the generic s,t rank-three preparation compiles",
  status[compiledST] === "CompiledMultiquadraticStripV1"];

solvedST = If[status[compiledST] === "CompiledMultiquadraticStripV1",
  solve[recordST, frameST, prepareOptions,
    "SamplePrimes" -> {2147483423},
    "RegulatorValues" -> {1/13},
    "HeldOutPrime" -> 2147483323,
    "HeldOutRegulatorValue" -> 5/23,
    "PointCount" -> 2, "MaximumAttempts" -> 512,
    "RandomSeed" -> 2026082319],
  <|"Status" -> "CompilePrerequisiteFailed"|>
];
check["the generic s,t rank-three strip reaches modular consistency",
  status[solvedST] === "ModularConsistent" &&
    solvedST["RootCount"] === 3 && solvedST["GradeCount"] === 8 &&
    Length[solvedST["BranchCertificate"]] === 8 &&
    AllTrue[solvedST["BranchCertificate"], TrueQ[#1["ResidualZero"]] &]];

(* Family, sector, lower-sector and unrelated campaign metadata must never
   enter the mathematical ABI. *)
recordMetadataOnly = Join[recordST, <|
  "Family" -> "UNRELATED_PROCESS_OMEGA",
  "Sector" -> "opaque-sector-name",
  "LowerSector" -> {1, 4, 9},
  "CampaignMetadata" -> <|"Owner" -> "arbitrary", "Iteration" -> 999|>
|>];
preparedMetadataOnly = prepare[recordMetadataOnly, frameST, prepareOptions];
check["family and campaign metadata do not alter the strip ABI",
  status[preparedMetadataOnly] === "PreparedMultiquadraticStripV1" &&
    preparedMetadataOnly["ABIFingerprint"] === preparedST["ABIFingerprint"] &&
    preparedMetadataOnly["ABIPayload"] === preparedST["ABIPayload"]];

recordNoMetadata = KeyDrop[recordST, {"Family", "Sector", "LowerSector"}];
preparedNoMetadata = prepare[recordNoMetadata, frameST, prepareOptions];
check["family and sector metadata are optional, not hidden solver inputs",
  status[preparedNoMetadata] === "PreparedMultiquadraticStripV1" &&
    preparedNoMetadata["ABIFingerprint"] === preparedST["ABIFingerprint"]];

(* Rename every variable, regulator and chart symbol.  Canonical ABI text must
   be bit-identical, not merely algebraically equivalent. *)
frameAB = FeynFacet`BuildAlgebraicTransportFrame[
  {a, b, 1 - a - b}, {a, b}, {ca, cb}];
denominatorAB = 1 - a - b;
gaugeAB = Sqrt[a] Sqrt[b] Sqrt[denominatorAB]/denominatorAB;
forcingAB = Table[{{Together[D[gaugeAB, {a, b}[[mu]]]]}}, {mu, 2}];
recordAB = <|"Family" -> "NO_CANONICAL_PREFIX_REQUIRED",
  "Variables" -> {a, b}, "Regulator" -> ep,
  "Strip" -> {zeroDiagonal, zeroDiagonal, forcingAB}|>;
preparedAB = prepare[recordAB, frameAB,
  "OneForms" -> {}, "GaugeDenominator" -> denominatorAB,
  "Support" -> {{0, 0}}];
check["renaming s,t,eta to a,b,ep preserves the exact ABI fingerprint",
  status[preparedAB] === "PreparedMultiquadraticStripV1" &&
    preparedAB["ABIFingerprint"] === preparedST["ABIFingerprint"] &&
    preparedAB["ABIPayload"] === preparedST["ABIPayload"]];

(* The field implementation must not recognize only the roots from the
   motivating families.  Exercise unrelated irreducible-looking polynomial
   square classes, including quadratic and mixed terms. *)
stressRootSets = {
  {1 + s, 2 + t, 3 + s + t + s t},
  {1 + s + s^2 + t, 2 + s + t^2, 5 + 2 s + 3 t + s t},
  {2 - s + t^2, 3 + t + s^2, 7 + s - 2 t + 2 s t}
};
stressResults = MapIndexed[Function[{squares, index}, Module[
    {frame, q, gauge, forcing, record, preparation, assembly},
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      squares, {s, t}, {cs, ct}];
    q = 11 + index[[1]] s + (index[[1]] + 1) t;
    gauge = Times @@ (Sqrt /@ squares)/q;
    forcing = Table[{{Together[D[gauge, {s, t}[[mu]]]]}}, {mu, 2}];
    record = <|"Family" -> ("SYNTHETIC_" <> ToString[index[[1]]]),
      "Variables" -> {s, t}, "Regulator" -> eta,
      "Strip" -> {zeroDiagonal, zeroDiagonal, forcing}|>;
    preparation = prepare[record, frame, "OneForms" -> {},
      "GaugeDenominator" -> q, "Support" -> {{0, 0}}];
    assembly = If[AssociationQ[preparation], compile[preparation], $Failed];
    <|"Prepare" -> status[preparation], "Compile" -> status[assembly],
      "RootCount" -> If[AssociationQ[preparation],
        Lookup[preparation, "RootCount", None], None]|>
  ]], stressRootSets];
check["unrelated polynomial root triples prepare and compile generically",
  Length[stressResults] === Length[stressRootSets] &&
    AllTrue[stressResults,
      #1 === <|"Prepare" -> "PreparedMultiquadraticStripV1",
        "Compile" -> "CompiledMultiquadraticStripV1",
        "RootCount" -> 3|> &]];

(* Algebraically the declaration order of a basis of square classes is not
   data.  This probe also detects avoidable artifact-cache fragmentation. *)
frameReversed = FeynFacet`BuildAlgebraicTransportFrame[
  Reverse[rootSquaresST], {s, t}, {cs, ct}];
preparedReversed = prepare[recordST, frameReversed, prepareOptions];
check["root declaration order does not alter the canonical strip ABI",
  status[preparedReversed] === "PreparedMultiquadraticStripV1" &&
    preparedReversed["ABIFingerprint"] === preparedST["ABIFingerprint"]];
If[status[preparedReversed] === "PreparedMultiquadraticStripV1" &&
    preparedReversed["ABIFingerprint"] =!= preparedST["ABIFingerprint"],
  Print["DIAGNOSTIC  differing ABI fields: ",
    Select[Keys[preparedST["ABIPayload"]],
      preparedST["ABIPayload", #1] =!=
        preparedReversed["ABIPayload", #1] &]]];

(* An extra independent symbol in a root square cannot reach modular
   sampling.  The public frame constructor currently accepts it as an exact
   symbolic frame; the strip boundary must still fail closed. *)
frameExtraU = FeynFacet`BuildAlgebraicTransportFrame[
  {s, t, u}, {s, t}, {cs, ct}];
recordExtraU = <|"Variables" -> {s, t}, "Regulator" -> eta,
  "Strip" -> {zeroDiagonal, zeroDiagonal,
    {{{Sqrt[u]}}, {{0}}}}|>;
preparedExtraU = prepare[recordExtraU, frameExtraU,
  "OneForms" -> {}, "GaugeDenominator" -> 1,
  "Support" -> {{0, 0}}];
check["an unsampled independent u cannot enter a context-free modular ABI",
  AssociationQ[frameExtraU] && frameExtraU["Status"] === "ExactFrame" &&
    status[preparedExtraU] === "ContextSensitiveStripABI"];

(* Three differential directions are not silently truncated. *)
frameThreeCall = FeynFacet`BuildAlgebraicTransportFrame[
  {s, t, u}, {s, t, u}, {cs, ct, cu}];
check["the frame constructor does not silently truncate three variables",
  ! AssociationQ[frameThreeCall] &&
    Head[frameThreeCall] === FeynFacet`BuildAlgebraicTransportFrame];

preparedThree = prepare[
  Join[recordST, <|"Variables" -> {s, t, u}|>], frameST,
  "OneForms" -> {}, "GaugeDenominator" -> denominatorST,
  "Support" -> {{0, 0}}];
check["the strip preparation rejects three variables by type",
  status[preparedThree] === "InvalidStripRecord"];

certificateThree = certificate[
  {zeroDiagonal, zeroDiagonal}, {{1}}, {{1}}, {s, t, u}, eta,
  {zeroDiagonal, zeroDiagonal}, {s, t, u}, None];
check["the modular family certificate cannot certify only two slices of a three-variable call",
  Head[certificateThree] === certificate];

(* Strict package-generality requirements.  These are intentionally tested as
   requirements, not normalized as backward compatibility. *)
publicTripleResult = FeynFacet`SolveEpsFormStripInFrame[
  {zeroDiagonal, zeroDiagonal, forcingST}, {s, t}, eta, frameST,
  "FiniteFieldFirst" -> True, "FiniteFieldFallback" -> True,
  "Verbose" -> False];
check["STRICT: the public in-frame solver dispatches a chartless triple-root strip to the promoted modular engine",
  MemberQ[{"Solved", "ModularConsistent"}, status[publicTripleResult]]];

rowGaugeLoadedQ = With[
  {prepareSymbol = private["familyRowGaugeFiniteFieldPrepare"],
   evaluateSymbol = private["familyRowGaugeFiniteFieldEvaluate"]},
  Length[DownValues[prepareSymbol]] > 0 &&
    Length[DownValues[evaluateSymbol]] > 0
];
check["STRICT: the standardized finite-field row-gauge implementation is loaded by the package",
  rowGaugeLoadedQ];

canonicalName = private["canonicalFamilyName"][1];
check["STRICT: generated canonical-family names are caller-configurable, not forced to CF<n>",
  ! StringMatchQ[SymbolName[canonicalName], "CF" ~~ DigitCharacter ..]];

defaultVariables = private["canonicalBlocksResolveVariables"][Automatic];
check["STRICT: a missing variable declaration does not silently select Global v,w",
  defaultVariables =!= {Symbol["Global`v"], Symbol["Global`w"]}];

defaultRegulatorRecord = private["diagonalBlockClassRecord"][
  <|"ClassID" -> "ZERO", "RepAv" -> {{0}}, "RepAw" -> {{0}}|>,
  Automatic, 10, None, False, Automatic];
check["STRICT: a regulator-free undeclared class does not silently select Global eps",
  ! AssociationQ[defaultRegulatorRecord] ||
    Lookup[defaultRegulatorRecord, "Regulator", None] =!= Symbol["Global`eps"]];

scratch = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "FeynFacetStrictPathAudit-" <> StringTake[CreateUUID[], 8]}]];
resultDirectory = FileNameJoin[{scratch, "ArbitraryProcess", "Results", "RunA"}];
CreateDirectory[resultDirectory, CreateIntermediateDirectories -> True];
location = private["ibpProjectLocation"][resultDirectory, scratch];
check["STRICT: generated workspaces do not contain an agent-specific Codex component",
  AssociationQ[location] && FreeQ[FileNameSplit[location["Root"]], "Codex"]];
Quiet[DeleteDirectory[scratch, DeleteContents -> True]];

Print[StringRepeat["-", 72]];
Print["standardization/generality adversarial audit: ", pass,
  " PASS, ", fail, " FAIL"];
Exit[Min[fail, 250]];
