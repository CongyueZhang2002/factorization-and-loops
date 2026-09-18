Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;

base=root<>"/Projects/EE_EEC";e=Global`Epsilon;
result=FeynFacet`ReadPartonicResult[base<>"/Results/NLO/q-qb/Results.wl"];
FTTest`FTAssert["the endpoint-inclusive result uses the common reader",AssociationQ[result]];
If[!AssociationQ[result],Print[InputForm[result]];FTTest`FTReport[]];
factor=FeynFacet`\[Alpha]s FeynCalc`CF/(2Pi);
row=result["Coefficients"][0];
(* Independent reference: arXiv:1905.01310, Eq.21. Its alpha_s/(4 pi)
   coefficient is converted to alpha_s/(2 pi); hq+hg+jq/2=13 CF/24.
   The reference is confined to this test file. *)
regular=(-9z^4-6z^3-42z^2+36z+4(-z^4-z^3+3z^2-15z+9)Log[1-z])/(4z^5);
expected=<|"DeltaCoefficients"-><|0->13/48,1->-2-Pi^2/6|>,
 "PlusCoefficients"-><|0-><|0->3/4|>,1-><|0->-3/2,1->-1|>|>,"RegularCoefficient"->regular|>;
actual=FeynFacet`Private`partonicMap[FullSimplify[#/factor,Q2>0&&muR2>0&&0<z<1]&,row];
FTTest`FTAssert["the self/collinear endpoint agrees exactly with the independent reference",actual["DeltaCoefficients"][0]===expected["DeltaCoefficients"][0]];
FTTest`FTAssert["the back-to-back endpoint agrees exactly with the independent reference",actual["DeltaCoefficients"][1]===expected["DeltaCoefficients"][1]];
FTTest`FTAssert["both endpoints' logarithmic-plus coefficients agree",Map[KeySort,actual["PlusCoefficients"]]===Map[KeySort,expected["PlusCoefficients"]]];
FTTest`FTAssert["the complete regular coefficient agrees as an analytic identity",Factor[actual["RegularCoefficient"]-regular]===0];
rawReal=FeynFacet`ReadPartonicResult[base<>"/Raw/NLO/q-qb/Real/Results.wl"];
rawVirtual=FeynFacet`ReadPartonicResult[base<>"/Raw/NLO/q-qb/Virtual/Results.wl"];
combined=FeynFacet`CombinePartonicResults[<|"Real"->rawReal,"Virtual"->rawVirtual|>,<|"Contribution"->"Sum"|>];
FTTest`FTAssert["raw real and virtual keep poles; their common sum cancels both poles",AssociationQ[combined]&&
 !FeynFacet`Private`partonicZeroTreeQ[rawVirtual["Coefficients"][-2]]&&
 AllTrue[Values[KeySelect[combined["Coefficients"],#<0&]],
 FeynFacet`Private`partonicZeroTreeQ[FeynFacet`Private`partonicMap[FullSimplify[#,Q2>0&&muR2>0]&,#]]&]];
endpoints=FeynFacet`FamilyArtifactRead[base<>"/Raw/NLO/q-qb/Real/Work/EndpointExpansion.wl"];
FTTest`FTAssert["regulator-exact endpoint series excludes delta derivatives",
 AllTrue[endpoints["EndpointSeries"]["Scalar"],#["MaxContactDerivativeOrder"]===0&&#["RemainderLocallyIntegrable"]&]];
born=FeynFacet`ReadPartonicResult[base<>"/Raw/LO/q-qb/Born/Results.wl"];
norm=result["GeneratedBornNormalization"];
FTTest`FTAssert["the two Born endpoints each carry weight one half",
 Values[born["Coefficients"][0]["DeltaCoefficients"]]/norm==={1/2,1/2}];
(* Inclusive integral independently removes the measurement at source,
   then uses the full-D normalized Dirichlet measure. *)
source=FeynFacet`FamilyArtifactRead[base<>"/Raw/NLO/q-qb/Real/Work/Integrands.wl"];
card=FeynFacet`ReadContributionCard[base<>"/Raw/NLO/q-qb","Real"];
geometry=Join[card["Assembly"]["PhaseSpace"],<|"Name"->eecInclusiveCheck,"FinalMomenta"->{k1,k2,k3}|>];
definition=FeynFacet`CreateMasslessPhaseSpaceDefinition[geometry];
integrand=FeynFacet`SubstituteScalarPowers[source["Values"]["Scalar"],card["Assembly"]["BareCouplingRules"]];
prepared=FeynFacet`PrepareCutIntegrand[integrand,definition,<|"ExternalKinematicConditions"->Q2>0|>];
inclusive=FeynFacet`IntegrateMasslessInvariantMoments[prepared,e];
FTTest`FTAssert["the inclusive amplitude integral is computed independently of angular masters",AssociationQ[inclusive]];
If[!AssociationQ[inclusive],Print[InputForm[inclusive]];FTTest`FTReport[]];
virtual=FeynFacet`FamilyArtifactRead[base<>"/Raw/NLO/q-qb/Virtual/Work/VirtualIntegration.wl"];
inclusiveValue=FullSimplify[Normal[Series[(inclusive["Value"]+Total[Lookup[Values[virtual["ContactIntegrals"]],"Value"]])/norm,{e,0,0}]],Q2>0&&muR2>0];
moment0=FeynFacet`UnitIntervalDistributionMoment[actual,z,0];
moment1=FeynFacet`UnitIntervalDistributionMoment[actual,z,1];
FTTest`FTAssert["zeroth moment equals the independently generated inclusive NLO rate",FullSimplify[factor moment0-inclusiveValue]===0&&moment0===3/2];
FTTest`FTAssert["first moment equals half the independently generated inclusive rate",FullSimplify[factor moment1-inclusiveValue/2]===0&&moment1===3/4];
(* Numeric bin wholly in the interior, independent adaptive quadrature
   of the paper's formula versus the reconstructed master coefficient. *)
interior=FeynFacet`PartonicResultInteriorCoefficients[result];
FTTest`FTAssert["common interior restriction preserves both endpoint plus densities",AssociationQ[interior]&&
 FullSimplify[interior["Coefficients"][0]/factor-
 (3-2z)/(2(1-z)z^5)*(3z(2-3z)+2(2z^2-6z+3)Log[1-z]),0<z<1]===0];
flat=FeynFacet`PartonicScalarCoefficientRules[result];
FTTest`FTAssert["scalar flattening preserves both endpoint labels",AssociationQ[flat]&&Length[flat]===6];
FTTest`FTAssert["the saved result has no unresolved integral or Laurent operation",
 FreeQ[result["Coefficients"],_Integrate|_Inactive|_FeynCalc`GLI|_Hypergeometric2F1|_Series|_SeriesData|_Failure|_Missing]];
FeynFacet`FamilyArtifactWrite[<|"Reference"->"https://arxiv.org/abs/1905.01310","Equation"->21,
 "ReferenceConvention"->"Converted from alpha_s/(4 pi) to alpha_s/(2 pi), sigma0 normalization",
 "EndpointInclusive"->True,"NativeMasterCount"->6,"PoleResiduals"->result["PoleCancellationResiduals"],
 "ZerothMoment"->moment0,"FirstMoment"->moment1,"IndependentInclusiveCorrection"->inclusiveValue,
 "ActualCorrectionDividedByAlphaCFOver2Pi"->actual|>,root<>"/Reports/2026-09-17/QuadraticMeasurements/FullEECVerification.wl"];
Print["FULL EEC VERIFICATION COMPLETE"];FTTest`FTReport[];
