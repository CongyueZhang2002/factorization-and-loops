Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
dir=CreateDirectory[];request=<|"LibraryDirectory"->dir,"Mode"->"ReadWrite",
 "Provenance"-><|"Producer"->"Synthetic library contract fixture"|>|>;
definition=<|"MasterIntegral"->FeynCalc`GLI["FamilyA",{1,1}],"LoopMomenta"->{ell},
 "ExternalMomenta"->{p},"DimensionalRegulator"->ee,"Dimension"->4-2ee,
 "InversePropagators"->{FeynCalc`SPD[ell],FeynCalc`SPD[ell-p]},
 "PropagatorMomenta"->{ell,ell-p},"PropagatorTypes"->{"QuadraticLorentzian","QuadraticLorentzian"},
 "PropagatorPowers"->{1,1},"CutIndices"->{},"Prescription"->{1},
 "OriginalPropagatorPrescriptions"->{1,1},"PropagatorPrescriptions"->{1,1},
 "MeasurePrefactor"->1/(I Pi^(2-ee)),"MasterIntegralPrefactor"->1,
 "KinematicRules"->{FeynCalc`SPD[p]->s},"KinematicConditions"->s>0,
 "EvaluationScope"->"GenericKinematics"|>;
value=<|"Coefficients"-><|-1->2,0->Log[s],1->Pi^2|>,"LaurentLowerBound"->-1,"KnownThroughOrder"->1|>;
value=Join[value,<|"UniversalScalarSources"-><|"Source"->"Independent synthetic contract fixture"|>|>];
FTTest`FTAssert["an empty shared library is an explicit miss",
 MissingQ[FeynFacet`FindMasterIntegralValue[definition,{-1,1},request]]];
stored=FeynFacet`StoreMasterIntegralValue[definition,value,request];
FTTest`FTAssert["a complete explicit master is persisted",AssociationQ[stored]];
renamed=definition/.{ell->otherLoop,p->otherExternal,ee->ep};
renamed=Append[renamed,"MasterIntegral"->FeynCalc`GLI["UnrelatedProjectFamily",{1,1}]];
found=FeynFacet`FindMasterIntegralValue[renamed,{-2,1},request];
FTTest`FTAssert["family, loop, external and epsilon renaming preserves exact identity",
 AssociationQ[found]&&found["Coefficients"]===<|-2->0,-1->2,0->Log[s],1->Pi^2|>&&
 found["DimensionalRegulator"]===ep];
FTTest`FTAssert["universal scalar provenance survives storage and reuse",
 found["UniversalScalarSources"]===value["UniversalScalarSources"]&&
 MemberQ[Lookup[found["MasterIntegralProvenance"],"UniversalScalarSources",None],value["UniversalScalarSources"]]];
FTTest`FTAssert["missing higher coefficients are not assumed zero",
 MissingQ[FeynFacet`FindMasterIntegralValue[renamed,{-1,2},request]]];
partialBatch=FeynFacet`FindMasterIntegralValues[<|1->definition,2->renamed|>,
 <|1->{2,2},2->{1,1}|>,request];
FTTest`FTAssert["batch lookup preserves lower-order data without claiming sufficient coverage",
 !partialBatch["Complete"]&&partialBatch["InsufficientOrderRows"]==={1}&&
 Keys[partialBatch["Values"]]==={2}&&Keys[partialBatch["PartialValues"]]==={1}&&
 partialBatch["PartialValues"][1]["KnownThroughOrder"]===1&&
 partialBatch["PartialValues"][1]["Coefficients"][1]===Pi^2];
FTTest`FTAssert["a changed normalization cannot reuse the master",
 MissingQ[FeynFacet`FindMasterIntegralValue[Append[definition,"MeasurePrefactor"->2definition["MeasurePrefactor"]],{-1,0},request]]];
FTTest`FTAssert["a changed causal prescription cannot reuse the master",
 MissingQ[FeynFacet`FindMasterIntegralValue[Join[definition,<|"Prescription"->{-1},"OriginalPropagatorPrescriptions"->{-1,-1}|>],{-1,0},request]]];
FTTest`FTAssert["different analytic domains and endpoint scope stay distinct",
 MissingQ[FeynFacet`FindMasterIntegralValue[Append[definition,"KinematicConditions"->s<0],{-1,0},request]]&&
 MissingQ[FeynFacet`FindMasterIntegralValue[Append[definition,"EvaluationScope"->"EndpointDistributions"],{-1,0},request]]];
FTTest`FTAssert["a missing coefficient inside the saved range is rejected",
 FailureQ[FeynFacet`StoreMasterIntegralValue[definition,Append[value,"Coefficients"->KeyDrop[value["Coefficients"],0]],request]]];
FTTest`FTAssert["unevaluated masters and free DE constants are rejected",
 FailureQ[FeynFacet`StoreMasterIntegralValue[definition,<|"ExactValue"->FeynCalc`GLI["X",{1}]|>,request]]&&
 FailureQ[FeynFacet`StoreMasterIntegralValue[definition,<|"ExactValue"->FeynFacetSolution`C[1,0]|>,request]]];
extended=Join[value,<|"Coefficients"->Append[value["Coefficients"],2->Zeta[3]],"KnownThroughOrder"->2|>];
FeynFacet`StoreMasterIntegralValue[definition,extended,request];
FTTest`FTAssert["deeper coverage extends the existing master",
 FeynFacet`FindMasterIntegralValue[renamed,{-1,2},request]["Coefficients"][2]===Zeta[3]&&
 FeynFacet`MasterIntegralLibraryInventory[request]["MasterCount"]===1];
FTTest`FTAssert["conflicting overlapping coefficients are rejected",
 FailureQ[FeynFacet`StoreMasterIntegralValue[definition,Append[value,"Coefficients"->Append[value["Coefficients"],0->123]],request]]];
