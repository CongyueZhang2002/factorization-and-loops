
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/Tests/TestKit.wl"];
q=pa+pb-pc;dim=4-2eps;alpha=1-eps;
kin=FeynCalc`FCI[{FeynCalc`SPD[pa]->0,FeynCalc`SPD[pb]->0,FeynCalc`SPD[pc]->0,
 FeynCalc`SPD[pa,pb]->1/2,FeynCalc`SPD[pa,pc]->1/8,FeynCalc`SPD[pb,pc]->(3/4-z)/2}];
top=FeynCalc`FCTopology[testCollinear,{FeynCalc`SFAD[k],FeynCalc`SFAD[l],FeynCalc`SFAD[q-k-l],
 FeynCalc`SFAD[pa-k],FeynCalc`SFAD[pc+l],FeynCalc`SFAD[k+l],
 FeynCalc`SFAD[pc+k],FeynCalc`SFAD[pa-l],FeynCalc`SFAD[pa-k-l],FeynCalc`SFAD[pc+k+l]},
 {k,l},{pa,pb,pc},kin,{}];
pp={{1,1,1,1,1,1,0,0,0,0},{1,1,1,1,1,0,1,1,0,0},
 {1,1,1,0,0,0,0,0,1,1},{1,1,1,0,1,0,0,0,1,0},
 {1,1,1,2,2,2,0,0,0,0}};
defs=FeynFacet`ConstructMasterIntegralDefinitions[<|"Topology"->top,"Prescription"->{0,0},
 "DimensionalRegulator"->eps,"CutIndices"->{1,2,3},"CutMomenta"->{k,l,q-k-l},
 "Master"->(FeynCalc`GLI[testCollinear,#]&/@pp)|>]["MasterIntegralDefinitions"];
boundary=<|"NormalVariable"->z,"BoundaryKinematicRules"->(kin/.z->0)|>;
values=FeynFacet`ConstructDoubleCollinearBoundaryIntegral[#,boundary]&/@defs;
FTAssert["four complete profiles recognized without family cases",
 Lookup[Values[KeyTake[values,Range[4]]],"DoubleCollinearIntegralClass"]===
 {"EuclideanSunset","ProductOfEuclideanBubbles","TwoClusterDenominators","ClusterAndConstituentDenominators"}];
FTAssert["leading normal powers include the internal pair scaling",
 Expand[Lookup[Values[KeyTake[values,Range[4]]],"NormalExponent"]]===
 {-1-4eps,-1-4eps,1-4eps,1-4eps}];
bubble[h_,a_,b_,L_]:=Pi^h L^(h-a-b)Gamma[a+b-h]Gamma[h-a]Gamma[h-b]/
 (Gamma[a]Gamma[b]Gamma[2h-a-b]);
(* Integrate one loop at a time, independently of the stored sunset kernel. *)
chain=bubble[alpha,1,1,1]bubble[alpha,1,2-alpha,4/3];
FTAssert["sunset agrees with two successive one-loop integrations inside its strip",
 Abs[N[(values[1]["TransverseIntegral"]-chain)/.eps->-1/4,40]]<10^-30];
FTAssert["cluster coefficient agrees with a direct doubled-dimension bubble",
 Abs[N[(values[3]["TransverseIntegral"]-bubble[2alpha,1,1,4/3])/.eps->1/4,40]]<10^-30];
FTAssert["constituent factor agrees with a convergent conditional Beta integral",
 Abs[N[(values[4]["AnalyticExpression"]/values[3]["AnalyticExpression"]-
 Gamma[alpha-1]Gamma[2alpha]/(Gamma[alpha]Gamma[2alpha-1]))/.eps->-1/4,40]]<10^-30];
FTAssert["nonunit powers also use the general sunset convolution",
 AssociationQ[values[5]]&&Abs[N[(values[5]["TransverseIntegral"]-
 bubble[alpha,2,2,1]bubble[alpha,2,4-alpha,4/3])/.eps->-3/2,40]]<10^-30];
FTReport[];
