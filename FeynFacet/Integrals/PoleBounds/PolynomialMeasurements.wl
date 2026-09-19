(* Conservative pole multiplicity of a polynomial-measurement distribution.
   A resolution theorem bounds the number of simultaneous Mellin poles; it
   does not supply resolved sectors, endpoint contacts or physical constants. *)
BeginPackage["FeynFacet`"];
DeterminePolynomialMeasurementLaurentBound::usage=
 "DeterminePolynomialMeasurementLaurentBound[family,integral,coordinates,request] verifies a supported complete algebraic parent measure, the bounded measurement map and its common causal convergence domain. It bounds the regulator-pole multiplicity of the original unit-cut distribution by the parent dimension plus the normalization pole order. It does not establish a scalar restriction, contact order or boundary values. Automatic coordinates select the measured pair from the actual cut.";
Begin["`Private`"];
polynomialPeriodAlgebraicQ[expression_,variables_,conditions_]:=Which[
 FreeQ[expression,Alternatives@@variables],normalizationFiniteConstantQ[expression,conditions],
 MemberQ[variables,expression],True,
 MemberQ[{Plus,Times},Head[expression]],AllTrue[List@@expression,polynomialPeriodAlgebraicQ[#,variables,conditions]&],
 Head[expression]===Power&&MatchQ[expression[[2]],_Integer|_Rational],
  polynomialPeriodAlgebraicQ[expression[[1]],variables,conditions],
 Head[expression]===Abs,polynomialPeriodAlgebraicQ[expression[[1]],variables,conditions],
 True,False];
polynomialPeriodAffinePowersQ[expression_,variables_,e_,conditions_]:=Which[
 FreeQ[expression,e],polynomialPeriodAlgebraicQ[expression,variables,conditions],
 MemberQ[{Plus,Times},Head[expression]],
  AllTrue[List@@expression,polynomialPeriodAffinePowersQ[#,variables,e,conditions]&],
 Head[expression]===Power&&FreeQ[expression[[1]],e]&&
   PolynomialQ[expression[[2]],e]&&Exponent[expression[[2]],e]<=1&&
   AllTrue[CoefficientList[expression[[2]],e],MatchQ[#,_Integer|_Rational]&],
  polynomialPeriodAlgebraicQ[expression[[1]],variables,conditions],
 True,False];
DeterminePolynomialMeasurementLaurentBound[input_Association,integral_FeynCalc`GLI,
 Automatic,request_Association]:=Catch[Module[{data,e=Lookup[request,"DimensionalRegulator",None]},
 If[!MatchQ[e,_Symbol],cutFamilyFail["PolynomialPeriodRegulatorRequired"]];
 data=pairMeasurementIntegralCharts[input,integral,e];
 DeterminePolynomialMeasurementLaurentBound[input,integral,First[data["Charts"]]["Coordinates"],request]
],"CutFamily"];
DeterminePolynomialMeasurementLaurentBound[input_Association,integral_FeynCalc`GLI,
 coordinates_Association,request_Association]:=Catch[Module[
 {e,conditions,canonical,moment,family,parameters,n,d,z,ordinary,powers,rules,
  density,normalization,normalFactors,dependent,verification,normalBound,cutNormalization},
 e=Lookup[request,"DimensionalRegulator",None];conditions=Lookup[request,"ExternalKinematicConditions",None];
 If[!MatchQ[e,_Symbol]||conditions===None||
   Lookup[coordinates,"Method",None]=!="TwoResolvedParticlesAndRecoilDecay",
  cutFamilyFail["SupportedAlgebraicParentCoordinatesRequired"]];
 (* Regenerate the declared physical chart. An arbitrary association with a
    dimension or convergence flag is not evidence for this theorem. *)
 canonical=FeynFacet`MasslessPairPhaseSpaceCoordinates[coordinates["FinalMomenta"],
   coordinates["TotalMomentum"],coordinates["Scale"],e,coordinates["Parameters"]];
 If[!AssociationQ[canonical]||
   KeyTake[canonical,{"Bounds","PhysicalDomain","ScalarProductRules","Density","Dimension"}]=!=
    KeyTake[coordinates,{"Bounds","PhysicalDomain","ScalarProductRules","Density","Dimension"}],
  cutFamilyFail["OriginalPhysicalParentChartRequired"]];
 moment=FeynFacet`ConstructPolynomialMeasurementMoment[input,integral,canonical,{0,0},0,request];
 If[!AssociationQ[moment],cutFamilyFail["PolynomialPeriodPhysicalGermNotEstablished",<|"Cause"->moment|>]];
 family=moment["MeasuredFamily"];parameters=canonical["Parameters"];
 n=Length[canonical["FinalMomenta"]];d=Length[parameters];z=moment["Variable"];
 If[d=!=Binomial[n,2]-1||canonical["Bounds"]=!=({#,0,1}&/@parameters),
  cutFamilyFail["IndependentCompactInvariantParentRequired"]];
 If[!FreeQ[Lookup[family,"MasterIntegralPrefactor",1],z],
  cutFamilyFail["MeasurementIndependentMasterNormalizationRequired"]];
 ordinary=Complement[Range[Length[integral[[2]]]],family["CutIndices"]];powers=integral[[2]];
 rules=canonical["ScalarProductRules"];
 cutNormalization=(family["MeasurePrefactor"]Lookup[family,"MasterIntegralPrefactor",1]/
   (2Pi)^(n-(n-1)D))/.D->4-2e;
 (* This is the ORIGINAL scalar unit-cut density paired with a test function,
    so 1/|F| remains. No moment numerator is inserted here. *)
 density=cutNormalization canonical["Density"] Times@@Table[
   Factor[family["InversePropagators"][[j]]/.rules]^(-powers[[j]]),{j,ordinary}]/
   Factor[moment["AbsoluteMeasurementSlope"]/.rules];
 density=density/.Beta[a_,b_]:>Gamma[a]Gamma[b]/Gamma[a+b];
 normalFactors=If[Head[density]===Times,List@@density,{density}];
 normalization=Times@@Select[normalFactors,FreeQ[#,Alternatives@@parameters]&];
 dependent=Times@@Select[normalFactors,!FreeQ[#,Alternatives@@parameters]&];
 verification=FeynFacet`VerifyMeromorphicNormalization[{normalization},e,conditions];
 If[!AssociationQ[verification],cutFamilyFail["PolynomialPeriodNormalizationNotEstablished",<|"Cause"->verification|>]];
 If[!FreeQ[dependent,_FeynCalc`Pair|_FeynCalc`Momentum|_FeynCalc`Eps]||
    !polynomialPeriodAffinePowersQ[dependent,parameters,e,conditions],
  cutFamilyFail["FixedAlgebraicFactorsAndAffineRegulatorPowersRequired"]];
 normalBound=FeynFacet`DetermineMeromorphicLaurentLowerBound[normalization,e];
 If[!IntegerQ[normalBound],cutFamilyFail["FiniteNormalizationPoleBudgetRequired"]];
 <|"Format"->"FeynFacet-PolynomialMeasurementDistributionLaurentBound",
  "OriginalFamily"->family,"OriginalIntegral"->integral,"DimensionalRegulator"->e,
  "Variable"->z,"ParameterConditions"->conditions,"ParentDimension"->d,
  "PhysicalChart"->canonical,"OriginalParentDensity"->density,
  "OriginalUnitCutJacobian"->1/moment["AbsoluteMeasurementSlope"],
  "MeasurementMap"->moment["PhysicalObservable"],"MeasurementSupport"->{0,1},
  "PhysicalMomentConstruction"->moment,"Normalization"->normalization,
  "NormalizationVerification"->verification,"NormalizationLaurentLowerBound"->normalBound,
  "DistributionLaurentLowerBound"->normalBound-d,
  "FixedAlgebraicFactorsAndAffinePowersVerified"->True,
  "ResolvedChartsConstructed"->False,"ScalarRestrictionEstablished"->False,
  "EndpointContactOrderEstablished"->False,"PhysicalBoundaryConstantsFixed"->False,
  "Theorem"->"Simultaneously resolve the original density and the bounded rational measurement map (actual physical graph closure, not the entire cut equation). The proper graph resolution preserves parent dimension. Each resolved coordinate contributes at most one simple regulator pole; smooth test functions of the lifted map obey finite seminorm bounds. The common causal convergence germ fixes the continuation.",
  "MathematicalReference"->"https://arxiv.org/abs/1002.4589",
  "Scope"->"Regulator-pole multiplicity of the original unit-cut distribution. A compatible smooth-meromorphic DE restriction is needed for scalar initial values. No endpoint contact order, sectors, constants or coefficient values are inferred."|>
],"CutFamily"];
DeterminePolynomialMeasurementLaurentBound[___]:=Failure["TypedPolynomialPeriodBoundArgumentsRequired",<||>];
End[];EndPackage[];
