Print["FEYNFACET DRIVER ENTERED"];
(* Generic physical two-stratum solution: explicit constants and finite
   iterated integrals, with GPL conversion after applying physical amplitudes. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: solve_ordered_measured_master_integrals.wls DEFINITIONS BOUNDARY REQUEST OUTPUT_DIRECTORY"];Exit[2]];
libraryDefinitions=FeynFacet`FamilyArtifactRead[ExpandFileName[arguments[[1]]]];
boundary=FeynFacet`FamilyArtifactRead[ExpandFileName[arguments[[2]]]];
request=FeynFacet`FamilyArtifactRead[ExpandFileName[arguments[[3]]]];
out=ExpandFileName[arguments[[4]]];
If[!AssociationQ[boundary]||!AssociationQ[request],Print["Completed physical boundaries and order request required"];Exit[1]];
If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
save[value_,name_]:=Module[{written=FeynFacet`FamilyArtifactWrite[
 value,out<>"/"<>name<>".wl",Compression->Automatic]},
 If[FailureQ[written]||written===$Failed,Print["SOLUTION WRITE FAILED ",name," ",written];Exit[1]];
 written
];
check[value_,stage_]:=If[!AssociationQ[value],
 save[value,stage<>"Failure"];Print[stage," ",ToString[System`Short[value,4],InputForm]];Exit[1]];
audit[value_,stage_]:=(save[value,stage<>"Audit"];
 If[!AssociationQ[value["Result"]]||value["EpsilonRemainderAudit"]["Status"]=!="Passed",
  Print[stage," ",ToString[System`Short[value,4],InputForm]];Exit[1]];value["Result"]);
withPreviousGPL[value_,name_]:=Module[{file=out<>"/"<>name<>".wl",old},
 If[!FileExistsQ[file],Return[value]];
 old=FeynFacet`FamilyArtifactRead[file];
 If[AssociationQ[old]&&AssociationQ[Lookup[old,"GPLRepresentation",None]],
  Join[value,<|"GPLRepresentation"->old["GPLRepresentation"]|>],value]
];
upper=Lookup[request,"MasterIntegralUpperOrders",None];
If[ListQ[upper]&&Lookup[request,"CurrentMasterIntegralBasis",None]=!=boundary["MasterIntegralBasis"],
 Print["Heterogeneous epsilon orders require the matching physical master basis"];Exit[1]];
If[IntegerQ[upper],upper=ConstantArray[upper,Length[boundary["MasterIntegralBasis"]]]];
If[!VectorQ[upper,IntegerQ]||Length[upper]=!=Length[boundary["MasterIntegralBasis"]],
 Print["One integer upper order per physical master is required"];Exit[1]];
If[!AssociationQ[libraryDefinitions]||
 libraryDefinitions["MasterIntegralBasis"]=!=boundary["MasterIntegralBasis"],
 Print["Matching original master definitions required"];Exit[1]];
libraryRanges=AssociationThread[Range[Length[upper]],({Min[0,#],#}&/@upper)];
{librarySeconds,libraryLookup}=AbsoluteTiming[FeynFacet`FindMasterIntegralValues[
 libraryDefinitions["MasterIntegralDefinitions"],libraryRanges]];
