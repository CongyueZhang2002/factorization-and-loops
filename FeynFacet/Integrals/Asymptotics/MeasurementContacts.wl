(* Bound the endpoint extension order from the original regulated density,
   including correlated energy/measurement limits. No finite interior fit
   or observable-specific singularity assumption enters this proof. *)
BeginPackage["FeynFacet`"];
VerifyOneLoopMeasurementContactOrder::usage="VerifyOneLoopMeasurementContactOrder[density,order,request] verifies that [z(1-z)]^(order+1) times each originally prescribed component is uniformly integrable on the full energy/measurement unit square near epsilon=0 after finite regulator poles are cleared. It constructs a complete half-square and positive-sector cover, checks every analytic factor on each closed chart, and rejects negative integer normal powers. This bounds possible endpoint contact derivatives by order; it supplies no contact coefficients. Additional coordinate-independent Assumptions may be supplied.";
ResolveOneLoopMeasurementEndpointCharts::usage="ResolveOneLoopMeasurementEndpointCharts[density,weight,request] constructs a complete eight-chart cover per branch of a two-variable measured scalar-loop density, multiplied by an explicit regulator-independent weight. Each original prescribed product is resolved into normal powers and finite-meromorphic smooth factors verified on the entire closed chart. It retains exact regulated densities for subsequent endpoint subtraction. Negative integer powers are reported, not declared integrable.";
VerifyOneLoopInclusivePrescriptionLimit::usage="VerifyOneLoopInclusivePrescriptionLimit[charts] proves removal of only the external ordinary prescriptions after causal loop integration in a common convergent negative-epsilon neighborhood. It requires an unweighted complete-domain chart construction, finite regulator meromorphy, integer normal powers at least -1 and negative regulator slopes for every logarithmic face. It does not remove the virtual prescription or evaluate the inclusive integral.";
Begin["`Private`"];
ResolveOneLoopMeasurementEndpointCharts[density_Association,weight_:1,request_Association:<||>]:=Catch[Module[
 {e,x,z,parameters,values,atlas,halfVariables={Unique["halfMeasurement"],Unique["halfEnergy"]},
  halfRules,mapping,xs,conditions,resolved,regularity,records={},powers,seconds},
 If[Lookup[density,"Format",None]=!="FeynFacet-OneLoopMeasurementDensity"||
   !TrueQ[Lookup[density,"ExactInRegulator",False]]||!TrueQ[density["PhaseSpaceDensityIncluded"]],
  cutFamilyFail["ExactMeasuredScalarLoopDensityAndContactOrderRequired"]];
 {e,x,z}=Lookup[density,{"DimensionalRegulator","IntegrationVariable","Variable"}];
 If[!FreeQ[Lookup[request,"Assumptions",True],x|z|e],
  cutFamilyFail["CoordinateIndependentContactOrderAssumptionsRequired"]];
 If[!FreeQ[weight,e],cutFamilyFail["RegulatorIndependentEndpointWeightRequired"]];
 atlas=FeynFacet`ConstructWeightedEndpointCharts[halfVariables,{1,1}];
 If[!AssociationQ[atlas],cutFamilyFail["CompleteMeasurementEndpointSectorCoverRequired"]];
 Do[
  If[!FreeQ[branch["Prefactor"],x|z]||
    !TrueQ[Lookup[branch,"ExternalFactorModulusBoundsEstablished",False]]||
    !AssociationQ[Lookup[branch,"ExternalPrescriptionComponents",None]],
   cutFamilyFail["PrescribedMeasuredScalarProductDecompositionRequired"]];
  parameters=(branch["PhysicalDomain"]/.{x->1/2,z->1/2})&&Lookup[request,"Assumptions",True];
  If[!TrueQ[FullSimplify[Implies[parameters&&0<x<1&&0<z<1,branch["PhysicalDomain"]]]],
   cutFamilyFail["WholeUnitEnergyMeasurementSquareRequired"]];
  values=Map[#["ScalarCoefficient"]#["InteriorExternalProduct"]*
    Times@@(Power@@#&/@branch["RegulatorFactors"])branch["Prefactor"]weight&,branch["ExternalPrescriptionComponents"]];
  Do[
   halfRules=Thread[{z,x}->(corner+(1-2corner)halfVariables/2)];
   Do[
    xs=chart["Variables"];mapping=halfRules/.chart["SourceVariableSubstitution"];
    conditions=parameters&&And@@(0<#<1/4&/@xs);
    {seconds,resolved}=AbsoluteTiming[FeynFacet`ResolveOneLoopScalarEndpointPowers[
      Map[Factor[(#/.mapping)chart["AbsoluteJacobian"]/4]&,values],e,xs,conditions]];
    If[!AssociationQ[resolved],cutFamilyFail["MeasuredContactCornerResolutionFailed",
      <|"Corner"->corner,"Chart"->chart,"Cause"->resolved|>]];
    powers=Flatten[Lookup[resolved["Terms"],"Powers"]]/.e->0;
    regularity=FeynFacet`VerifyResolvedEndpointCube[resolved,parameters];
    If[!AssociationQ[regularity],cutFamilyFail["UniformMeasuredContactChartNotEstablished",
      <|"Corner"->corner,"Chart"->chart,"Cause"->regularity|>]];
    AppendTo[records,<|"Branch"->index,"Corner"->corner,"SectorChart"->chart,
      "SourceVariableSubstitution"->mapping,"AbsoluteJacobian"->chart["AbsoluteJacobian"]/4,
      "EndpointPowers"->DeleteDuplicates[Lookup[resolved["Terms"],"Powers"]],
      "ResolvedDensity"->resolved,"FactorVerification"->regularity,"ResolutionSeconds"->seconds|>];
    If[TrueQ[Lookup[request,"PrintTimings",False]],Print["MEASURED SCALAR ENDPOINT CHART ",index," ",corner,
      " ",chart["AnchorIndex"]," RESOLUTION SECONDS ",seconds]],
   {chart,atlas["Charts"]}],{corner,Tuples[{0,1},2]}],
 {index,Length[density["Branches"]]},{branch,{density["Branches"][[index]]}}];
 <|"Format"->"FeynFacet-MeasuredScalarEndpointCharts","Variable"->z,"IntegrationVariable"->x,
  "Interval"->{0,1},"Weight"->weight,"Charts"->records,"CompleteDomainCoverVerified"->True,
  "RegulatorMeromorphicityVerified"->True,"ExternalPrescriptionLimitEstablished"->False,
  "Scope"->"Exact original-product endpoint powers and uniformly meromorphic smooth factors. Integrability, prescribed limits and endpoint subtractions must still be established from these powers."|>
],"CutFamily"];
VerifyOneLoopInclusivePrescriptionLimit[charts_Association]:=Catch[Module[
 {powers,terms,e,integer,slopes},
 If[Lookup[charts,"Format",None]=!="FeynFacet-MeasuredScalarEndpointCharts"||
   Lookup[charts,"Weight",None]=!=1||!TrueQ[Lookup[charts,"CompleteDomainCoverVerified",False]]||
   !TrueQ[Lookup[charts,"RegulatorMeromorphicityVerified",False]],
  cutFamilyFail["CompleteUnweightedScalarEndpointChartsRequired"]];
 If[Lookup[charts,"Charts",{}]==={}||!AllTrue[charts["Charts"],
    TrueQ[Lookup[Lookup[#,"FactorVerification",<||>],"RegulatorMeromorphicityVerified",False]]&],
  cutFamilyFail["CompleteUnweightedScalarEndpointChartsRequired"]];
 e=First[charts["Charts"]]["ResolvedDensity"]["DimensionalRegulator"];
 powers=Flatten[Lookup[charts["Charts"],"EndpointPowers"]];
 If[!AllTrue[powers,PolynomialQ[#,e]&&Exponent[#,e]<=1&],cutFamilyFail["AffineResolvedEndpointPowersRequired"]];
 integer=powers/.e->0;slopes=Coefficient[#,e]&/@powers;
 If[!AllTrue[integer,IntegerQ[#]&&#>=-1&]||
   !AllTrue[Pick[slopes,integer,-1],TrueQ[#<0]&],
  cutFamilyFail["CommonConvergentDimensionalHalfPlaneNotEstablished",
    <|"Powers"->DeleteDuplicates[powers]|>]];
 <|"Format"->"FeynFacet-InclusiveExternalPrescriptionLimit",
  "ExternalPrescriptionLimitEstablished"->True,"VirtualPrescriptionRemoved"->False,
  "ConvergentRegulatorDomain"->"For sufficiently small negative real epsilon, away from isolated regulator poles.",
  "IntegerPowers"->DeleteDuplicates[integer],"LogarithmicFaceSlopes"->DeleteDuplicates[Pick[slopes,integer,-1]],
  "Argument"->"The complete closed-chart smooth factors are meromorphic with finite regulator poles. Every power is greater than -1 in one common sufficiently small negative-epsilon interval. The original external prescribed-product modulus bounds then give dominated convergence after the causal virtual loop has been integrated. Meromorphic continuation preserves that equality. Virtual causal phases are retained.",
  "IntegralEvaluated"->False|>
],"CutFamily"];
VerifyOneLoopMeasurementContactOrder[density_Association,order_Integer:0,request_Association:<||>]:=Catch[Module[
 {z=Lookup[density,"Variable",None],atlas,records,weight},
 If[order<0||!MatchQ[z,_Symbol],cutFamilyFail["ExactMeasuredScalarLoopDensityAndContactOrderRequired"]];
 weight=(z(1-z))^(order+1);
 atlas=FeynFacet`ResolveOneLoopMeasurementEndpointCharts[density,weight,request];
 If[!AssociationQ[atlas],Throw[atlas,"CutFamily"]];
 records=atlas["Charts"];
 If[!AllTrue[records,TrueQ[#["FactorVerification"]["NonnegativeIntegerPowers"]]&],
  cutFamilyFail["RequestedMeasuredContactOrderNotEstablished",<|"RequestedOrder"->order,
    "IntegerPowers"->Lookup[Lookup[records,"FactorVerification"],"IntegerPowers"]|>]];
 <|"Format"->"FeynFacet-MeasuredEndpointContactOrder","Variable"->z,"Interval"->{0,1},
  "ContactDerivativeOrderBound"->order,"SubtractionWeight"->weight,
  "ChartVerifications"->(KeyDrop[#,"ResolvedDensity"]&/@records),
  "OriginalExternalPrescriptionsIncluded"->True,"CompleteEnergyMeasurementCoverVerified"->True,
  "RegulatorMeromorphicityVerified"->True,"ContactCoefficientsDetermined"->False,
  "Argument"->"Any smooth test function with vanishing endpoint jets through the stated order is [z(1-z)]^(order+1) times a smooth function. Every prescribed-product component times this weight has a uniform integrable majorant after clearing finite regulator poles, on a complete disjoint-interior chart cover including its seams. Its meromorphic continuation is therefore fixed by the interior on that test-function subspace. Remaining endpoint-supported terms can contain only delta derivatives through the stated order. Original external factors obey their modulus bounds and virtual causal functions remain continued on their specified branches."|>
],"CutFamily"];
End[];EndPackage[];
