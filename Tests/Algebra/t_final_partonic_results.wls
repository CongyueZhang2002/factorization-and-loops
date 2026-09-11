$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
meta=<|"Order"->"NNLO","Contribution"->"Total","Scale"->q2,"Variables"->{xx},
 "DimensionalRegulator"->ee,"StructureFunctions"->{"A"},
 "DistributionBasis"-><|"Axes"->{<|"Variable"->xx,"NormalVariable"->rr,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-xx|>}|>|>;
row[value_]:=<|"DeltaCoefficient"->{value},"PlusCoefficients"-><|0->{value}|>,"RegularCoefficient"->{value}|>;
result=FeynFacet`CreatePartonicResult[<|-1->row[0],0->row[(1+xx)^2]|>,meta];
FTAssert["auxiliary normal-variable names are absent from physical result conventions",
 !KeyExistsQ[First[result["DistributionBasis"]["Axes"]],"NormalVariable"]];
flat=FeynFacet`PartonicScalarCoefficientRules[result];
FTAssert["the recursive result has complete scalar coefficient indexing",
 Length[flat]===6&&flat[{0,"Regular",1}]===(1+xx)^2];
check=FeynFacet`VerifyPartonicPoleCancellation[<|"toy"->result|>,{{xx->1/3,q2->1}},<|"WorkingPrecision"->30,"AbsoluteTolerance"->10^-20|>];
FTAssert["all pole coefficients are checked without a literature reference",
 AssociationQ[check]&&check["Status"]==="Passed"&&check["CoefficientCount"]===3&&!check["AlgebraicIdentityProof"]];
final=FeynFacet`FinalizePartonicResults[<|"toy"->result|>,check,<||>];
FTAssert["finite coefficient extraction preserves the computed expression",
 final["toy"]["EpsilonRange"]==={0,0}&&final["toy"]["Coefficients"][0]===result["Coefficients"][0]];
changed=result;changed["Coefficients"]=Join[changed["Coefficients"],<|-1->row[1]|>];
FTAssert["a pole check cannot be reused after changing a source coefficient",
 FailureQ[FeynFacet`FinalizePartonicResults[<|"toy"->changed|>,check,<||>]]];
expr=(a+I b)Log[xx]+PolyLog[2,1-xx];
conjugate=FeynFacet`ConjugateExplicitScalarFunctions[expr,0<xx<1];
FTAssert["causal interference conjugation preserves real analytic logarithms",
 Simplify[conjugate-((a-I b)Log[xx]+PolyLog[2,1-xx]),0<xx<1]===0];
FTAssert["unresolved function branches are refused by scalar conjugation",
 FailureQ[FeynFacet`ConjugateExplicitScalarFunctions[unknownFunction[xx],0<xx<1]]];
temp=FileNameJoin[{$TemporaryDirectory,"feynfacet-partonic-basis-"<>ToString[$ProcessID]<>".wl"}];
FeynFacet`FamilyArtifactWrite[result,temp];
FTAssert["card normal-coordinate labels do not change the physical distribution basis",
 AssociationQ[FeynFacet`ReadPartonicResult[temp,<|"DistributionBasis"->meta["DistributionBasis"]|>]]];
DeleteFile[temp];

exact=FeynFacet`VerifyPartonicPoleCancellation[<|"toy"->result|>];
FTAssert["exact pole verification remains distinct from numerical evidence",
 exact["Status"]==="Passed"&&exact["AlgebraicIdentityProof"]&&
 FailureQ[FeynFacet`FinalizePartonicResults[<|"toy"->result|>,check,<|"RequireAlgebraicIdentityProof"->True|>]]];
short=FeynFacet`CreatePartonicResult[<|0->row[1]|>,Join[meta,<|"LaurentLowerBound"->-1|>]];
FTAssert["an omitted possible pole cannot pass a vacuous pole check",
 FailureQ[FeynFacet`VerifyPartonicPoleCancellation[<|"short"->short|>]]];
FTAssert["numerical checks require exact parameter inputs",
 FailureQ[FeynFacet`VerifyPartonicPoleCancellation[<|"toy"->result|>,{{xx->0.3}}]]];
changed=Join[result,<|"Assumptions"->xx>1|>];
FTAssert["changed branch assumptions invalidate a stored pole check",
 FailureQ[FeynFacet`FinalizePartonicResults[<|"toy"->changed|>,exact,<||>]]];
changed=result;changed["Coefficients"]=Join[changed["Coefficients"],<|0->row[FeynCalc`D0[xx]]|>];
FTAssert["a pole check does not certify an unresolved finite integral",
 FailureQ[FeynFacet`FinalizePartonicResults[<|"toy"->changed|>,exact,<||>]]];
changed=result;changed["Coefficients"]=Join[changed["Coefficients"],<|0->row[2+xx]|>];
changedFinal=FeynFacet`FinalizePartonicResults[<|"toy"->changed|>,exact,<||>];
FTAssert["a pole certificate does not replace finite coefficients from its actual input",
 changedFinal["toy"]["Coefficients"][0]===changed["Coefficients"][0]];
twoMeta=Join[meta,<|"Variables"->{xx,zz},"StructureFunctions"->{"A","B"},
 "DistributionBasis"-><|"Axes"->{First[meta["DistributionBasis"]["Axes"]],
  <|"Variable"->zz,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-zz|>}|>|>];
vectorRow[v_]:=<|"DeltaCoefficient"->v,"PlusCoefficients"-><|1->v|>,"RegularCoefficient"->v|>;
nested[v_]:=vectorRow[vectorRow[v]];
two=FeynFacet`CreatePartonicResult[<|-1->nested[{0,0}],0->nested[{xx,zz}]|>,twoMeta];
twoFlat=FeynFacet`PartonicScalarCoefficientRules[two];
twoCheck=FeynFacet`VerifyPartonicPoleCancellation[<|"two"->two|>];
twoFinal=FeynFacet`FinalizePartonicResults[<|"two"->two|>,twoCheck,<||>];
FTAssert["two components and two axes retain every distinct coefficient",
 Length[twoFlat]===36&&twoFlat[{0,"Regular",{"Plus",1},2}]===zz&&
 twoFinal["two"]["Coefficients"][0]===two["Coefficients"][0]];
opposite=FeynFacet`CreatePartonicResult[<|-1->nested[{xx,-xx}],0->nested[{0,0}]|>,twoMeta];
FTAssert["opposite poles in separate structure functions do not cancel",
 FeynFacet`VerifyPartonicPoleCancellation[<|"two"->opposite|>]["Status"]==="Failed"];
FTAssert["missing vector components cannot become zeros",
 FailureQ[FeynFacet`CreatePartonicResult[<|0->nested[{1}]|>,twoMeta]]];

positive=FeynFacet`CreatePartonicResult[<|-1->row[0],0->row[1],1->row[2]|>,meta];
positiveCheck=FeynFacet`VerifyPartonicPoleCancellation[<|"toy"->positive|>];
positiveFinal=FeynFacet`FinalizePartonicResults[<|"toy"->positive|>,positiveCheck,
 <|"EpsilonRanges"-><|"toy"->{1,1}|>|>]["toy"];
FTAssert["extracting a positive epsilon slice does not assert that lower finite coefficients vanish",
 positiveFinal["LaurentLowerBound"]===0&&
 FailureQ[FeynFacet`CombinePartonicResults[<|"slice"->positiveFinal|>,<||>]]];
FTReport[];
