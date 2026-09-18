Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
base=root<>"/Projects/EE_EEC";
(* Independent direct checks are generated from the cards. They are not
   prerequisites left by an earlier interactive session. *)
Do[checkCard=FeynFacet`ReadContributionCard[base<>"/Raw/"<>entry[[1]]<>"/q-qb",entry[[2]]];
 checkPrepared=FeynFacet`PrepareMeasuredCurrentContribution[checkCard,"resume"];
 checkResult=FeynFacet`CheckMeasuredContributionInterior[checkCard,checkPrepared];
 If[!AssociationQ[checkResult],Print[InputForm[checkResult]];Exit[1]],
 {entry,{{"LO","Born"},{"NLO","Real"}}}];
born=FeynFacet`FamilyArtifactRead[base<>"/Raw/LO/q-qb/Born/Work/DirectIntegration.wl"];
real=FeynFacet`FamilyArtifactRead[base<>"/Raw/NLO/q-qb/Real/Work/DirectIntegration.wl"];
de=FeynFacet`FamilyArtifactRead[base<>"/Raw/NLO/q-qb/Real/Work/DifferentialSystem.wl"];
prepared=FeynFacet`FamilyArtifactRead[base<>"/Raw/NLO/q-qb/Real/Work/MeasuredIntegrands.wl"];
FTTest`FTAssert["the Born, radiative and native DE artifacts exist",AllTrue[{born,real,de,prepared},AssociationQ]];
If[!AllTrue[{born,real,de,prepared},AssociationQ],FTTest`FTReport[]];
norm=Total[Lookup[Values[born["ContactIntegrals"]],"Value"]];
FTTest`FTAssert["the generated Born spectrum has both half-weight contacts",
 AllTrue[Values[born["ContactIntegrals"]],Cancel[#["Value"]/norm]===1/2&]&&
 Sort[Flatten[(Lookup[#["ContactMeasurements"],"Observable"]&/@Values[born["ContactIntegrals"]])]]==={0,1}];
actual=Factor[real["InteriorExpression"]/(norm/.Global`Epsilon->0)];
(* Independent reference: Eq. (3) of arXiv:1801.03219v2, multiplied by
   |d cos(chi)/dz|=2. This formula is never loaded by production. *)
reference=FeynFacet`\[Alpha]s/(2Pi)FeynCalc`CF (3-2z)/(2(1-z)z^5)*
 (3z(2-3z)+2(2z^2-6z+3)Log[1-z]);
FTTest`FTAssert["generated tree-level EEC agrees exactly with the published interior coefficient",
 Factor[actual-reference]===0];
sys=de["DifferentialSystem"];families=sys["Families"];masters=sys["MasterIntegralBasis"];
values=Table[
 family=SelectFirst[families,#["Topology"][[1]]===master[[1]]&];
 row=SelectFirst[Values[prepared["NoncontactTerms"]],MemberQ[
   First[#["Topology"]]&/@#["Decomposition"]["Families"],master[[1]]]&];
 order=DeleteDuplicates[Flatten[row["ParticleTuples"][[1]]]];
 order=Join[order,Complement[Range[3],order]];
 slots=family["CutIndices"];ordinary=Complement[Range[Length[master[[2]]]],slots];
 pure=FeynFacet`CreateCutIntegralDefinition[Join[family,<|
   "Topology"->ReplacePart[family["Topology"],2->family["Topology"][[2,slots]]],
   "MeasurementNumerator"->1|>]];
 integrand=Times@@(family["InversePropagators"][[#]]^-master[[2,#]]&/@ordinary);
 one=FeynFacet`PrepareCutIntegrand[integrand,pure,<|"ExternalKinematicConditions"->Q2>0|>];
 If[!AssociationQ[one],Print[InputForm[one]];FTTest`FTReport[]];
 direct=FeynFacet`EvaluateThreeParticleMeasurementInterior[one,<|"ParticleOrder"->order,
   "Assumptions"->Q2>0&&0<z<1|>];
 If[!AssociationQ[direct],Print[InputForm[direct]];FTTest`FTReport[]];
 direct["Value"],{master,masters}];
residual=FullSimplify[D[values,z]-(Normal[First[sys["ConnectionMatrices"]]]/.D->4).values,0<z<1&&Q2>0];
FTTest`FTAssert["every physical native-cut master satisfies its generated DE in four dimensions",AllTrue[residual,#===0&]];
solution=FeynFacet`FamilyArtifactRead[base<>"/Raw/NLO/q-qb/Real/Work/MasterValues.wl"];
FTTest`FTAssert["all six masters have explicit exact-regulator physical values",AssociationQ[solution]&&
 solution["ExactInRegulator"]===True&&FreeQ[solution["Values"],_Integrate|_Inactive|_Failure|_Missing]];
exactValues=solution["Values"];
exactResidual=D[exactValues,z]-(Normal[First[sys["ConnectionMatrices"]]]/.D->4-2Global`Epsilon).exactValues;
points={{Q2->2,z->1/3,Global`Epsilon->-2/5},{Q2->3,z->2/5,Global`Epsilon->-3/7},{Q2->5,z->3/7,Global`Epsilon->-1/4}};
FTTest`FTAssert["exact-regulator physical masters satisfy the DE at independent rational points",
 AllTrue[points,Max[Abs[N[D[exactValues,z]/.#,55]-N[(Normal[First[sys["ConnectionMatrices"]]]/.D->4-2Global`Epsilon)/.#,55].N[exactValues/.#,55]]]<10^-45&]];
reconstructed=Total[Flatten[KeyValueMap[#2 #1&,#]&/@Values[de["IntegralDecomposition"]["Coefficients"]]]];
reconstructed=reconstructed/.Dispatch[sys["Reduction"]["Rules"]]/.Thread[masters->exactValues]/.D->4-2Global`Epsilon;
expanded=FeynFacet`ExpandGaussHypergeometricCombinations[<|"Scalar"->reconstructed|>,Global`Epsilon,{0,0}];
FTTest`FTAssert["the shared epsilon planner expands through spurious reduction poles",AssociationQ[expanded]];
If[!AssociationQ[expanded],Print[InputForm[expanded]];FTTest`FTReport[]];
finite=expanded["Coefficients"][{1,0}];
FTTest`FTAssert["exact master solutions reconstruct the independently integrated physical spectrum",
 FullSimplify[finite-real["InteriorExpression"],Q2>0&&muR2>0&&0<z<1]===0];
report=<|"PublishedReference"->"https://arxiv.org/abs/1801.03219","Equation"->3,
 "DensityConversion"->"dSigma/dz = 2 dSigma/dcos(chi)","NormalizedInteriorCoefficient"->Factor[actual],
 "BornNormalization"->norm,"NativeMasterCount"->Length[masters],
 "ExactInteriorReferenceResidual"->Factor[actual-reference],"MasterDEResidual"->residual,
 "EndpointInclusiveRadiativeResultVerified"->False,"AlphaSquaredEECComputed"->False|>;
FeynFacet`FamilyArtifactWrite[report,root<>"/Reports/2026-09-17/QuadraticMeasurements/EECVerification.wl"];
Print["EEC CARD WORKFLOW TEST COMPLETE"];
FTTest`FTReport[];
