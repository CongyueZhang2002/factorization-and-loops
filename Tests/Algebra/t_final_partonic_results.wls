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
FTReport[];
