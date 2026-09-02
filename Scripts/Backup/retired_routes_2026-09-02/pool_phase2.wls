(* pool_phase2: CANONICA on slices of the UNIFORM normalized family
   symnorm_c97.wl -> branch-consistent T2(y_i) samples *)
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Scripts", "HardClassToolkit.wl"}]];
x = Global`x; y = Global`y; eps = Global`eps;
here = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/eps0";
SetDirectory[here];
sn = Get["symnorm_c97.wl"];
Anorm = sn["A"];
p2Mission[ystr_String] := Module[
  {y0 = ToExpression[ystr], ytag = StringReplace[ystr, "/" -> "_"],
   As, mats, bnd, res, T2, An, ok},
  As = Together[Anorm /. y -> y0];
  mats = {As} /. (sy_Symbol /; SymbolName[sy] === "eps") :> CANONICA`eps;
  bnd = CANONICA`SectorBoundariesFromDE[mats];
  res = Quiet@CANONICA`RecursivelyTransformSectors[mats, {x}, bnd,
    {1, Length[bnd]},
    CANONICA`TDeltaNumeratorDegree -> 2, CANONICA`TDeltaDenominatorDegree -> 2,
    CANONICA`DDeltaNumeratorDegree -> 2, CANONICA`DDeltaDenominatorDegree -> 2];
  If[! (ListQ[res] && Length[res] >= 2 && res[[1]] =!= False),
   Return[<|"Tag" -> ystr, "Status" -> "CANONICAFailed"|>]];
  T2 = res[[1]] /. (sy_Symbol /; SymbolName[sy] === "eps") :> Global`eps;
  An = (If[ListQ[res[[2]]], res[[2, 1]], res[[2]]]) /.
    (sy_Symbol /; SymbolName[sy] === "eps") :> Global`eps;
  ok = AllTrue[Flatten[An], FreeQ[Cancel[Together[#/eps]], eps] &];
  If[! ok, Return[<|"Tag" -> ystr, "Status" -> "NotEpsForm"|>]];
  HCTPut[<|"Y0" -> y0, "T2" -> T2, "An" -> An|>,
    FileNameJoin[{here, "p2_c97_y" <> ytag <> ".wl"}]];
  <|"Tag" -> ystr, "Status" -> "OK"|>];
ys = {"3/7", "5/11", "2/9", "7/13", "4/5", "1/6", "9/14", "5/8",
  "3/10", "8/17", "1/12", "7/15"};
LaunchKernels[4];
With[{cn = "/home/maxzhang/factorization-and-loops/Addon/Mathematica_Addon/CANONICA/src/CANONICA.m",
  tkf = FileNameJoin[{root, "Scripts", "HardClassToolkit.wl"}], hh = here},
 ParallelEvaluate[Get[tkf]; SetDirectory[hh];
  Quiet[Block[{Print = (Null &)}, Get[cn]], {General::shdw}]]];
DistributeDefinitions[Anorm, p2Mission, here];
results = HCTMissionPool[ys, p2Mission, "Kernels" -> 4,
  "Progress" -> Function[{res, remaining, elapsed},
    Print["POOL ", res["Tag"], " -> ", res["Status"],
      " | remaining=", remaining, " elapsed=", Round[elapsed], "s"]]];
Print["ok count: ", Count[results, r_ /; r["Status"] === "OK"]];
Print["DONE"];
