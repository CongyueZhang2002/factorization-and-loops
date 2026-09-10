#!/usr/bin/env wolframscript
(* Usage: wolframscript -file ... FORM.wl REQUEST.wl OUTPUT_DIRECTORY
   No process or family is selected in this driver. The request is explicit. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=3,Print["Expected FORM.wl REQUEST.wl OUTPUT_DIRECTORY"];Exit[2]];
form=FeynFacet`FamilyArtifactRead[args[[1]]];
req=FeynFacet`FamilyArtifactRead[args[[2]]];
If[AssociationQ[req]&&AssociationQ[Lookup[req,"Request",None]],req=req["Request"]];
If[!AssociationQ[form] || !AssociationQ[req],Print["Invalid input"];Exit[2]];
Do[If[KeyExistsQ[req,key]&&StringQ[req[key]]&&
   !StringStartsQ[req[key],"/"]&&!StringMatchQ[req[key],RegularExpression["^[A-Za-z]:.*"]],
 req[key]=ExpandFileName[FileNameJoin[{DirectoryName[ExpandFileName[args[[2]]]],req[key]}]]],
 {key,{"FiniteIntegrationPreparationFile","MasterIntegralRepresentationsFile",
   "OriginalDifferentialSystemFile","RationalizingParametrizationFile","ConstructionCheckpointFile"}}];
If[Lookup[form,"DataType",None]==="FamilyDLogEpsilonForm",
 vars=form["CoefficientVariables"]; ep=form["DimensionalRegulator"];
 system=Join[form,<|"Family"->form["Family"],"KinematicVariables"->vars,"DimensionalRegulator"->ep,
    "InputValidation"->form["Validation"],
   "OriginalMasterIntegralBasis"->form["OriginalMasterIntegralBasis"],
   "ConnectionMatrices"->Module[{coordinateIndex}, Table[ep Total[MapThread[#1 D[#2,vars[[coordinateIndex]]]/#2 &,
     {form["ConstantResidueMatrices"],form["Letters"]}]],{coordinateIndex,Length[vars]}]],
   "BasisTransformationMatrix"->form["BasisTransformationMatrix"],
   "InverseBasisTransformationMatrix"->form["CachedInverseBasisTransformationMatrix"]|>],
 system=Join[form,<|"InputValidation"->Lookup[form,"Validation",<||>]|>]
];
If[Lookup[form,"DataType",None]==="FamilyDLogEpsilonForm",
 originalFile=Lookup[req,"OriginalDifferentialSystemFile",
   FileNameJoin[{DirectoryName[args[[1]]],"FamilyDifferentialSystem.wl"}]];
 If[FileExistsQ[originalFile],
  original=FamilyArtifactRead[originalFile];
  If[original["OriginalMasterIntegralBasis"]=!=form["OriginalMasterIntegralBasis"],
    Print["Original master basis ordering does not match"];Exit[2]];
  substitution=form["CoefficientPresentation"]["SourceVariableSubstitution"];
  sourceCoordinates=original["KinematicVariables"]/.substitution;
  originalConnection=Module[{i,j},Table[
    Total[Table[D[sourceCoordinates[[j]],vars[[i]]] (original["ConnectionMatrices"][[j]]/.substitution),
      {j,Length[sourceCoordinates]}]],{i,Length[vars]}]];
  system=Join[system,<|"OriginalConnectionMatrices"->originalConnection|>]
 ]
];
If[KeyExistsQ[req,"EpsilonZeroBlockReductionFiles"],
 system=Join[system,<|"EpsilonZeroBlockReductions"->(FamilyArtifactRead /@ req["EpsilonZeroBlockReductionFiles"])|>]];
