root = "/home/maxzhang/FACET";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

testRoot = CreateDirectory[];
project = FileNameJoin[{testRoot, "KiraProject"}];
runtime = <|"Kira" -> "test", "Version" -> 1|>;
payloadOne = <|"Topology" -> topoA, "Targets" -> {targetA}|>;
payloadTwo = <|"Topology" -> topoA, "Targets" -> {targetB}|>;

stateOne = FeynFacet`Private`ibpResetProject[
  project,
  testRoot,
  payloadOne,
  runtime
];
marker = FileNameJoin[{project, "stale.marker"}];
Export[marker, "stale", "String"];
stateSame = FeynFacet`Private`ibpResetProject[
  project,
  testRoot,
  payloadOne,
  runtime
];
sameInputDeletesStaleFiles = ! FileExistsQ[marker];
Export[marker, "stale", "String"];
stateChanged = FeynFacet`Private`ibpResetProject[
  project,
  testRoot,
  payloadTwo,
  runtime
];

normalizedCoefficient = FeynFacet`Private`exactCoefficientNormalize[
  4^Global`Epsilon/(1 - Global`x) +
    2^(2 Global`Epsilon)/(1 + Global`x)
];

checks = <|
  "FreshWorkspaceHasNoResumeState" -> And[
    ! KeyExistsQ[stateOne, "ResumeEligible"],
    ! KeyExistsQ[stateSame, "ResumeEligible"],
    ! KeyExistsQ[stateChanged, "ResumeEligible"]
  ],
  "ExactInputRecreatesWorkspace" -> sameInputDeletesStaleFiles,
  "ExactInputKeepsFingerprint" ->
    stateOne["InputFingerprint"] === stateSame["InputFingerprint"],
  "ChangedInputDeletesStaleFiles" -> ! FileExistsQ[marker],
  "FingerprintChangesWithTarget" ->
    stateOne["InputFingerprint"] =!= stateChanged["InputFingerprint"],
  "DimensionRuleIsUnique" -> And[
    (System`D /. FeynFacet`Private`$dimensionRule) ===
      4 - 2 Global`Epsilon,
    FreeQ[System`D /. FeynFacet`Private`$dimensionRule, System`D]
  ],
  "ExactProtectedPowersNormalize" ->
    normalizedCoefficient =!= $Failed &&
      FeynFacet`Private`exactDataQ[normalizedCoefficient]
|>;

DeleteDirectory[testRoot, DeleteContents -> True];
Print[checks];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
