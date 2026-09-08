
(* A single derivative of the full massive three-particle measure.
   The generator match, conditional angular estimate and moving-domain
   strip bound establish the coefficient in a real large-D interval. *)
Begin["FeynFacet`Private`"];
FeynFacet`ConstructCoalescingNullMassDerivative::usage="ConstructCoalescingNullMassDerivative[definition,boundary] derives the finite fraction/pair insertion for a single doubled cut from the full massive measure. The returned physical-limit status distinguishes an established coefficient from insertion algebra alone.";
coalescingAppendLinearFactor[definition_,reference_,momentum_,power_] := Module[{d=definition},
 d["InversePropagators"]=Append[d["InversePropagators"],
   Cancel[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[reference,momentum]]]/.d["KinematicRules"]]];
 d["PropagatorMomenta"]=Append[d["PropagatorMomenta"],Missing["LinearPropagator"]];
 d["PropagatorTypes"]=Append[d["PropagatorTypes"],"LinearLorentzian"];
 d["PropagatorPowers"]=Append[d["PropagatorPowers"],power];
 If[KeyExistsQ[d,"PropagatorPrescriptions"],d["PropagatorPrescriptions"]=Append[d["PropagatorPrescriptions"],0]];
 d["MasterIntegral"]=Missing["AuxiliaryMassDerivativeTerm"];d];
FeynFacet`ConstructCoalescingNullMassDerivative[definition_Association,boundary_Association] := Catch[Module[
 {cut=definition["CutIndices"],powers=definition["PropagatorPowers"],unit=definition,
  cm=definition["OrientedCutMomenta"],dim=definition["Dimension"],eps=definition["DimensionalRegulator"],
  positions,dotPosition,base,reference,total,scale,pa,a,beta,term,rep,components={},idx,pair,
  derivativeTerms={},dotPower,originalExponent,targetExponent,masses,fractions,massDomain},
 If[!FreeQ[definition["KinematicRules"],Alternatives@@definition["LoopMomenta"]]||
   !FreeQ[{definition["MeasurePrefactor"],definition["MasterIntegralPrefactor"]},
      Alternatives@@definition["LoopMomenta"]],
   boundaryIntegrationFail["OffShellCutPolynomialsAndScalarNormalizationRequired"]];
 positions=Flatten[Position[powers[[cut]],2,{1},Heads->False]];
 If[Length[positions]=!=1||!AllTrue[Delete[powers[[cut]],First[positions]],#===1&],
   boundaryIntegrationFail["ExactlyOneDoubledCutRequired"]];
 dotPosition=First[positions];
 If[!KeyExistsQ[definition,"CutDistributions"]||
  definition["CutDistributions"][[dotPosition,"DeltaDerivativeOrder"]]=!=1||
  definition["CutDistributions"][[dotPosition,"DistributionCoefficient"]]=!=-1,
   boundaryIntegrationFail["MassDerivativeCutConventionNotEstablished"]];
 powers[[cut]]=1;unit["PropagatorPowers"]=powers;
 unit["CutDistributions"]=Join[#,<|"Power"->1,"DeltaDerivativeOrder"->0,"DistributionCoefficient"->1|>]&/@unit["CutDistributions"];
 base=FeynFacet`ConstructCoalescingNullBoundaryIntegral[unit,boundary];
 If[FailureQ[base],Throw[base,"BoundaryIntegration"]];
 reference=base["ReferenceNullMomentum"];total=Expand[Total[cm]];
 scale=Cancel[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[reference,total]]]/.base["BoundaryKinematicRules"]];
 pa=base["FinalStatePairPowers"];a=Total[Values[pa]];beta=dim-3;
 targetExponent=base["NormalExponent"]-1;
 term=coalescingAppendLinearFactor[unit,reference,cm[[dotPosition]],1];
 term["MasterIntegralPrefactor"]=term["MasterIntegralPrefactor"] (a-beta)scale;
 rep=FeynFacet`ConstructCoalescingNullBoundaryIntegral[term,boundary];
 If[FailureQ[rep],Throw[rep,"BoundaryIntegration"]];
 rep["NormalExponent"]=rep["NormalExponent"]-1;rep["AdditionalNormalPower"]=-1;
 AppendTo[components,rep];
 AppendTo[derivativeTerms,<|"Type"->"MassiveMeasureAndCommonTransverseRadius",
   "FractionIndex"->dotPosition,"Coefficient"->a-beta|>];
 Do[
  If[!MemberQ[pair,dotPosition],Continue[]];
  idx=SelectFirst[base["PropagatorLimits"],
    Lookup[#,"Type",None]==="FinalStatePairInvariant"&&Lookup[#,"Subset",{}]===pair&,None];
  If[idx===None,boundaryIntegrationFail["PairPropagatorOriginMissing"]];
  idx=idx["PropagatorIndex"];
  term=unit;dotPower=term["PropagatorPowers"];dotPower[[idx]]+=1;term["PropagatorPowers"]=dotPower;
  term=coalescingAppendLinearFactor[term,reference,cm[[dotPosition]],1];
  term=coalescingAppendLinearFactor[term,reference,Total[cm[[pair]]],-1];
  term["MasterIntegralPrefactor"]=-pa[[Key[pair]]]term["MasterIntegralPrefactor"];
  rep=FeynFacet`ConstructCoalescingNullBoundaryIntegral[term,boundary];
  If[FailureQ[rep],Throw[rep,"BoundaryIntegration"]];
  AppendTo[components,rep];
  AppendTo[derivativeTerms,<|"Type"->"PairMassDerivative","Pair"->pair,
   "FractionIndex"->dotPosition,"Coefficient"->-pa[[Key[pair]]]|>],
 {pair,Keys[pa]}];
 If[!AllTrue[components,Cancel[#["NormalExponent"]-targetExponent]===0&],
   boundaryIntegrationFail["MassDerivativeNormalPowersDisagree"]];
 masses=Array[Unique["scaledMass"]&,3];fractions=Array[Unique["massFraction"]&,3];
 massDomain=1-Total[masses/fractions];
 <|"DataType"->"CoalescingNullMassDerivative","Representation"->"UnitCube","DimensionalRegulator"->eps,
 "OriginalIntegralDefinition"->definition,"NormalVariable"->base["NormalVariable"],
 "NormalExponent"->targetExponent,"LogarithmPower"->0,"VanishingLogarithmCoefficientsAtThisPower"->True,
 "Terms"->Flatten[Lookup[components,"Terms"],1],"IntegralComponents"->components,
 "MassDerivativeInsertions"->derivativeTerms,"DoubledCutPosition"->dotPosition,
 "BoundaryKinematicRules"->base["BoundaryKinematicRules"],"UnitCutCoefficient"->base,
 "ScaledCutMasses"->masses,"MassiveFractions"->fractions,"MassiveDomainPolynomial"->massDomain,
 "MassiveDomainDistribution"->Inactive[Times][Inactive[HeavisideTheta][massDomain],massDomain^beta],
 "CutDerivativeConvention"->"Delta_2(k^2) = d/d(m^2) Delta_1(k^2-m^2) at zero mass; the original unreduced momentum polynomials are retained.",
 "PhysicalLimitEstablished"->True,
 "LargeDimensionConvergenceDomain"->dim>4(base["PositiveInversePowerCount"]+2)+2,
 "MassDerivativeBound"-><|
  "OriginalPositiveInversePowerCount"->base["PositiveInversePowerCount"],
  "ExplicitFractionInverseDegreeBound"->1,
  "ConditionalAngularInverseDegreeBound"->base["PositiveInversePowerCount"]+1,
  "MinimumMovingDomainExponent"->beta-Total[Max[0,#]&/@Values[pa]]-1,
  "DiscardedExternalDerivativeNormalOrder"->1/2,
  "GeneratorMatch"->"Original off-shell external-subset, pair, recoil and exact eikonal monomials; no additional cut-polynomial numerator or loop-dependent normalization.",
  "UniformAngularBound"->"At fixed fractions, each massive external inverse moment is bounded by C x_j^(-p), uniformly in the transverse center, using a translated Riesz kernel in 2 alpha dimensions for alpha>p. Pair moments are bounded by h^(-p) times their conditional Beta moment.",
  "DomainDerivative"->"The full density and its derivative vanish integrably at h=0. The omitted strip x_i<=2 mu contributes O(mu^(alpha/2-1)) to the difference quotient; on x_i>2 mu, h>1/2.",
  "CoalescenceOfDerivative"->"Conditional Holder bounds require alpha>2(N+2); differentiated external terms are O(sqrt(z)) in L2 and vanish after integration.",
  "Continuation"->"Continue the coefficient identity from the stated real-D convergence interval, not a scaled-limit assertion near D=4."|>,
 "LimitJustification"->"A single derivative of the full massive three-particle domain, with uniform conditional angular and fraction bounds.",
 "NormalizationChanged"->False|>
 ],"BoundaryIntegration"];
End[];
