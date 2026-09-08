(* The epsilon-jet Laurent extraction (overhaul 2026-09-02) must reproduce
   SeriesCoefficient exactly, entry by entry and order by order, on
   matrices whose entries are rational in eps with algebraic (radical)
   coefficients -- the CF259 shape -- including a zero entry, an eps-free
   entry, an entry whose leading numerator coefficient is an algebraic
   zero in disguise, and an entry outside the compiler's grammar (eps under
   a radical), which must take the SeriesCoefficient fallback.
   Acceptance: every coefficient difference is zero under RootReduce, both
   routes give identical structural zeros, and the jet route is used
   (method flag honoured). *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
x = Symbol["Global`x"]; y = Symbol["Global`y"]; eps = Symbol["Global`eps"];
r1 = Sqrt[1 - 4 x y]; r2 = Sqrt[x^2 + 4 y];
jetMatrix = {
  {(2 - 9 eps + 9 eps^2)/(2 eps^2), 0, (x + y r1)/(eps (1 - 2 eps) (x - y))},
  {(-2 + 13 eps - 27 eps^2 + 18 eps^3) r2/(2 eps^3 (x + y)), x y/(1 - x),
    ((1 + eps) (r1 - x) + (r1 + x) (1 - eps))/(eps^2 (1 + x eps))},
  {(r1^2 - (1 - 4 x y))/eps^3 + 1/eps, Sqrt[1 + eps]/eps,
    1/(eps (1 - eps r2/(1 + x)))^2}
};
orders = {-3, 3};
jetRows[mat_] := Block[{FeynFacet`Private`$observableTransportLaurentMethod = "Jet"},
  FeynFacet`Private`observableTransportLaurentRows[mat, eps, orders, Range[Length[mat]]]];
seriesRows[mat_] := Block[{FeynFacet`Private`$observableTransportLaurentMethod = "SeriesCoefficient"},
  FeynFacet`Private`observableTransportLaurentRows[mat, eps, orders, Range[Length[mat]]]];
{jetSeconds, jet} = AbsoluteTiming[jetRows[jetMatrix]];
{seriesSeconds, series} = AbsoluteTiming[seriesRows[jetMatrix]];
Print["jet ", Round[jetSeconds, 0.001], " s; SeriesCoefficient ", Round[seriesSeconds, 0.001], " s"];
FTAssert["both routes return every requested order", Keys[jet] === Range @@ orders && Keys[series] === Range @@ orders];
zeroQ[e_] := TrueQ[RootReduce[Together[e]] === 0];
agree = And @@ Flatten[Table[zeroQ[jet[order][[i, j]] - series[order][[i, j]]],
  {order, orders[[1]], orders[[2]]}, {i, 3}, {j, 3}]];
FTAssert["jet coefficients equal SeriesCoefficient coefficients under RootReduce", agree];
FTAssert["structural zeros agree", Table[TrueQ[jet[order][[i, j]] === 0], {order, -3, 3}, {i, 3}, {j, 3}] ===
  Table[TrueQ[series[order][[i, j]] === 0], {order, -3, 3}, {i, 3}, {j, 3}]];
FTAssert["algebraic-zero leading coefficient handled (entry (3,1) has valuation -1)",
  zeroQ[jet[-3][[3, 1]]] && zeroQ[jet[-2][[3, 1]]] && zeroQ[jet[-1][[3, 1]] - 1]];
FTAssert["radical-in-eps entry falls back to SeriesCoefficient exactly",
  zeroQ[jet[-1][[3, 2]] - 1] && zeroQ[jet[0][[3, 2]] - 1/2]];
FTAssert["compiler refuses eps under a radical",
  Catch[FeynFacet`Private`observableTransportEpsJetCompile[Sqrt[1 + eps], eps],
    "observableTransportEpsJetUnsupported"] === $Failed];
FTAssert["compiler accepts an eps-free radical entry",
  ListQ[FeynFacet`Private`observableTransportEpsJetCompile[r1/(1 - eps), eps]]];
FTReport[];
