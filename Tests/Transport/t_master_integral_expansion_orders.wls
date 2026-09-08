#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]];
Clear[xx,yy,uu,vv,ee,aa,bb];
cube[power_,pref_:1] := <|"Representation"->"UnitCube","Terms"->{
 <|"IntegrationVariables"->{uu},"EndpointPowers"->{power},"Prefactor"->pref|>}|>;
overlap=<|"Representation"->"UnitCube","Terms"->{
 <|"IntegrationVariables"->{uu,vv},"PolynomialFactors"->{
   <|"Polynomial"->uu+vv,"Exponent"->-2-ee|>},"Prefactor"->Gamma[ee]|>}|>;
bound[d_] := DetermineIntegralLaurentBound[Join[d,<|"DimensionalRegulator"->ee|>]];
o=bound[overlap];
FTAssert["overlapping endpoints are resolved without numerical integration",
 o["LowerBound"]===-2 && o["SectorCount"]===2 &&
 o["IntegralValuesEvaluatedNumerically"]===False];
FTAssert["sector Jacobian is included in the endpoint powers",
 Lookup[o["ResolvedTerms"],"EndpointPowers"]==={{-1-ee,0},{0,-1-ee}}];
mixed=bound[<|"Representation"->"UnitCube","Terms"->{
 <|"IntegrationVariables"->{uu,vv},"PolynomialFactors"->{
   <|"Polynomial"->uu/2+vv/2-uu vv/4,"Exponent"->-2-ee|>}|>}|>];
FTAssert["positive mixed-coefficient endpoint polynomial is resolved",
 AssociationQ[mixed] && mixed["LowerBound"]===-1 && mixed["SectorCount"]===2];
interiorZero=bound[<|"Representation"->"UnitCube","Terms"->{
 <|"IntegrationVariables"->{uu,vv},"PolynomialFactors"->{
   <|"Polynomial"->(uu-1/2)^2+(vv-1/2)^2,"Exponent"->-1-ee|>}|>}|>];
FTAssert["nonnegative polynomial with an interior zero is rejected",FailureQ[interiorZero]];
logOverlap=overlap;logOverlap["Terms"]={Join[First[overlap["Terms"]],<|"LogPowers"->{1,0}|>]};
o=bound[logOverlap];
FTAssert["logarithms follow sector coordinate substitutions",
 o["LowerBound"]===-3 && o["SectorCount"]===3];
beta=bound[<|"Representation"->"UnitCube","Terms"->{
 <|"IntegrationVariables"->{uu},"EndpointPowers"->{-1-ee},
 "UpperEndpointPowers"->{-1-ee}|>}|>];
FTAssert["opposite endpoints give a simple beta-function pole",
 beta["LowerBound"]===-1 && beta["SectorCount"]===2];
exactBeta=Series[Gamma[-ee]^2/Gamma[-2ee],{ee,0,0}];
FTAssert["beta endpoint bound agrees with its independently known integral",
 exactBeta[[4]]===-1];
rational=bound[<|"Representation"->"UnitCube","Terms"->{
 <|"IntegrationVariables"->{uu,vv},"EndpointPowers"->{-ee,0},
   "RegularFactor"->1/(uu+vv)^2|>}|>];
FTAssert["a singular rational denominator is converted to polynomial factors",
 rational["LowerBound"]===-1];
bad=bound[<|"Representation"->"UnitCube","Terms"->{
 <|"IntegrationVariables"->{uu},"PolynomialFactors"->{
  <|"Polynomial"->uu-1/2,"Exponent"->-1-ee|>}|>}|>];
FTAssert["an unresolved interior singularity does not receive a pole bound",FailureQ[bad]];
FTAssert["sector limit returns failure instead of a partial bound",
 FailureQ[DetermineIntegralLaurentBound[Join[overlap,<|"DimensionalRegulator"->ee|>],"MaximumSectors"->1]]];
