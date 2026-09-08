
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
makeDot[d_,i_]:=Module[{x=d,pp,cd},
 pp=x["PropagatorPowers"];pp[[x["CutIndices"][[i]]]]=2;x["PropagatorPowers"]=pp;
 cd=x["CutDistributions"];cd[[i]]=Join[cd[[i]],<|"Power"->2,"DeltaDerivativeOrder"->1,"DistributionCoefficient"->-1|>];x["CutDistributions"]=cd;x];
volumeDef=defs[1];pp=volumeDef["PropagatorPowers"];pp[[Complement[Range[Length[pp]],volumeDef["CutIndices"]]]]=0;volumeDef["PropagatorPowers"]=pp;
dvol=makeDot[volumeDef,1];
dv=FeynFacet`ConstructCoalescingNullBoundaryIntegral[dvol,<|"NormalVariable"->z,"BoundaryKinematicRules"->(kin/.z->0)|>];
check["single cut mass derivative has a physical endpoint certificate",
 AssociationQ[dv]&&TrueQ[dv["PhysicalLimitEstablished"]]&&dv["NormalExponent"]===-2eps];
v=FeynFacet`IntegrateEulerBoundaryIntegral[dv,{-3,0},"IntegrationBackend"->"GammaBeta"];
baseVolume=(2Pi)^(3-2dim)Pi^(dim-2)Gamma[alpha]^3/(4Gamma[2alpha]Gamma[3alpha]);
reference=-(dim-3)(3alpha-1)/(alpha-1)baseVolume;
check["dotted volume agrees with mass derivative and cut sign",
 AssociationQ[v]&&FullSimplify[(v["AnalyticExpression"]-reference)/.eps->-6]===0];
dpair=FeynFacet`ConstructCoalescingNullBoundaryIntegral[makeDot[defs[1],1],
 <|"NormalVariable"->z,"BoundaryKinematicRules"->(kin/.z->0)|>];
v=FeynFacet`IntegrateEulerBoundaryIntegral[dpair,{-3,0},"IntegrationBackend"->"GammaBeta"];
reference=-(dim-3)baseVolume Gamma[alpha-2]Gamma[3alpha]/(Gamma[alpha]Gamma[3alpha-2]);
check["one-pair mass insertion agrees with exact dot-lowering cut IBP",
 AssociationQ[v]&&FullSimplify[(v["AnalyticExpression"]-reference)/.eps->-6]===0];
off=dvol;off["PropagatorPowers"]=Append[off["PropagatorPowers"],-1];
off["PropagatorMomenta"]=Append[off["PropagatorMomenta"],k];
off["PropagatorTypes"]=Append[off["PropagatorTypes"],"QuadraticLorentzian"];
off["InversePropagators"]=Append[off["InversePropagators"],First[off["InversePropagators"]]];
bad=FeynFacet`ConstructCoalescingNullBoundaryIntegral[off,<|"NormalVariable"->z,"BoundaryKinematicRules"->(kin/.z->0)|>];
check["unsupported off-shell cut numerator is not silently set to zero",FailureQ[bad]];
Print["ASSERTIONS ",pass+failed," FAILED ",failed];If[failed>0,Exit[1],Exit[0]];
