Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
dir=CreateDirectory[];req=<|"LibraryDirectory"->dir,"Mode"->"ReadWrite","IBPTimeLimit"->20|>;
top=FeynCalc`FCTopology[TestBubble,FeynCalc`FCI[FeynCalc`SFAD[#]]&/@{ell,ell-p},
 {ell},{p},FeynCalc`FCI[{FeynCalc`SPD[p]->s}],{}];
input=<|"MasterIntegralBasis"->{FeynCalc`GLI[TestBubble,{1,1}],FeynCalc`GLI[TestBubble,{2,1}]},
 "Topologies"->{<|"Topology"->top|>},"DimensionalRegulator"->ep,"KinematicConditions"->s>0|>;
defs=FeynFacet`ConstructMasterIntegralDefinitions[input]["MasterIntegralDefinitions"];
a=FeynFacet`EvaluateOneLoopIntegral[defs[1],{-1,2}];
b=FeynFacet`EvaluateOneLoopIntegral[defs[2],{-1,1}];
FeynFacet`StoreMasterIntegralValue[defs[1],a,req];
found=FeynFacet`FindMasterIntegralValue[defs[2],{-1,1},req];
Print["RELATION RESULT ",If[AssociationQ[found],found["LibraryReuse"],found]];
FTTest`FTAssert["a dotted master is reduced to stored masters by actual IBP equations",
 AssociationQ[found]&&found["LibraryReuse"]["IdentityMethod"]==="ExactIBPRowReduction"];
If[!AssociationQ[found],Exit[1]];
FTTest`FTAssert["the derived dotted bubble agrees with direct analytic integration",
 AllTrue[Range[-1,1],FullSimplify[found["Coefficients"][#]-b["Coefficients"][#],
  Assumptions->s>0]===0&]];
FTTest`FTAssert["a verified relation is stored instead of a duplicate solved expression",
 FeynFacet`MasterIntegralLibraryInventory[req]["MasterCount"]===1&&
 Length[FileNames["Relations.wl",dir,Infinity]]===1];
again=FeynFacet`FindMasterIntegralValue[defs[2],{-1,0},Append[req,"IBPTimeLimit"->0.000001]];
FTTest`FTAssert["a stored relation does not redo the IBP reduction",
 AssociationQ[again]&&again["LibraryReuse"]["IdentityMethod"]==="ExactIBPRowReduction"];
(* In D=3-2 epsilon the bubble relation has an epsilon pole in the
   inverse direction: I(1,1)=s/(2 epsilon) I(2,1). *)
dir3=CreateDirectory[];req3=<|"LibraryDirectory"->dir3,"Mode"->"ReadWrite","IBPTimeLimit"->20|>;
three=Map[Append[#,"Dimension"->3-2ep]&,defs];
exact=FeynFacet`Private`oneLoopSingleScaleGamma[{s},{2,1},3-2ep,1,s>0];
finite=Normal[Series[exact,{ep,0,1}]];
value3=<|"Coefficients"->Association@Table[k->Coefficient[Expand[finite],ep,k],{k,0,1}],
 "LaurentLowerBound"->0,"KnownThroughOrder"->1|>;
FeynFacet`StoreMasterIntegralValue[three[2],value3,req3];
pole=FeynFacet`FindMasterIntegralValue[three[1],{0,0},req3];
expected=Normal[Series[s exact/(2ep),{ep,0,0}]];
FTTest`FTAssert["an IBP coefficient epsilon pole requests the extra stored order",
 AssociationQ[pole]&&Simplify[pole["Coefficients"][0]-expected,Assumptions->s>0]===0];
tooDeep=FeynFacet`FindMasterIntegralValue[three[1],{0,1},req3];
FTTest`FTAssert["insufficient IBP epsilon coverage is an explicit miss",
 MatchQ[tooDeep,Missing["InsufficientStoredEpsilonCoverage",_]]];
readDir=CreateDirectory[];readReq=Append[req3,"LibraryDirectory"->readDir];
FeynFacet`StoreMasterIntegralValue[three[2],value3,readReq];
readResult=FeynFacet`FindMasterIntegralValue[three[1],{0,0},Append[readReq,"Mode"->"ReadOnly"]];
FTTest`FTAssert["ReadOnly derives a relation without publishing any file",
 AssociationQ[readResult]&&FileNames["Relations.wl",readDir,Infinity]==={}];
FTTest`FTAssert["the inventory distinguishes values from IBP relations",
 FeynFacet`MasterIntegralLibraryInventory[req3]["RelationCount"]===1&&
 FeynFacet`MasterIntegralLibraryInventory[req3]["MasterCount"]===1];
(* Consistency is checked when the library contains an overcomplete set. *)
over=Append[req,"LibraryDirectory"->CreateDirectory[]];
FeynFacet`StoreMasterIntegralValue[defs[1],<|"ExactValue"->1|>,over];
FeynFacet`StoreMasterIntegralValue[defs[2],<|"ExactValue"->-(1-2ep)/s|>,over];
target=FeynFacet`Private`masterLibraryPowerDefinition[defs[1],{3,1}];
consistent=FeynFacet`FindMasterIntegralValue[target,{-1,0},over];
FTTest`FTAssert["an overcomplete but consistent stored basis is allowed",AssociationQ[consistent]];
badReq=Append[req,"LibraryDirectory"->CreateDirectory[]];
FeynFacet`StoreMasterIntegralValue[defs[1],<|"ExactValue"->1|>,badReq];
FeynFacet`StoreMasterIntegralValue[defs[2],<|"ExactValue"->-2(1-2ep)/s|>,badReq];
inconsistent=FeynFacet`FindMasterIntegralValue[target,{-1,0},badReq];
FTTest`FTAssert["inconsistent stored masters exposed by IBP are rejected",
 MatchQ[inconsistent,Failure["StoredIBPConstraintNotSatisfied",_]]];
FTTest`FTReport[];