vacuum=<|"Representation"->"FeynmanParameters","FeynmanParameters"->{aa},
 "PropagatorPowers"->{2},"LoopCount"->1,"SymanzikPolynomials"->{aa,xx aa^2},
 "NormalizationPrefactor"->1|>;
vbound=bound[vacuum/.xx->1/4];
FTAssert["Feynman parameter normalization supplies the ultraviolet Gamma pole",
 vbound["LowerBound"]===-1 && vbound["ResolvedTerms"][[1,"IntegrationVariables"]]==={}];
FTAssert["a regulator normalization zero cancels the ultraviolet pole",
 bound[Join[vacuum/.xx->1/4,<|"NormalizationPrefactor"->ee|>]]["LowerBound"]===0];
bubble=<|"Representation"->"FeynmanParameters","FeynmanParameters"->{aa,bb},
 "PropagatorPowers"->{1,1},"LoopCount"->1,
 "SymanzikPolynomials"->{aa+bb,(aa+bb)^2+3aa bb},"NormalizationPrefactor"->1|>;
FTAssert["simplex primary sectors retain the correct normalization",
 bound[bubble]["SectorCount"]===2 && bound[bubble]["LowerBound"]===-1];
FTAssert["incorrect Symanzik homogeneity is rejected",
 FailureQ[bound[Join[bubble,<|"SymanzikPolynomials"->{aa+bb,aa+bb}|>]]]];
FTAssert["uncut Feynman parameter formula cannot be applied to a cut propagator",
 FailureQ[bound[Join[bubble,<|"CutPropagators"->{1}|>]]]];

sys=<|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,"ConnectionMatrices"->{{{-ee/xx}}}|>;
req=<|"BasePoint"->{1/4},"RequestedMasterIntegralOrderRanges"-><|1->{-1,0}|>,
 "MasterIntegralRepresentations"-><|1->vacuum|>|>;
originalReq=req;
ordinary=DetermineMasterIntegralExpansionOrders[sys,req];
FTAssert["normalization is fixed in the original master basis",
 ordinary["BoundaryNormalization"]["Type"]==="OrdinaryPoint" &&
 ordinary["BasePoint"]==={1/4} && req===originalReq];
FTAssert["requested master range derives evolution and boundary orders from its integral",
 ordinary["OrdinaryPointConstantLowerBounds"]==={-1} &&
 ordinary["FundamentalMatrixEpsilonOrders"]["MaximumTransformedOrder"]===1 &&
 ordinary["BoundaryCoefficientOrders"][[1,"RequiredOrders"]]==={-1,0}];
FTAssert["no boundary value or global evolution was computed",
 ordinary["GlobalEvolutionComputed"]===False && ordinary["BoundaryCoefficientsEvaluated"]===False];
auto=DetermineMasterIntegralExpansionOrders[sys,KeyDrop[req,"BasePoint"]];
FTAssert["an ordinary rational base point can be selected automatically",
 auto["BasePoint"]==={1/4}];
negative=DetermineMasterIntegralExpansionOrders[
 <|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,"ConnectionMatrices"->{{{ee}}}|>,
 <|"BasePointRegion"->xx<0,"RequestedMasterIntegralOrderRanges"-><|1->{0,0}|>,
   "MasterIntegralRepresentations"-><|1->cube[0]|>|>];
FTAssert["automatic normalization respects the specified kinematic region",
 First[negative["BasePoint"]]<0];
FTAssert["a singular requested ordinary point is rejected",
 FailureQ[DetermineMasterIntegralExpansionOrders[sys,Join[req,<|"BasePoint"->{0}|>]]]];
missing=DetermineMasterIntegralExpansionOrders[sys,KeyDrop[req,"MasterIntegralRepresentations"]];
FTAssert["a desired lower order is not silently treated as a pole bound",
 missing["Status"]==="AdditionalIntegralDataRequired" &&
 missing["MissingIntegralData"][[1,"MasterRow"]]===1];