check[libraryLookup,"MasterLibraryLookup"];
save[Join[KeyDrop[libraryLookup,{"Values","PartialValues"}],<|"LookupSeconds"->librarySeconds,
 "Matches"->Map[KeyTake[#,{"LibraryReuse"}]&,libraryLookup["Values"]]|>],"MasterLibraryLookup"];
Print["MASTER LIBRARY MATCHES ",Length[libraryLookup["Values"]],"/",Length[upper]," SECONDS ",librarySeconds];
If[TrueQ[libraryLookup["Complete"]],
 values=libraryLookup["Values"];
 physical=<|"DataType"->"PhysicalMasterLaurentSolution","Representation"->"ExplicitAnalytic",
  "MasterIntegralBasis"->boundary["MasterIntegralBasis"],"DimensionalRegulator"->boundary["DimensionalRegulator"],
  "OriginalMasterLaurentLowerBounds"->Lookup[Values[values],"LaurentLowerBound"],
  "MasterIntegralUpperOrders"->upper,"BoundaryValuesApplied"->True,
  "PhysicalBoundaryDefinition"->FeynFacet`OrderedPhysicalBoundaryDefinition[boundary],
  "Coefficients"->Association@Flatten[KeyValueMap[Function[{i,row},
    KeyValueMap[{i,#1}->(#2/.libraryDefinitions["IntegralToSolutionCoordinates"])&,row["Coefficients"]]],values]],
  "AlgebraicDefinitions"->{},"KernelDefinitions"->{},"IntegralDefinitions"->{},
  "MasterLibraryReuse"-><|"Complete"->True,"LookupSeconds"->librarySeconds,
   "Records"->Map[KeyTake[#,{"LibraryReuse"}]&,values]|>|>;
 save[physical,"PhysicalMasterExplicitGPLSolution"];
 Print["COMPLETED PHYSICAL MASTER SOLUTION ",out," FROM SHARED MASTER LIBRARY"];Exit[0]
];
knownMasterValues=Join[libraryLookup["PartialValues"],libraryLookup["Values"]]/.
 libraryDefinitions["IntegralToSolutionCoordinates"];
evolutionUpper=If[knownMasterValues===<||>,upper,
 ConstantArray[Max[upper[[libraryLookup["MissingRows"]]]],Length[upper]]];
{seconds,prep}=AbsoluteTiming[FeynFacet`PrepareOrderedMeasuredBoundaryIntegration[boundary,
 Join[KeyDrop[request,"MasterIntegralUpperOrders"],<|"MeasurementBasePoint"->Automatic,
 "MasterIntegralUpperOrders"->evolutionUpper|>]]];
check[prep,"OrderedBoundaryPreparation"];save[prep,"OrderedBoundaryPreparation"];
Print["ORDERED PREPARATION ",seconds," s; corner orders ",prep["CornerConnectionColumnUpperOrders"],
 "; normal orders ",prep["NormalConnectionColumnUpperOrders"]];
{seconds,corner}=AbsoluteTiming[FeynFacet`ConstructSingularBoundaryConnection[
 prep["CornerPreparation"],prep["CornerSeed"]["Basis"],
 <|"ColumnUpperOrders"->prep["CornerConnectionColumnUpperOrders"]|>,
 "ContourDeformation"->0,"EndpointPower"->1,"Verbose"->True]];
check[corner,"PhysicalCornerConnection"];save[corner,"PhysicalCornerConnection"];

e=prep["DimensionalRegulator"];
matrix=<|"DimensionalRegulator"->e,"Dimensions"->{corner["Dimension"],corner["BoundaryDimension"]},
 "CoefficientMatrices"->(Values[Association[#]]&/@corner["Coefficients"]),
 "EntryLaurentLowerBounds"->prep["CornerConnectionEntryLaurentLowerBounds"],
 "ColumnUpperOrders"->prep["CornerConnectionColumnUpperOrders"]|>;
gamma=FeynFacet`ExpandLaurentCoefficientVector[prep["AnalyticCornerAmplitudeValues"],e,
 Transpose[{prep["CornerAmplitudeLaurentLowerBounds"],prep["CornerAmplitudeUpperOrders"]}]];
check[gamma,"PhysicalCornerAmplitudes"];
values=audit[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`MultiplyLaurentCoefficientMatrix[matrix,gamma,
 Transpose[{prep["TangentialValueLaurentLowerBounds"],prep["TangentialValueUpperOrders"]}]]],"PhysicalTangentialValues"];
cornerAlgebra=corner["AlgebraicDefinitions"];
resolveCornerAlgebra[i_Integer]:=resolveCornerAlgebra[i]=cornerAlgebra[[i]]/.
 FeynFacetSolution`a[j_Integer]:>resolveCornerAlgebra[j];
values["Coefficients"]=Map[Function[value,Factor[Expand[
 value/.FeynFacetSolution`a[i_Integer]:>resolveCornerAlgebra[i]]]],values["Coefficients"]];
physicalCorner=Join[corner,<|"Coefficients"->values["Coefficients"],
 "AlgebraicDefinitions"->{},"PhysicalBoundaryConstantsApplied"->True|>];
save[physicalCorner,"PhysicalCornerFiniteSolution"];
{gplSeconds,cornerGPL}=AbsoluteTiming[FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[withPreviousGPL[physicalCorner,"PhysicalCornerGPLConnection"],
 "Verbose"->True,"TimeLimit"->Lookup[request,"GPLTimeLimit",300],
 "FunctionTimeLimit"->Lookup[request,"GPLFunctionTimeLimit",Lookup[request,"GPLTimeLimit",300]]]];
check[cornerGPL,"PhysicalCornerGPLConnection"];save[cornerGPL,"PhysicalCornerGPLConnection"];
If[cornerGPL["GPLRepresentation"]["Status"]=!="RequiredIntegralsConvertedToGPL",
 Print["Corner GPL conversion incomplete ",KeyTake[cornerGPL["GPLRepresentation"],
 {"Status","UnconvertedIntegrals","GPLCount"}]];Exit[1]];
Print["MATERIALIZING PHYSICAL CORNER GPL COEFFICIENTS"];
flat=FeynFacetSolution`MaterializeGPLExpressions[cornerGPL,cornerGPL["Coefficients"]];
If[FailureQ[flat],Print[flat];Exit[1]];
values["Coefficients"]=flat;
sigma=prep["CornerPreparation"]["NormalizedDifferentialSystem"]["Variable"];
z=boundary["MeasurementVariable"];values=values/.sigma->1-z;save[values,"PhysicalTangentialCoefficients"];
map=prep["TangentialValueToNormalAmplitudeMatrix"];
ampUpper=prep["NormalAmplitudeUpperOrders"];vLower=values["LaurentLowerBounds"];
mapUpper=Table[Max[Table[If[map[[i,j]]===0,-Infinity,ampUpper[[i]]-vLower[[j]]],
 {i,Length[ampUpper]}]],{j,Length[vLower]}];
matrix=FeynFacet`ExpandLaurentCoefficientMatrix[map,e,mapUpper];check[matrix,"NormalAmplitudeMap"];
amplitudes=audit[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`MultiplyLaurentCoefficientMatrix[matrix,values,
 Transpose[{prep["NormalAmplitudeLaurentLowerBounds"],ampUpper}]]],"PhysicalNormalAmplitudes"];
save[amplitudes,"PhysicalNormalAmplitudeCoefficients"];
Print["PHYSICAL NORMAL AMPLITUDES READY"];
If[knownMasterValues=!=<||>,
 {seconds,physical}=AbsoluteTiming[FeynFacet`ConstructPhysicalBoundarySolution[
  prep["NormalLinePreparation"],prep["NormalLineSeed"]["Basis"],amplitudes,
  <|"MasterIntegralUpperOrders"->upper,"EvolutionUpperOrder"->Max[evolutionUpper],
   "OriginalMasterLaurentLowerBounds"->(Min[#,0]&/@prep["OriginalMasterLaurentLowerBounds"]),
   "ColumnUpperOrders"->prep["NormalConnectionColumnUpperOrders"],
   "KnownMasterValues"->knownMasterValues,
   "Assumptions"->Lookup[Lookup[boundary,"Request",<||>],"Assumptions",True],
   "GPLTimeLimit"->Lookup[request,"GPLTimeLimit",300],
   "GPLMaxExpressionLeaves"->Lookup[request,"GPLMaxExpressionLeaves",2000000]|>]];
 check[physical,"PartialPhysicalMasterEvolution"];
 physical=Join[physical,<|"MasterIntegralBasis"->boundary["MasterIntegralBasis"],
  "PhysicalBoundaryDefinition"->FeynFacet`OrderedPhysicalBoundaryDefinition[boundary]|>];
 save[physical,"PhysicalMasterExplicitGPLSolution"];
 save[Join[physical["PartialReuse"],<|"Seconds"->seconds|>],"PartialMasterEvolution"];
 Print["PARTIAL PHYSICAL EVOLUTION ",seconds," s; integrated coefficients ",
  Length[physical["PartialReuse"]["IntegratedCoefficients"]],"; reused prepared coefficients ",
  Length[physical["PartialReuse"]["ReusedPreparedCoefficients"]]],
{seconds,normal}=AbsoluteTiming[FeynFacet`ConstructSingularBoundaryConnection[
 prep["NormalLinePreparation"],prep["NormalLineSeed"]["Basis"],
 <|"ColumnUpperOrders"->prep["NormalConnectionColumnUpperOrders"]|>,
 "ContourDeformation"->0,"EndpointPower"->1,"Verbose"->True]];
check[normal,"PhysicalNormalConnection"];save[normal,"PhysicalNormalConnection"];
Print["NORMAL CONNECTION ",seconds," s"];
shared=FeynFacet`ShareFiniteCoefficientVector[normal,amplitudes];
check[shared,"SharedPhysicalBoundaryCoefficients"];
normal=shared["Connection"];amplitudes=shared["Vector"];
matrix=<|"DimensionalRegulator"->e,"Dimensions"->{normal["Dimension"],normal["BoundaryDimension"]},
 "CoefficientMatrices"->(Values[Association[#]]&/@normal["Coefficients"]),
 "EntryLaurentLowerBounds"->prep["NormalConnectionEntryLaurentLowerBounds"],
 "ColumnUpperOrders"->prep["NormalConnectionColumnUpperOrders"]|>;
coefficients=audit[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`MultiplyLaurentCoefficientMatrix[matrix,amplitudes,
 Transpose[{prep["OriginalMasterLaurentLowerBounds"],prep["MasterIntegralUpperOrders"]}]]],"PhysicalMasterCoefficients"];
physical=Join[normal,<|"Coefficients"->coefficients["Coefficients"],
 "MasterIntegralBasis"->boundary["MasterIntegralBasis"],"BoundaryValuesApplied"->True,
 "PhysicalBoundaryDefinition"->FeynFacet`OrderedPhysicalBoundaryDefinition[boundary],
 "OriginalMasterLaurentLowerBounds"->coefficients["LaurentLowerBounds"],
 "MasterIntegralUpperOrders"->upper|>];
save[physical,"PhysicalMasterFiniteSolution"];
physicalConditions=Lookup[Lookup[boundary,"Request",<||>],"Assumptions",True];
conditionTerms=If[Head[physicalConditions]===And,List@@physicalConditions,{physicalConditions}];
gplParameterConditions=And@@Select[conditionTerms,FreeQ[#,boundary["RecoilVariable"]]&];
If[TrueQ[Refine[boundary["RecoilVariable"]>0,physicalConditions]],
 gplParameterConditions=gplParameterConditions&&boundary["RecoilVariable"]>0];
{seconds,gpl}=AbsoluteTiming[FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[withPreviousGPL[physical,"PhysicalMasterGPLSolution"],
 "Assumptions"->gplParameterConditions,"Verbose"->True,"TimeLimit"->Lookup[request,"GPLTimeLimit",300],"FunctionTimeLimit"->Lookup[request,"GPLFunctionTimeLimit",Lookup[request,"GPLTimeLimit",300]],
 "MaxExpressionLeaves"->Lookup[request,"GPLMaxExpressionLeaves",2000000]]];
check[gpl,"PhysicalMasterGPLSolution"];save[gpl,"PhysicalMasterGPLSolution"];
Print["GPL CONVERSION ",seconds," s; ",KeyTake[gpl["GPLRepresentation"],
 {"Status","GPLCount","MaximumGPLWeight","UnconvertedIntegrals"}]];
If[gpl["GPLRepresentation"]["Status"]=!="RequiredIntegralsConvertedToGPL",
 Print["EXPLICIT MASTER GPL CONVERSION INCOMPLETE"];Exit[1]];
If[gpl["GPLRepresentation"]["Status"]==="RequiredIntegralsConvertedToGPL",
 explicit=FeynFacetSolution`MaterializeGPLExpressions[gpl,gpl["Coefficients"]];
 If[FailureQ[explicit],Print[explicit];Exit[1]];
 save[Join[KeyDrop[physical,{"AlgebraicDefinitions","KernelDefinitions","IntegralDefinitions"}],
  <|"Coefficients"->explicit,"Representation"->"ExplicitGPL","Assumptions"->gplParameterConditions,"AlgebraicDefinitions"->{},
   "KernelDefinitions"->{},"IntegralDefinitions"->{}|>],"PhysicalMasterExplicitGPLSolution"]];
];
libraryPublication=FeynFacet`StoreMasterIntegralSolution[
 libraryDefinitions["MasterIntegralDefinitions"],
 FeynFacet`FamilyArtifactRead[out<>"/PhysicalMasterExplicitGPLSolution.wl"],
 <|"CoordinateRules"->libraryDefinitions["SolutionToIntegralCoordinates"],
  "Provenance"-><|"Producer"->"solve_ordered_measured_master_integrals.wls",
   "SourceFile"->out<>"/PhysicalMasterExplicitGPLSolution.wl"|>|>];
check[libraryPublication,"MasterLibraryPublication"];save[libraryPublication,"MasterLibraryPublication"];
Print["COMPLETED PHYSICAL MASTER SOLUTION ",out];