FTTest`FTAssert["a sufficient hit does not invoke the provider",
 calls=0;AssociationQ[FeynFacet`EvaluateWithMasterIntegralLibrary[definition,{-1,1},
 Function[{},calls++;$Failed],request]]&&calls===0];
FTTest`FTAssert["an exact expression cannot contradict stored Laurent data",
 FailureQ[FeynFacet`StoreMasterIntegralValue[definition,<|"ExactValue"->1/ee|>,request]]];
exactFunction=2/ee+Log[s]+Pi^2 ee+Zeta[3]ee^2+ee^3 Exp[ee];
FeynFacet`StoreMasterIntegralValue[definition,<|"ExactValue"->exactFunction|>,request];
exact=FeynFacet`FindMasterIntegralValue[definition,Automatic,request];
FTTest`FTAssert["an exact analytic function is retained as a solved value",
 AssociationQ[exact]&&exact["ExactValue"]===exactFunction];
FTTest`FTAssert["recompute explicitly bypasses lookup",
 MissingQ[FeynFacet`FindMasterIntegralValue[definition,{-1,1},Append[request,"Mode"->"Recompute"]]]];
FTTest`FTAssert["an exact result supplies deeper coefficients without a solver",
 FeynFacet`FindMasterIntegralValue[definition,{-1,5},request]["Coefficients"][5]===1/2];
FTTest`FTAssert["an unrecorded more singular pole contradicts a finite value",
 FailureQ[FeynFacet`StoreMasterIntegralValue[definition,
  <|"Coefficients"-><|0->Log[s],1->Pi^2|>,"LaurentLowerBound"->0,"KnownThroughOrder"->1|>,request]]];
batch=FeynFacet`FindMasterIntegralValues[<|1->definition,2->renamed|>,<|1->{-1,1},2->{0,2}|>,request];
FTTest`FTAssert["a batch request preserves requested row identities",
 TrueQ[batch["Complete"]]&&Keys[batch["Values"]]==={1,2}&&batch["Values"][2]["Coefficients"][2]===Zeta[3]];
physical=<|"MasterIntegralBasis"->{definition["MasterIntegral"]},
 "OriginalMasterLaurentLowerBounds"->{-1},"MasterIntegralUpperOrders"->{1},
 "DimensionalRegulator"->ee,"BoundaryValuesApplied"->True,
 "Coefficients"-><|{1,-1}->2,{1,0}->Log[rho],{1,1}->Pi^2|>|>;
FTTest`FTAssert["a fully explicit physical solution can be published in original coordinates",
 AssociationQ[FeynFacet`StoreMasterIntegralSolution[<|1->definition|>,physical,
  Append[request,"CoordinateRules"->{rho->s}]]]];
FTTest`FTAssert["a solution without applied physical constants is rejected",
 FailureQ[FeynFacet`StoreMasterIntegralSolution[<|1->definition|>,
  Append[physical,"BoundaryValuesApplied"->False],request]]];
Print["LIBRARY TEST DIRECTORY ",dir];
fresh=FeynFacet`EvaluateWithMasterIntegralLibrary[definition,{-1,3},
 Function[{},<|"ExactValue"->exactFunction|>],Append[request,"Mode"->"Recompute"]];
reused=FeynFacet`FindMasterIntegralValue[definition,{-1,3},request];
FTTest`FTAssert["fresh exact providers and library hits have identical finite Laurent coverage",
 AssociationQ[fresh]&&KeyTake[fresh,{"Coefficients","LaurentLowerBound","KnownThroughOrder","ExactInEpsilon"}]===
   KeyTake[reused,{"Coefficients","LaurentLowerBound","KnownThroughOrder","ExactInEpsilon"}]];
FTTest`FTAssert["a fresh finite provider cannot claim unavailable requested coefficients",
 FailureQ[FeynFacet`EvaluateWithMasterIntegralLibrary[definition,{-1,4},
   Function[{},value],Append[request,"Mode"->"Disabled"]]]];
FTTest`FTAssert["disabled library writes still return finite coefficients from an exact provider",
 AssociationQ[FeynFacet`EvaluateWithMasterIntegralLibrary[definition,{-1,3},
   Function[{},<|"ExactValue"->exactFunction|>],Append[request,"Mode"->"Disabled"]]["Coefficients"]]];
FTTest`FTAssert["required scalar provenance is also enforced on a fresh provider",
 FailureQ[FeynFacet`EvaluateWithMasterIntegralLibrary[definition,{-1,0},
  Function[{},<|"ExactValue"->exactFunction|>],Join[request,<|"Mode"->"Disabled",
   "RequiredProvenanceFields"->{"UniversalScalarSources"}|>]]]];
Print["MASTER LIBRARY TEST COMPLETE"];FTTest`FTReport[];
