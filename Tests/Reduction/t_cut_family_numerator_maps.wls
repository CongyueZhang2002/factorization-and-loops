Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
prop[m_,eta_:1]:=FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[m,D],0,0,{1,eta}]];
measurement=FeynCalc`FeynAmpDenominator[FeynCalc`GenericPropagatorDenominator[
 FeynCalc`FCI[zz FeynCalc`SPD[kk,qq]^2-ss^2],{1,1}]];
cuts={<|"Index"->1,"Type"->"Particle","Momentum"->kk,"EnergyDirection"->1|>,
 <|"Index"->2,"Type"->"Particle","Momentum"->qq-kk,"EnergyDirection"->1|>,
 <|"Index"->3,"Type"->"Measurement"|>};
family[name_,props_]:=FeynFacet`CreateCutIntegralFamily[<|
 "Topology"->FeynCalc`FCTopology[name,props,{kk},{qq},FeynCalc`FCI[{FeynCalc`SPD[qq]->ss}],{}],
 "Cuts"->cuts,"MeasurePrefactor"->1,"TimeDirection"->qq,"Assumptions"->ss>0|>];
rep=family[AffineRepresentative,{prop[kk],prop[qq-kk],measurement,prop[kk+3qq]}];
src=family[NumeratorSource,{prop[kk],prop[qq-kk],measurement,prop[kk+3qq],prop[kk+qq]}];
If[!AllTrue[{rep,src},AssociationQ],Print[InputForm[{rep,src}]];Exit[1]];
ri=FeynCalc`GLI[AffineRepresentative,{1,1,1,1}];si=FeynCalc`GLI[NumeratorSource,{1,1,1,1,-1}];
maps=FeynFacet`FindCutIntegralFamilyMaps[{ri,si},{rep,src}];
FTTest`FTAssert["polynomial measurement families match independently of auxiliary numerator choices",
 AssociationQ[maps]&&maps["RepresentativeFamilyCount"]===1];
If[!AssociationQ[maps],Print[InputForm[maps]];Exit[1]];
map=SelectFirst[maps["Mappings"],#["SourceFamily"]===NumeratorSource&];
vars=rep["DenominatorVariables"];
FTTest`FTAssert["the numerator image is an off-shell affine sum with a constant",
 Expand[map["MappedInversePropagators"][[-1]]-(2vars[[1]]-vars[[2]]+2ss)]===0];
FTTest`FTAssert["unit-cut multiplication removes exactly the pinched terms",
 FeynFacet`ApplyCutIntegralFamilyMap[si,map]===2ss ri];
dotted=ReplacePart[si,{2,1}->2];
FTTest`FTAssert["dotted cuts retain the lower positive power under polynomial multiplication",
 Expand[FeynFacet`ApplyCutIntegralFamilyMap[dotted,map]-
  (2ri+2ss FeynCalc`GLI[AffineRepresentative,{2,1,1,1}])]===0];
FTTest`FTAssert["a positive unmatched auxiliary slot is outside the certified sectors",
 MatchQ[FeynFacet`ApplyCutIntegralFamilyMap[ReplacePart[si,{2,5}->1],map],
  Failure["IntegralOutsideMappedPositiveSectors",_]]];
flipped=family[OppositePrescription,{prop[kk],prop[qq-kk],measurement,prop[kk+3qq,-1],prop[kk+qq]}];
separate=FeynFacet`FindCutIntegralFamilyMaps[{ri,FeynCalc`GLI[OppositePrescription,si[[2]]]},{rep,flipped}];
FTTest`FTAssert["opposite ordinary prescriptions cannot reuse a family map",
 AssociationQ[separate]&&separate["RepresentativeFamilyCount"]===2];
Print["CUT FAMILY NUMERATOR MAP TEST COMPLETE"];
FTTest`FTReport[];
