
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];
Clear[x,ep,p,q,l1,l2,A,B,H1,H2];
den[k_,eta_:1]:=FeynCalc`FeynAmpDenominator[
 FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[k,D],0,0,{1,eta}]];
kin={FeynCalc`SPD[p]->0,FeynCalc`SPD[q]->0};
record[name_,last_,direction_:1,eta_:1]:=<|
 "Topology"->FeynCalc`FCTopology[name,{den[l1],den[l2],den[p+q-l1-l2],den[last,eta]},
 {l1,l2},{p,q},FeynCalc`FCI[kin],{}],
 "CutIndices"->{1,2,3},"CutMomenta"->{l1,l2,p+q-l1-l2},
 "CutDirections"->{1,1,direction}|>;
ga=FeynCalc`GLI[A,{1,1,1,1}];gb=FeynCalc`GLI[B,{1,1,1,1}];
eq=FindCutIntegralEquivalences[{ga,gb},{record[A,p-l1],record[B,p-(p+q-l1-l2)]},
 "Normalization"->"same phase-space measure"];
FTAssert["all cut momenta, not only chosen loop labels, may be permuted",
 AssociationQ[eq]&&eq["EquivalenceClassCount"]===1];
flip=FindCutIntegralEquivalences[{ga,gb},{record[A,p-l1],record[B,p-(p+q-l1-l2),-1]},
 "Normalization"->"same phase-space measure"];
FTAssert["a positive-energy orientation change is not an integral identity",
 AssociationQ[flip]&&flip["EquivalenceClassCount"]===2];
prescription=FindCutIntegralEquivalences[{ga,gb},{record[A,p-l1],record[B,p-(p+q-l1-l2),1,-1]},
 "Normalization"->"same phase-space measure"];
FTAssert["opposite ordinary propagator prescriptions stay distinct",
 prescription["EquivalenceClassCount"]===2];
FTAssert["normalization is explicit",FailureQ[
 FindCutIntegralEquivalences[{ga},{record[A,p-l1]}]]];

gA=FeynCalc`GLI[A,{1}];gB=FeynCalc`GLI[B,{1}];
u=FeynCalc`GLI[A,{2}];vB=FeynCalc`GLI[B,{2}];
sys[name_,basis_,matrix_]:=<|"Family"->name,"OriginalMasterIntegralBasis"->basis,
 "KinematicVariables"->{x},"DimensionalRegulator"->ep,"ConnectionMatrices"->{matrix}|>;
toyMaps=<|"DataType"->"CutIntegralEquivalences","Mappings"->{
 <|"Source"->gA,"Representative"->gA,"Factor"->1|>,
 <|"Source"->gB,"Representative"->gA,"Factor"->1|>,
 <|"Source"->u,"Representative"->u,"Factor"->1|>,
 <|"Source"->vB,"Representative"->vB,"Factor"->1|>}|>;
gs=ConstructGlobalMasterDifferentialSystem[
 {sys["A",{gA,u},{{0,1},{0,0}}],sys["B",{gB,vB},{{0,x},{0,-1/x}}]},
 toyMaps,"PreferredMasterIntegrals"->{gA,vB}];
FTAssert["overlapping DEs produce a kinematics-dependent exact integral identity",
 AssociationQ[gs]&&gs["IndependentRelationCount"]===1&&gs["GlobalSpanningMasterCount"]===2];
closedRelations=ConstructGlobalMasterDifferentialSystem[
 {sys["A",{gA,u},{{0,1},{0,0}}],sys["B",{gB,vB},{{0,x},{0,0}}]},toyMaps];
FTAssert["differentiated identities are closed automatically",
 AssociationQ[closedRelations]&&closedRelations["IndependentRelationCount"]===2&&
 closedRelations["GlobalSpanningMasterCount"]===1&&
 Normal[First[closedRelations["ConnectionMatrices"]]]==={{0}}];
FTAssert["closure retains the forced zero integrals in the original substitutions",
 And@@(Normal[#["IntegralEmbedding"]][[2]]==={0}&/@closedRelations["FamilyMaps"])];

aSys=sys["A",{gA},{{ep}}];bSys=sys["B",{gB,vB},{{ep,0},{1,0}}];
same=<|"DataType"->"CutIntegralEquivalences","Mappings"->{
 <|"Source"->gA,"Representative"->gA,"Factor"->1|>,
 <|"Source"->gB,"Representative"->gA,"Factor"->1|>,
 <|"Source"->vB,"Representative"->vB,"Factor"->1|>}|>;
gg=ConstructGlobalMasterDifferentialSystem[{aSys,bSys},same];
make[d_,pt_]:=ExpandMasterIntegralSolutionInInitialConstants[
 ConstructMasterIntegralSolution[d,<|"BasePoint"->{pt},"RequestedEpsilonOrders"->{0,1,2},
 "AnalyticDomain"->"Real line","BranchPrescription"->"Real polynomial and exponential continuation."|>],
 ConstantArray[0,Length[d["OriginalMasterIntegralBasis"]]],{0,1,2}];
sa=make[aSys,0];sb=make[bSys,1];
reduced=ReduceMasterIntegralSolutionConstants[<|"A"->sa,"B"->sb|>,gg,
 "EvaluateKnownIntegrals"->False];
FTAssert["different base points use explicit fixed-point solutions",
 AssociationQ[reduced]&&reduced["RequiredBoundarySeriesCount"]===2&&
 Length[reduced["Solutions"]["B"]["FixedPointSolutionImports"]]===1&&
 MasterIntegralSolutionQ[reduced["Solutions"]["B"]]];
Get[FileNameJoin[{root,"FeynFacet","Solution.m"}]];
c=FeynFacetSolution`C;
values={c[1,0]->3,c[1,1]->1,c[1,2]->0,c[2,0]->5,c[2,1]->0,c[2,2]->0};
ev=FeynFacetSolution`EvaluateMasterIntegralSolution[reduced["Solutions"]["B"],{2},
 "NumericalBackend"->"Wolfram","CheckConvergence"->False,"WorkingPrecision"->40,
 "InitialConstantValues"->values];
FTAssert["the changed boundary basis remains numerically evaluable",
 AssociationQ[ev]&&Abs[Lookup[Association[ev["MasterIntegralEpsilonCoefficients"][0]],2]-8]<10^-25&&
 Abs[Lookup[Association[ev["MasterIntegralEpsilonCoefficients"][1]],2]-11/2]<10^-25];

(* Full multiplicity and tangential observation are essential. *)
localSystem=<|"KinematicVariables"->{x,y},"DimensionalRegulator"->ep,
 "MasterIntegralBasis"->{gA,vB},"ConnectionMatrices"->{
  {{1-2ep,1},{-1,-1-2ep}}/x,ConstantArray[0,{2,2}]}|>;
ll=ConstructHomogeneousBlockLimits[localSystem,<|"NormalVariable"->z,
 "CoordinateSubstitution"->{x->z,y->t},"TangentialPointRules"->{t->1/3}|>];
bb=BoundBoundaryDataByScaling[ll,<|"MasterRows"->{1},
 "MaximumEpsilonSlope"->-2,"Justification"->"Synthetic allowed repeated exponent."|>,
 {z->1/5,ep->1/17}];
FTAssert["a repeated eigenvalue retains both Jordan-chain directions",
 bb["RemainingDimensionUpperBound"]===2&&
 ll["Blocks"][[1]]["Exponents"][[1]]["AlgebraicMultiplicity"]===2];
joint=<|"KinematicVariables"->{x,y},"DimensionalRegulator"->ep,
 "MasterIntegralBasis"->{gA,vB},"ConnectionMatrices"->{
  ConstantArray[0,{2,2}],{{0,1},{1,0}}}|>;
jl=ConstructHomogeneousBlockLimits[joint,<|"NormalVariable"->z,
 "CoordinateSubstitution"->{x->z,y->t},"TangentialPointRules"->{t->1/3}|>];
jc=<|"MasterRows"->{1},"MaximumEpsilonSlope"->-2,
 "Justification"->"Synthetic bound on an open tangential interval."|>;
j0=BoundBoundaryDataByScaling[jl,jc,{z->1/5,ep->1/17}];
j1=BoundBoundaryDataByScaling[jl,Join[jc,<|"UniformInTangentialNeighborhood"->True|>],
 {z->1/5,ep->1/17}];
FTAssert["tangential observation requires a bound on a neighborhood",
 j0["RemainingDimensionUpperBound"]===2&&j1["RemainingDimensionUpperBound"]===0];

momenta={l1,l2,p+q-l1-l2,p-l1};
psdef=<|"CutIndices"->{1,2,3},"PropagatorPowers"->{1,1,1,0},
 "LoopMomenta"->{l1,l2},"OrientedCutMomenta"->Take[momenta,3],
 "PropagatorMomenta"->momenta,"PropagatorTypes"->ConstantArray["QuadraticLorentzian",4],
 "InversePropagators"->(FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[#]]]&/@momenta),
 "KinematicRules"->FeynCalc`FCI[{FeynCalc`SPD[p]->0,FeynCalc`SPD[q]->0,FeynCalc`SPD[p,q]->1/2}],
 "Dimension"->6,"TimeDirection"->p+q,"MasterIntegralPrefactor"->1,"MeasurePrefactor"->1|>;
ps0=FeynFacet`Private`miRepElementaryPhaseSpace[psdef];
ps1=FeynFacet`Private`miRepElementaryPhaseSpace[Join[psdef,<|"PropagatorPowers"->{1,1,1,1}|>]];
ps2=FeynFacet`Private`miRepElementaryPhaseSpace[Join[psdef,<|"PropagatorPowers"->{2,1,1,0}|>]];
FTAssert["one eikonal inverse moment agrees with direct D=6 beta integrals",
 Simplify[ps1["Terms"][[1]]["Prefactor"]/ps0["Terms"][[1]]["Prefactor"]]===-5];
FTAssert["one doubled cut has the mass-derivative sign and D=6 coefficient",
 Simplify[ps2["Terms"][[1]]["Prefactor"]/ps0["Terms"][[1]]["Prefactor"]]===-15];

(* Both proposed sample points annihilate this exact relation coefficient.
   Symbolic row-space verification must recover the missing rank. *)
lostSample=FeynFacet`Private`globalDECloseRelations[
 {{(x-1/2)(x-1/3),0}},{{{0,0},{0,0}}},{x},{{x->1/2},{x->1/3}},3];
FTAssert["sample rank loss cannot discard an exact integral relation",
 AssociationQ[lostSample]&&lostSample["Rows"]==={{1,0}}];

FTReport[];
