Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
dir=CreateDirectory[];req=<|"LibraryDirectory"->dir,"Mode"->"ReadWrite"|>;
make[loop_,mom_,power_]:=<|"MasterIntegral"->FeynCalc`GLI["Test",power],
 "LoopMomenta"->loop,"ExternalMomenta"->{p},"DimensionalRegulator"->ee,"Dimension"->4-2ee,
 "PropagatorMomenta"->mom,"PropagatorPowers"->power,"CutIndices"->{},
 "PropagatorTypes"->ConstantArray["QuadraticLorentzian",Length[mom]],
 "InversePropagators"->(FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[#]]]&/@mom),
 "Prescription"->ConstantArray[1,Length[loop]],"PropagatorPrescriptions"->ConstantArray[1,Length[mom]],
 "OriginalPropagatorPrescriptions"->ConstantArray[1,Length[mom]],
 "MeasurePrefactor"->(I Pi^(2-ee))^-Length[loop],"MasterIntegralPrefactor"->1,
 "KinematicRules"->FeynCalc`FCI[{FeynCalc`SPD[p]->s}],"KinematicConditions"->s>0|>;
a=make[{ell},{ell,ell-p},{1,2}];b=make[{ell},{ell+3p,ell+2p},{1,2}];
c=make[{ell},{ell,ell-p},{2,1}];
value=<|"Coefficients"-><|-1->1/s,0->Log[s]/s|>,"LaurentLowerBound"->-1,"KnownThroughOrder"->0|>;
stored=FeynFacet`StoreMasterIntegralValue[a,value,req];
FTTest`FTAssert["external-momentum shifts of virtual integrals are identified",
 AssociationQ[FeynFacet`FindMasterIntegralValue[b,{-1,0},req]]];
FTTest`FTAssert["family automorphisms identify permuted dotted powers",
 AssociationQ[FeynFacet`FindMasterIntegralValue[c,{-1,0},req]]];
d=make[{ell},{ell,ell-p},{2,2}];
FeynFacet`StoreMasterIntegralValue[d,Append[value,"Coefficients"-><|-1->2/s,0->2Log[s]/s|>],req];
inventory=FeynFacet`MasterIntegralLibraryInventory[req];
FTTest`FTAssert["different powers share one family and retain separate master records",
 inventory["FamilyCount"]===1&&inventory["MasterCount"]===2];
FTTest`FTAssert["sector numbering uses positive propagator bits",
 FeynFacet`CanonicalMasterIntegral[a]["Sector"]===3&&
 FeynFacet`CanonicalMasterIntegral[make[{ell},{ell,ell-p},{1,-1}]]["Sector"]===2];
two=make[{k1,k2},{k1,k2,k1-k2,k1-p,k2-p},{1,1,1,1,1}];
shifted=make[{k1,k2},{k1,k2,k1-k2,k1-p,k2-p}/.{k1->k1+k2+2p,k2->k2-p},{1,1,1,1,1}];
FeynFacet`StoreMasterIntegralValue[two,value,req];
found=FeynFacet`FindMasterIntegralValue[shifted,{-1,0},req];
FTTest`FTAssert["two-loop mixing and shifts share the same exact integral",
 AssociationQ[found]&&found["Coefficients"]===value["Coefficients"]];
FTTest`FTAssert["the adopted virtual change has unit absolute Jacobian",
 AssociationQ[found]&&Abs[Det[found["LibraryReuse"]["LoopTransformation"][[All,1;;2]]]]===1];
wrong=Append[shifted,"OriginalPropagatorPrescriptions"->{1,1,1,1,-1}];
FTTest`FTAssert["virtual matching cannot change an ordinary prescription",
 MissingQ[FeynFacet`FindMasterIntegralValue[wrong,{-1,0},req]]];
renamed=Table[i->Append[a,"MasterIntegral"->FeynCalc`GLI["Project"<>ToString[i],{1,2}]],{i,200}];
batch=FeynFacet`FindMasterIntegralValues[Association[renamed],
 Association@Table[i->{-1,0},{i,200}],req];
FTTest`FTAssert["batch lookup reads the selected catalog and sector only once",
 TrueQ[batch["Complete"]]&&batch["LookupStatistics"]["CatalogReads"]===1&&
 batch["LookupStatistics"]["SectorIndexReads"]===1&&batch["LookupStatistics"]["ValueReads"]===1];
batch=FeynFacet`FindMasterIntegralValues[<|1->a,2->Append[a,"KinematicConditions"->s<0]|>,
 <|1->{-1,2},2->{-1,0}|>,req];
FTTest`FTAssert["unidentified masters and insufficient orders have distinct statuses",
 batch["InsufficientOrderRows"]==={1}&&batch["UnidentifiedRows"]==={2}];
FTTest`FTAssert["insufficient coverage preserves available coefficients for partial evolution",
 Keys[batch["PartialValues"]]==={1}&&batch["PartialValues"][1]["KnownThroughOrder"]===0&&
 batch["LookupStatistics"]["ValueReads"]===1];
FTTest`FTAssert["no flat index or content hashes are created",
 !FileExistsQ[dir<>"/Index.wl"]&&FileNames["*hash*",dir,Infinity]==={}];
Print["MASTER LIBRARY TEST COMPLETE"];FTTest`FTReport[];
