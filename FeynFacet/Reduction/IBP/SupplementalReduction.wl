(* Supplementary geometric IBPs for dependencies outside a solved seed set.
   The original reduction database and declared master basis remain fixed. *)

ibpUnreducedExportIntegrals[log_String, ordered_List, counts_List] := Module[
 {names, reported, result},
 names=Association[(StringDelete[ibpKiraIntegralText[#],Whitespace]->#)&/@ordered];
 reported=StringDelete[#,Whitespace]&/@StringCases[log,
   RegularExpression["This integral is unreduced: ([^#\\r\\n]+)"]->"$1"];
 If[!DuplicateFreeQ[reported]||Length[reported]=!=Total[counts]||
   !AllTrue[reported,KeyExistsQ[names,#]&],
  ibpFail["Kira export closure","the explicit unreduced integral list is inconsistent with the export counts"]];
 result=Lookup[names,reported];
 If[ListQ[result],result,{}]
];

ibpSupplementalSeedPadding[text_String,padding_Integer] := If[padding===0,text,
 StringReplace[text,{
  ("r: "~~digits:DigitCharacter..):>("r: "<>ToString[FromDigits[digits]+padding]),
  ("s: "~~digits:DigitCharacter..):>("s: "<>ToString[FromDigits[digits]+padding])}]];

ibpSupplementalRulesQ[rules_,targets_List,records_List] :=
 ListQ[rules]&&AllTrue[rules,MatchQ[#,_Rule]&]&&exactDataQ[rules]&&
 DuplicateFreeQ[First/@rules]&&Sort[First/@rules]===Sort[targets]&&
 validateCutGLIs[rules,records]===True&&
 FreeQ[Last/@rules,Alternatives@@targets];

ibpReduceMissingExportIntegrals[project_Association,targets_List,iteration_Integer,
 records_List] := Module[
 {payload,names,topologies,declared,selectedTargets,parent,directory,state,auxiliary,
  rules,selected,table,job,padding,attempts={},seconds,result=$Failed},
 If[Lookup[project,"EquationSource",None]==="TypedIBP"||
   KeyExistsQ[project,"IndexedIntegrals"],
  ibpFail["Kira supplementary reduction",
   "missing user-equation reductions require additional supplied equations"]];
 payload=project["InputPayload"];names=DeleteDuplicates[First/@targets];
 topologies=Select[payload["Topologies"],MemberQ[names,#["Topology"][[1]]]&];
 If[targets==={}||Length[topologies]=!=Length[names]||
   validateCutGLIs[targets,records]=!=True,
  ibpFail["Kira supplementary reduction","valid original topology and cut definitions are required"]];
 (* Existing masters are requested as well, so the sector list includes the
    known basis. Their reductions do not replace the original master list. *)
 declared=Select[ibpDeclaredMasters[project],MemberQ[names,First[#]]&];
 selectedTargets=DeleteDuplicates[Join[targets,declared]];
 parent=FileNameJoin[{project["ProjectRoot"],"SupplementalReductions"}];
 If[!DirectoryQ[parent],CreateDirectory[parent,CreateIntermediateDirectories->True]];
 Do[
  directory=FileNameJoin[{parent,"Closure"<>IntegerString[iteration,10,3]<>
    "-Padding"<>ToString[padding]<>"-"<>StringTake[CreateUUID[],8]}];
  state=ibpResetProject[directory,parent,
    reductionInputPayload[topologies,selectedTargets,payload["MassDimensions"],project["Runtime"]],
    project["Runtime"]];
  auxiliary=ibpPrepareKiraProject[topologies,selectedTargets,state,payload["MassDimensions"],payload["Targets"]];
  job=FileNameJoin[{auxiliary["Directory"],"jobs.yaml"}];
  Export[job,ibpSupplementalSeedPadding[Import[job,"Text"],padding],"String"];
  Print["Reducing ",Length[targets]," missing dependencies in ",Length[topologies],
    " families; seed padding ",padding];
  seconds=First@AbsoluteTiming[
   ibpRunKira[auxiliary];
   rules=Flatten[(ibpImportRuleTable[#["Name"],
     kiraStreamTablePath[auxiliary["Directory"],#]]&/@auxiliary["Manifest"]),1];
   table=Association[rules];
   selected=If[AllTrue[targets,KeyExistsQ[table,#]&],
     Thread[targets->Lookup[table,targets]],{}];
  ];
  AppendTo[attempts,<|"Directory"->directory,"SeedPadding"->padding,
    "TargetCount"->Length[targets],"RequestedIntegralCount"->Length[selectedTargets],
    "ElapsedMilliseconds"->Round[1000 seconds]|>];
  If[ibpSupplementalRulesQ[selected,targets,records],
   result=<|"Rules"->selected,"Diagnostic"-><|
    "Method"->"SupplementaryGeometricIBPReduction",
    "OriginalMasterBasisRetained"->True,"Attempts"->attempts,
    "ReductionInputFingerprint"->auxiliary["InputFingerprint"],
    "SolvedProjectFingerprint"->ibpSolvedProjectFingerprint[auxiliary]|>|>;
   FamilyArtifactWrite[result,FileNameJoin[{directory,"SupplementalReduction.wl"}]];
   Break[]],
  {padding,0,2}];
 If[result===$Failed,
  ibpFail["Kira supplementary reduction",
    "bounded local seed extensions did not reduce the missing dependencies to other integrals"]];
 result
];
