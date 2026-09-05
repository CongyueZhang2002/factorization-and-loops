(* Sampled family-level equalities are probabilistic even when every
   coefficient is rational. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, verdict_] := If[TrueQ[verdict], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label, " -> ", InputForm[verdict]]];

Clear[x, y, eps];
connection = {{{eps/x}}, {{eps/y}}};
candidate = <|
  "Family" -> "SyntheticRationalFamily",
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Blocks" -> {{1}}, "Ranges" -> {{1}},
  "TTotal" -> {{1}}, "TTotalInverse" -> {{1}},
  "EpsFormX" -> connection[[1]], "EpsFormY" -> connection[[2]]|>;
system = <|"Av" -> connection[[1]], "Aw" -> connection[[2]]|>;

symbolic = FeynFacet`ValidateFamilyDLogEpsilonForm[candidate, system,
  "SourceVariables" -> {x, y}, "IdentityMethod" -> "Symbolic"];
modular = FeynFacet`ValidateFamilyDLogEpsilonForm[candidate, system,
  "SourceVariables" -> {x, y}, "IdentityMethod" -> "Modular",
  "ModularPoints" -> 3, "ModularPrimes" -> 2];
dependentAlphabetCandidate = Join[candidate,
  <|"Letters" -> {x, -x, y, x y}|>];
dependentAlphabet = FeynFacet`ValidateFamilyDLogEpsilonForm[
  dependentAlphabetCandidate, system,
  "SourceVariables" -> {x, y}, "IdentityMethod" -> "Modular",
  "ModularPoints" -> 3, "ModularPrimes" -> 2];
randomPoints = FeynFacet`ValidateFamilyDLogEpsilonForm[candidate, system,
  "SourceVariables" -> {x, y}, "IdentityMethod" -> "RandomPoints",
  "Points" -> 2];

check["symbolic identities are exact",
  symbolic["DataType"] === "FamilyDLogEpsilonFormValidationResult" &&
    symbolic["Status"] === "FamilyDLogEpsilonFormValidationPassed" &&
    TrueQ[symbolic["Validation", "Exact"]] &&
    ! TrueQ[symbolic["Validation", "Probabilistic"]]];
check["finite-field identities are validated but not exact",
  modular["DataType"] === "FamilyDLogEpsilonFormValidationResult" &&
    modular["Status"] === "FamilyDLogEpsilonFormValidationPassed" &&
    TrueQ[modular["Validation", "Probabilistic"]] &&
    ! TrueQ[modular["Validation", "Exact"]] &&
    modular["Validation", "Method"] ===
      "ProbabilisticFiniteFieldSampling"];
check["a redundant caller alphabet is reduced to independent divisors",
  dependentAlphabet["Status"] ===
    "FamilyDLogEpsilonFormValidationPassed" &&
    TrueQ[dependentAlphabet["Validation", "Conditions",
      "DLogReconstruction"]]];
check["random rational points are validated but not exact",
  randomPoints["DataType"] === "FamilyDLogEpsilonFormValidationResult" &&
    randomPoints["Status"] === "FamilyDLogEpsilonFormValidationPassed" &&
    TrueQ[randomPoints["Validation", "Probabilistic"]] &&
    ! TrueQ[randomPoints["Validation", "Exact"]] &&
    randomPoints["Validation", "Method"] ===
      "RandomRationalPointEvaluation"];

badCandidate = ReplacePart[candidate,
  {"EpsFormX", 1, 1} -> eps/x + eps x];
bad = FeynFacet`ValidateFamilyDLogEpsilonForm[badCandidate, system,
  "SourceVariables" -> {x, y}, "IdentityMethod" -> "Modular",
  "ModularPoints" -> 3, "ModularPrimes" -> 2];
check["a non-dlog polynomial part is rejected",
  bad["Status"] === "FamilyDLogEpsilonFormValidationFailed" &&
    ! TrueQ[bad["Validation", "Conditions", "DLogReconstruction"]]];

Print["t_family_certificate_modular: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
