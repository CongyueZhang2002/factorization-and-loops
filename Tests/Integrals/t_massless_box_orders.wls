Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
reference=Import[root<>"/Tests/Support/MasslessBoxCausalReferences.json","RawJSON"];
readNumber[s_String]:=ToExpression[StringReplace[s,{"e"->"`50*^"}]<>If[StringContainsQ[s,"e"],"","`50"],InputForm];
Do[
 inputs=row["Invariants"];
 data=EvaluateMasslessBoxIntegral[inputs,eps,{-2,2},True];
 If[FailureQ[data],Print[data]];
 FTAssert["explicit box through epsilon squared in chamber "<>ToString[inputs,InputForm],
  AssociationQ[data]&&And@@Table[
   expected=readNumber[entry["Real"]]+I readNumber[entry["Imaginary"]];
   actual=N[data["Coefficients"][[Key[{1,entry["Order"]}]]],35];
   If[!NumberQ[actual]||!TrueQ[Abs[actual-expected]<10^-28],Print["DIFFERENCE ",inputs," ",entry["Order"]," ",N[actual-expected,12]]];
   NumberQ[actual]&&Abs[actual-expected]<10^-28,
  {entry,row["Coefficients"]}]],
 {row,reference["Rows"]}];
onShell=EvaluateMasslessBoxIntegral[{2,-3,0},eps,{-2,0},True];
FTAssert["the on-shell limit has the two infrared double-pole terms",
 onShell["Coefficients"][[Key[{1,-2}]]]==-2/3];
diagonal=EvaluateMasslessBoxIntegral[{3,-2,-2},eps,{-2,2},True];
FTAssert["the removable internal diagonal is finite at every stored order",
 AssociationQ[diagonal]&&FreeQ[diagonal["Coefficients"],Indeterminate|_DirectedInfinity]];
(* Verify the weight-two reduction independently of the final box evaluator,
   including every real sign chamber and both causal prescriptions. *)
FTAssert["the on-shell weight-two Gauss sum equals its causal logarithms in every real sign chamber",
 And@@Flatten[Table[
  With[{ss=point[[1]],tt=point[[2]],prescription=eta},
   u=-ss-tt; y1=-u/ss;y2=-u/tt;
   ps=If[ss>0,prescription I Pi,0];pt=If[tt>0,prescription I Pi,0];
   gauss=(ps^2+pt^2)/2+pt Log[Abs[1-y1]]+ps Log[Abs[1-y2]]-
    pt Log[Abs[y1]]-ps Log[Abs[y2]]+
    FeynFacet`Private`boxFiniteHypergeometricCoefficient[2,y1,True]+
    FeynFacet`Private`boxFiniteHypergeometricCoefficient[2,y2,True];
   reduced=(Log[Abs[u/(ss tt)]]+Log[Abs[ss]]-ps)*
    (Log[Abs[u/(ss tt)]]+Log[Abs[tt]]-pt)-Pi^2/2;
   Abs[N[gauss,40]-N[reduced,40]]<10^-30],
  {point,{{-2,-3},{2,3},{2,-3},{3,-2},{-2,3},{-3,2}}},{eta,{-1,1}}]]];

FTAssert["positive weight-two Gauss coefficient is regular across argument one",
 And@@Table[
  oldValue=If[argument===1,-Zeta[2],Log[Abs[argument]](Log[Abs[argument]]-Log[Abs[1-argument]])/2-
   FeynFacet`Private`boxContinuousPolyLog[2,argument,True]];
  newValue=FeynFacet`Private`boxFiniteHypergeometricCoefficient[2,argument,True];
  Abs[N[oldValue,40]-N[newValue,40]]<10^-30,{argument,{1/3,999/1000,1,1001/1000,7/3}}]];
FTAssert["weight-two symbolic specialization does not generate zero times an infinite logarithm",
 (FeynFacet`Private`boxFiniteHypergeometricCoefficient[2,argument,argument>0]/.argument->1)===-Pi^2/6];
Print["MASSLESS BOX ORDER TEST COMPLETE"];FTReport[];
