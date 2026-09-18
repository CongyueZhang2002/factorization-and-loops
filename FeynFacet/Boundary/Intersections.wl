(* Exact logarithmic structure at an intersection of two endpoint divisors.
   No physical mode is selected by this coordinate/basis operation. *)
BeginPackage["FeynFacet`"];
NormalizeEndpointIntersection::usage="NormalizeEndpointIntersection[endpoint,request] extends a normal endpoint gauge by normalizing its tangential residue system, then recomputes both full connections. It requires coordinate times connection to be holomorphic at the joint origin and verifies commuting corner residues. It does not select physical Frobenius modes.";
MatchOrderedBoundaryAtMonomialCorner::usage="MatchOrderedBoundaryAtMonomialCorner[intersection,orderedBoundary,chart] extracts a finite separating corner coefficient map from the complete physical ordered Frobenius germ in a verified logarithmic frame. The current implementation accepts triangular positive monomial maps and log-free physical source seeds. All original master rows and both evaluated boundary constants are retained.";
ConstructEulerEndpointBoundaryValues::usage="ConstructEulerEndpointBoundaryValues[endpoint,intersection,matching] solves a physically selected diagonal Euler tangential system exactly and fixes its constants from the matched joint corner. General tangential systems require the finite DE solver.";
PullBackEndpointBoundaryValues::usage="PullBackEndpointBoundaryValues[sourceEndpoint,targetEndpoint,values,request] transfers a physical normalized leading boundary through a positive monomial overlap. It verifies both full gauge-comparison equations and the resulting boundary DE; no finite Taylor series is evaluated at a distant seam.";
MatchEndpointBoundaryAtIntersection::usage="MatchEndpointBoundaryAtIntersection[endpoint,intersection,values] extracts the regular leading coefficient of an already determined physical boundary in a common logarithmic corner frame and verifies both residue equations.";
TransferJointBoundaryConstants::usage="TransferJointBoundaryConstants[sourceIntersection,targetIntersection,matching] changes compatible logarithmic frames or the ordering of two normal coordinates by their exact regular gauge comparison, preserving every physical constant.";
ConstructEulerEndpointBoundaryBasis::usage="ConstructEulerEndpointBoundaryBasis[endpoint,normalExponent,tangentialRegulatorExponent] constructs an exact diagonal-Euler boundary basis with undetermined constants. It makes no physical sector-selection claim.";
MatchEndpointBoundaryBasisAtIntersection::usage="MatchEndpointBoundaryBasisAtIntersection[endpoint,intersection,basis,matching] fixes an exact boundary basis by the complete physical joint constant map, with a full-rank regular leading comparison.";
ConstructPhysicalEndpointBoundarySystem::usage="ConstructPhysicalEndpointBoundarySystem[endpoint,intersection,matching,request] constructs the tangential DE of a physically matched log-free normal eigenspace and its exact normalized corner seed, without evaluating that one-variable DE.";
TransferPhysicalEndpointBoundarySystem::usage="TransferPhysicalEndpointBoundarySystem[sourceEndpoint,targetEndpoint,system,request] transfers a physical tangential boundary system across an overlap whose normal coordinate differs by an integer power of the unchanged positive tangential coordinate. It includes the regulator-dependent scalar shift of the tangential connection.";
Begin["`Private`"];
NormalizeEndpointIntersection[endpoint_Association,request_Association:<||>]:=Catch[Module[
 {r,t,e,n,normal,tangent,prep,g,gi,a,b,gauge,inverse,residues,commutator,
  variables,denominators,units,zeroRules,cancel},
 If[Lookup[endpoint,"DataType",None]=!="TangentialEndpointSystem",
  tangentialEndpointFail["TangentialEndpointSystemRequired"]];
 {r,t,e,n}=Lookup[endpoint,{"NormalVariable","TangentialVariable","DimensionalRegulator","Dimension"}];
 {normal,tangent}=Lookup[endpoint,{"NormalizedNormalConnectionMatrix","NormalizedTangentialConnectionMatrix"}];
 prep=FeynFacet`PrepareSingularBoundarySystem[
  <|"Variable"->t,"DimensionalRegulator"->e,"ConnectionMatrix"->endpoint["TangentialConnectionMatrix"]|>,
  "Verbose"->Lookup[request,"Verbose",False]];
 If[FailureQ[prep],tangentialEndpointFail["IntersectionTangentialNormalizationFailed",<|"Cause"->prep|>]];
 {g,gi}=Lookup[prep,{"NormalizedToOriginalGauge","OriginalToNormalizedGauge"}];
 cancel[m_]:=Module[{answer=FeynFacet`CancelRationalCoefficients[Flatten[Normal[m]]]},
  If[!ListQ[answer],tangentialEndpointFail["ExactIntersectionMatrixCancellationFailed"]];
  Partition[answer,Last[Dimensions[m]]]];
 a=cancel[gi.normal.g];b=cancel[gi.(tangent.g-D[g,t])];
 variables={r,t};zeroRules=Thread[variables->0];
 denominators=DeleteDuplicates[Denominator/@Flatten[{cancel[r a],cancel[t b]}]];
 units=Cancel/@(denominators/.zeroRules);
 If[AnyTrue[units,#===0||!FreeQ[#,Indeterminate|_DirectedInfinity]&],
  tangentialEndpointFail["LogarithmicNormalCrossingNotEstablished",
   <|"NonunitDenominators"->Pick[denominators,Map[#===0||!FreeQ[#,Indeterminate|_DirectedInfinity]&,units],True]|>]];
 residues=cancel/@({r a,t b}/.zeroRules);
 commutator=cancel[residues[[1]].residues[[2]]-residues[[2]].residues[[1]]];
 If[!AllTrue[Flatten[commutator],#===0&],tangentialEndpointFail["CornerResiduesDoNotCommute"]];
 If[!AllTrue[Flatten[cancel[D[a,t]-D[b,r]+a.b-b.a]],#===0&],
  tangentialEndpointFail["IntersectionConnectionNotFlat"]];
 gauge=cancel[endpoint["NormalGaugeMatrix"].g];
 inverse=cancel[gi.endpoint["InverseNormalGaugeMatrix"]];
 If[!AllTrue[Flatten[cancel[inverse.gauge-IdentityMatrix[n]]],#===0&],
  tangentialEndpointFail["IntersectionGaugeInverseFailed"]];
 <|"DataType"->"NormalCrossingBoundarySystem","Status"->"ExactLogarithmicIntersectionEstablished",
  "KinematicVariables"->variables,"DimensionalRegulator"->e,"Dimension"->n,
  "OriginalMasterIntegralBasis"->endpoint["OriginalMasterIntegralBasis"],
  "ConnectionMatrices"->{a,b},"GaugeMatrix"->gauge,"InverseGaugeMatrix"->inverse,
  "CornerResidues"->residues,"NonvanishingUnitFactorsAtCorner"->units,
  "TangentialPreparation"->prep,"SourceEndpointSystem"->endpoint,
  "Verification"-><|"ExactFlatness"->True,"ExactGaugeInverse"->True,
   "HolomorphicLogarithmicConnectionsAtCorner"->True,"CommutingCornerResidues"->True|>,
  "PhysicalModesSelected"->False,
  "Scope"->"A generic-regulator logarithmic connection at this two-divisor intersection. Physical mode selection, boundary values and sufficient coefficient orders remain separate."|>
],"TangentialEndpoint"];

MatchOrderedBoundaryAtMonomialCorner[intersection_Association,source_Association,chart_Association]:=
 Catch[Module[{r,t,e,matrix,powerR,powerT,powerSigma,n,gi,sourceNormal,rho,z,sigma,
  lambdaRho,lambdaSigma,sectors,physical,normalOrderLow,tLower,nMaximum,endpoint,
  sourceSeed,corner,cornerSeed,cornerLeft,cornerGauge,w=0,kn,cn,next,cornerOrder,
  rLower,mMaximum,expansion,coefficients,map,radialExponent,tangentExponent,
  residues,rows,left,cancel,coefficient,scalarOrder,normalLogCheck,sourceGauge,sourceInverse,
 sourceConnections,images,substitution,pulled,targetGauge,connectionResidual,jointNullity},
 If[Lookup[intersection,"Status",None]=!="ExactLogarithmicIntersectionEstablished"||
  Lookup[source,"Status",None]=!="OrderedPhysicalBoundaryValuesDetermined"||
  intersection["OriginalMasterIntegralBasis"]=!=source["MasterIntegralBasis"]||
  !TrueQ[Lookup[source["CornerBoundaryValues"]["Verification"],"FullExactMatchingRank",False]],
  tangentialEndpointFail["MatchingVerifiedIntersectionAndCompleteOrderedBoundaryRequired"]];
 {r,t}=intersection["KinematicVariables"];e=intersection["DimensionalRegulator"];
 matrix=Lookup[chart,"ExponentMatrix",None];
 If[!MatchQ[matrix,{{_Integer,_Integer},{_Integer,0}}]||matrix[[1,1]]<0||
  matrix[[1,2]]<1||matrix[[2,1]]<1||chart["Variables"]=!={r,t},
  tangentialEndpointFail["TriangularPositiveMonomialCornerMapRequired"]];
 {powerR,powerT,powerSigma}={matrix[[1,1]],matrix[[1,2]],matrix[[2,1]]};
 {rho,z,sigma}=Lookup[source,{"RecoilVariable","MeasurementVariable","MeasurementEndpointVariable"}];
 gi=intersection["InverseGaugeMatrix"];n=Length[gi];
 sourceNormal=source["NormalEndpointSystem"];lambdaRho=source["PhysicalRecoilExponent"];
 physical=source["CornerBoundaryValues"];corner=source["CornerPreparation"];
 sectors=Keys[physical["FrobeniusExpansions"]];
 If[Length[sectors]=!=1,tangentialEndpointFail["SinglePhysicalCornerExponentRequired"]];
 lambdaSigma=First[sectors];
 sourceSeed=source["PhysicalNormalSeedMatrix"];
 cancel[a_]:=Module[{answer=FeynFacet`CancelRationalCoefficients[Flatten[Normal[a]]]},
  If[!ListQ[answer],tangentialEndpointFail["ExactCornerMatchingCancellationFailed"]];
  Partition[answer,Last[Dimensions[a]]]];
 scalarOrder[value_,variable_]:=If[value===0,Infinity,
  Exponent[Numerator[value],variable,Min]-Exponent[Denominator[value],variable,Min]];
 coefficient[a_,variable_,order_]:=Map[Cancel[SeriesCoefficient[#,{variable,0,order}]]&,a,{2}];

 sourceGauge=sourceNormal["NormalGaugeMatrix"];sourceInverse=sourceNormal["InverseNormalGaugeMatrix"];
 sourceConnections={cancel[(D[sourceGauge,rho]+sourceGauge.sourceNormal["NormalizedNormalConnectionMatrix"]).sourceInverse],
  cancel[(D[sourceGauge,z]+sourceGauge.sourceNormal["NormalizedTangentialConnectionMatrix"]).sourceInverse]};
 images={r^powerR t^powerT,1-r^powerSigma};substitution=Thread[{rho,z}->images];
 pulled=Table[cancel[Total[MapThread[#1 #2&,{D[images,variable],sourceConnections/.substitution}]]],
  {variable,{r,t}}];
 targetGauge=intersection["GaugeMatrix"];
 connectionResidual=Table[cancel[gi.(pulled[[j]].targetGauge-D[targetGauge,{r,t}[[j]]])-
  intersection["ConnectionMatrices"][[j]]],{j,2}];
 If[!AllTrue[Flatten[connectionResidual],#===0&],
  tangentialEndpointFail["OrderedAndMonomialPhysicalConnectionsDoNotMatch"]];
 normalLogCheck=cancel[(sourceNormal["NormalResidue"]-lambdaRho IdentityMatrix[n]).sourceSeed];
 If[!AllTrue[Flatten[normalLogCheck],#===0&],
  tangentialEndpointFail["LogarithmicSourceGermNeedsBinomialTransfer"]];
 normalOrderLow=First[sourceNormal["OriginalNormalOrderRange"]];
 tLower=Min[scalarOrder[#,t]&/@Flatten[gi]];
 nMaximum=Floor[-tLower/powerT];
 If[nMaximum<normalOrderLow,tangentialEndpointFail["NoSeparatingPhysicalCornerJets"]];
 endpoint=FeynFacet`ExtendTangentialEndpointSystem[sourceNormal,
  Max[sourceNormal["MaximumNormalOrder"],nMaximum-normalOrderLow]];
 If[FailureQ[endpoint],Throw[endpoint,"TangentialEndpoint"]];
 sourceNormal=SelectFirst[endpoint["PrimarySectors"],epsOrderZero[#["Exponent"]-lambdaRho]&];
 If[MissingQ[sourceNormal],tangentialEndpointFail["PhysicalRecoilPrimarySectorRequired"]];
 cornerSeed=physical["NormalizedSeedMatrix"];cornerLeft=physical["NormalizedSeedLeftInverse"];
 cornerGauge=corner["NormalizedToOriginalGauge"];
 w=ConstantArray[0,{n,Length[cornerGauge]}];
 Do[
  kn=coefficient[gi,t,-powerT j];If[AllTrue[Flatten[kn],#===0&],Continue[]];
  cn=cancel[sourceNormal["OriginalCoefficients"][[j-normalOrderLow+1,1]].sourceSeed];
  next=cancel[r^(powerR j)kn.(cn/.z->1-r^powerSigma).(cornerGauge/.sigma->r^powerSigma)];
  w=cancel[w+next],
 {j,normalOrderLow,nMaximum}];
 rLower=Min[scalarOrder[#,r]&/@Flatten[w]];
 If[rLower===Infinity,tangentialEndpointFail["PhysicalCornerCoefficientMapVanished"]];
 mMaximum=Max[0,Floor[-rLower/powerSigma]];
 expansion=FeynFacet`ConstructPrimaryFrobeniusExpansion[corner["NormalizedDifferentialSystem"],
  <|"Basis"->cornerSeed,"LeftInverse"->cornerLeft|>,
  <|"ResidueEigenvalue"->lambdaSigma,"SpectralVariable"->cornerEigenvalue,
   "ResidueAnnihilatingPolynomial"->cornerEigenvalue-lambdaSigma,
   "MaximumNormalOrder"->mMaximum|>];
 If[FailureQ[expansion],Throw[expansion,"TangentialEndpoint"]];
 If[expansion["MaximumLogarithmPower"]=!=0,tangentialEndpointFail["LogarithmicCornerGermNeedsBinomialTransfer"]];
 coefficients=Normal/@expansion["Coefficients"][[All,1]];
 map=cancel[Sum[coefficient[w,r,-powerSigma j].coefficients[[j+1]],{j,0,mMaximum}]];
 radialExponent=Cancel[powerR lambdaRho+powerSigma lambdaSigma];
 tangentExponent=Cancel[powerT lambdaRho];residues=intersection["CornerResidues"];
 If[!AllTrue[Flatten[cancel[residues[[1]].map-radialExponent map]],#===0&]||
  !AllTrue[Flatten[cancel[residues[[2]].map-tangentExponent map]],#===0&],
  tangentialEndpointFail["PhysicalJointResidueMatchingFailed",<|"ConstantMap"->map|>]];
 jointNullity=n-MatrixRank[Join[residues[[1]]-radialExponent IdentityMatrix[n],
  residues[[2]]-tangentExponent IdentityMatrix[n]]];
 rows=boundaryFunctionSystemIndependentRows[map];
 If[rows===$Failed||Length[rows]=!=source["BoundaryConstantCount"],
  tangentialEndpointFail["OrderedBoundaryCornerMapNotInjective",<|"ConstantMap"->map|>]];
 left=cancel[Inverse[map[[rows]]].IdentityMatrix[n][[rows]]];
 If[!AllTrue[Flatten[cancel[left.map-IdentityMatrix[Length[rows]]]],#===0&],
  tangentialEndpointFail["PhysicalCornerConstantMapLeftInverseFailed"]];
 <|"DataType"->"MonomialCornerBoundaryMatching","Status"->"PhysicalJointBoundaryConstantsMatched",
  "KinematicVariables"->{r,t},"DimensionalRegulator"->e,"MasterIntegralBasis"->source["MasterIntegralBasis"],
  "JointResidueExponents"->{radialExponent,tangentExponent},
  "OrderedConstantToCornerVectorMatrix"->map,"CornerVectorToOrderedConstantMatrix"->left,
  "InitialConstantValues"->physical["InitialConstantValues"],"BoundaryConstantCount"->Length[rows],"JointEigenspaceDimension"->jointNullity,
  "RequiredSourceNormalOrderRange"->{normalOrderLow,nMaximum},"RequiredSourceCornerOrder"->mMaximum,
  "TargetConstantFunctional"->"The coefficient of r^lambda t^mu with integer degrees(0,0) and logarithm degrees(0,0) in the common logarithmic frame; across joint primary spaces these functionals separate all corner constants.",
  "ExcludedJointModes"->"Every other regulator exponent pair has zero coefficient in the complete ordered physical germ. The normalized logarithmic frame has zero integer residue exponents; no higher analytic jet contributes to the separating constant coefficient.",
  "Verification"-><|"ExactRadialResidueMatching"->True,"ExactTangentialResidueMatching"->True,
   "ExactInjectiveSourceMap"->True,"ExactFullConnectionPullback"->True,"AllOriginalMasterRowsRetained"->True|>,
  "PhysicalSource"->"Complete physically constrained ordered Frobenius germ, not only raw leading master values.",
  "Scope"->"This common logarithmic corner. Transport to other divisors and the final endpoint coefficient orders remain separate."|>
],"TangentialEndpoint"];


ConstructEulerEndpointBoundaryValues[endpoint_Association,intersection_Association,matching_Association]:=
 Catch[Module[{r,t,e,lambda,beta,sector,rank,connection,exponents,integerPowers,basis,gi,
  comparison,leading,rows,left,constantMap,coefficientMatrix,cancel,order},
 If[Lookup[matching,"Status",None]=!="PhysicalJointBoundaryConstantsMatched"||
  endpoint["OriginalMasterIntegralBasis"]=!=intersection["OriginalMasterIntegralBasis"]||
  endpoint["OriginalMasterIntegralBasis"]=!=matching["MasterIntegralBasis"]||
  {endpoint["NormalVariable"],endpoint["TangentialVariable"]}=!=matching["KinematicVariables"],
  tangentialEndpointFail["MatchingPhysicalCornerAndEndpointCoordinatesRequired"]];
 {r,t}=matching["KinematicVariables"];e=matching["DimensionalRegulator"];
 {lambda,beta}=matching["JointResidueExponents"];
 sector=FeynFacet`ConstructEndpointSectorDifferentialSystem[endpoint,lambda];
 If[FailureQ[sector],Throw[sector,"TangentialEndpoint"]];
 rank=sector["Dimension"];connection=First[sector["ConnectionMatrices"]];
 cancel[a_]:=Module[{answer=FeynFacet`CancelRationalCoefficients[Flatten[Normal[a]]]},
  If[!ListQ[answer],tangentialEndpointFail["ExactEulerBoundaryCancellationFailed"]];
  Partition[answer,Last[Dimensions[a]]]];
 exponents=Cancel/@Diagonal[t connection];
 integerPowers=FeynFacet`CancelRationalCoefficients[exponents-beta];
 If[!ListQ[integerPowers],tangentialEndpointFail["EulerExponentCancellationFailed"]];
 If[!FreeQ[exponents,t]||!AllTrue[integerPowers,IntegerQ]||
  !AllTrue[Flatten[cancel[t connection-DiagonalMatrix[exponents]]],#===0&],
  tangentialEndpointFail["PhysicalTangentialSystemNeedsGeneralBoundaryTransport"]];
 basis=sector["NormalizedLeadingVectorEmbedding"];
 gi=intersection["TangentialPreparation"]["OriginalToNormalizedGauge"];
 comparison=cancel[gi.basis.DiagonalMatrix[t^#&/@integerPowers]];
 order=Min[If[#===0,Infinity,Exponent[Numerator[#],t,Min]-Exponent[Denominator[#],t,Min]]&/@Flatten[comparison]];
 If[!TrueQ[order>=0],tangentialEndpointFail["EulerBoundaryComparisonNotRegular"]];
 leading=comparison/.t->0;rows=boundaryFunctionSystemIndependentRows[leading];
 If[rows===$Failed||Length[rows]=!=rank,tangentialEndpointFail["EulerBoundaryLeadingMapNotInjective"]];
 left=cancel[Inverse[leading[[rows]]].IdentityMatrix[Length[leading]][[rows]]];
 constantMap=cancel[left.matching["OrderedConstantToCornerVectorMatrix"]];
 If[!AllTrue[Flatten[cancel[leading.constantMap-matching["OrderedConstantToCornerVectorMatrix"]]],#===0&],
  tangentialEndpointFail["PhysicalEulerBoundaryConstantMismatch"]];
 coefficientMatrix=cancel[basis.DiagonalMatrix[t^#&/@integerPowers].constantMap];
 If[!AllTrue[Flatten[cancel[D[coefficientMatrix,t]+beta coefficientMatrix/t-
   endpoint["TangentialConnectionMatrix"].coefficientMatrix]],#===0&]||
  !AllTrue[Flatten[cancel[endpoint["NormalResidue"].coefficientMatrix-lambda coefficientMatrix]],#===0&],
  tangentialEndpointFail["PhysicalEulerBoundaryEquationMismatch"]];
 <|"DataType"->"ExactEndpointBoundaryValues","Status"->"PhysicalEndpointBoundaryValuesDetermined",
  "NormalVariable"->r,"TangentialVariable"->t,"DimensionalRegulator"->e,
  "MasterIntegralBasis"->matching["MasterIntegralBasis"],"NormalExponent"->lambda,
  "TangentialRegulatorExponent"->beta,"RationalCoefficientMatrix"->coefficientMatrix,
  "InitialConstantValues"->matching["InitialConstantValues"],
  "BoundaryConstantCount"->matching["BoundaryConstantCount"],
  "CoefficientConvention"->"Normalized leading vector = TangentialVariable^TangentialRegulatorExponent times RationalCoefficientMatrix times InitialConstantValues.",
  "PrimarySector"->sector,"EulerConstantMap"->constantMap,
  "Verification"-><|"ExactRadialResidueEquation"->True,"ExactTangentialEquation"->True,
    "ExactPhysicalCornerMatching"->True|>|>
],"TangentialEndpoint"];


(* A regular rational tangential change can move an ordinary point to the
   origin. Its regulator power is an analytic unit, which must be retained
   in the boundary equation and in the corner matching. *)
pullBackEndpointBoundaryAtOrdinaryPoint[source_,target_,values_,request_]:=Catch[Module[
 {rs,ts,r,t,e,image,lambda,beta,l,sourceMatrices,targetMatrices,checks,leading,v,
 factor,logDerivative,cancel,order},
 {rs,ts}=Lookup[source,{"NormalVariable","TangentialVariable"}];
 {r,t}=Lookup[target,{"NormalVariable","TangentialVariable"}];
 e=values["DimensionalRegulator"];image=request["TangentialImage"];
 If[!FreeQ[image,r]||!FreeQ[image/.t->0,Indeterminate|_DirectedInfinity]||
   !TrueQ[FullSimplify[(image/.t->0)>0,Lookup[request,"Assumptions",True]]]||
   source["OriginalMasterIntegralBasis"]=!=target["OriginalMasterIntegralBasis"]||
   source["OriginalMasterIntegralBasis"]=!=values["MasterIntegralBasis"],
  tangentialEndpointFail["RegularPositiveTangentialBoundaryMapRequired"]];
 cancel[m_]:=Module[{answer=FeynFacet`CancelRationalCoefficients[Flatten[Normal[m]]]},
  If[!ListQ[answer],tangentialEndpointFail["ExactBoundaryOverlapCancellationFailed"]];
  Partition[answer,Last[Dimensions[m]]]];
 l=cancel[target["InverseNormalGaugeMatrix"].(source["NormalGaugeMatrix"]/.{rs->r,ts->image})];
 sourceMatrices=Normal/@Lookup[source,{"NormalizedNormalConnectionMatrix","NormalizedTangentialConnectionMatrix"}];
 sourceMatrices=(sourceMatrices/.{rs->r,ts->image}){1,D[image,t]};
 targetMatrices=Normal/@Lookup[target,{"NormalizedNormalConnectionMatrix","NormalizedTangentialConnectionMatrix"}];
 checks=Table[cancel[D[l,{r,t}[[j]]]+l.sourceMatrices[[j]]-targetMatrices[[j]].l],{j,2}];
 If[!AllTrue[Flatten[checks],#===0&],tangentialEndpointFail["OrdinaryBoundaryOverlapConnectionMismatch"]];
 order=Min[If[#===0,Infinity,Exponent[Numerator[#],r,Min]-Exponent[Denominator[#],r,Min]]&/@Flatten[l]];
 If[!TrueQ[order>=0],tangentialEndpointFail["OrdinaryBoundaryOverlapNeedsHigherNormalJets"]];
 {lambda,beta}=Lookup[values,{"NormalExponent","TangentialRegulatorExponent"}];
 v=cancel[(l/.r->0).(values["RationalCoefficientMatrix"]/.ts->image)];
 factor=(Lookup[values,"TangentialAnalyticFactor",1]/.ts->image) image^beta;
 logDerivative=Cancel[beta D[image,t]/image]+
  (Lookup[values,"TangentialAnalyticLogDerivative",0]/.ts->image)D[image,t];
 If[!AllTrue[Flatten[cancel[D[v,t]+logDerivative v-target["TangentialConnectionMatrix"].v]],#===0&]||
  !AllTrue[Flatten[cancel[target["NormalResidue"].v-lambda v]],#===0&],
  tangentialEndpointFail["TransferredOrdinaryBoundaryEquationMismatch"]];
 Join[KeyDrop[values,{"PrimarySector","EulerConstantMap"}],<|
  "NormalVariable"->r,"TangentialVariable"->t,"TangentialRegulatorExponent"->0,
  "RationalCoefficientMatrix"->v,"TangentialAnalyticFactor"->factor,
  "TangentialAnalyticLogDerivative"->logDerivative,
  "TangentialAnalyticFactorAtOrigin"->(factor/.t->0),
  "Overlap"-><|"TangentialImage"->image,"GaugeComparison"->l|>,
  "Verification"-><|"ExactFullGaugeComparison"->True,"ExactRadialResidueEquation"->True,
   "ExactTangentialEquation"->True,"PositiveOrdinaryTangentialImage"->True|>|>]
],"TangentialEndpoint"];

PullBackEndpointBoundaryValues[source_Association,target_Association,values_Association,request_Association]/;
 KeyExistsQ[request,"TangentialImage"]:=pullBackEndpointBoundaryAtOrdinaryPoint[source,target,values,request];

PullBackEndpointBoundaryValues[source_Association,target_Association,values_Association,request_Association]:=
 Catch[Module[{rs,ts,r,t,e,a,b,d,u,images,substitution,sourceMatrices,targetMatrices,
  l,pulled,checks,order,leading,v,lambda,beta,cancel,coefficientMatrix,sector,factor,logDerivative},
 If[!MemberQ[{"PhysicalEndpointBoundaryValuesDetermined","ExactEndpointBoundaryBasisConstructed"},Lookup[values,"Status",None]]||
  source["OriginalMasterIntegralBasis"]=!=target["OriginalMasterIntegralBasis"]||
  source["OriginalMasterIntegralBasis"]=!=values["MasterIntegralBasis"],
  tangentialEndpointFail["MatchingPhysicalEndpointBoundaryRequired"]];
 {rs,ts}={source["NormalVariable"],source["TangentialVariable"]};
 {r,t}={target["NormalVariable"],target["TangentialVariable"]};e=values["DimensionalRegulator"];
 {a,b}=Lookup[request,{"NormalUnitPower","TangentialPower"},None];
 If[!IntegerQ[a]||!MatchQ[b,_Integer|_Rational]||b===0,
  tangentialEndpointFail["ExplicitPositiveMonomialOverlapRequired"]];
 If[b<0&&Lookup[values,"TangentialAnalyticFactor",1]=!=1,
  tangentialEndpointFail["AnalyticUnitAtReciprocalEndpointRequiresContinuation"]];
 d=Denominator[b];u=If[d===1,t,Unique["positiveTangentialRoot"]];
 images={r u^(d a),u^(d b)};substitution=Thread[{rs,ts}->images];
 cancel[m_]:=Module[{answer=FeynFacet`CancelRationalCoefficients[Flatten[Normal[m]]]},
  If[!ListQ[answer],tangentialEndpointFail["ExactBoundaryOverlapCancellationFailed"]];
  Partition[answer,Last[Dimensions[m]]]];
 sourceMatrices={source["NormalizedNormalConnectionMatrix"],source["NormalizedTangentialConnectionMatrix"]}/.substitution;
 targetMatrices={target["NormalizedNormalConnectionMatrix"],target["NormalizedTangentialConnectionMatrix"]}/.t->u^d;
 l=cancel[(target["InverseNormalGaugeMatrix"]/.t->u^d).(source["NormalGaugeMatrix"]/.substitution)];
 pulled=Table[Total[MapThread[#1 #2&,{D[images,var],sourceMatrices}]],{var,{r,u}}];
 checks={cancel[D[l,r]+l.pulled[[1]]-targetMatrices[[1]].l],
  cancel[D[l,u]+l.pulled[[2]]-d u^(d-1)targetMatrices[[2]].l]};
 If[!AllTrue[Flatten[checks],#===0&],tangentialEndpointFail["EndpointOverlapFullConnectionMismatch"]];
 order=Min[If[#===0,Infinity,Exponent[Numerator[#],r,Min]-Exponent[Denominator[#],r,Min]]&/@Flatten[l]];
 If[!TrueQ[order>=0],tangentialEndpointFail["BoundaryOverlapNeedsHigherNormalJets"]];
 leading=l/.r->0;
 {lambda,beta}=Lookup[values,{"NormalExponent","TangentialRegulatorExponent"}];
 coefficientMatrix=cancel[leading.(values["RationalCoefficientMatrix"]/.ts->u^(d b))];
 factor=Lookup[values,"TangentialAnalyticFactor",1]/.ts->u^(d b);
 logDerivative=Cancel[(Lookup[values,"TangentialAnalyticLogDerivative",0]/.ts->u^(d b))D[u^(d b),u]];
 beta=Cancel[a lambda+b beta];
 If[!AllTrue[Flatten[cancel[D[coefficientMatrix,u]+(d beta/u+logDerivative)coefficientMatrix-
   d u^(d-1)(target["TangentialConnectionMatrix"]/.t->u^d).coefficientMatrix]],#===0&]||
  !AllTrue[Flatten[cancel[(target["NormalResidue"]/.t->u^d).coefficientMatrix-lambda coefficientMatrix]],#===0&],
  tangentialEndpointFail["TransferredPhysicalBoundaryEquationMismatch"]];
 coefficientMatrix=coefficientMatrix/.u->t^(1/d);
 sector=FeynFacet`ConstructEndpointSectorDifferentialSystem[target,lambda];
 If[FailureQ[sector],Throw[sector,"TangentialEndpoint"]];
 Join[KeyDrop[values,{"PrimarySector","EulerConstantMap"}],<|
  "NormalVariable"->r,"TangentialVariable"->t,"NormalExponent"->lambda,
  "TangentialRegulatorExponent"->beta,"RationalCoefficientMatrix"->coefficientMatrix,
  "TangentialAnalyticFactor"->(factor/.u->t^(1/d)),
  "TangentialAnalyticLogDerivative"->(Cancel[logDerivative/(d u^(d-1))]/.u->t^(1/d)),
  "PrimarySector"->sector,
  "Overlap"-><|"NormalUnitPower"->a,"TangentialPower"->b,"PositiveTangentialRamification"->d,
   "GaugeComparison"->(l/.u->t^(1/d))|>,
  "Verification"-><|"ExactFullNormalConnection"->True,"ExactFullTangentialConnection"->True,
   "RegularNormalGaugeComparison"->True,"ExactRadialResidueEquation"->True,
   "ExactTangentialEquation"->True|>|>]
],"TangentialEndpoint"];

MatchEndpointBoundaryAtIntersection[endpoint_Association,intersection_Association,values_Association]:=
 Catch[Module[{r,t,e,lambda,beta,v,map,rows,left,cancel,order,residues,l,indices,
  sourceMatrices,targetMatrices,checks,exponents},
 If[Lookup[values,"Status",None]=!="PhysicalEndpointBoundaryValuesDetermined"||
  intersection["OriginalMasterIntegralBasis"]=!=values["MasterIntegralBasis"]||
  endpoint["OriginalMasterIntegralBasis"]=!=values["MasterIntegralBasis"]||
  Sort[intersection["KinematicVariables"]]=!=Sort[{endpoint["NormalVariable"],endpoint["TangentialVariable"]}],
  tangentialEndpointFail["MatchingPhysicalBoundaryAndIntersectionRequired"]];
 {r,t}={endpoint["NormalVariable"],endpoint["TangentialVariable"]};e=intersection["DimensionalRegulator"];
 {lambda,beta}=Lookup[values,{"NormalExponent","TangentialRegulatorExponent"}];
 cancel[m_]:=Module[{answer=FeynFacet`CancelRationalCoefficients[Flatten[Normal[m]]]},
  If[!ListQ[answer],tangentialEndpointFail["ExactBoundaryCornerCancellationFailed"]];
  Partition[answer,Last[Dimensions[m]]]];
 l=cancel[intersection["InverseGaugeMatrix"].endpoint["NormalGaugeMatrix"]];
 indices=First@FirstPosition[intersection["KinematicVariables"],#]&/@{r,t};
 sourceMatrices={endpoint["NormalizedNormalConnectionMatrix"],endpoint["NormalizedTangentialConnectionMatrix"]};
 targetMatrices=intersection["ConnectionMatrices"][[indices]];
 checks=Table[cancel[D[l,{r,t}[[j]]]+l.sourceMatrices[[j]]-targetMatrices[[j]].l],{j,2}];
 If[!AllTrue[Flatten[checks],#===0&],tangentialEndpointFail["PhysicalBoundaryIntersectionConnectionMismatch"]];
 order=Min[If[#===0,Infinity,Exponent[Numerator[#],r,Min]-Exponent[Denominator[#],r,Min]]&/@Flatten[l]];
 If[!TrueQ[order>=0],tangentialEndpointFail["PhysicalBoundaryIntersectionNeedsHigherNormalJets"]];
 v=cancel[(l/.r->0).values["RationalCoefficientMatrix"]];
 order=Min[If[#===0,Infinity,Exponent[Numerator[#],t,Min]-Exponent[Denominator[#],t,Min]]&/@Flatten[v]];
 If[!TrueQ[order>=0],tangentialEndpointFail["PhysicalBoundaryCornerComparisonNotRegular"]];
 map=(v/.t->0) Lookup[values,"TangentialAnalyticFactorAtOrigin",1];residues=intersection["CornerResidues"];
 exponents=Lookup[AssociationThread[{r,t},{lambda,beta}],intersection["KinematicVariables"]];
 If[!AllTrue[Flatten[Table[cancel[residues[[j]].map-exponents[[j]]map],{j,2}]],#===0&],
  tangentialEndpointFail["PhysicalBoundaryJointResidueMismatch"]];
 rows=boundaryFunctionSystemIndependentRows[map];
 If[rows===$Failed||Length[rows]=!=values["BoundaryConstantCount"],
  tangentialEndpointFail["PhysicalBoundaryCornerMapNotInjective"]];
 left=cancel[Inverse[map[[rows]]].IdentityMatrix[Length[map]][[rows]]];
 <|"DataType"->"MonomialCornerBoundaryMatching","Status"->"PhysicalJointBoundaryConstantsMatched",
  "KinematicVariables"->intersection["KinematicVariables"],"DimensionalRegulator"->e,"MasterIntegralBasis"->values["MasterIntegralBasis"],
  "JointResidueExponents"->exponents,"OrderedConstantToCornerVectorMatrix"->map,
  "CornerVectorToOrderedConstantMatrix"->left,"InitialConstantValues"->values["InitialConstantValues"],
  "BoundaryConstantCount"->values["BoundaryConstantCount"],
  "Verification"-><|"ExactFullGaugeComparison"->True,"RegularPhysicalBoundaryComparison"->True,
   "ExactRadialResidueMatching"->True,"ExactTangentialResidueMatching"->True,"ExactInjectiveSourceMap"->True|>|>
],"TangentialEndpoint"];

TransferJointBoundaryConstants[source_Association,target_Association,matching_Association]:=
 Catch[Module[{variables,e,order,l,li,zero,constants,exponents,sourceMatrices,targetMatrices,checks,
  map,rows,left,cancel,n},
 variables=target["KinematicVariables"];e=target["DimensionalRegulator"];
 If[Sort[variables]=!=Sort[source["KinematicVariables"]]||
  target["OriginalMasterIntegralBasis"]=!=source["OriginalMasterIntegralBasis"]||
  matching["KinematicVariables"]=!=source["KinematicVariables"]||
  Lookup[matching,"Status",None]=!="PhysicalJointBoundaryConstantsMatched",
  tangentialEndpointFail["SamePhysicalIntersectionAndMatchingRequired"]];
 cancel[m_]:=Module[{answer=FeynFacet`CancelRationalCoefficients[Flatten[Normal[m]]]},
  If[!ListQ[answer],tangentialEndpointFail["ExactJointFrameCancellationFailed"]];
  Partition[answer,Last[Dimensions[m]]]];
 n=target["Dimension"];l=cancel[target["InverseGaugeMatrix"].source["GaugeMatrix"]];
 li=cancel[source["InverseGaugeMatrix"].target["GaugeMatrix"]];zero=Thread[variables->0];
 If[AnyTrue[Denominator/@Flatten[{l,li}],TrueQ[Cancel[#/.zero]===0]&],
  tangentialEndpointFail["JointGaugeComparisonMustBeInvertibleAtCorner"]];
 order=First@FirstPosition[source["KinematicVariables"],#]&/@variables;
 sourceMatrices=source["ConnectionMatrices"][[order]];targetMatrices=target["ConnectionMatrices"];
 checks=Table[cancel[D[l,variables[[j]]]+l.sourceMatrices[[j]]-targetMatrices[[j]].l],{j,Length[variables]}];
 If[!AllTrue[Flatten[checks],#===0&],tangentialEndpointFail["JointFrameConnectionMismatch"]];
 map=cancel[(l/.zero).matching["OrderedConstantToCornerVectorMatrix"]];
 exponents=matching["JointResidueExponents"][[order]];
 checks=Table[cancel[target["CornerResidues"][[j]].map-exponents[[j]]map],{j,Length[variables]}];
 If[!AllTrue[Flatten[checks],#===0&],tangentialEndpointFail["TransferredJointResidueMismatch"]];
 rows=boundaryFunctionSystemIndependentRows[map];left=cancel[Inverse[map[[rows]]].IdentityMatrix[n][[rows]]];
 Join[matching,<|"KinematicVariables"->variables,"JointResidueExponents"->exponents,
  "OrderedConstantToCornerVectorMatrix"->map,"CornerVectorToOrderedConstantMatrix"->left,
  "JointGaugeComparison"->l,"Verification"-><|"ExactFullConnectionComparison"->True,
    "InvertibleRegularCornerComparison"->True,"ExactJointResidueMatching"->True|>|>]
],"TangentialEndpoint"];


ConstructEulerEndpointBoundaryBasis[endpoint_Association,lambda_,beta_]:=Catch[Module[
 {sector,t,e,connection,exponents,integers,coefficientMatrix},
 sector=FeynFacet`ConstructEndpointSectorDifferentialSystem[endpoint,lambda];
 If[FailureQ[sector],Throw[sector,"TangentialEndpoint"]];
 t=endpoint["TangentialVariable"];e=endpoint["DimensionalRegulator"];
 connection=First[sector["ConnectionMatrices"]];exponents=Cancel/@Diagonal[t connection];
 integers=Cancel[#-beta]&/@exponents;
 If[!FreeQ[exponents,t]||!AllTrue[integers,IntegerQ]||
  !tangentialEndpointZeroQ[t connection-DiagonalMatrix[exponents]],
  tangentialEndpointFail["DiagonalEulerBoundaryBasisRequired"]];
 coefficientMatrix=tangentialEndpointMatrix[sector["NormalizedLeadingVectorEmbedding"].DiagonalMatrix[t^#&/@integers]];
 <|"DataType"->"ExactEndpointBoundaryValues","Status"->"ExactEndpointBoundaryBasisConstructed",
  "NormalVariable"->endpoint["NormalVariable"],"TangentialVariable"->t,"DimensionalRegulator"->e,
  "MasterIntegralBasis"->endpoint["OriginalMasterIntegralBasis"],"NormalExponent"->lambda,
  "TangentialRegulatorExponent"->beta,"RationalCoefficientMatrix"->coefficientMatrix,
  "InitialConstantValues"->Missing["Undetermined"],"BoundaryConstantCount"->sector["Dimension"],
  "PhysicalBoundaryConstantsDetermined"->False,"PhysicalSectorSelectionEstablished"->False,
  "PrimarySector"->sector,
  "CoefficientConvention"->"A general leading vector in the stated primary sector is t^beta times this rational matrix times an undetermined constant vector."|>
],"TangentialEndpoint"];

MatchEndpointBoundaryBasisAtIntersection[endpoint_Association,intersection_Association,
 basis_Association,matching_Association]:=Catch[Module[
 {t,v,order,leading,rows,left,map,result},
 If[Lookup[basis,"Status",None]=!="ExactEndpointBoundaryBasisConstructed"||
  Lookup[matching,"Status",None]=!="PhysicalJointBoundaryConstantsMatched"||
  matching["KinematicVariables"]=!={endpoint["NormalVariable"],endpoint["TangentialVariable"]}||
  matching["MasterIntegralBasis"]=!=basis["MasterIntegralBasis"]||
  matching["JointResidueExponents"]=!={basis["NormalExponent"],basis["TangentialRegulatorExponent"]},
  tangentialEndpointFail["MatchingExactBoundaryBasisAndPhysicalCornerRequired"]];
 t=endpoint["TangentialVariable"];
 v=tangentialEndpointMatrix[intersection["TangentialPreparation"]["OriginalToNormalizedGauge"].basis["RationalCoefficientMatrix"]];
 order=Min[If[#===0,Infinity,Exponent[Numerator[#],t,Min]-Exponent[Denominator[#],t,Min]]&/@Flatten[v]];
 If[!TrueQ[order>=0],tangentialEndpointFail["BoundaryBasisCornerComparisonNotRegular"]];
 leading=v/.t->0;rows=boundaryFunctionSystemIndependentRows[leading];
 If[rows===$Failed||Length[rows]=!=basis["BoundaryConstantCount"],
  tangentialEndpointFail["BoundaryBasisLeadingMapNotInjective"]];
 left=tangentialEndpointMatrix[Inverse[leading[[rows]]].IdentityMatrix[Length[leading]][[rows]]];
 map=tangentialEndpointMatrix[left.matching["OrderedConstantToCornerVectorMatrix"]];
 If[!tangentialEndpointZeroQ[leading.map-matching["OrderedConstantToCornerVectorMatrix"]],
  tangentialEndpointFail["BoundaryBasisDoesNotSpanPhysicalCorner"]];
 result=Join[basis,<|"Status"->"PhysicalEndpointBoundaryValuesDetermined",
  "InitialConstantValues"->matching["InitialConstantValues"],
  "RationalCoefficientMatrix"->tangentialEndpointMatrix[basis["RationalCoefficientMatrix"].map],
  "BoundaryConstantCount"->matching["BoundaryConstantCount"],"PhysicalBoundaryConstantsDetermined"->True,
  "PhysicalSectorSelectionEstablished"->True,"PhysicalConstantMatchingMatrix"->map|>];
 If[!tangentialEndpointZeroQ[D[result["RationalCoefficientMatrix"],t]+
   result["TangentialRegulatorExponent"]result["RationalCoefficientMatrix"]/t-
   endpoint["TangentialConnectionMatrix"].result["RationalCoefficientMatrix"]],
  tangentialEndpointFail["MatchedBoundaryBasisDifferentialEquationMismatch"]];
 result
],"TangentialEndpoint"];


ConstructPhysicalEndpointBoundarySystem[endpoint_Association,intersection_Association,matching_Association,
 request_Association:<||>]:=Catch[Module[{r,t,e,lambda,beta,sector,relations,reduced,basis,gamma,
 prep,comparison,order,leading,rows,left,seed,residue,check,cancel,n,m},
 If[Lookup[matching,"Status",None]=!="PhysicalJointBoundaryConstantsMatched"||
  matching["KinematicVariables"]=!={endpoint["NormalVariable"],endpoint["TangentialVariable"]}||
  matching["MasterIntegralBasis"]=!=endpoint["OriginalMasterIntegralBasis"]||
  intersection["SourceEndpointSystem"]=!=endpoint,
  tangentialEndpointFail["MatchedPhysicalIntersectionRequired"]];
 {r,t}=matching["KinematicVariables"];e=matching["DimensionalRegulator"];
 {lambda,beta}=matching["JointResidueExponents"];n=endpoint["Dimension"];
 cancel[a_]:=Module[{answer=FeynFacet`CancelRationalCoefficients[Flatten[Normal[a]]]},
  If[!ListQ[answer],tangentialEndpointFail["PhysicalBoundarySystemCancellationFailed"]];
  Partition[answer,Last[Dimensions[a]]]];
 sector=FeynFacet`ConstructEndpointSectorDifferentialSystem[endpoint,lambda];
 If[FailureQ[sector],Throw[sector,"TangentialEndpoint"]];
 relations=cancel[(endpoint["NormalResidue"]-lambda IdentityMatrix[n]).sector["NormalizedLeadingVectorEmbedding"]];
 reduced=FeynFacet`RestrictDifferentialSystemToRelations[sector,relations,
  <|"ValidationPoints"->Lookup[request,"ValidationPoints",{}],
   "RelationProvenance"->"The matched joint physical seed has no normal Jordan logarithms. Residue horizontality transports this eigenspace along the boundary."|>];
 If[FailureQ[reduced],Throw[reduced,"TangentialEndpoint"]];
 basis=cancel[sector["NormalizedLeadingVectorEmbedding"].reduced["SolutionEmbedding"]];
 gamma=First[reduced["ConnectionMatrices"]];m=Length[gamma];
 prep=FeynFacet`PrepareSingularBoundarySystem[<|"Variable"->t,"DimensionalRegulator"->e,"ConnectionMatrix"->gamma|>];
 If[FailureQ[prep],Throw[prep,"TangentialEndpoint"]];
 comparison=cancel[intersection["TangentialPreparation"]["OriginalToNormalizedGauge"].basis.prep["NormalizedToOriginalGauge"]];
 order=Min[If[#===0,Infinity,Exponent[Numerator[#],t,Min]-Exponent[Denominator[#],t,Min]]&/@Flatten[comparison]];
 If[!TrueQ[order>=0],tangentialEndpointFail["PhysicalBoundarySubspaceComparisonNotRegular"]];
 leading=comparison/.t->0;rows=boundaryFunctionSystemIndependentRows[leading];
 If[rows===$Failed||Length[rows]=!=m,tangentialEndpointFail["PhysicalBoundarySubspaceLeadingMapNotInjective"]];
 left=cancel[Inverse[leading[[rows]]].IdentityMatrix[n][[rows]]];
 seed=cancel[left.matching["OrderedConstantToCornerVectorMatrix"]];
 If[!tangentialEndpointZeroQ[leading.seed-matching["OrderedConstantToCornerVectorMatrix"]],
  tangentialEndpointFail["PhysicalCornerOutsideLogFreeNormalEigenspace"]];
 residue=cancel[t prep["NormalizedDifferentialSystem"]["ConnectionMatrix"]]/.t->0;
 If[!tangentialEndpointZeroQ[residue.seed-beta seed]||
  !tangentialEndpointZeroQ[D[basis,t]+basis.gamma-endpoint["TangentialConnectionMatrix"].basis],
  tangentialEndpointFail["PhysicalBoundarySubspaceEquationMismatch"]];
 <|"DataType"->"PhysicalEndpointBoundarySystem","Status"->"PhysicalEndpointBoundarySystemConstructed",
  "NormalVariable"->r,"TangentialVariable"->t,"DimensionalRegulator"->e,
  "MasterIntegralBasis"->matching["MasterIntegralBasis"],"NormalExponent"->lambda,
  "TangentialBoundaryExponent"->beta,"NormalizedLeadingVectorEmbedding"->basis,
  "ConnectionMatrix"->gamma,"BoundaryFunctionCount"->m,"BoundaryConstantCount"->matching["BoundaryConstantCount"],
  "CornerPreparation"->prep,"CornerSeedMatrix"->seed,"InitialConstantValues"->matching["InitialConstantValues"],
  "BoundaryFunctionArgumentRules"->{},
  "Verification"-><|"NormalJordanLogarithmsAbsent"->True,"ExactInvariantBoundarySubspace"->True,
   "ExactPhysicalCornerSeed"->True|>|>
],"TangentialEndpoint"];

TransferPhysicalEndpointBoundarySystem[source_Association,target_Association,boundary_Association,request_Association]:=
 Catch[Module[{rs,ts,r,t,e,a,lambda,beta,sub,images,l,ls,checks,order,basis,gamma,
 sourceMatrices,targetMatrices,prep,k,seed,residue,cancel,m},
 If[Lookup[boundary,"Status",None]=!="PhysicalEndpointBoundarySystemConstructed"||
  source["OriginalMasterIntegralBasis"]=!=target["OriginalMasterIntegralBasis"]||
  source["OriginalMasterIntegralBasis"]=!=boundary["MasterIntegralBasis"],
  tangentialEndpointFail["MatchingPhysicalBoundarySystemRequired"]];
 a=Lookup[request,"NormalUnitPower",None];
 If[!IntegerQ[a],tangentialEndpointFail["IntegerPositiveTangentialNormalUnitRequired"]];
 {rs,ts}={source["NormalVariable"],source["TangentialVariable"]};
 {r,t}={target["NormalVariable"],target["TangentialVariable"]};e=boundary["DimensionalRegulator"];
 If[boundary["CornerPreparation"]["NormalizedDifferentialSystem"]["Variable"]=!=ts||
  Lookup[boundary,"BoundaryFunctionArgumentRules",{}]=!={},
  tangentialEndpointFail["BoundarySystemTransferRequiresTheDeclaredZeroEndpointCoordinate"]];
 lambda=boundary["NormalExponent"];beta=Cancel[boundary["TangentialBoundaryExponent"]+a lambda];
 images={r t^a,t};sub=Thread[{rs,ts}->images];m=boundary["BoundaryFunctionCount"];
 cancel[x_]:=Module[{answer=FeynFacet`CancelRationalCoefficients[Flatten[Normal[x]]]},
  If[!ListQ[answer],tangentialEndpointFail["BoundarySystemOverlapCancellationFailed"]];
  Partition[answer,Last[Dimensions[x]]]];
 l=cancel[target["InverseNormalGaugeMatrix"].(source["NormalGaugeMatrix"]/.sub)];
 sourceMatrices={source["NormalizedNormalConnectionMatrix"],source["NormalizedTangentialConnectionMatrix"]}/.sub;
 targetMatrices={target["NormalizedNormalConnectionMatrix"],target["NormalizedTangentialConnectionMatrix"]};
 checks=Table[cancel[D[l,var]+l.Total[MapThread[#1 #2&,{D[images,var],sourceMatrices}]]-
  targetMatrices[[j]].l],{j,2},{var,{{r,t}[[j]]}}];
 If[!AllTrue[Flatten[checks],#===0&],tangentialEndpointFail["BoundarySystemOverlapConnectionMismatch"]];
 order=Min[If[#===0,Infinity,Exponent[Numerator[#],r,Min]-Exponent[Denominator[#],r,Min]]&/@Flatten[l]];
 If[!TrueQ[order>=0],tangentialEndpointFail["BoundarySystemOverlapNeedsHigherNormalJets"]];
 basis=cancel[(l/.r->0).(boundary["NormalizedLeadingVectorEmbedding"]/.ts->t)];
 gamma=cancel[(boundary["ConnectionMatrix"]/.ts->t)+a lambda IdentityMatrix[m]/t];
 If[!tangentialEndpointZeroQ[D[basis,t]+basis.gamma-target["TangentialConnectionMatrix"].basis]||
  !tangentialEndpointZeroQ[target["NormalResidue"].basis-lambda basis],
  tangentialEndpointFail["TransferredBoundarySubspaceMismatch"]];
 prep=FeynFacet`PrepareSingularBoundarySystem[<|"Variable"->t,"DimensionalRegulator"->e,"ConnectionMatrix"->gamma|>];
 If[FailureQ[prep],Throw[prep,"TangentialEndpoint"]];
 k=cancel[prep["OriginalToNormalizedGauge"].(boundary["CornerPreparation"]["NormalizedToOriginalGauge"]/.ts->t)];
 order=Min[If[#===0,Infinity,Exponent[Numerator[#],t,Min]-Exponent[Denominator[#],t,Min]]&/@Flatten[k]];
 If[!TrueQ[order>=0],tangentialEndpointFail["TransferredBoundarySeedComparisonNotRegular"]];
 seed=cancel[(k/.t->0).boundary["CornerSeedMatrix"]];
 residue=cancel[t prep["NormalizedDifferentialSystem"]["ConnectionMatrix"]]/.t->0;
 If[!tangentialEndpointZeroQ[residue.seed-beta seed],tangentialEndpointFail["TransferredBoundarySeedResidueMismatch"]];
 Join[boundary,<|"NormalVariable"->r,"TangentialVariable"->t,"TangentialBoundaryExponent"->beta,
  "NormalizedLeadingVectorEmbedding"->basis,"ConnectionMatrix"->gamma,"CornerPreparation"->prep,
  "CornerSeedMatrix"->seed,"BoundaryFunctionArgumentRules"->{},
  "Overlap"-><|"NormalUnitPower"->a,"TangentialCoordinateUnchanged"->True,"GaugeComparison"->l|>,
  "Verification"-><|"ExactFullConnectionComparison"->True,"ExactInvariantBoundarySubspace"->True,
   "ExactRegulatorScalarShift"->True,"ExactPhysicalCornerSeed"->True|>|>]
],"TangentialEndpoint"];


ConstructPhysicalEndpointBoundarySystem[data_Association]:=Module[{endpoint,system,e,z,sigma,basis,gamma},
 If[Lookup[data,"Status",None]=!="OrderedPhysicalBoundaryValuesDetermined",
  Return[Failure["CompleteOrderedPhysicalBoundaryRequired",<||>]]];
 endpoint=data["NormalEndpointSystem"];system=data["PhysicalTangentialSystem"];
 {e,z,sigma}=Lookup[data,{"DimensionalRegulator","MeasurementVariable","MeasurementEndpointVariable"}];
 basis=data["PhysicalNormalSeedMatrix"];gamma=First[system["ConnectionMatrices"]];
 If[!tangentialEndpointZeroQ[D[basis,z]+basis.gamma-endpoint["TangentialConnectionMatrix"].basis]||
  !tangentialEndpointZeroQ[endpoint["NormalResidue"].basis-data["PhysicalRecoilExponent"]basis],
  Return[Failure["OrderedBoundarySubspaceEquationsNotSatisfied",<||>]]];
 <|"DataType"->"PhysicalEndpointBoundarySystem","Status"->"PhysicalEndpointBoundarySystemConstructed",
 "NormalVariable"->data["RecoilVariable"],"TangentialVariable"->z,"DimensionalRegulator"->e,
 "MasterIntegralBasis"->data["MasterIntegralBasis"],"NormalExponent"->data["PhysicalRecoilExponent"],
 "NormalizedLeadingVectorEmbedding"->basis,"ConnectionMatrix"->gamma,
 "BoundaryFunctionCount"->Length[gamma],"BoundaryConstantCount"->data["BoundaryConstantCount"],
 "CornerPreparation"->data["CornerPreparation"],"CornerSeedMatrix"->data["CornerBoundaryValues"]["NormalizedSeedMatrix"],
 "InitialConstantValues"->data["CornerBoundaryValues"]["InitialConstantValues"],
 "BoundaryFunctionArgumentRules"->{sigma->1-z},
 "Verification"-><|"ExactInvariantBoundarySubspace"->True,"ExactPhysicalCornerSeed"->True|>|>
];

End[];EndPackage[];
