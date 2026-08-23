(* Parallel certification census: recompute the exact whole-family
   epsilon-form certificate for every differential-equation family, on
   one main kernel plus subkernels (the license-safe topology).

   usage: wolframscript -file certify_family_epsform_parallel.wls \
            OUTPUT DE_DIRECTORY KERNELS INPUT_DIRECTORY ...

   Per family: candidate records are searched in the input directories
   in order; each candidate is read with the context-guarded
   FamilyArtifactRead and re-certified from the differential system by
   CertifyFamilyEpsilonForm (never trusting a stored verdict); the
   first exactly certified candidate is written atomically to OUTPUT.
   The report certification_report.wl matches the serial campaign's
   schema. *)

If[Length[$ScriptCommandLine] < 6,
  Print["usage: wolframscript -file certify_family_epsform_parallel.wls ",
    "OUTPUT DE_DIRECTORY KERNELS INPUT_DIRECTORY ..."];
  Exit[2]
];

root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
loader = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
Get[loader];

{outputDirectory, differentialDirectory} =
  ExpandFileName /@ $ScriptCommandLine[[2 ;; 3]];
kernelTarget = Min[8, Max[1, ToExpression[$ScriptCommandLine[[4]]]]];
inputDirectories = ExpandFileName /@ $ScriptCommandLine[[5 ;;]];
If[! DirectoryQ[differentialDirectory] ||
    ! AllTrue[inputDirectories, DirectoryQ],
  Print["CERTIFY-PARALLEL input directory missing"];
  Exit[3]
];
If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];

familyName[file_] := First[StringCases[FileBaseName[file],
  StartOfString ~~ "nnlo_de_" ~~ family : ("CF" ~~ DigitCharacter ..) ~~
    EndOfString :> family], Missing["NoFamily"]];

differentialFiles = SortBy[
  FileNames["nnlo_de_CF*.wl", differentialDirectory],
  ToExpression[StringDrop[familyName[#], 2]] &
];
Print["CERTIFY-PARALLEL families=", Length[differentialFiles],
  " kernels=", kernelTarget];

launched = If[kernelTarget > 1,
  Quiet[LaunchKernels[kernelTarget]], {}];
Print["CERTIFY-PARALLEL launched ", Length[launched], " subkernels"];
If[launched =!= {},
  With[{file = loader},
    ParallelEvaluate[(Quiet[Get[file]];), launched]]];

certifyOne[systemFile_String] := Module[
  {family, outputFile, existing, candidates, system, accepted = False,
   diagnostics = {}, familyStart, record, certified, elapsed},
  family = familyName[systemFile];
  outputFile = FileNameJoin[{outputDirectory,
    "family_epsform_" <> family <> ".wl"}];
  If[FileExistsQ[outputFile],
    existing = FeynFacet`FamilyArtifactRead[outputFile];
    If[AssociationQ[existing] &&
        FeynFacet`ExactFamilyEpsilonFormQ[existing],
      Return[<|"Family" -> family, "Status" -> "AlreadyExact",
        "File" -> outputFile, "Seconds" -> 0.|>]]];
  candidates = DeleteDuplicates @ Flatten[
    FileNames["family_epsform_" <> family <> ".wl", #, Infinity] & /@
      inputDirectories];
  If[candidates === {},
    Return[<|"Family" -> family, "Status" -> "NoCandidate"|>]];
  system = FeynFacet`FamilyArtifactRead[systemFile];
  If[! AssociationQ[system],
    Return[<|"Family" -> family, "Status" -> "SystemUnreadable"|>]];
  familyStart = AbsoluteTime[];
  Do[
    record = FeynFacet`FamilyArtifactRead[candidate];
    If[! AssociationQ[record],
      AppendTo[diagnostics, <|"Source" -> candidate,
        "Status" -> "Unreadable"|>];
      Continue[]];
    certified = FeynFacet`CertifyFamilyEpsilonForm[record, system];
    If[AssociationQ[certified] &&
        certified["Status"] === "ExactEpsilonForm" &&
        FeynFacet`ExactFamilyEpsilonFormQ[certified],
      FeynFacet`FamilyArtifactWrite[certified, outputFile];
      elapsed = AbsoluteTime[] - familyStart;
      accepted = True;
      Break[],
      AppendTo[diagnostics, <|"Source" -> candidate,
        "Status" -> Lookup[certified, "Status", "NotAnAssociation"],
        "Checks" -> Lookup[certified, "Checks", <||>]|>]
    ],
    {candidate, candidates}];
  If[accepted,
    Print["CERTIFY-LIVE family=", family, " exact=True seconds=",
      Round[elapsed, 0.1]];
    <|"Family" -> family, "Status" -> "Exact", "File" -> outputFile,
      "Seconds" -> elapsed, "Bytes" -> FileByteCount[outputFile]|>,
    Print["CERTIFY-LIVE family=", family, " exact=False seconds=",
      Round[AbsoluteTime[] - familyStart, 0.1]];
    <|"Family" -> family, "Status" -> "NoExactlyCertifiedCandidate",
      "Candidates" -> candidates,
      "CandidateDiagnostics" -> diagnostics,
      "Seconds" -> AbsoluteTime[] - familyStart|>]
];

campaignStart = AbsoluteTime[];
results = If[launched === {},
  certifyOne /@ differentialFiles,
  ParallelMap[certifyOne, differentialFiles,
    Method -> "FinestGrained", DistributedContexts -> Automatic]];

Do[
  Print["CERTIFY-PARALLEL family=", row["Family"],
    " status=", row["Status"],
    " seconds=", Round[Lookup[row, "Seconds", 0.], 0.1]],
  {row, results}];

report = <|
  "Status" -> If[AllTrue[results,
      MemberQ[{"Exact", "AlreadyExact"}, #Status] &],
    "CompleteExactInventory", "IncompleteExactInventory"],
  "DifferentialFamilyCount" -> Length[differentialFiles],
  "ExactFamilyCount" -> Count[results,
    row_ /; MemberQ[{"Exact", "AlreadyExact"}, row["Status"]]],
  "ExactFamilies" -> Lookup[
    Select[results, MemberQ[{"Exact", "AlreadyExact"}, #["Status"]] &],
    "Family", {}],
  "IncompleteFamilies" -> Lookup[
    Select[results,
      ! MemberQ[{"Exact", "AlreadyExact"}, #["Status"]] &],
    "Family", {}],
  "KernelCount" -> Length[launched] + 1,
  "ElapsedSeconds" -> AbsoluteTime[] - campaignStart,
  "Results" -> results
|>;
FeynFacet`FamilyArtifactWrite[report,
  FileNameJoin[{outputDirectory, "certification_report.wl"}]];
If[launched =!= {}, Quiet[CloseKernels[launched]]];
Print["CERTIFY-PARALLEL exact=", report["ExactFamilyCount"], "/",
  report["DifferentialFamilyCount"], " seconds=",
  Round[report["ElapsedSeconds"], 0.1]];
Print["CERTIFY-PARALLEL incomplete=", report["IncompleteFamilies"]];
