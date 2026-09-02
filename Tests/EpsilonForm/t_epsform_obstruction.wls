(* EpsFormStripObstruction: the order-by-order certificate.
   (a) a block with a known rational gauge (CF254 (9,7) frozen fixture):
       no obstruction up to order 3, gauge series rational;
   (b) CF305 block (18,15) (saved 2026-08-22): no obstruction to order 4,
       every D_k of numerator total degree 9 (the block that exposed the
       bidegree-rectangle support defect of the finite-field solver);
   (c) a synthetic missing letter: the alphabet is overridden to exclude
       the forcing's curve -> MissingLetters; supplying it as ExtraLetters
       clears the verdict. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
pass = 0; fail = 0;
check[label_, ok_] := (If[TrueQ[ok], pass++; Print["OK   ", label], fail++; Print["FAIL ", label]]);
R = FileNameJoin[{root, "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical"}];
(* (a) *)
fixture = FeynFacet`FamilyArtifactRead[FileNameJoin[{R, "BenchmarkStripBackends/frozen_M0/fixture_CF254_9_7.wl"}]];
(* cost discipline 2026-09-02: the certificate's residue and primitive
   stages grow with the order (measured on this fixture: orders 0..3 take
   14, 45, 66, 93 s); the default run certifies orders 0 and 1, the full
   order-3 certificate needs FACET_TEST_LONG=1 *)
orderA = If[Environment["FACET_TEST_LONG"] === "1", 3, 1];
{ta, ra} = AbsoluteTiming[FeynFacet`EpsFormStripObstruction[fixture, "MaximumOrder" -> orderA]];
Print["(a) ", Round[ta, 0.1], " s: ", If[AssociationQ[ra], KeyTake[ra, {"Status", "Order", "GaugeNumeratorDegrees"}], ra]];
check["(a) solvable block: no obstruction to order " <> ToString[orderA], AssociationQ[ra] && ra["Status"] === "NoObstructionToOrder" && ra["Order"] === orderA];
check["(a) gauge series D_0..D_" <> ToString[orderA] <> " rational", AssociationQ[ra] && Length[ra["GaugeSeries"]] === orderA + 1 && FreeQ[ra["GaugeSeries"], Log]];
(* (b) *)
blockFile = FileNameJoin[{R, "FamilyEpsFormsSolving/tworoot_2026-08-22/CF305/sector_CF305_standard/CF305_18_15_input.wl"}];
If[FileExistsQ[blockFile],
  block = FeynFacet`FamilyArtifactRead[blockFile];
  {tb, rb} = AbsoluteTiming[FeynFacet`EpsFormStripObstruction[block, "MaximumOrder" -> 4]];
  Print["(b) ", Round[tb, 0.1], " s: ", If[AssociationQ[rb], KeyTake[rb, {"Status", "Order"}], rb]];
  check["(b) CF305 (18,15): no obstruction to order 4", AssociationQ[rb] && rb["Status"] === "NoObstructionToOrder" && rb["Order"] === 4];
  check["(b) gauge series D_0..D_4 with numerator total degree 9", AssociationQ[rb] && Length[rb["GaugeSeries"]] === 5 && Max[rb["GaugeNumeratorDegrees"]] === 9];
  check["(b) residues are geometric in the order (ratio -4 from order 2)", AssociationQ[rb] && Module[{k3 = rb["ResidueSeries"][[4]]["Residues"], k4 = rb["ResidueSeries"][[5]]["Residues"]},
    And @@ Flatten[Table[k4[L][e] === -4 k3[L][e], {L, Keys[k3]}, {e, Keys[k3[L]]}]]]],
  Print["(b) skipped: block record not present"]];
(* (c) synthetic: 1x1 diagonal blocks e = 0, c = 0, forcing eps dlog(x + y - 5) -> the curve is absent from the alphabet *)
syn = <|"Family" -> "SYN", "Sector" -> 2, "LowerSector" -> 1, "Variables" -> {Global`x, Global`y}, "Regulator" -> Global`eps,
  "Strip" -> {{{{0}}, {{0}}}, {{{0}}, {{0}}}, {{{Global`eps/(Global`x + Global`y - 5)}}, {{Global`eps/(Global`x + Global`y - 5)}}}}|>;
rc = FeynFacet`EpsFormStripObstruction[syn, "MaximumOrder" -> 2, "Alphabet" -> {Global`x, Global`y}];
Print["(c) ", If[AssociationQ[rc], KeyTake[rc, {"Status", "Order", "MissingLetters"}], rc]];
check["(c) missing letter detected", AssociationQ[rc] && rc["Status"] === "MissingLetters" && MemberQ[rc["MissingLetters"], Global`x + Global`y - 5 | -5 + Global`x + Global`y]];
rc2 = FeynFacet`EpsFormStripObstruction[syn, "MaximumOrder" -> 2, "Alphabet" -> {Global`x, Global`y}, "ExtraLetters" -> {Global`x + Global`y - 5}];
check["(c) with the letter supplied: no obstruction", AssociationQ[rc2] && rc2["Status"] === "NoObstructionToOrder"];
Print["t_epsform_obstruction: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
