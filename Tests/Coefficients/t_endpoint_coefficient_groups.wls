Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;$HistoryLength=0;
Clear[e,z,v,A];checks=0;
check[label_,condition_]:=If[TrueQ[condition],checks++,Print["FAIL ",label," ",condition];Exit[1]];
master=FeynCalc`GLI[A,{1}];id={"A",{1}};
makeFrame[gauge_]:=<|"Dimension"->1,"GaugeLeafCount"->LeafCount[gauge],
 "OriginalMasterIntegralBasis"->{master},"RowsByIntegralClass"-><|id->{1}|>,
 "SourceDifferentialSystemFile"->"source.wxf","AcceptedEndpointBinding"-><|"Test"->True|>,
 "Endpoint"-><|"NormalVariable"->z,"TangentialVariable"->v,"DimensionalRegulator"->e,
  "NormalGaugeMatrix"->{{gauge}}|>|>;
topology=<|"Topology"->FeynCalc`FCTopology[A,{FeynCalc`FeynAmpDenominator[
 FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[k,D],0,0,{1,1}]]},{k},{p},{ }],
 "CutIndices"->{1},"CutMomenta"->{k},"CutDirections"->{1}|>;
cutCatalog=<|"Integrals"->{master},"Families"->{topology},"Normalization"->"Test physical measure"|>;
catalog[gauge_]:=<|"CutCatalog"->cutCatalog,"Frames"-><|"A"->makeFrame[gauge]|>,"IntegralClasses"-><|id->id|>|>;
table[terms_]:=<|"Format"->"FeynFacet-MasterIntegralCoefficients",
 "TargetCatalog"->cutCatalog,"Definitions"-><|"Topologies"->{topology}|>,
 "PhysicalMasterNormalizationApplied"->True,"DimensionalRegulator"->e,"PreFactor"->1,
 "Source"->"source-coefficients.wxf","RemainderTerms"->{},
 "Masters"->{<|"Master"->master,"Terms"->terms|>}|>;
exact[x_]:=<|"Representation"->"Exact","PreFactor"->1,"Coefficient"->x|>;
request=<|"ThroughOrder"->0,"KinematicRules"->{},"FrameTimeLimit"->30|>;
pp=Catch[FeynFacet`Private`endpointGroupPrincipalPart[
  3/(z-e)^2+2/(z-e)+1/(z+1),z,e,e],"EndpointGroups"];
check["complete higher principal part",AssociationQ[pp]&&pp["PoleOrder"]===2&&
 Together[pp["PrincipalPart"]-3/(z-e)^2-2/(z-e)]===0];
one=FeynFacet`ConstructEndpointCoefficientGroups[table[{exact[1/(z-e)]}],catalog[z-e],request];
check["singular determinant allowed",AssociationQ[one]&&Length[one["CoefficientInputs"]]===1&&
 First[Values[one["CoefficientInputs"]]]["NormalizedCoefficientRow"]==={1}];
bad=FeynFacet`ConstructEndpointCoefficientGroups[table[{exact[1/(z-e)]}],catalog[1/(z-e)],request];
check["moving pole in embedding rejected",FailureQ[bad]];
finite=<|"Representation"->"LaurentSeries","PreFactor"->1,
 "Coefficient"-><|"SeriesVariable"->e,"Orders"-><|0->1,1->2|>,"SeriesTruncation"->1|>,
 "LaurentRemainderClass"-><|"Status"->"source-bound"|>|>;
shared=FeynFacet`ConstructEndpointCoefficientGroups[
 table[{finite,exact[1/(z-e)+2/(z+e)]}],catalog[(z-e)(z+e)],request];
If[!AssociationQ[shared],Print["SHARED FAILURE ",shared]];
check["shared source gives two groups and a remainder",AssociationQ[shared]&&Length[shared["CoefficientInputs"]]===3];
ordinary=shared["CoefficientInputs"]["A"]["CoefficientEntries"][[1]];
check["fresh finite prefix unchanged",ordinary["Terms"][[1]]===finite&&TrueQ[shared["FiniteRegularCoefficientsUnchanged"]]];
check["only exact exceptional term subtracted",ordinary["Terms"][[2,"Coefficient"]]===0&&
 Length[shared["RemovedCoefficientPieces"]]===2&&Union[Lookup[shared["RemovedCoefficientPieces"],"SourceTermIndex"]]==={2}];
check["exact parts recombine",Together[Total[Lookup[shared["AddedCoefficientPieces"],"PoleExpression"]]-1/(z-e)-2/(z+e)]===0];
check["separate labels in same family",DuplicateFreeQ[Lookup[Values[shared["CoefficientInputs"]],"ContributionLabel"]]&&
 Union[Lookup[Values[shared["CoefficientInputs"]],"Family"]]==={"A"}];
different=table[{exact[1/(z-e)]}];
different["Definitions"]=<|"Topologies"->{Append[topology,"MeasurePrefactor"->2]}|>;
check["same master label with changed definition rejected",
 FailureQ[FeynFacet`ConstructEndpointCoefficientGroups[different,catalog[z-e],request]]];
check["unbound physical catalog rejected",
 FailureQ[FeynFacet`ConstructEndpointCoefficientGroups[
 KeyDrop[table[{exact[1/(z-e)]}],"TargetCatalog"],catalog[z-e],request]]];
collisionCatalog=Append[catalog[z-e],"Frames"-><|"PoleGroup0001"->makeFrame[z-e]|>];
check["pole label cannot overwrite an ordinary contribution",
 FailureQ[FeynFacet`ConstructEndpointCoefficientGroups[
 table[{finite,exact[1/(z-e)]}],collisionCatalog,request]]];
Print["ENDPOINT COEFFICIENT GROUP TESTS PASS ",checks];