assumed=DetermineMasterIntegralExpansionOrders[sys,
 Join[KeyDrop[req,"MasterIntegralRepresentations"],<|"MasterIntegralLaurentLowerBounds"-><|1->-1|>|>]];
FTAssert["explicit numerical lower bounds stay conditional",
 assumed["Status"]==="SufficientForAssumedLaurentBounds"];
alias=DetermineMasterIntegralExpansionOrders[sys,
 req/.ee->CANONICA`eps];
FTAssert["regulator contexts are normalized in integral inputs",
 alias["OrdinaryPointConstantLowerBounds"]==={-1}];
FTAssert["integration variables cannot be overwritten by base-point substitution",
 FailureQ[DetermineMasterIntegralExpansionOrders[sys,
   Join[req,<|"MasterIntegralRepresentations"-><|1->cube[-1-ee]/.uu->xx|>|>]]]];
FTAssert["mismatched master identities are rejected",
 FailureQ[DetermineMasterIntegralExpansionOrders[
  Join[sys,<|"OriginalMasterIntegralBasis"->{"first"}|>],
  Join[req,<|"MasterIntegralRepresentations"-><|1->Join[vacuum,<|"MasterIntegral"->"second"|>]|>|>]]]];

diag=<|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,
 "ConnectionMatrices"->{ee IdentityMatrix[2]}|>;
selected=DetermineMasterIntegralExpansionOrders[diag,
 <|"RequestedMasterIntegralOrderRanges"-><|1->{0,0}|>,
 "MasterIntegralRepresentations"-><|1->cube[-1-ee]|>|>];
FTAssert["decoupled masters need no unrelated integral bounds",
 selected["Status"]==="SufficientOrdersDetermined" && Keys[selected["IntegralBoundRecords"]]==={1} &&
 selected["BoundaryCoefficientOrders"][[2,"RequiredOrders"]]==={}];
separate=DetermineMasterIntegralExpansionOrders[diag,
 <|"RequestedMasterIntegralOrderRanges"-><|1->{0,0},2->{-1,1}|>,
 "MasterIntegralRepresentations"-><|1->cube[-1-ee],2->cube[-1-ee,Gamma[ee]]|>|>];
FTAssert["different masters retain separate target ranges and depths",
 separate["OriginalFundamentalMatrixCoefficientUpperOrders"]==={{1,-Infinity},{-Infinity,3}} &&
 Lookup[separate["BoundaryCoefficientOrders"],"RequiredThroughOrder"]==={0,1}];
(* An epsilon-pole change of basis forces a higher constant coefficient. *)
nilpotent=<|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,
 "ConnectionMatrices"->{{{0,1/ee},{0,0}}}|>;
nr=DetermineMasterIntegralExpansionOrders[nilpotent,
 <|"BasePoint"->{1/4},"RequestedMasterIntegralOrderRanges"-><|1->{0,0}|>,
 "MasterIntegralRepresentations"-><|1->cube[0],2->cube[0]|>|>];
FTAssert["a pole in the original fundamental matrix increases boundary depth",
 nr["OriginalFundamentalMatrixEntryLowerBounds"][[1,2]]===-1 &&
 nr["BoundaryCoefficientOrders"][[2,"RequiredThroughOrder"]]===1];
FTAssert["zero lower-bound data are not inferred from the regular prepared equation",
 nr["OrdinaryPointConstantLowerBounds"]==={0,0} &&
 nr["IntegralBoundRecords"][[1]]["Status"]==="BoundEstablishedForRepresentation"];

sing=DetermineMasterIntegralExpansionOrders[sys,Join[req,
 <|"BoundaryNormalization"-><|"Type"->"Frobenius","NormalVariable"->xx,"SingularPoint"->0|>|>]];
FTAssert["Frobenius boundary normalization fixes an ordinary matching coordinate",
 sing["BoundaryNormalization"]["UniformNormalMatchingPathEstablished"]===True &&
 sing["BoundaryNormalization"]["OrdinaryMatchingCoordinate"]===1/4];
FTAssert["local boundary and matching orders are determined without computing matching functions",
 sing["BoundaryCoefficientOrders"][[1,"RequiredOrders"]]==={-1,0} &&
 sing["LocalBoundaryEpsilonOrders"]["SolutionCoefficientUpperOrders"]==={{1}}];
scaled=DetermineMasterIntegralExpansionOrders[sys,Join[req,
 <|"BoundaryNormalization"-><|"Type"->"Frobenius","NormalVariable"->xx,
 "BoundaryNormalizationMatrix"->{{ee^2}}|>|>]];
FTAssert["rescaling boundary constants changes their bounds and demanded orders consistently",
 scaled["BoundaryCoefficientOrders"][[1,"LaurentLowerBound"]]===-3 &&
 scaled["BoundaryCoefficientOrders"][[1,"RequiredThroughOrder"]]===-2 &&
 scaled["LocalBoundaryEpsilonOrders"]["SolutionCoefficientUpperOrders"]==={{1}}];
twovar=<|"KinematicVariables"->{xx,yy},"DimensionalRegulator"->ee,
 "ConnectionMatrices"->{{{-ee/xx}},{{ee}}}|>;
tr=DetermineMasterIntegralExpansionOrders[twovar,
 Join[req,<|"BasePoint"->{1/4,1/3},
 "MasterIntegralRepresentations"-><|1->Join[vacuum,<|"NormalizationPrefactor"->Exp[ee yy]|>]|>,
 "BoundaryNormalization"-><|"Type"->"Frobenius","NormalVariable"->xx|>|>]];
FTAssert["singular-boundary coefficients are fixed at definite tangential coordinates",
 tr["BoundaryNormalization"]["TangentialPoint"]===<|yy->1/3|> &&
 tr["BoundaryNormalization"]["BoundaryConstantsKinematicsIndependent"]===True];
upperSys=<|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,
 "ConnectionMatrices"->{{{-ee/(xx-1)}}}|>;
upperReq=Join[req,<|"MasterIntegralRepresentations"-><|1->cube[-1-ee]|>,
 "BoundaryNormalization"-><|"Type"->"Frobenius","NormalVariable"->xx,"SingularPoint"->1|>|>];
up=DetermineMasterIntegralExpansionOrders[upperSys,upperReq];
FTAssert["an upper endpoint uses a positive inward normal coordinate",
 up["BoundaryNormalization"]["NormalDirection"]===-1 &&
 up["BoundaryNormalization"]["OrdinaryMatchingCoordinate"]===3/4];
movingSys=<|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,
 "ConnectionMatrices"->{{{ee/(xx+ee)}}}|>;
FTAssert["a moving singularity blocks the local pole argument",
 FailureQ[DetermineMasterIntegralExpansionOrders[movingSys,
 Join[req,<|"MasterIntegralRepresentations"-><|1->cube[0]|>,
  "BoundaryNormalization"-><|"Type"->"Frobenius","NormalVariable"->xx|>|>]]]];
pathSys=<|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,
 "ConnectionMatrices"->{{{ee/(xx-1/8)}}}|>;
FTAssert["a singularity on the matching segment is detected",
 FailureQ[DetermineMasterIntegralExpansionOrders[pathSys,
 Join[req,<|"MasterIntegralRepresentations"-><|1->cube[0]|>,
  "BoundaryNormalization"-><|"Type"->"Frobenius","NormalVariable"->xx|>|>]]]];

(* The returned ordinary evolution request is executable and agrees with
   the exact normalized one-loop vacuum integral I=Gamma(eps) x^-eps. *)
finite=ConstructMasterIntegralSolution[ordinary["PreparedDifferentialSystem"],
 First[ordinary["EvolutionConstructionRequests"]],"AutomaticPreparation"->False];
FTAssert["determined evolution orders can be passed directly to the finite constructor",
 MasterIntegralSolutionQ[finite] && finite["RequestedEpsilonOrders"]==={0,1}];
FTAssert["the resulting evolution satisfies its coefficient identities",
 AssociationQ[VerifyMasterIntegralSolution[finite,"IdentityCheck"->"Exact"]]];
uFinite=MasterIntegralSolutionCoefficient[finite,1,1][[1]];
Do[uFinite=uFinite/.FeynFacetSolution`a[j]->finite["AlgebraicDefinitions"][[j]],
 {j,Length[finite["AlgebraicDefinitions"]],1,-1}];
