$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=3,Print["Usage: solve_endpoint_boundary_coefficients.wls COEFFICIENT_JETS REQUEST OUTPUT_DIRECTORY"];Exit[2]];
jets=FeynFacet`FamilyArtifactRead[ExpandFileName[args[[1]]]];
request=FeynFacet`FamilyArtifactRead[ExpandFileName[args[[2]]]];out=ExpandFileName[args[[3]]];
If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
save[value_,name_]:=FeynFacet`FamilyArtifactWrite[value,out<>"/"<>name<>".wl",Compression->Automatic];
check[value_,name_]:=If[!AssociationQ[value],save[value,name<>"Failure"];Print["FAILED ",name," ",InputForm[value]];Exit[1]];
checkAudit[value_,name_]:=(save[value,name<>"Audit"];If[!AssociationQ[value["Result"]]||
 value["EpsilonRemainderAudit"]["Status"]=!="Passed",Print["FAILED AUDIT ",name," ",value["EpsilonRemainderAudit"]["Status"]];Exit[1]];value["Result"]);
{seconds,prep}=AbsoluteTiming[FeynFacet`PreparePhysicalBoundaryCoefficientIntegration[jets,request]];
check[prep,"Preparation"];save[prep,"Preparation"];
Print["PREPARED ",seconds," s; CONNECTION ORDERS ",prep["ConnectionColumnUpperOrders"],
 " CONSTANT ORDERS ",Transpose[{prep["ConstantLaurentLowerBounds"],prep["ConstantUpperOrders"]}],
 " FUNCTION UPPER ORDERS ",prep["BoundaryFunctionUpperOrders"]];
e=prep["DimensionalRegulator"];
{seconds,connection}=AbsoluteTiming[FeynFacet`ConstructSingularBoundaryConnection[
 prep["CornerPreparation"],prep["SaturatedCornerSeed"]["Basis"],
 <|"ColumnUpperOrders"->prep["ConnectionColumnUpperOrders"]|>,
 "ContourDeformation"->0,"EndpointPower"->1,"Verbose"->True]];
check[connection,"Connection"];save[connection,"Connection"];Print["CONNECTION ",seconds," s"];
matrix=<|"DimensionalRegulator"->e,"Dimensions"->{connection["Dimension"],connection["BoundaryDimension"]},
 "CoefficientMatrices"->(Values[Association[#]]&/@connection["Coefficients"]),
 "EntryLaurentLowerBounds"->prep["ConnectionEntryLaurentLowerBounds"],
 "ColumnUpperOrders"->prep["ConnectionColumnUpperOrders"]|>;
gamma=FeynFacet`ExpandLaurentCoefficientVector[prep["AnalyticConstantValues"],e,
 Transpose[{prep["ConstantLaurentLowerBounds"],prep["ConstantUpperOrders"]}]];
check[gamma,"ConstantSeries"];
values=checkAudit[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`MultiplyLaurentCoefficientMatrix[matrix,gamma,prep["BoundaryFunctionOrderRanges"]]],"BoundaryFunctions"];
algebra=connection["AlgebraicDefinitions"];
resolveAlgebra[i_Integer]:=resolveAlgebra[i]=algebra[[i]]/.FeynFacetSolution`a[j_Integer]:>resolveAlgebra[j];
values["Coefficients"]=Map[Function[value,Factor[Expand[value/.FeynFacetSolution`a[j_Integer]:>resolveAlgebra[j]]]],values["Coefficients"]];
physical=Join[connection,<|"Coefficients"->values["Coefficients"],"AlgebraicDefinitions"->{}|>];
{seconds,gpl}=AbsoluteTiming[FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[physical,
 "TimeLimit"->300,"FunctionTimeLimit"->30,"Verbose"->True]];
check[gpl,"GPL"];
If[gpl["GPLRepresentation"]["Status"]=!="RequiredIntegralsConvertedToGPL",save[gpl,"IncompleteGPL"];Print["GPL INCOMPLETE"];Exit[1]];
explicit=FeynFacetSolution`MaterializeGPLExpressions[gpl,gpl["Coefficients"]];check[explicit,"ExplicitGPL"];
values["Coefficients"]=explicit/.prep["BoundaryFunctionArgumentRules"];
If[Cases[values["Coefficients"],_Derivative,{0,Infinity},Heads->True]=!={},Print["UNEVALUATED PARAMETER DERIVATIVE"];Exit[1]];
save[values,"BoundaryFunctionCoefficients"];Print["GPL ",seconds," s"];
coefficientMatrix=FeynFacet`ExpandLaurentCoefficientMatrix[prep["CoefficientMatrix"],e,prep["CoefficientColumnUpperOrders"]];
check[coefficientMatrix,"CoefficientMatrix"];
result=checkAudit[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`MultiplyLaurentCoefficientMatrix[coefficientMatrix,values,prep["OutputOrderRanges"]]],"PhysicalEdgeCoefficients"];
{seconds,collected}=AbsoluteTiming[FeynFacet`CancelRationalCoefficients[Values[result["Coefficients"]]]];
If[!ListQ[collected],save[collected,"CoefficientCollectionFailure"];Print["EXACT COEFFICIENT COLLECTION FAILED"];Exit[1]];
Print["COEFFICIENT COLLECTION ",seconds," s; LEAVES ",LeafCount[Values[result["Coefficients"]]]," -> ",LeafCount[collected]];
result["Coefficients"]=AssociationThread[Keys[result["Coefficients"]],collected];
result=Join[result,KeyTake[prep,{"CoefficientRowLabels","NormalVariable","TangentialVariable","NormalExponent","IntegerNormalPower"}]];
save[result,"PhysicalEdgeCoefficients"];
Print["COMPLETED EXPLICIT PHYSICAL EDGE COEFFICIENTS ",out];
