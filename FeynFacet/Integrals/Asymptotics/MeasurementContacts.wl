(* Bound the endpoint extension order from the original regulated density,
   including correlated energy/measurement limits. No finite interior fit
   or observable-specific singularity assumption enters this proof. *)
BeginPackage["FeynFacet`"];
VerifyOneLoopMeasurementContactOrder::usage="VerifyOneLoopMeasurementContactOrder[density,order,request] verifies that [z(1-z)]^(order+1) times each originally prescribed component is uniformly integrable on the full energy/measurement unit square near epsilon=0 after finite regulator poles are cleared. It constructs a complete half-square and positive-sector cover, checks every analytic factor on each closed chart, and rejects negative integer normal powers. This bounds possible endpoint contact derivatives by order; it supplies no contact coefficients. Additional coordinate-independent Assumptions may be supplied.";
Begin["`Private`"];
VerifyOneLoopMeasurementContactOrder[density_Association,order_Integer:0,request_Association:<||>]:=Catch[Module[
 {e,x,z,parameters,values,atlas,halfVariables={Unique["halfMeasurement"],Unique["halfEnergy"]},
  halfRules,mapping,xs,conditions,resolved,regularity,records={},powers,weight,seconds},
 If[order<0||Lookup[density,"Format",None]=!="FeynFacet-OneLoopMeasurementDensity"||
   !TrueQ[Lookup[density,"ExactInRegulator",False]]||!TrueQ[density["PhaseSpaceDensityIncluded"]],
  cutFamilyFail["ExactMeasuredScalarLoopDensityAndContactOrderRequired"]];
 {e,x,z}=Lookup[density,{"DimensionalRegulator","IntegrationVariable","Variable"}];
 If[!FreeQ[Lookup[request,"Assumptions",True],x|z|e],
  cutFamilyFail["CoordinateIndependentContactOrderAssumptionsRequired"]];
 weight=(z(1-z))^(order+1);
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
    Times@@(Power@@#&/@branch["RegulatorFactors"])weight&,branch["ExternalPrescriptionComponents"]];
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
    If[!AllTrue[powers,IntegerQ[#]&&#>=0&],cutFamilyFail["RequestedMeasuredContactOrderNotEstablished",
      <|"RequestedOrder"->order,"Corner"->corner,"Chart"->chart,"IntegerPowers"->powers|>]];
    regularity=FeynFacet`VerifyResolvedEndpointCube[resolved,parameters];
    If[!AssociationQ[regularity],cutFamilyFail["UniformMeasuredContactChartNotEstablished",
      <|"Corner"->corner,"Chart"->chart,"Cause"->regularity|>]];
    AppendTo[records,<|"Branch"->index,"Corner"->corner,"SectorChart"->chart,
      "SourceVariableSubstitution"->mapping,"AbsoluteJacobian"->chart["AbsoluteJacobian"]/4,
      "EndpointPowers"->DeleteDuplicates[Lookup[resolved["Terms"],"Powers"]],
      "FactorVerification"->regularity,"ResolutionSeconds"->seconds|>];
    If[TrueQ[Lookup[request,"PrintTimings",False]],Print["MEASURED CONTACT ORDER CHART ",index," ",corner,
      " ",chart["AnchorIndex"]," RESOLUTION SECONDS ",seconds]],
   {chart,atlas["Charts"]}],{corner,Tuples[{0,1},2]}],
 {index,Length[density["Branches"]]},{branch,{density["Branches"][[index]]}}];
 <|"Format"->"FeynFacet-MeasuredEndpointContactOrder","Variable"->z,"Interval"->{0,1},
  "ContactDerivativeOrderBound"->order,"SubtractionWeight"->weight,"ChartVerifications"->records,
  "OriginalExternalPrescriptionsIncluded"->True,"CompleteEnergyMeasurementCoverVerified"->True,
  "ContactCoefficientsDetermined"->False,
  "Argument"->"Any smooth test function with vanishing endpoint jets through the stated order is [z(1-z)]^(order+1) times a smooth function. Every prescribed-product component times this weight has a uniform integrable majorant after clearing finite regulator poles, on a complete disjoint-interior chart cover including its seams. Its meromorphic continuation is therefore fixed by the interior on that test-function subspace. Remaining endpoint-supported terms can contain only delta derivatives through the stated order. Original external factors obey their modulus bounds and virtual causal functions remain continued on their specified branches."|>
],"CutFamily"];
End[];EndPackage[];
