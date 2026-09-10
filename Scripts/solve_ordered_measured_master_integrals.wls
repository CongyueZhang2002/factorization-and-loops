(* Generic physical two-stratum solution: explicit constants and finite
   iterated integrals, with GPL conversion after applying physical amplitudes. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=3,Print["Usage: solve_ordered_measured_master_integrals.wls BOUNDARY REQUEST OUTPUT_DIRECTORY"];Exit[2]];
boundary=FeynFacet`FamilyArtifactRead[ExpandFileName[arguments[[1]]]];
request=FeynFacet`FamilyArtifactRead[ExpandFileName[arguments[[2]]]];
out=ExpandFileName[arguments[[3]]];
If[!AssociationQ[boundary]||!AssociationQ[request],Print["Completed physical boundaries and order request required"];Exit[1]];
If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
save[value_,name_]:=FeynFacet`FamilyArtifactWrite[value,out<>"/"<>name<>".wl",Compression->Automatic];
check[value_,stage_]:=If[!AssociationQ[value],
 save[value,stage<>"Failure"];Print[stage," ",ToString[System`Short[value,4],InputForm]];Exit[1]];
audit[value_,stage_]:=(save[value,stage<>"Audit"];
 If[!AssociationQ[value["Result"]]||value["EpsilonRemainderAudit"]["Status"]=!="Passed",
  Print[stage," ",ToString[System`Short[value,4],InputForm]];Exit[1]];value["Result"]);
upper=Lookup[request,"MasterIntegralUpperOrders",None];
If[IntegerQ[upper],upper=ConstantArray[upper,Length[boundary["MasterIntegralBasis"]]]];
{seconds,prep}=AbsoluteTiming[FeynFacet`PrepareOrderedMeasuredBoundaryIntegration[boundary,
 Join[KeyDrop[request,"MasterIntegralUpperOrders"],<|"MeasurementBasePoint"->Automatic,
 "MasterIntegralUpperOrders"->upper|>]]];
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
{gplSeconds,cornerGPL}=AbsoluteTiming[FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[physicalCorner,
 "Verbose"->True,"TimeLimit"->Lookup[request,"GPLTimeLimit",300],
 "FunctionTimeLimit"->Lookup[request,"GPLFunctionTimeLimit",30]]];
check[cornerGPL,"PhysicalCornerGPLConnection"];save[cornerGPL,"PhysicalCornerGPLConnection"];
If[cornerGPL["GPLRepresentation"]["Status"]=!="RequiredIntegralsConvertedToGPL",
 Print["Corner GPL conversion incomplete ",KeyTake[cornerGPL["GPLRepresentation"],
 {"Status","UnconvertedIntegrals","GPLCount"}]];Exit[1]];
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
 "OriginalMasterLaurentLowerBounds"->coefficients["LaurentLowerBounds"],
 "MasterIntegralUpperOrders"->upper|>];
save[physical,"PhysicalMasterFiniteSolution"];
{seconds,gpl}=AbsoluteTiming[FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[physical,
 "Verbose"->True,"TimeLimit"->Lookup[request,"GPLTimeLimit",300],"FunctionTimeLimit"->Lookup[request,"GPLFunctionTimeLimit",30],
 "MaxExpressionLeaves"->Lookup[request,"GPLMaxExpressionLeaves",2000000]]];
check[gpl,"PhysicalMasterGPLSolution"];save[gpl,"PhysicalMasterGPLSolution"];
Print["GPL CONVERSION ",seconds," s; ",KeyTake[gpl["GPLRepresentation"],
 {"Status","GPLCount","MaximumGPLWeight","UnconvertedIntegrals"}]];
If[gpl["GPLRepresentation"]["Status"]==="RequiredIntegralsConvertedToGPL",
 explicit=FeynFacetSolution`MaterializeGPLExpressions[gpl,gpl["Coefficients"]];
 If[FailureQ[explicit],Print[explicit];Exit[1]];
 save[Join[KeyDrop[physical,{"AlgebraicDefinitions","KernelDefinitions","IntegralDefinitions"}],
  <|"Coefficients"->explicit,"Representation"->"ExplicitGPL","AlgebraicDefinitions"->{},
   "KernelDefinitions"->{},"IntegralDefinitions"->{}|>],"PhysicalMasterExplicitGPLSolution"]];
Print["COMPLETED PHYSICAL MASTER SOLUTION ",out];
