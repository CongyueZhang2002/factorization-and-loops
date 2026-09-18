Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
bsCard=FeynFacet`BuildCountertermProjectCard[root<>"/Projects/SIDIS_UU/Raw/NNLO/q-q"];
(* Synthetic complete bare distributions isolate charge covariance from retained
   process outputs. Consumer-owned generation is checked separately. *)
bsRow[d_]:=<|"DeltaCoefficient"->{d,2d},"PlusCoefficients"-><|0->{3d,5d}|>,
 "RegularCoefficient"->{(1+x)d,(1+z)d}|>;
bsTree[d_]:=<|"DeltaCoefficient"->bsRow[d],"PlusCoefficients"-><|1->bsRow[2d]|>,
 "RegularCoefficient"->bsRow[3d]|>;
bsResult[order_,channel_,hi_]:=FeynFacet`CreatePartonicResult[
 Association@Table[k->bsTree[(k+3)eU^2 FeynFacet`\[Alpha]s^order],{k,If[order===0,0,-2],hi}],
 Join[KeyTake[bsCard["Assembly"],{"Scale","Variables","DistributionBasis","DensityConvention","CurrentNormalization"}],
 <|"Order"->{"LO","NLO"}[[order+1]],"Contribution"->"Bare","Channel"->channel,
 "DimensionalRegulator"->Global`Epsilon,"RenormalizationStage"->"Bare",
 "CouplingPower"->order,"StructureFunctions"->bsCard["StructureFunctions"]|>]];
bsRows=Association@Table[order->Association@Table[channel->bsResult[order,channel,2-order],
 {channel,Select[Keys[bsCard["Channels"]],bsCard["MinimumChannelOrders"][#]<=order&]}],{order,0,1}];
bsCatalog=<|"Format"->"FeynFacet-BarePartonicSourceCatalog","Sources"->bsRows,
 "Channels"->bsCard["Channels"],"MinimumChannelOrders"->bsCard["MinimumChannelOrders"],
 "FlavorClasses"->bsCard["FlavorClasses"],"ChargeSymbols"->{eU,eD},
 "FlavorCovariance"->"SingleMasslessQuarkLine","Project"->bsCard["Project"],
 "Polarization"->bsCard["Polarization"]|>;
FTTest`FTAssert["bare-source fixture has the declared LO and NLO channel coverage",
 AssociationQ[bsCatalog]&&Length[bsCatalog["Sources"][0]]===2&&Length[bsCatalog["Sources"][1]]===6&&
 AllTrue[Join[Values[bsRows[0]],Values[bsRows[1]]],AssociationQ]];
bsSource=FeynFacet`ResolveBarePartonicSource[bsCatalog,1,{{"q","newDown"},{"q","newDown"}},
 <|"newDown"->"DownType"|>,1];
bsOriginal=bsCatalog["Sources"][1]["q-q"];
If[!AssociationQ[bsSource],Print["SOURCE FAILURE ",bsSource]];
bsRestored=Map[FeynFacet`Private`partonicMap[Function[value,Cancel[Together[eU^2 value/eD^2]]],#]&,bsSource["Coefficients"]];
bsSubtracted=MapThread[FeynFacet`Private`partonicDistributionSum[{#1,
 FeynFacet`Private`partonicMap[Function[value,-value],#2]},2]&, {Values[bsRestored],Values[bsOriginal["Coefficients"]]}];
bsResidual=Map[FeynFacet`Private`partonicMap[Function[value,Cancel[Together[value]]],#]&,bsSubtracted];
FTTest`FTAssert["flavor relabeling proves the charge factor throughout the full distribution",
 AssociationQ[bsSource]&&bsSource["FlavorRelabeling"]["ChargeIndependentRemainderVerified"]&&
 FreeQ[bsSource["Coefficients"],eU]&&!FreeQ[bsSource["Coefficients"],eD]&&
 FeynFacet`Private`partonicZeroTreeQ[bsResidual]];
FTTest`FTAssert["a distinct-flavor channel is zero only below its explicit minimum order",
 FeynFacet`ResolveBarePartonicSource[bsCatalog,1,{{"q","u"},{"q","d"}},
 <|"u"->"UpType","d"->"DownType"|>,1]===0];
bsMissing=Join[bsCatalog,<|"Sources"->Join[bsCatalog["Sources"],<|1->KeyDrop[bsCatalog["Sources"][1],"q-q"]|>]|>];
FTTest`FTAssert["a missing allowed channel is not inferred to be zero",
 FailureQ[FeynFacet`ResolveBarePartonicSource[bsMissing,1,{{"q","u"},{"q","u"}},<|"u"->"UpType"|>,1]]];
FTTest`FTAssert["positive epsilon coverage is mandatory",
 FailureQ[FeynFacet`ResolveBarePartonicSource[bsCatalog,1,{{"q","u"},{"q","u"}},<|"u"->"UpType"|>,2]]];
bsContaminated=bsCatalog;
bsBadBorn=Join[bsCatalog["Sources"][0]["q-q"],<|"Coefficients"->Map[
 FeynFacet`Private`partonicMap[Function[value,value+nD eD^2],#]&,bsCatalog["Sources"][0]["q-q"]["Coefficients"]]|>];
bsContaminated=Join[bsCatalog,<|"Sources"->Join[bsCatalog["Sources"],
 <|0->Join[bsCatalog["Sources"][0],<|"q-q"->bsBadBorn|>]|>]|>];
FTTest`FTAssert["an internal flavor-charge sum cannot be relabeled as an external squared charge",
 FailureQ[FeynFacet`ResolveBarePartonicSource[bsContaminated,0,{{"q","newDown"},{"q","newDown"}},
 <|"newDown"->"DownType"|>,2]]];
bsWrongStage=Join[bsCatalog,<|"Sources"->Join[bsCatalog["Sources"],
 <|1->Join[bsCatalog["Sources"][1],<|"q-q"->Join[bsOriginal,<|"RenormalizationStage"->"Renormalized"|>]|>]|>]|>];
FTTest`FTAssert["a finite hard result cannot stand in for a bare source",
 FailureQ[FeynFacet`ResolveBarePartonicSource[bsWrongStage,1,{{"q","u"},{"q","u"}},
 <|"u"->"UpType"|>,0]]];
bsDY=FeynFacet`CreatePartonicResult[<|
 0-><|"DeltaCoefficient"->{eU^2},"PlusCoefficients"-><||>,"RegularCoefficient"->{0}|>,
 1-><|"DeltaCoefficient"->{-eU^2},"PlusCoefficients"-><||>,"RegularCoefficient"->{0}|>|>,
 <|"Order"->"LO","Contribution"->"Born","Scale"->Q2,"Variables"->{z},
 "DimensionalRegulator"->Global`Epsilon,"RenormalizationStage"->"Bare","StructureFunctions"->{"C_DY"},
 "DistributionBasis"-><|"Axes"->{<|"Variable"->z,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-z|>}|>|>];
bsDYCatalog=Join[bsCatalog,<|"Channels"-><|"q-qb"-><|"Incoming"->{{"q","u"},{"qb","u"}}|>|>,
 "MinimumChannelOrders"-><|"q-qb"->0|>,"Sources"-><|0-><|"q-qb"->bsDY|>|>|>];
bsDYResolved=FeynFacet`ResolveBarePartonicSource[bsDYCatalog,0,{{"q","newDown"},{"qb","newDown"}},
 <|"newDown"->"DownType"|>,1];
FTTest`FTAssert["a two-incoming-leg source preserves both beams without inventing an observed FF leg",
 AssociationQ[bsDYResolved]&&bsDYResolved["PhysicalChannel"]["Incoming"]===
 {{"q","newDown"},{"qb","newDown"}}&&!KeyExistsQ[bsDYResolved["PhysicalChannel"],"Observed"]&&
 bsDYResolved["Coefficients"][0]["DeltaCoefficient"]==={eD^2}&&
 bsDYResolved["Coefficients"][1]["DeltaCoefficient"]==={-eD^2}];

(* A QCD source keeps the complete recoil identity; it has no electromagnetic
   charge reweighting. The scalar entries are deliberately independent. *)
bsQCDChannel=<|"Incoming"->{{"q","u"},{"q","d"}},"Observed"->{"q","u"},"Recoil"->{"q","d"}|>;
bsQCDSource=FeynFacet`CreatePartonicResult[Association@Table[k->
 <|"DeltaCoefficient"->k+3,"PlusCoefficients"-><|0->(k+3)bsQCDPlus|>,"RegularCoefficient"->(k+3)w|>,
 {k,-2,1}],<|"Order"->"NLO","Contribution"->"Bare","Scale"->Q2,"Variables"->{v,w},
 "DimensionalRegulator"->Global`Epsilon,"RenormalizationStage"->"Bare","CouplingPower"->3,
 "PhysicalChannel"->bsQCDChannel|>];
bsQCDCatalog=<|"Format"->"FeynFacet-BarePartonicSourceCatalog","FlavorCovariance"->"MasslessQCD",
 "Channels"-><|"qqp-qqp"->bsQCDChannel|>,"MinimumChannelOrders"-><|"qqp-qqp"->0|>,
 "Sources"-><|1-><|"qqp-qqp"->bsQCDSource|>|>|>;
bsQCDTarget={{"q","c"},{"q","s"},{"q","c"}};
bsQCDResolved=FeynFacet`ResolveBarePartonicSource[bsQCDCatalog,1,bsQCDTarget,
 <|"c"->"UpType","s"->"DownType"|>,1,"qqp-qqp"];
FTTest`FTAssert["massless QCD relabeling preserves all scalars and the physical recoil flavor",
 AssociationQ[bsQCDResolved]&&bsQCDResolved["Coefficients"]===bsQCDSource["Coefficients"]&&
 bsQCDResolved["PhysicalChannel"]===<|"Incoming"->{{"q","c"},{"q","s"}},
  "Observed"->{"q","c"},"Recoil"->{"q","s"}|>&&
 bsQCDResolved["FlavorRelabeling"]["FullPhysicalChannelRetained"]];
bsQCDDuplicate=Join[bsQCDCatalog,<|"Channels"-><|"qqp-qqp"->bsQCDChannel,"same-active-source"->bsQCDChannel|>,
 "MinimumChannelOrders"-><|"qqp-qqp"->0,"same-active-source"->0|>,
 "Sources"-><|1-><|"qqp-qqp"->bsQCDSource,"same-active-source"->bsQCDSource|>|>|>];
FTTest`FTAssert["multiple QCD sources with the same active species require explicit channel selection",
 FailureQ[FeynFacet`ResolveBarePartonicSource[bsQCDDuplicate,1,{{"q","u"},{"q","d"},{"q","u"}},<||>,1]]&&
 AssociationQ[FeynFacet`ResolveBarePartonicSource[bsQCDDuplicate,1,bsQCDTarget,<||>,1,"qqp-qqp"]]];
bsQCDEquivalent=FeynFacet`ResolveBarePartonicSource[bsQCDDuplicate,1,bsQCDTarget,<||>,1];
FTTest`FTAssert["covariant QCD candidates use one representative per complete flavor and recoil pattern",
 AssociationQ[bsQCDEquivalent]&&bsQCDEquivalent["Coefficients"]===bsQCDSource["Coefficients"]&&
 bsQCDEquivalent["PhysicalChannel"]["Recoil"]==={"q","s"}];
FTTest`FTAssert["an explicit QCD source selection must still match the requested flavor pattern",
 FailureQ[FeynFacet`ResolveBarePartonicSource[bsQCDCatalog,1,ConstantArray[{"q","c"},3],<||>,1,"qqp-qqp"]]];

FTTest`FTReport[];
