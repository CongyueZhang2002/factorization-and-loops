(* FactorFamilyRegulatorDependence: a dlog connection whose residues carry
   the regulator through a constant transformation T(eps) is returned to
   eps-factored form by a constant transformation; an eps-factored input is
   recognized; the letters are untouched. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
pass = 0; fail = 0;
check[label_, ok_] := (If[TrueQ[ok], pass++; Print["OK   ", label], fail++; Print["FAIL ", label]]);
Clear[x, y, eps];
k1 = {{1, 0, 0}, {0, -1, 0}, {2, 0, 0}}; k2 = {{0, 1, 0}, {1, 0, 0}, {0, 0, 3}}; k3 = {{2, 0, 1}, {0, 0, 0}, {0, 1, -2}};
letters = {x, y, 1 - x - y};
dl[L_] := {D[Log[L], x], D[Log[L], y]};
canonical = Table[eps Sum[{k1, k2, k3}[[a]] dl[letters[[a]]][[mu]], {a, 3}], {mu, 2}];
t = {{1, eps, 0}, {0, 1 + 4 eps, 0}, {eps^2, 0, 1/(1 - 2 eps)}};
tInv = Inverse[t];
connection = Table[Map[Together, t . canonical[[mu]] . tInv, {2}], {mu, 2}];
check["input is not eps-factored", ! FeynFacet`Private`familyRegulatorFactoredQ[connection[[1]], eps]];
{sec, r} = AbsoluteTiming[FeynFacet`FactorFamilyRegulatorDependence[connection, {x, y}, eps, "Verbose" -> True]];
Print["result: ", If[AssociationQ[r], KeyTake[r, {"Status", "Method", "Points", "Seconds"}], r], " (", Round[sec, 0.1], " s)"];
check["status OK", AssociationQ[r] && r["Status"] === "OK"];
If[AssociationQ[r] && r["Status"] === "OK",
  newA = r["Connection"];
  check["output eps-factored", FeynFacet`Private`familyRegulatorFactoredQ[newA[[1]], eps] && FeynFacet`Private`familyRegulatorFactoredQ[newA[[2]], eps]];
  check["transformation constant in the variables", FreeQ[r["Transformation"], x | y]];
  check["gauge identity", And @@ Flatten[Table[PossibleZeroQ[Together[(r["Inverse"] . connection[[mu]] . r["Transformation"])[[i, j]] - newA[[mu, i, j]]]], {mu, 2}, {i, 3}, {j, 3}]]];
  check["inverse exact", And @@ Flatten[Map[PossibleZeroQ, Together[r["Transformation"] . r["Inverse"] - IdentityMatrix[3]], {2}]]]];
r2 = FeynFacet`FactorFamilyRegulatorDependence[canonical, {x, y}, eps];
check["eps-factored input recognized", AssociationQ[r2] && r2["Status"] === "AlreadyEpsFactored"];
Print["t_family_regulator_factor: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
