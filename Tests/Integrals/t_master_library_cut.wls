Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
dir=CreateDirectory[];req=<|"LibraryDirectory"->dir,"Mode"->"ReadWrite"|>;
base=<|"FinalMomenta"->{k1,k2,k3},"TotalMomentum"->p+q,
 "ExternalMomenta"->{p,q},"ReferenceMomentum"->p,"TaggedMomentum"->k1,
 "MeasurementVariable"->z,"KinematicRules"->{
 FeynCalc`SPD[p]->0,FeynCalc`SPD[q]->0,FeynCalc`SPD[p,q]->s/2},
 "Assumptions"->s>0&&0<z<1|>;
family[m_,eta_:1]:=FeynFacet`CreateMeasuredPhaseSpaceDefinition[
 Join[base,<|"Name"->CF1,"OrdinaryPropagators"->{
 FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[
 FeynCalc`Momentum[m,D],0,0,{1,eta}]]}|>]];
definition[family_,powers_:{1,1,1,1,1}]:=FeynFacet`ConstructMasterIntegralDefinitions[
 <|"MasterIntegralBasis"->{FeynCalc`GLI[CF1,powers]},"Families"->{family},
 "DimensionalRegulator"->ee|>]["MasterIntegralDefinitions"][1];
a=definition[family[p-k2]];b=definition[family[p-k3]];
FTTest`FTAssert["typed measured integral definitions are complete",AssociationQ[a]&&AssociationQ[b]];
value=<|"Coefficients"-><|-1->z,0->Log[s]|>,"LaurentLowerBound"->-1,"KnownThroughOrder"->0|>;
stored=FeynFacet`StoreMasterIntegralValue[a,value,req];
found=FeynFacet`FindMasterIntegralValue[b,{-1,0},req];
FTTest`FTAssert["the persistent library uses exact cut momentum changes",
 AssociationQ[stored]&&AssociationQ[found]&&found["Coefficients"]===value["Coefficients"]&&
 found["LibraryReuse"]["IdentityMethod"]==="ExactAffineCutMomentumChanges"];
FTTest`FTAssert["changing a measurement derivative prevents library reuse",
 MissingQ[FeynFacet`FindMasterIntegralValue[definition[family[p-k3],{1,1,1,2,1}],{-1,0},req]]];
FTTest`FTAssert["original opposite causal prescriptions are not merged",
 MissingQ[FeynFacet`FindMasterIntegralValue[definition[family[p-k3,-1]],{-1,0},req]]];
FTTest`FTAssert["changing the explicit cut measure prevents library reuse",
 MissingQ[FeynFacet`FindMasterIntegralValue[Append[b,"MeasurePrefactor"->2b["MeasurePrefactor"]],{-1,0},req]]];
plainDef[ordinary_]:=Module[{top,record,input},
 top=FeynCalc`FCTopology[PlainPhaseSpace,FeynCalc`FCI[FeynCalc`SFAD[#]]&/@{ell,p-ell,ordinary},
  {ell},{p,q},FeynCalc`FCI[{FeynCalc`SPD[p]->s,FeynCalc`SPD[q]->0,FeynCalc`SPD[p,q]->u}],{}];
 record=<|"Topology"->top,"CutIndices"->{1,2},"CutMomenta"->{ell,p-ell},
  "CutDirections"->{1,1},"Prescription"->{0}|>;
 input=<|"MasterIntegralBasis"->{FeynCalc`GLI[PlainPhaseSpace,{1,1,1}]},
  "Topologies"->{record},"DimensionalRegulator"->ee,"KinematicConditions"->s>0&&u<0|>;
 FeynFacet`ConstructMasterIntegralDefinitions[input]["MasterIntegralDefinitions"][1]
];
plainA=plainDef[ell-q];plainB=plainDef[p-ell-q];
FTTest`FTAssert["ordinary phase-space definitions retain only their momentum topology",
 KeyExistsQ[plainA,"MomentumSpaceTopology"]&&FreeQ[plainA,_Failure]];
FeynFacet`StoreMasterIntegralValue[plainA,value,req];
FTTest`FTAssert["unmeasured cuts share values under an exact recoil momentum change",
 AssociationQ[FeynFacet`FindMasterIntegralValue[plainB,{-1,0},req]]];
compact=FeynFacet`ConstructMasterIntegralDefinitions[
 <|"MasterIntegralBasis"->{FeynCalc`GLI[CF1,{1,1,1,1,1}]},"Families"->{family[p-k2]},
 "DimensionalRegulator"->ee,"UnrelatedDifferentialSystem"->ConstantArray[1,10000]|>];
FTTest`FTAssert["typed cut definitions do not copy the source DE into every master",
 !KeyExistsQ[compact["MasterIntegralDefinitions"][1]["SourceCutDefinition"],"UnrelatedDifferentialSystem"]];
Print["MASTER LIBRARY TEST COMPLETE"];FTTest`FTReport[];
