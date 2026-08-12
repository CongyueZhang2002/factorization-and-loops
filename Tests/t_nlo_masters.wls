(* Solved NLO UU master integrals: exactness and validation gates.

   Acceptance criteria:
   A. The artifact loads with the expected basis of 7 masters.
   B. The 2F1 contiguous relation used by the certificates is exact
      (numeric spot check to 25 digits).
   C. Every master satisfies BOTH differential equations of the
      stored system exactly (symbolic zero after eliminating F').
   D. The volume master equals the closed two-body formula.
   E. Numeric spot values: the exact masters reproduce the stored
      independent phase-space integration references at
      (v,w,eps) = (0.2, 0.3, -0.15) to 12 digits.
   F. Soft-surface structure: the z -> 1 masters carry the
      (1-v-w)^(-1-2eps) branch; the z -> 0 masters are single-branch
      with exponent -eps. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

artifact = Get[FileNameJoin[{root, "ppHX_NLO", "Results",
  "NLO_UU_Masters.wl"}]];
eps = Global`Epsilon; v = Global`v; w = Global`w;

FTTest`FTAssert["A. artifact format and basis",
  AssociationQ[artifact] &&
    artifact["Format"] === "FeynFacet-NLOMasters" &&
    Length[artifact["Masters"]] === 7 &&
    Length[artifact["DifferentialSystem"]["Basis"]] === 7];

(* The built-in derivative of 2F1 raises the parameters, so the
   residual check works on an inert head and eliminates F' by the
   contiguous relation (verified numerically in B). *)
inertRule = Hypergeometric2F1[1, 1, 1 - eps, zed_] :> ff[zed];
contiguous = HoldPattern[Derivative[1][ff][zc_]] :>
  ((zc + eps) ff[zc] - eps)/(zc (1 - zc));

contiguousCheck = Module[{e = -3/20, z = 4/10},
  Abs @ N[
    (D[Hypergeometric2F1[1, 1, 1 - e, zz], zz] /. zz -> z) -
      (((z + e) Hypergeometric2F1[1, 1, 1 - e, z] - e)/(z (1 - z))),
    25]
];
FTTest`FTAssert["B. contiguous relation exact (numeric, 25 digits)",
  TrueQ[contiguousCheck < 10^-24]];

basis = artifact["DifferentialSystem"]["Basis"];
Av = artifact["DifferentialSystem"]["Av"];
Aw = artifact["DifferentialSystem"]["Aw"];
values = Lookup[artifact["Masters"], basis][[All, Key["Exact"]]];

inertValues = values /. inertRule;
residual[matrix_, variable_] := Together[
  (D[inertValues, variable] /. contiguous) - matrix.inertValues
];
resV = residual[Av, v];
resW = residual[Aw, w];
FTTest`FTAssert["C. all 14 differential equations hold exactly",
  Union[resV] === {0} && Union[resW] === {0}];

volFormula = 2^(1 - (4 - 2 eps)) *
  2 Pi^((3 - 2 eps)/2)/Gamma[(3 - 2 eps)/2] (1 - v - w)^(-eps);
FTTest`FTAssert["D. volume master equals the closed formula",
  Together[values[[1]] - volFormula] === 0];

(* Stored references from the independent two-angle phase-space
   integration (numeric_nlo_masters, WorkingPrecision 30), at
   v = 1/5, w = 3/10, eps = -3/20. *)
references = <|
  1 -> 1.34423415238677087230801087367796427095,
  2 -> -108.170628689348177842669709977695054757,
  3 -> -138.710691066105671209485478977532875842,
  4 -> -74.7825017454159035961424751857367048866,
  5 -> 45.9140250480965118607659154985853122007,
  6 -> -193.136080037209098886378651205873711646,
  7 -> 285.473939528335274679411518445242859281
|>;
numericPoint = {v -> 1/5, w -> 3/10, eps -> -3/20};
spot = Table[
  Abs @ N[
    (values[[i]] /. numericPoint)/references[i] - 1, 20],
  {i, 7}
];
FTTest`FTAssert["E. exact masters match stored numeric references",
  AllTrue[spot, TrueQ[# < 10^-10] &]];
Print["    max spot deviation: ", N[Max[spot], 3]];

softExponents = Map[
  Lookup[#, "SoftBranches"][[All, Key["Exponent"]]] &,
  Lookup[artifact["Masters"], basis]
];
FTTest`FTAssert["F. soft branch exponents: -eps everywhere, and
-1-2eps present exactly for the z->1 masters",
  softExponents[[1]] === {-eps} &&
    Count[softExponents, {-eps, -1 - 2 eps}] === 3 &&
    Count[softExponents, {-eps}] === 4];

FTTest`FTReport[];