If[KeyExistsQ[req,"FiniteIntegrationPreparationFile"],
 preparationRecord=FamilyArtifactRead[req["FiniteIntegrationPreparationFile"]];
 If[!AssociationQ[preparationRecord],Print["Invalid finite-integration preparation"];Exit[2]];
 preparation=Lookup[preparationRecord,"Preparation",preparationRecord];
 If[!AssociationQ[preparation],Print["Finite-integration preparation failed"];Exit[2]];
 system=ApplyFiniteIntegrationPreparation[system,preparation];
 If[!AssociationQ[system],Print[system];Exit[1]];
];
If[KeyExistsQ[req,"MasterIntegralRepresentationsFile"],
 representationRecord=FamilyArtifactRead[req["MasterIntegralRepresentationsFile"]];
 If[!AssociationQ[representationRecord]||
    !AssociationQ[Lookup[representationRecord,"MasterIntegralRepresentations",None]],
  Print["Invalid normalized master-integral representations"];Exit[2]];
 req=Join[req,<|"MasterIntegralRepresentations"->representationRecord["MasterIntegralRepresentations"]|>]
];
If[KeyExistsQ[req,"RationalizingParametrizationFile"],
 parametrization=FamilyArtifactRead[req["RationalizingParametrizationFile"]];
 lift=Lookup[req,"ParametrizingBasePoint",Missing["BasePointLift"]];
 If[!AssociationQ[parametrization]||!ListQ[lift],Print["Explicit parametrization and base-point lift required"];Exit[2]];
 If[KeyExistsQ[system,"BasePoint"]&&system["BasePoint"]=!=req["BasePoint"],
  Print["Request base point conflicts with the source normalization"];Exit[2]];
 If[AssociationQ[Lookup[req,"BoundaryNormalization",None]]&&
   KeyExistsQ[req["BoundaryNormalization"],"BasePoint"]&&
   req["BoundaryNormalization"]["BasePoint"]=!=req["BasePoint"],
  Print["Boundary and source normalization points must agree"];Exit[2]];
 system=Join[system,<|"BasePoint"->req["BasePoint"]|>];
 system=PullBackMasterIntegralDifferentialSystem[system,parametrization,lift,
  "RootValuesAtBasePoint"->Lookup[req,"RootValuesAtBasePoint",Automatic]];
 If[FailureQ[system],Print[system];Exit[1]];
 req=Join[req,
  AssociationMap[(req[#]/.parametrization["SourceVariableSubstitution"])&,
   Select[{"MasterIntegralRepresentations","BasePointRegion"},KeyExistsQ[req,#]&]],
  <|"BasePoint"->lift|>];
 If[AssociationQ[Lookup[req,"BoundaryNormalization",None]]&&
   Lookup[req["BoundaryNormalization"],"Type","OrdinaryPoint"]==="OrdinaryPoint",
  req=Join[req,<|"BoundaryNormalization"->Join[req["BoundaryNormalization"],<|"BasePoint"->lift|>]|>]]
];
Print["Constructing explicit finite expressions for ",Lookup[system,"Family","unnamed system"]];
seconds=First[AbsoluteTiming[
 sol=ConstructMasterIntegralSolution[system,req,
  "FlatnessCheck"->Lookup[req,"FlatnessCheck","NumericalPoints"],
  "ValidationPoints"->Lookup[req,"ValidationPoints",Automatic], "Verbose"->True,
  "HomogeneousSolveTimeLimit"->Lookup[req,"HomogeneousSolveTimeLimit",30],
  "AutomaticPreparation"->!KeyExistsQ[req,"FiniteIntegrationPreparationFile"]]
]];
If[FailureQ[sol],Print[InputForm[sol]];Exit[1]];
If[StringQ[Lookup[req,"ConstructionCheckpointFile",None]],
 checkpoint=req["ConstructionCheckpointFile"]; checkpointTemporary=checkpoint<>".tmp";
 Export[checkpointTemporary,sol,"WXF"];
 RenameFile[checkpointTemporary,checkpoint,OverwriteTarget->True];
 Print["Finite expressions saved before verification: ",checkpoint]
];
If[TrueQ[Lookup[req,"VerifyCoefficientIdentities",False]],
 Print["Verifying stored coefficient identities (",Lookup[req,"IdentityCheck","NumericalPoints"],")"];
 verification=VerifyMasterIntegralSolution[sol,"RecheckFlatness"->False,"Verbose"->True,
  "IdentityCheck"->Lookup[req,"IdentityCheck","NumericalPoints"],
  "ValidationPoints"->Lookup[req,"ValidationPoints",Automatic]];
 If[FailureQ[verification],Print[InputForm[verification]];Exit[1]];
 sol["Validation"]=Join[sol["Validation"],<|"CoefficientIdentities"->verification|>]
];
If[KeyExistsQ[req,"GPLConversionOptions"],
 Get[FileNameJoin[{root,"FeynFacet", "Solution.m"}]];
 sol=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[sol,Sequence@@req["GPLConversionOptions"]];
 If[FailureQ[sol],Print[sol];Exit[1]];
 Print["GPL_CONVERSION ",KeyTake[sol["GPLRepresentation"],{"Status","GPLCount","MaximumGPLWeight"}]]
];
writeSeconds=First[AbsoluteTiming[writeResult=WriteMasterIntegralSolution[sol,args[[3]],
 "FileFormat"->Lookup[req,"FileFormat","WXF"]]]];
If[FailureQ[writeResult],Print[writeResult];Exit[1]];
Print["FINITE_SOLUTION_COMPLETE ",InputForm[<|"Family"->sol["Family"],
 "ConstructionSeconds"->seconds,"WriteSeconds"->writeSeconds,"IntegralDefinitions"->Length[sol["IntegralDefinitions"]],
 "AlgebraicDefinitions"->Length[sol["AlgebraicDefinitions"]],
 "RequestedEpsilonOrders"->sol["RequestedEpsilonOrders"],
 "TransformedSystemEpsilonOrderRange"->sol["TransformedSystemEpsilonOrderRange"],
 "PeakMemoryBytes"->MaxMemoryUsed[]|>]];
Exit[0];
