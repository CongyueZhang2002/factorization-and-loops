
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
invariants={qs rr/(1-rr),-qs(1-ss)/(1-rr),-qs ss/(1-rr)};mass=-qs;
routings=invariants[[#]]&/@{{1,2},{2,3},{1,3}};
resolved=FeynFacet`ResolveMasslessBoxEndpointPowers[Append[#,mass],ep,{rr,ss},
 qs>0&&0<rr<1/3&&0<ss<1/3]&/@routings;
FTTest`FTAssert["all three physical one-mass box routings resolve on the original corner",
 AllTrue[resolved,AssociationQ]&&Lookup[resolved,"ResolutionMethod"]===
 {"CorrelatedHypergeometricDifference","CorrelatedHypergeometricDifference","CorrelatedHypergeometricInversion"}];
exactResolved[record_]:=Total[(Times@@MapThread[Power,{{rr,ss},#["Powers"]}])#["SmoothFactor"]&/@record["Terms"]];
realF[x_,e_]:=If[x<1,Abs[x]^-e Hypergeometric2F1[1,-e,1-e,x],
 Pi e Cot[Pi e]+x^-e(1-Hypergeometric2F1[1,e,1+e,1/x])];
direct[s_,t_,m_,e_]:=Module[{u=m-s-t,phase},
 phase[v_]:=If[v>0,Exp[I Pi e],1];
 2 Gamma[1+e]Gamma[1-e]^2/(e^2 s t Gamma[1-2e])Abs[u/(s t)]^e*
 (phase[t]realF[-u/s,e]+phase[s]realF[-u/t,e]-phase[m]realF[-u m/(s t),e])];
errors=Flatten[Table[
 rule={rr->3/25,ss->7/100,qs->3,ep->e};
 iv=Append[routings[[i]],mass]/.rule;
 reference=N[direct[Sequence@@iv,e],35];
 got=N[exactResolved[resolved[[i]]]/.rule,35];
 Abs[(got-reference)/reference],{i,3},{e,{-1/7,1/11}}]];
Print["Resolved-box relative errors ",errors];
FTTest`FTAssert["exact resolved forms match the original correlated hypergeometric functions",
 Max[errors]<10^-25];
jets=FeynFacet`ExpandMasslessBoxCornerJets[#,{2,2}]&/@resolved;
FTTest`FTAssert["corner jets contain finite polynomials exact in epsilon",
 AllTrue[jets,AssociationQ]&&FreeQ[jets,_AppellF1|_Hypergeometric2F1|_SeriesData|_Series]];
jetExpression[record_]:=Total[(Times@@MapThread[Power,{{rr,ss},#["Powers"]}])#["SmoothFactorTaylorPolynomial"]&/@record["Terms"]];
jetErrors=Flatten[Table[
 rule={rr->1/100000,ss->ratio,qs->3,ep->-1/7};
 reference=N[exactResolved[resolved[[i]]]/.rule,30];
 got=N[jetExpression[jets[[i]]]/.rule,30];
 Abs[(got-reference)/reference],
 {i,3},{ratio,{1/10^10,3/10^5,1/Sqrt[100000]}}]];
FTTest`FTAssert["one corner jet covers strongly unequal approaches as well as comparable scales",
 Max[jetErrors]<10^-6];

faces=Table[FeynFacet`ExpandMasslessBoxFaceJets[record,<|variable->2|>],
 {record,resolved},{variable,{rr,ss}}];
FTTest`FTAssert["both complete edges retain tangential functions without unresolved Appell factors",
 AllTrue[Flatten[faces],AssociationQ]&&FreeQ[faces,_AppellF1|_Derivative|_SeriesData]];
faceJetExpression[record_]:=Total[Map[Function[term,
 Times@@MapThread[Power,{{rr,ss},term["Powers"]}]*
 Total[KeyValueMap[Times@@MapThread[Power,{record["FaceNormalVariables"],#1}]#2&,
  term["NormalTaylorCoefficients"]]]],record["Terms"]]];
faceErrors=Flatten[Table[
 faceRecord=faces[[i,j]];faceVariable={rr,ss}[[j]];tangentVariable={ss,rr}[[j]];
 rule={faceVariable->1/100000,tangentVariable->2/7,qs->3,ep->-1/7};
 ref=N[exactResolved[resolved[[i]]]/.rule,35];
 val=N[faceJetExpression[faceRecord]/.rule,35];
 Abs[(val-ref)/ref],{i,3},{j,2}]];
FTTest`FTAssert["edge jets agree with exact boxes at finite tangential coordinates",
 Max[faceErrors]<10^-10];
decayInvariants=qs*{rz rx(1-rx)/(1-rz rx),rx(1-rz)/(1-rz rx),1-rx};
decay=FeynFacet`ResolveMasslessBoxEndpointPowers[Append[decayInvariants[[#]],qs],ep,{rx},
 qs>0&&0<rx<1&&0<rz<1]&/@{{1,2},{1,3},{2,3}};
FTTest`FTAssert["timelike rational decay invariants retain explicit endpoint valuations",
 AllTrue[decay,AssociationQ]&&FreeQ[Lookup[decay,"Terms"],_Abs]];
Print["MASSLESS BOX ENDPOINT TEST COMPLETE"];
FTTest`FTReport[];