Do[With[{f=finite["IntegralDefinitions"][[j]]},
 uFinite=uFinite/.FeynFacetSolution`F[j,z_]:>
 Inactive[Integrate][f["Integrand"],{f["IntegrationVariable"],0,z}]],
 {j,Length[finite["IntegralDefinitions"]],1,-1}];
uFinite=uFinite/.FeynFacetSolution`K[j_Integer,z_]:>
 (finite["KernelDefinitions"][[j,"Expression"]]/.finite["KernelDefinitions"][[j,"Parameter"]]->z);
FTAssert["requested finite master coefficient agrees with an independent Gamma formula",
 FullSimplify[-EulerGamma+Log[4]+Activate[uFinite]-(-EulerGamma-Log[xx]),xx>1/4]===0];

(* An explicitly chosen resonant normalization has a pole even though the
   original physical masters and ordinary evolution can be epsilon-regular. *)
resonantFrame=<|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,
 "ConnectionMatrices"->{{{0,0},{1/xx,ee^3/xx}}},
 "BasisTransformationMatrix"->{{0,xx},{1,0}}|>;
resReq=<|"BasePoint"->{1/4},"RequestedMasterIntegralOrderRanges"-><|1->{0,0},2->{0,0}|>,
 "MasterIntegralRepresentations"-><|1->cube[0],2->cube[0]|>,
 "BoundaryNormalization"-><|"Type"->"Frobenius","NormalVariable"->xx,
   "LocalBasisTransformationMatrix"->IdentityMatrix[2]|>|>;
res=DetermineMasterIntegralExpansionOrders[resonantFrame,resReq,"AutomaticPreparation"->False];
FTAssert["finite local resonance analysis derives the boundary pole without global evolution",
 res["BoundaryNormalization"]["LocalAnalysis"]["LastResonantIndex"]===1 &&
 Lookup[res["BoundaryCoefficientOrders"],"LaurentLowerBound"]==={-3,0}];
FTAssert["resonant off-diagonal poles do not spread to unrelated diagonal entries",
 res["BoundaryNormalization"]["BoundaryToOrdinaryPointEntryLowerBounds"]==={{0,-3},{Infinity,0}}];
FTAssert["singular matching returns separate boundary coefficient depths",
 Lookup[res["BoundaryCoefficientOrders"],"RequiredThroughOrder"]==={0,3} &&
 res["LocalBoundaryEpsilonOrders"]["SolutionCoefficientUpperOrders"]==={{3,0},{-Infinity,0}}];
FTAssert["matching connection orders include lower-pole local solution coefficients",
 res["LocalBoundaryEpsilonOrders"]["ConnectionCoefficientUpperOrders"][[1,1]]===3];
better=DetermineMasterIntegralExpansionOrders[resonantFrame,
 Join[resReq,<|"BoundaryNormalization"-><|"Type"->"Frobenius","NormalVariable"->xx|>|>],
 "AutomaticPreparation"->False];
FTAssert["using the prepared local basis avoids the avoidable resonance pole",
 Lookup[better["BoundaryCoefficientOrders"],"LaurentLowerBound"]==={0,0} &&
 Max[Lookup[better["BoundaryCoefficientOrders"],"RequiredThroughOrder"]]===0];

twoLoop=<|"Representation"->"FeynmanParameters","FeynmanParameters"->{aa,bb},
 "PropagatorPowers"->{2,2},"LoopCount"->2,
 "SymanzikPolynomials"->{aa bb,xx aa bb(aa+bb)},"NormalizationPrefactor"->1|>;
nnloSystem=<|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,
 "ConnectionMatrices"->{{{-2ee/xx}}}|>;
nnlo=DetermineMasterIntegralExpansionOrders[nnloSystem,
 Join[req,<|"RequestedMasterIntegralOrderRanges"-><|1->{-2,0}|>,
 "MasterIntegralRepresentations"-><|1->twoLoop|>,
 "BoundaryNormalization"-><|"Type"->"Frobenius","NormalVariable"->xx|>|>]];
FTAssert["a two-loop integral determines its double pole from the parameter representation",
 nnlo["IntegralBoundRecords"][1]["LowerBound"]===-2 &&
 nnlo["IntegralBoundRecords"][1]["SectorCount"]===2];
FTAssert["two-loop finite coefficients require evolution through two and boundary through zero",
 nnlo["FundamentalMatrixEpsilonOrders"]["MaximumTransformedOrder"]===2 &&
 nnlo["BoundaryCoefficientOrders"][[1,"RequiredOrders"]]==={-2,-1,0}];
FTAssert["epsilon factors in a regular numerator reduce the derived pole order",
 bound[<|"Terms"->{<|"IntegrationVariables"->{uu},"EndpointPowers"->{-1-ee},
 "RegularFactor"->ee/(1+uu)|>}|>]["LowerBound"]===0];
FTAssert["explicit regulator poles are separated from the regular rational factor",
 bound[<|"Terms"->{<|"IntegrationVariables"->{uu},"EndpointPowers"->{0},
 "RegularFactor"->1/(ee^2(1+uu))|>}|>]["LowerBound"]===-2];

dlog=<|"DataType"->"FamilyDLogEpsilonForm","CoefficientVariables"->{xx},
 "DimensionalRegulator"->ee,"OriginalMasterIntegralBasis"->{1},
 "ConstantResidueMatrices"->{{{-1}}},"Letters"->{xx},
 "BasisTransformationMatrix"->{{1}},"CachedInverseBasisTransformationMatrix"->{{1}}|>;
fromDlog=DetermineMasterIntegralExpansionOrders[dlog,req];
FTAssert["saved epsilon-form records are accepted directly",
 fromDlog["FundamentalMatrixEpsilonOrders"]["MaximumTransformedOrder"]===1];
zero=DetermineMasterIntegralExpansionOrders[sys,
 Join[req,<|"MasterIntegralRepresentations"-><|1->cube[-1,0]|>|>]];
FTAssert["an identically zero boundary component demands no evolution or boundary coefficients",
 zero["EvolutionConstructionRequests"]==={} &&
 zero["BoundaryCoefficientOrders"][[1,"RequiredOrders"]]==={}];

(* Normalization by rho^R consumes R[2,2] at order one even when the
   direct differential recurrence for the demanded Phi[2,2] needs order zero. *)
normalizedFrame=Join[resonantFrame,<|"ConnectionMatrices"->{{{ee/xx,0},{1/xx,ee^3/xx}}}|>];
normalized=DetermineMasterIntegralExpansionOrders[normalizedFrame,resReq,"AutomaticPreparation"->False];
FTAssert["local residue-exponential normalization has its own expansion requirements",
 normalized["LocalBoundaryEpsilonOrders"]["ResidueMatrixCoefficientUpperOrders"][[2,2]]>=1 &&
 normalized["LocalBoundaryEpsilonOrders"]["ResidueExponentialCoefficientUpperOrders"][[2,2]]>=1];
FTReport[];




