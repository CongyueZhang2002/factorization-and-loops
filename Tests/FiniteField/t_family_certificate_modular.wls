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
randomPoints = FeynFacet`ValidateFamilyDLogEpsilonForm[candidate, system,
  "SourceVariables" -> {x, y}, "IdentityMethod" -> "RandomPoints",
  "Points" -> 2];

check["symbolic identities are exact",
  FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[symbolic]];
check["finite-field identities are validated but not exact",
  FeynFacet`ValidatedFamilyDLogEpsilonFormQ[modular] &&
    ! FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[modular] &&
    modular["Validation", "Method"] === "FiniteFieldEvaluation"];
check["random rational points are validated but not exact",
  FeynFacet`ValidatedFamilyDLogEpsilonFormQ[randomPoints] &&
    ! FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[randomPoints] &&
    randomPoints["Validation", "Method"] ===
      "RandomRationalPointEvaluation"];

forged = ReplacePart[modular, {
  "Status" -> "ExactlyValidatedFamilyDLogEpsilonForm",
  {"Validation", "Exact"} -> True}];
check["a status and exact-flag rewrite cannot convert sampled evidence",
  ! FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[forged]];

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
