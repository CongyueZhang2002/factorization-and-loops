
root="/home/maxzhang/factorization-and-loops";
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
pass=0;failed=0;
check[name_,value_]:=If[TrueQ[value],pass++;Print["PASS ",name],failed++;Print["FAIL ",name]];
q=pa+pb-pc;
kin=FeynCalc`FCI[{FeynCalc`SPD[pa]->0,FeynCalc`SPD[pb]->0,FeynCalc`SPD[pc]->0,
 FeynCalc`SPD[pa,pb]->1/2,FeynCalc`SPD[pa,pc]->1/8,FeynCalc`SPD[pb,pc]->(3/4-z)/2}];
top=FeynCalc`FCTopology[testFamily,{FeynCalc`SFAD[k],FeynCalc`SFAD[l],FeynCalc`SFAD[q-k-l],
 FeynCalc`SFAD[pa-k],FeynCalc`SFAD[pb-l],FeynCalc`SFAD[q]},{k,l},{pa,pb,pc},kin,{}];
data=<|"Topology"->top,"DimensionalRegulator"->eps,"Prescription"->{0,0},
 "CutIndices"->{1,2,3},"CutMomenta"->{k,l,q-k-l},
 "Master"->{FeynCalc`GLI[testFamily,{1,1,1,0,0,0}],FeynCalc`GLI[testFamily,{1,1,1,1,0,0}],
 FeynCalc`GLI[testFamily,{1,1,1,1,1,0}],FeynCalc`GLI[testFamily,{1,1,1,0,0,1}],
 FeynCalc`GLI[testFamily,{1,1,2,0,0,0}]}|>;
defs=FeynFacet`ConstructMasterIntegralDefinitions[data]["MasterIntegralDefinitions"];
Print["DEFINITIONS ",Length[defs]];
boundary=<|"NormalVariable"->z,"BoundaryKinematicRules"->(kin/.z->0)|>;
reps=FeynFacet`ConstructCoalescingNullBoundaryIntegral[#,boundary]&/@defs;
Print["CONSTRUCTION ",Map[If[FailureQ[#],#,KeyTake[#,{"NormalExponent","PropagatorLimits"}]]&,reps]];
check["volume limit constructed",AssociationQ[reps[1]]];
check["raised cuts remain unresolved",FailureQ[reps[5]]];
results=FeynFacet`IntegrateEulerBoundaryIntegral[#,{0,0}]&/@KeyTake[reps,{1,2,3,4}];
alpha=1-eps;dim=4-2eps;c2=Pi^((dim-1)/2)/(2^(dim-2)Gamma[(dim-1)/2]);
volume=(2Pi)^(3-2dim)c2^2 Gamma[alpha]Gamma[2alpha]/Gamma[3alpha];
references={volume,volume(-3/4)^-1 Gamma[alpha-1]Gamma[3alpha]/(Gamma[alpha]Gamma[3alpha-1]),
 volume(3/16)^-1 Gamma[alpha-1]^2 Gamma[3alpha]/(Gamma[alpha]^2 Gamma[3alpha-2]),volume};
Do[
 value=Lookup[results[i],"AnalyticExpression",None];
 check["Gamma normalization "<>ToString[i],value=!=None&&
  Abs[N[(value-references[[i]])/.eps->-7/3,40]]<10^-30],
 {i,4}];
check["explicit recoil propagator changes integer power",reps[4]["NormalExponent"]===-2eps];
Print["ASSERTIONS ",pass+failed," FAILED ",failed];If[failed>0,Exit[1],Exit[0]];
