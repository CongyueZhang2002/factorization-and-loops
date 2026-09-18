#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];
Clear[kl,pp,ee,dimensionTest,drrTestFamily];
top=FeynCalc`FCTopology[drrTestFamily,{FeynCalc`SFAD[kl],FeynCalc`SFAD[pp-kl]},
 {kl},{pp},{FeynCalc`SPD[pp]->3},{}];
input=<|"Topology"->top,"Master"->FeynCalc`GLI[drrTestFamily,{1,1}],
 "Prescription"->{0},"CutIndices"->{1,2},"CutMomenta"->{kl,pp-kl},"DimensionalRegulator"->ee|>;
definitions=ConstructMasterIntegralRepresentations[input];
directory=CreateDirectory[];
record=ConstructMasterIntegralDimensionalRecurrence[definitions,"WorkingDirectory"->directory];
FTAssert["a complete two-body cut recurrence is constructed without an IBP run",
 AssociationQ[record] && record["Reduction"]["IBPReductionRequired"]===False];
dim=record["Dimension"];
FTAssert["the raising matrix contains the dimension-dependent angular factor",
 Cancel[record["RaisingMatrix"][[1,1]]-3/(4(dim-1))]===0 &&
 record["RaisingNormalizationFactor"]===1/(2Pi)];
insertions=FeynFacet`Private`cutDrrInsertions[Values[definitions["MasterIntegralRepresentations"]]];
ibpChoice=FeynCalc`GLI[drrTestFamily,{2,1}];
converted=Catch[FeynFacet`Private`cutDrrAssemble[insertions,
 {First[insertions["MasterIntegralBasis"]]->insertions["Dimension"] ibpChoice}],"EpsilonOrders"];
FTAssert["a rational change from the reducer basis is applied to the Gram insertions",
 Cancel[converted["RaisingMatrix"][[1,1]]-3/(4(insertions["Dimension"]-1))]===0];
(* Independent Gamma representation at two convergent dimensions. *)
volume=definitions["MasterIntegralRepresentations"][1]["Terms"][[1,"Prefactor"]];
FTAssert["the dimensional shift agrees with the independent phase-volume formula",
 And@@Table[FullSimplify[(volume/.ee->(4-d-2)/2)/(volume/.ee->(4-d)/2)-
  record["RaisingNormalizationFactor"] (record["RaisingMatrix"][[1,1]]/.dim->d)]===0,{d,{6,8}}]];
bounds=DetermineLaurentBoundsFromDimensionalRecurrence[record];
FTAssert["no exceptional upward grid poles establish holomorphy at four dimensions",
 bounds["LaurentLowerBounds"]==={0} && bounds["HolomorphicDimension"]===4 &&
 bounds["DimensionSteps"]===0];
scaled=ConstructMasterIntegralRepresentations[input,<|"MasterIntegralPrefactors"-><|1->ee^2|>|>];
cached=ConstructMasterIntegralDimensionalRecurrence[scaled,"WorkingDirectory"->directory];
FTAssert["a cached bare recurrence refreshes the scalar master prefactors",
 cached["IntegralRepresentations"][[1,"MasterIntegralPrefactor"]]===ee^2 &&
 DetermineLaurentBoundsFromDimensionalRecurrence[cached]["LaurentLowerBounds"]==={2}];
FTAssert["kinematic changes cannot reuse an old recurrence directory",
 FailureQ[ConstructMasterIntegralDimensionalRecurrence[
 ConstructMasterIntegralRepresentations[input /. 3 -> 5],"WorkingDirectory"->directory]]];
FTAssert["the denominator factorization finds remote grid poles without a search cutoff",
 FeynFacet`Private`cutDrrCriticalDimensions[
  {{1/((dimensionTest-1000)(dimensionTest-9/2)(dimensionTest^2+1))}},dimensionTest,4]==={1000}];
FTAssert["cancelled denominator zeros are not treated as dimensional poles",
 FeynFacet`Private`cutDrrCriticalDimensions[
  {{(dimensionTest-4)/((dimensionTest-4)(dimensionTest-6))}},dimensionTest,4]==={6}];
altered=Join[record,<|"RaisingNormalizationFactor"->(dim-5)/(dim-7)|>];
FTAssert["an unscanned dimension-dependent scalar factor is refused",
 FailureQ[DetermineLaurentBoundsFromDimensionalRecurrence[altered]]];
FTAssert["a scalar recurrence without physical high-dimensional holomorphy is refused",
 FailureQ[DetermineLaurentBoundsFromDimensionalRecurrence[
  Join[record,<|"IntegralRepresentations"->{Join[First[record["IntegralRepresentations"]],
    <|"TimeDirection"->-pp|>]}|>]]]];

