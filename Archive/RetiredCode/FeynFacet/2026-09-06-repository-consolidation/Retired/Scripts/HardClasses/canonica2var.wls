(* two-variable CANONICA on the symbolically normalized class-97 system *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Scripts", "HardClassToolkit.wl"}]];
x = Global`x; y = Global`y; eps = Global`eps;
SetDirectory["/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/eps0"];
sn = Get["symnorm_c97.wl"];
Ax = sn["A"];
(* y-direction connection of the normalized system: Ay_norm =
   Ttot^-1 Ay Ttot - Ttot^-1 d_y Ttot, with Ay the chart y-connection *)
cls = Get["classes.wl"]; ent = SelectFirst[cls, #["ClassID"] == 97 &];
v = Global`v; w = Global`w;
vx = Global`xx y; wx = (1 - Global`xx) (1 - y);
AyChart = Together[((ent["RepAv"] /. {v -> vx, w -> wx}) Global`xx -
    (ent["RepAw"] /. {v -> vx, w -> wx}) (1 - Global`xx)) /. Global`xx -> x];
T = sn["Ttot"];
Ay = Together[Inverse[T] . AyChart . T - Inverse[T] . D[T, y]];
Print["y-connection built; integrability check (dAx/dy - dAy/dx + [Ax,Ay]):"];
F = Together[D[Ax, y] - D[Ay, x] + Ax . Ay - Ay . Ax];
Print["  flat? ", AllTrue[Flatten[F], # === 0 &]];
Get[FileNameJoin[{root, "Addon", "Mathematica_Addon", "CANONICA", "src",
  "CANONICA.m"}]];
mats = {Ax, Ay} /. (sy_Symbol /; SymbolName[sy] === "eps") :> CANONICA`eps;
bnd = CANONICA`SectorBoundariesFromDE[mats];
Print["sector boundaries: ", InputForm[bnd]];
res = CANONICA`RecursivelyTransformSectors[mats, {x, y}, bnd, {1, Length[bnd]},
  CANONICA`TDeltaNumeratorDegree -> 2, CANONICA`TDeltaDenominatorDegree -> 2,
  CANONICA`DDeltaNumeratorDegree -> 2, CANONICA`DDeltaDenominatorDegree -> 2];
Print["result: ", If[ListQ[res] && res[[1]] =!= False, "TRANSFORM RETURNED", InputForm[Short[res, 2]]]];
If[ListQ[res] && Length[res] >= 2 && res[[1]] =!= False,
 HCTPut[<|"T2" -> res[[1]], "A" -> res[[2]]|>, "c97_2var_canonica.wl"];
 Print[">>> saved c97_2var_canonica.wl"]];
Print["DONE"];
