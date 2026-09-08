#!/usr/bin/env wolframscript
(* Compare physical saved solutions to AMFlow; references are never boundaries. *)
$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/FeynFacet/Solution.m"];Get[root<>"/Scripts/Validation/common.wl"];
args=Rest[$ScriptCommandLine];If[!MemberQ[{3,4},Length[args]],Print["Expected FAMILY_REQUEST.wxf REFERENCE.wxf OUTPUT.wxf [rows]"];Exit[2]];
spec=readValidationFile[args[[1]]];reference=readValidationFile[args[[2]]];
rows=If[Length[args]===4,ToExpression/@StringSplit[args[[4]],","],spec["Rows"]];
report=CheckAbort[Catch[Module[{data,evaluation,refRows,refMasters,refIndex,comparisons={},a,b,orders,cmp,position,options,referenceRequest},
 If[rows==={}||!VectorQ[rows,IntegerQ]||!DuplicateFreeQ[rows]||!ContainsAll[spec["Rows"],rows],Throw[Failure["InvalidValidationRows",<||>]]];
 If[!AssociationQ[reference]||Lookup[reference,"Status",None]=!="AMFlowMastersEvaluated"||
   Lookup[reference,"AMFlowOrderConvention",None]=!="OffsetFromMinusTwoLoops"||
   reference["Point"]=!=spec["Point"]||reference["KinematicVariables"]=!=spec["KinematicVariables"],
  Throw[Failure["AMFlowReferenceDefinitionOrPointMismatch",<||>]]];
 If[reference["PrecisionGoal"]<Max["AccuracyGoal"/.spec["ComparisonOptions"],"PrecisionGoal"/.spec["ComparisonOptions"]]+5,
  Throw[Failure["AMFlowReferencePrecisionInsufficient",<||>]]];
 referenceRequest=readValidationFile[spec["OutputDirectory"]<>"/amflow_request.wl"];
 If[!AssociationQ[referenceRequest]||reference["IntegralDefinition"]=!=referenceRequest["IntegralDefinition"]||
   reference["MasterIntegralPrefactors"]=!=referenceRequest["MasterIntegralPrefactors"],
  Throw[Failure["AMFlowReferenceNormalizationOrCutMismatch",<||>]]];
 data=FeynFacetSolution`ReadMasterIntegralSolution[spec["SolutionDirectory"]];
 If[FailureQ[data]||!TrueQ[data["UnknownBoundarySeriesCount"]===0],Throw[Failure["PhysicalBoundaryConstantsRequired",<||>]]];
 options=spec["EvaluationOptions"];
 If[!FreeQ[First/@options,"InitialConstantValues"|"BoundaryCoefficientValues"],Throw[Failure["SuppliedConstantsForbiddenInCompleteMasterTest",<||>]]];
 refRows=reference["RowIndices"];refMasters=reference["OriginalMasterIntegralBasis"];
 Do[position=FirstPosition[refRows,row,Missing[]];
  If[MissingQ[position]||validationMasterID[data["OriginalMasterIntegralBasis"][[row]]]=!=validationMasterID[refMasters[[First[position]]]],
   Throw[Failure["AMFlowReferenceMasterMismatch",<|"Row"->row|>]]],{row,rows}];
 evaluation=FeynFacetSolution`EvaluateMasterIntegralSolution[data,spec["Point"],Sequence@@options];
 If[FailureQ[evaluation],Throw[evaluation]];
 If[!TrueQ[evaluation["PhysicalBoundaryValuesDetermined"]],Throw[Failure["EvaluationDoesNotUsePhysicalBoundaries",<||>]]];
 writeValidationFile[spec["OutputDirectory"]<>"/physical_evaluation.wxf",evaluation];
 Do[
  orders=spec["RequiredOrders"][row];a=<||>;b=<||>;
  Do[
   If[KeyExistsQ[evaluation["MasterIntegralEpsilonCoefficients"],k]&&KeyExistsQ[Association[evaluation["MasterIntegralEpsilonCoefficients"][k]],row],
    AssociateTo[a,k->Lookup[Association[evaluation["MasterIntegralEpsilonCoefficients"][k]],row]]];
   If[KeyExistsQ[reference["MasterIntegralEpsilonCoefficients"],k]&&KeyExistsQ[Association[reference["MasterIntegralEpsilonCoefficients"][k]],row],
    AssociateTo[b,k->Lookup[Association[reference["MasterIntegralEpsilonCoefficients"][k]],row]]],{k,orders}];
  cmp=FeynFacetSolution`CompareLaurentCoefficients[a,b,orders,Sequence@@spec["ComparisonOptions"]];
  If[FailureQ[cmp],Throw[cmp]];
  AppendTo[comparisons,Join[<|"Row"->row,"MasterIntegral"->data["OriginalMasterIntegralBasis"][[row]]|>,cmp]];
  Print[spec["ID"]," row ",row," ",cmp["Status"]," coefficients ",cmp["PassedCoefficientCount"],"/",Length[orders]],{row,rows}];
 <|"Test"->"CompleteMasterIntegrals","Family"->spec["ID"],"Point"->spec["Point"],
  "Status"->If[AllTrue[comparisons,#["Status"]==="Passed"&],"Passed",If[AnyTrue[comparisons,#["Status"]==="Failed"&],"Failed","Incomplete"]],
  "SelectedRows"->rows,"FamilyRequiredRows"->spec["Rows"],"AMFlowUsedAsBoundaryData"->False,
  "ReferenceNormalizationAndCutsMatched"->True,
  "PassedMasterCount"->Count[Lookup[comparisons,"Status"],"Passed"],
  "PassedCoefficientCount"->Total[Lookup[comparisons,"PassedCoefficientCount",0]],
  "Results"->comparisons,"EvaluationSeconds"->evaluation["ElapsedSeconds"]|>
]],Failure["CompleteMasterValidationAborted",<||>]];
writeValidationFile[ExpandFileName[args[[3]]],report];
summary=If[FailureQ[report],<|"Status"->"Failed","Failure"->ToString[report,InputForm],"Results"->{}|>,
 Join[KeyDrop[report,"Results"],<|"Results"->(KeyTake[#,{"Row","Status","RequiredOrders","PassedCoefficientCount","MissingComputedOrders","MissingReferenceOrders","NonzeroComparisonCount"}]&/@report["Results"])|>]];
Export[args[[3]]<>".json",summary,"RawJSON"];
Print["RESULT ",KeyDrop[summary,"Results"]];Exit[If[Lookup[summary,"Status",None]==="Passed",0,1]];
