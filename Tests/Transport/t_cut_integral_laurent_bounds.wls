#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];
Clear[kl,ll,pp,ee,qq,rr,cutTestFamily];
threeTop=FeynCalc`FCTopology[cutTestFamily,
 {FeynCalc`SFAD[kl],FeynCalc`SFAD[ll],FeynCalc`SFAD[pp-kl-ll]},
 {kl,ll},{pp},{FeynCalc`SPD[pp]->3},{}];
input=<|"Topology"->threeTop,"Master"->{FeynCalc`GLI[cutTestFamily,{1,1,2}],
 FeynCalc`GLI[cutTestFamily,{1,1,3}]},"CutIndices"->{1,2,3},
 "CutMomenta"->{kl,ll,pp-kl-ll},"Prescription"->{0,0},"DimensionalRegulator"->ee|>;
reps=ConstructMasterIntegralRepresentations[input]["MasterIntegralRepresentations"];
bound=DetermineIntegralLaurentBound[reps[1]];
FTAssert["unresolved three-body dots now have an automatic conservative bound",
 AssociationQ[bound] && IntegerQ[bound["LowerBound"]]];
FTAssert["cut normal derivatives do not count as additional integration variables",
 bound["RemainingIntegrationDimension"]===2 &&
 bound["CutIntegralTerms"]["NormalDerivativeOrder"]===1];
FTAssert["the geometric argument does not perform sector resolution",
 bound["SectorResolutionPerformed"]===False &&
 bound["IntegralValuesEvaluatedNumerically"]===False];
(* Evaluate the constructed normal derivative at a regular rational interior
   point and compare with direct differentiation before imposing the cuts. *)
rd=FeynFacet`Private`cutOrderReduceExternal[reps[2],
 FeynFacet`Private`cutOrderGeometry[reps[2]]];
nd=FeynFacet`Private`cutOrderNormalDerivatives[rd];
z=rd["IntegrationVariables"];cuts=rd["CutIndices"];
direct=D[rd["BaikovPolynomial"]^rd["BaikovExponent"],{z[[3]],2}]/2;
constructed=nd["Prefactor"] Total[(#["Numerator"] nd["Polynomial"]^#["Exponent"]& /@ nd["Terms"])];
sample=Thread[nd["IntegrationVariables"]->ConstantArray[1/2,2]];
FTAssert["repeated cut differentiation includes the factorial and every Gram term",
 FullSimplify[(constructed-rd["ParametricPrefactor"] (direct/.Thread[z[[cuts]]->0]))/.
 ee->-3/.sample]===0];
nonlinear=DetermineIntegralLaurentBound[Join[reps[1]/.ee->ee^2,<|"DimensionalRegulator"->ee|>]];
FTAssert["nonlinear dimension regulators multiply the possible pole order",
 nonlinear["RegulatorSlopeValuation"]===2 &&
 nonlinear["LowerBound"]===2bound["LowerBound"]];

actual=Get[FileNameJoin[{root,"Tests", "Fixtures", "DifferentialEquations", "Families","CF269","FamilyDLogEpsilonForm.wl"}]];
actualReps=ConstructMasterIntegralRepresentations[actual,<|"BasePoint"->{1/4,1/3}|>]["MasterIntegralRepresentations"];
g=FeynFacet`Private`cutOrderGeometry[actualReps[1]];
FTAssert["only fixed external null vectors may anchor the mass-deformed proof",
 Intersection[g["FixedNullRays"],Range[Length[actualReps[1]["CutIndices"]]]]==={}];
actualBounds=DetermineIntegralLaurentBound /@ actualReps;
FTAssert["all 23 actual cut-master bounds are derived without supplied assumptions",
 AllTrue[Values[actualBounds],AssociationQ] &&
 actualBounds[5]["LowerBound"]===0 && actualBounds[6]["LowerBound"]===-4];
FTAssert["inactive external directions are integrated out with a recomputed prefactor",
 actualBounds[6]["EffectiveExternalRank"]===2 &&
 actualBounds[6]["RemainingIntegrationDimension"]===4];

(* A massless uncut denominator which becomes an interior resonance cannot
   be certified merely by increasing dimension. *)
resonanceTop=FeynCalc`FCTopology[cutTestFamily,
 {FeynCalc`SFAD[kl],FeynCalc`SFAD[ll],FeynCalc`SFAD[pp-kl-ll],
  FeynCalc`SFAD[{kl+ll,1}]},{kl,ll},{pp},{FeynCalc`SPD[pp]->3},{}];
resonance=ConstructMasterIntegralRepresentations[Join[input,<|"Topology"->resonanceTop,
 "Master"->FeynCalc`GLI[cutTestFamily,{1,1,1,1}]|>]]["MasterIntegralRepresentations"][1];
failure=DetermineIntegralLaurentBound[resonance,"RegularityProofTimeLimit"->1];
FTAssert["an uncut interior massive resonance receives no high-dimensional bound",
 FailureQ[failure] && failure[[1]]==="CutPropagatorBoundaryContainmentNotEstablished"];
FTAssert["noncompact or threshold phase space is rejected",
 FailureQ[Catch[FeynFacet`Private`cutOrderGeometry[Join[reps[1],
  <|"TimeDirection"->-pp|>]],"EpsilonOrders"]]];

(* Genuine scalar products of future rays are certified in the deformed
   domain; identities holding only after setting cut squares to zero are not. *)
core=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[kl,ll]]];
g=FeynFacet`Private`cutOrderGeometry[reps[1]];
d=Join[reps[1],<|"InversePropagators"->Append[reps[1]["InversePropagators"],core]|>];
certificate=FeynFacet`Private`cutOrderBilinearCertificate[core,d,g];
FTAssert["literal causal scalar products have a rational certificate",
 AssociationQ[certificate]];
badCore=core+FeynCalc`FCI[FeynCalc`SPD[kl]];
FTAssert["on-shell equivalence alone does not certify the mass-deformed integrand",
 !AssociationQ[FeynFacet`Private`cutOrderBilinearCertificate[badCore,d,g]]];
FTReport[];
