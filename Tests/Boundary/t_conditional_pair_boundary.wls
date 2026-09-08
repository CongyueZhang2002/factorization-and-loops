
root="/home/maxzhang/factorization-and-loops";
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
q=pa+pb-pc;dim=4-2eps;alpha=1-eps;
kin=FeynCalc`FCI[{FeynCalc`SPD[pa]->0,FeynCalc`SPD[pb]->0,FeynCalc`SPD[pc]->0,
 FeynCalc`SPD[pa,pb]->1/2,FeynCalc`SPD[pa,pc]->1/8,FeynCalc`SPD[pb,pc]->(3/4-z)/2}];
top=FeynCalc`FCTopology[pairFamily,{FeynCalc`SFAD[k],FeynCalc`SFAD[l],FeynCalc`SFAD[q-k-l],
 FeynCalc`SFAD[k+l],FeynCalc`SFAD[pa-k],FeynCalc`SFAD[q-l]},{k,l},{pa,pb,pc},kin,{}];
input=<|"Topology"->top,"Prescription"->{0,0},"DimensionalRegulator"->eps,
 "CutIndices"->{1,2,3},"CutMomenta"->{k,l,q-k-l},"Master"->{
 FeynCalc`GLI[pairFamily,{1,1,1,1,0,0}],FeynCalc`GLI[pairFamily,{1,1,1,-1,0,0}],
 FeynCalc`GLI[pairFamily,{1,1,1,1,1,0}],FeynCalc`GLI[pairFamily,{1,1,1,1,0,1}]}|>;
defs=FeynFacet`ConstructMasterIntegralDefinitions[input]["MasterIntegralDefinitions"];
reps=FeynFacet`ConstructCoalescingNullBoundaryIntegral[#,<|"NormalVariable"->z,"BoundaryKinematicRules"->(kin/.z->0)|>]&/@defs;
pass=0;failed=0;check[name_,v_]:=If[TrueQ[v],pass++;Print["PASS ",name],failed++;Print["FAIL ",name]];
check["one pair invariant constructed",AssociationQ[reps[1]]&&reps[1]["NormalExponent"]===-2eps];
check["two pair invariants constructed",AssociationQ[reps[4]]&&TrueQ[reps[4]["TwoPairConditionalRepresentation"]]];
volume=(2Pi)^(3-2dim)Pi^(dim-2)Gamma[alpha]^3/(4Gamma[2alpha]Gamma[3alpha]);
pairReference=volume Gamma[alpha-1]Gamma[3alpha]/(Gamma[alpha]Gamma[3alpha-1]);
eval=FeynFacet`IntegrateEulerBoundaryIntegral[reps[1],{-3,0},"IntegrationBackend"->"GammaBeta"];
check["pair invariant marginal normalization",AssociationQ[eval]&&Abs[N[
 (eval["AnalyticExpression"]-pairReference)/.eps->-7/3,40]]<10^-30];
num=FeynFacet`IntegrateEulerBoundaryIntegral[reps[2],{0,0},"IntegrationBackend"->"GammaBeta"];
check["pair numerator mean is one third",AssociationQ[num]&&Abs[N[
 (num["AnalyticExpression"]-volume/3)/.eps->-7/3,40]]<10^-30];
joint=FeynFacet`IntegrateEulerBoundaryIntegral[reps[4],{-3,0},"IntegrationBackend"->"GammaBeta"];
jointReference=volume Gamma[alpha-1]^2 Gamma[3alpha]/(Gamma[alpha]^2 Gamma[3alpha-2]);
check["two-pair marginal agrees with invariant Dirichlet measure",AssociationQ[joint]&&Abs[N[
 (joint["AnalyticExpression"]-jointReference)/.eps->-7/3,40]]<10^-30];
check["conditional pair moment retained",Cancel[Together[reps[3]["ConditionalPairMoment"]-(1-2eps)/(-eps)]]===0];
Print["ASSERTIONS ",pass+failed," FAILED ",failed];If[failed>0,Exit[1],Exit[0]];
