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
FTReport[];
