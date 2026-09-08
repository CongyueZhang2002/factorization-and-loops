(* Demonstration targets for every currently regenerated V2 family system.
   These ranges are explicit master requests, not a final NNLO observable demand. *)
Module[{root,base,recurrence,specifications,pairs,name,count},
 root=DirectoryName[ExpandFileName[$InputFileName],3];
 base=FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","UU_08_10_canonical","DifferentialEquationDataV2"}];
 recurrence=Import[FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","EpsilonOrderDetermination",
   "CF269","DimensionalRecurrence.wxf"}],"WXF"];
 pairs={{"CF269",23},{"CF48",27},{"CF265",32},{"CF259",47},{"CF303",45}};
 specifications=Association@Table[
  name=pair[[1]];count=pair[[2]];name-><|
   "DataFile"->FileNameJoin[{base,name,If[MemberQ[{"CF269","CF48"},name],
     "FamilyDLogEpsilonForm.wl","FamilyDifferentialSystem.wl"]}],
   "Request"->Join[<|"RequestedMasterIntegralOrderRanges"->AssociationThread[
      Range[count],ConstantArray[If[name==="CF269",{-3,0},{-5,0}],count]]|>,
     If[name==="CF48",<||>,<|"BasePoint"->{1/4,1/3}|>],
     If[name==="CF269",<|"DimensionalRecurrence"->recurrence|>,<||>]],
   "Options"-><|"Verbose"->True|>|>,
  {pair,pairs}];
 specifications["CF303"]=Join[specifications["CF303"],<|
   "FiniteIntegrationPreparationFile"->FileNameJoin[{base,"CF303","FiniteIntegrationPreparation.wl"}]|>];
 <|"Scope"->"All five currently regenerated V2 systems; explicit demonstration master orders.",
   "Families"->specifications|>
]
