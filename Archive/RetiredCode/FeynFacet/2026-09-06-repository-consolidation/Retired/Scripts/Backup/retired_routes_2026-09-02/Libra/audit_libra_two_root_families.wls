#!/usr/bin/env wolframscript
(* Exact consistency audit for the two-root family Libra census. *)

$HistoryLength = 0;
argv = Rest[$ScriptCommandLine];
outputDirectory = ExpandFileName[If[Length[argv] >= 1, argv[[1]],
  "/home/maxzhang/FACET/Codex/General/LibraTwoRoot_20260819"]];
families = {
  "CF232", "CF236", "CF240", "CF319", "CF321", "CF385", "CF408",
  "CF249", "CF254", "CF265", "CF226", "CF231", "CF305"
};

summaries = Association@Table[
  file = FileNameJoin[{outputDirectory, "summary_" <> family <> ".wl"}];
  family -> If[FileExistsQ[file], Quiet[Check[Get[file], $Failed]], $Failed],
  {family, families}];
results = Association@Table[
  file = FileNameJoin[{outputDirectory,
    "family_epsform_" <> family <> ".wl"}];
  family -> If[FileExistsQ[file], Quiet[Check[Get[file], $Failed]], $Failed],
  {family, families}];

associationFilesQ = AllTrue[Join[Values[summaries], Values[results]],
  AssociationQ];
familyLabelsQ = associationFilesQ && AllTrue[families,
  Lookup[summaries[#], "Family", None] === # &&
    Lookup[results[#], "Family", None] === # &];
statusAgreementQ = associationFilesQ && AllTrue[families,
  Lookup[summaries[#], "Status", None] ===
    Lookup[results[#], "Status", None] &];
resultPathsQ = associationFilesQ && AllTrue[families,
  FileExistsQ[Lookup[summaries[#], "ResultFile", ""]] &];
chartIdentitiesQ = associationFilesQ && AllTrue[families,
  TrueQ[Lookup[Lookup[results[#], "ChartCertificate", <||>],
    "OK", False]] &];
physicsChecksQ = associationFilesQ && AllTrue[families,
  Function[family,
    status = Lookup[results[family], "Status", None];
    checks = Lookup[results[family], "Checks", <||>];
    Which[
      status === "EpsForm", And @@ (TrueQ /@ Values[checks]),
      status === "NotEpsForm",
        ! TrueQ[Lookup[checks, "EpsFactored", True]] &&
        ! TrueQ[Lookup[checks, "DLog", True]] &&
        And @@ (TrueQ /@ Lookup[checks, {
          "BlockLowerTriangular", "DiagonalEpsForm", "Flatness",
          "TransformationInverse", "GaugeIdentity"}, False]),
      True, False
    ]
  ]];

rows = Table[Lookup[summaries[family], {
  "Family", "Chart", "Dimension", "Blocks", "Status", "Seconds",
  "TransformationCount"}], {family, Sort[families]}];
exactFamilies = Select[families,
  Lookup[results[#], "Status", None] === "EpsForm" &];
audit = <|
  "Families" -> Sort[families],
  "Rows" -> rows,
  "ExactEpsFormFamilies" -> Sort[exactFamilies],
  "Checks" -> <|
    "AssociationFiles" -> associationFilesQ,
    "FamilyLabels" -> familyLabelsQ,
    "StatusAgreement" -> statusAgreementQ,
    "ResultPaths" -> resultPathsQ,
    "ChartIdentities" -> chartIdentitiesQ,
    "PhysicsIdentities" -> physicsChecksQ|>
|>;
audit = Append[audit, "AllChecks" -> And @@ Values[audit["Checks"]]];
Put[audit, FileNameJoin[{outputDirectory, "audit_summary.wl"}]];
Print[InputForm[audit]];
Exit[If[TrueQ[audit["AllChecks"]], 0, 1]];
