(* AnalyzeOffDiagonalBlockEpsilonFormObstructions: the order-by-order certificate.
   (a) a synthetic block with the known rational solution D = eps x;
   (b) a synthetic missing letter: the alphabet is overridden to exclude
       the inhomogeneity's curve -> MissingLetters; supplying it as ExtraLetters
       clears the verdict. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
pass = 0; fail = 0;
check[label_, ok_] := (If[TrueQ[ok], pass++; Print["OK   ", label], fail++; Print["FAIL ", label]]);
(* (a) *)
fixture = <|"Family" -> "SYNTHETIC_SOLVABLE", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {Global`x, Global`y},
  "Regulator" -> Global`eps,
  "OffDiagonalBlockEquation" -> {
    {{{0}}, {{0}}}, {{{0}}, {{0}}},
    {{{Global`eps}}, {{0}}}}|>;
orderA = 1;
{ta, ra} = AbsoluteTiming[FeynFacet`AnalyzeOffDiagonalBlockEpsilonFormObstructions[fixture, "MaximumOrder" -> orderA]];
Print["(a) ", Round[ta, 0.1], " s: ", If[AssociationQ[ra], KeyTake[ra, {"Status", "Order", "OffDiagonalBasisTransformationNumeratorDegrees"}], ra]];
check["(a) solvable block: no obstruction to order " <> ToString[orderA], AssociationQ[ra] && ra["Status"] === "NoObstructionToOrder" && ra["Order"] === orderA];
check["(a) basis-transformation series D_0..D_" <> ToString[orderA] <>
    " is rational",
  AssociationQ[ra] &&
    Length[ra["OffDiagonalBasisTransformationBlockSeries"]] === orderA + 1 &&
    FreeQ[ra["OffDiagonalBasisTransformationBlockSeries"], Log]];
(* (b) synthetic: 1x1 diagonal blocks e = 0, c = 0, inhomogeneity eps dlog(x + y - 5) -> the curve is absent from the alphabet *)
syn = <|"Family" -> "SYN", "Sector" -> 2, "LowerSector" -> 1, "Variables" -> {Global`x, Global`y}, "Regulator" -> Global`eps,
  "OffDiagonalBlockEquation" -> {{{{0}}, {{0}}}, {{{0}}, {{0}}}, {{{Global`eps/(Global`x + Global`y - 5)}}, {{Global`eps/(Global`x + Global`y - 5)}}}}|>;
rc = FeynFacet`AnalyzeOffDiagonalBlockEpsilonFormObstructions[syn, "MaximumOrder" -> 2, "Alphabet" -> {Global`x, Global`y}];
Print["(c) ", If[AssociationQ[rc], KeyTake[rc, {"Status", "Order", "MissingLetters"}], rc]];
check["(c) missing letter detected", AssociationQ[rc] && rc["Status"] === "MissingLetters" && MemberQ[rc["MissingLetters"], Global`x + Global`y - 5 | -5 + Global`x + Global`y]];
rc2 = FeynFacet`AnalyzeOffDiagonalBlockEpsilonFormObstructions[syn, "MaximumOrder" -> 2, "Alphabet" -> {Global`x, Global`y}, "ExtraLetters" -> {Global`x + Global`y - 5}];
check["(c) with the letter supplied: no obstruction", AssociationQ[rc2] && rc2["Status"] === "NoObstructionToOrder"];
Print["t_off_diagonal_block_epsilon_form_obstructions: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