Clear[xx,secondDrrFamily];
multiple=<|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,
 "ConnectionMatrices"->{{{-ee/xx,0},{0,-ee/xx}}},
 "OriginalMasterIntegralBasis"->{FeynCalc`GLI[drrTestFamily,{1,1}],
   FeynCalc`GLI[secondDrrFamily,{1,1}]},
 "Topologies"->{top /. 3->xx,(top /. 3->xx)/.drrTestFamily->secondDrrFamily},
 "Prescription"->{0},"CutIndices"->{1,2},"CutMomenta"->{kl,pp-kl}|>;
multiplePlan=DetermineMasterIntegralExpansionOrders[multiple,<|"BasePoint"->{3},
 "RequestedMasterIntegralOrderRanges"-><|1->{0,0},2->{0,0}|>,
 "CutPoleBoundMethod"->"DimensionalRecurrence"|>];
FTAssert["automatic recurrence construction groups several families",
 multiplePlan["Status"]==="SufficientOrdersDetermined" &&
 Length[multiplePlan["DimensionalRecurrenceBounds"]["FamilyReports"]]===2 &&
 multiplePlan["OrdinaryPointConstantLowerBounds"]==={0,0}];
FTAssert["unknown cut-bound methods are rejected",
 FailureQ[DetermineMasterIntegralExpansionOrders[multiple,<|
 "RequestedMasterIntegralOrderRanges"-><|1->{0,0}|>,"CutPoleBoundMethod"->"unknown"|>]]];

(* The saved complete CF269 recurrence was produced by the general constructor.
   No master-value evaluations enter this check. *)
path=FileNameJoin[{root,"Projects","ppHX_UU","NNLO","qqp-qqp","Results","DoubleReal","EpsilonOrderDetermination",
 "CF269","DimensionalRecurrence.wxf"}];
If[!FileExistsQ[path],Print["Required saved recurrence missing: ",path];Exit[2]];
actual=Import[path,"WXF"];
actualBounds=DetermineLaurentBoundsFromDimensionalRecurrence[actual];
expected={-3,-3,-3,-3,0,0,-1,-1,-3,-3,-3,-3,-3,-3,-1,-2,-2,-3,-2,-3,-3,-3,-3};
FTAssert["the complete actual family has the refined Laurent bounds",
 actualBounds["LaurentLowerBounds"]===expected];
FTAssert["only dimensions four and six obstruct the downward recurrence",
 actualBounds["LoweringMatrixPoleDimensions"]==={4,6} && actualBounds["HolomorphicDimension"]===8];
FTAssert["ordinary rational dimensions validate the raising/lowering inverse",
 actualBounds["InverseIdentityValidation"]["Passed"]===True &&
 FreeQ[actualBounds["InverseIdentityValidation"]["SampleDimensions"],9/2]];
savedPlan=Import[FileNameJoin[{DirectoryName[path],"MasterIntegralExpansionOrders.wxf"}],"WXF"];
sys=savedPlan["PreparedDifferentialSystem"];
request=<|"BasePoint"->{1/4,1/3},"DimensionalRecurrence"->actual,
 "MasterIntegralRepresentations"->AssociationThread[Range[23],actual["IntegralRepresentations"]],
 "RequestedMasterIntegralOrderRanges"->AssociationThread[Range[23],ConstantArray[{-3,0},23]]|>;
plan=DetermineMasterIntegralExpansionOrders[sys,request];
FTAssert["the planner uses recurrence bounds as derived results rather than assumptions",
 plan["Status"]==="SufficientOrdersDetermined" &&
 plan["AssumedMasterLaurentBounds"]==={} &&
 plan["OrdinaryPointConstantLowerBounds"]===expected];
FTAssert["finite original masters require heterogeneous boundary orders and evolution order four",
 plan["OrdinaryPointConstantUpperOrders"]==={0,0,0,0,3,2,0,1,0,1,1,0,0,0,0,1,0,0,0,0,1,0,1} &&
 plan["FundamentalMatrixEpsilonOrders"]["MaximumTransformedOrder"]===4];
FTAssert["a recurrence at a different boundary point is rejected",
 FailureQ[DetermineMasterIntegralExpansionOrders[sys,Join[request,<|"BasePoint"->{1/5,1/3}|>]]]];
FTAssert["the recurrence retains the complete homogeneous lower-sector system",
 Length[actual["OriginalMasterIntegralBasis"]]===23 &&
 Dimensions[actual["RaisingMatrix"]]==={23,23} &&
 actual["Reduction"]["UnreducedIntegrals"]===0];
d=actual["Dimension"];rep=actual["IntegralRepresentations"][[5]];
volume=rep["Terms"][[1,"Prefactor"]];ep=rep["DimensionalRegulator"];
FTAssert["the actual volume row has the AMFlow shift normalization",
 And@@Table[FullSimplify[(volume/.ep->(4-dim0-2)/2)/(volume/.ep->(4-dim0)/2)-
 actual["RaisingNormalizationFactor"] (actual["RaisingMatrix"][[5,5]]/.d->dim0)]===0,{dim0,{8,10}}] &&
 Count[actual["RaisingMatrix"][[5]],x_ /; x=!=0]===1];
FTReport[];
