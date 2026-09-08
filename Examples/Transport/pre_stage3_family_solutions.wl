(* Selected demonstration requests using the current general raw-DE route.
   These are example ranges, not a final NNLO observable order request. *)
Module[{root,base,recurrence,specifications,names,data,name,count},
 root=DirectoryName[ExpandFileName[$InputFileName],3];
 base=FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","UU_08_10_canonical","Stage1And2_2026-09-06"}];
 recurrence=Import[FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","EpsilonOrderDetermination",
   "CF269","DimensionalRecurrence.wxf"}],"WXF"];
 names={"CF269","CF48","CF265","CF259","CF303"};
 specifications=Association@Table[
  data=Get[FileNameJoin[{base,name,"FamilyDifferentialSystem.wl"}]];
  count=Length[data["OriginalMasterIntegralBasis"]];
  name-><|"DataFile"->FileNameJoin[{base,name,"FamilyDifferentialSystem.wl"}],
   "Request"->Join[<|"BasePoint"->{1/4,1/3},
      "RequestedMasterIntegralOrderRanges"->AssociationThread[
      Range[count],ConstantArray[If[name==="CF269",{-3,0},{-5,0}],count]]|>,
     If[name==="CF269",<|"DimensionalRecurrence"->recurrence|>,<||>]],
   "Options"-><|"Verbose"->True|>|>,
  {name,names}];
 specifications["CF303"]=Join[specifications["CF303"],<|
   "FiniteIntegrationPreparationFile"->FileNameJoin[{base,"CF303","FiniteIntegrationPreparation.wl"}]|>];
 <|"Scope"->"Selected demonstration master ranges using the current raw-DE inputs.",
   "Families"->specifications|>
]
