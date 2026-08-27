root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

blockFile = FileNameJoin[{root,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "FamilyEpsFormsSolving", "tworoot_2026-08-22", "CF305",
  "sector_CF305_standard", "CF305_18_15_input.wl"}];
block = FeynFacet`FamilyArtifactRead[blockFile];
{e, c, bbar} = block["Strip"];
{x, y} = block["Variables"];
ee = block["Regulator"];

(* Obtain only the already-unobstructed coefficients D_0,D_1,D_2, then
   independently form the order-three equation and take exact symbolic
   residues on the two reported curves. *)
{obsSeconds, obs2} = AbsoluteTiming[
  FeynFacet`EpsFormStripObstruction[block,
    "MaximumOrder" -> 2, "TransverseLines" -> 5, "Verbose" -> True]];
Print["ORDER2_STATUS=", KeyTake[obs2,
  {"Status", "Order", "GaugeNumeratorDegrees"}],
  " WALL=", Round[obsSeconds, .01]];
If[! (AssociationQ[obs2] && obs2["Status"] === "NoObstructionToOrder" &&
    obs2["Order"] === 2 && Length[obs2["GaugeSeries"]] === 3),
  Print["CERTIFICATE_ABORT: could not construct D_0..D_2"];
  Exit[2]];

series[m_, k_] := Map[Function[z, Together[SeriesCoefficient[z,
  {ee, 0, k}]]], m, {2}];
bk[k_] := Map[Function[z, Together[SeriesCoefficient[z,
  {ee, 0, k}]]], bbar, {3}];
gauge = obs2["GaugeSeries"];
w3 = Table[Together[
    Sum[(series[e[[mu]], m].gauge[[3 - m]] -
          gauge[[3 - m]].series[c[[mu]], m])[[i, j]], {m, 0, 2}] +
      bk[3][[mu, i, j]]],
  {mu, 2}, {i, 2}, {j, 1}];
closed = Table[PossibleZeroQ[Together[
  D[w3[[1, i, 1]], y] - D[w3[[2, i, 1]], x]]], {i, 2}];
Print["W3_CLOSED=", closed];

curveY3 = y - 3;
curveQ = -2 + 5*x - 2*y - 2*x*y + x*y^2;
xOnQ = Together[x /. First[Solve[curveQ == 0, x]]];
resY3 = Table[Factor[Together[
  Residue[w3[[2, i, 1]], {y, 3}]]], {i, 2}];
resQ = Table[Factor[Together[
  Residue[w3[[1, i, 1]], {x, xOnQ}]]], {i, 2}];
Print["RESIDUE_Y_MINUS_3_INPUTFORM=", InputForm[resY3]];
Print["RESIDUE_Q_INPUTFORM=", InputForm[resQ]];
Print["RESIDUE_Y_MINUS_3_CONSTANT_Q=", FreeQ[resY3, x | y]];
Print["RESIDUE_Q_CONSTANT_Q=", FreeQ[resQ, x | y]];
Print["RESIDUE_Y_MINUS_3_DERIVATIVE_ZERO_Q=",
  PossibleZeroQ /@ (Together[D[#, x]] & /@ resY3)];
Print["RESIDUE_Q_DERIVATIVE_ZERO_Q=",
  PossibleZeroQ /@ (Together[D[#, y]] & /@ resQ)];

{obs4Seconds, obs4} = AbsoluteTiming[
  FeynFacet`EpsFormStripObstruction[block,
    "MaximumOrder" -> 4, "TransverseLines" -> 5, "Verbose" -> True]];
Print["PACKAGED_ORDER4_RESULT=", KeyTake[obs4,
  {"Status", "Order", "GaugeNumeratorDegrees", "Obstructions"}],
  " WALL=", Round[obs4Seconds, .01]];

(* Diagnose the two-dimensional nullspace of the preceding (18,16)
   solve.  If its gauge part is kinematics-constant, changing the solver's
   normalization can add only constant-residue dlogs to the deeper forcing
   and therefore cannot cancel the nonconstant residues above. *)
prevFile = FileNameJoin[{root,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "FamilyEpsFormsSolving", "tworoot_2026-08-22", "CF305",
  "sector_CF305_standard", "CF305_18_16_input.wl"}];
prev = FeynFacet`FamilyArtifactRead[prevFile];
prep = FeynFacet`PrepareEpsFormStripSampling[prev];
p = 1000003;
sample = FeynFacet`SampleEpsFormStripAffine[prev, 1/21, p,
  "Preparation" -> prep, "ExpectedFingerprint" -> prep["Fingerprint"],
  "NumeratorDegreeOffset" -> {0, 0}, "Support" -> Automatic,
  "SupportShell" -> 0, "SolveAffineSystem" -> True,
  "DiscoverPlan" -> True, "Backend" -> "Wolfram"];
Print["PREV_SAMPLE=", KeyTake[sample,
  {"Consistent", "Rank", "Nullity", "GaugeUnknownCount",
   "FreeResidueCount", "GaugeSupportCount"}]];
support = sample["GaugeSupport"];
den = sample["GaugeDenominator"];
blockLength = Length[support];
gaugeFromVector[v_] := Map[
  Together[Dot[#, (x^#[[1]]*y^#[[2]] & /@ support)]/den] &,
  Partition[Take[v, sample["GaugeUnknownCount"]], blockLength]];
nullGauges = gaugeFromVector /@ Normal[sample["NullspaceBasis"]];
zeroModQ[z_] := PossibleZeroQ[PolynomialMod[
  Expand[Numerator[Together[z]]], p]];
nullGaugeConstantQ = Table[
  And @@ Flatten[Table[zeroModQ[D[nullGauges[[a, i]], v]],
    {i, Length[nullGauges[[a]]]}, {v, {x, y}}]],
  {a, Length[nullGauges]}];
Print["PREV_NULLSPACE_GAUGES_CONSTANT_MOD_P=", nullGaugeConstantQ];
Print["PREV_NULLSPACE_GAUGE_VALUES_AT_2_5_MOD_P=",
  Mod[nullGauges /. {x -> 2, y -> 5}, p]];

Print["CF305_18_15_EXACT_CERTIFICATE_DONE"];
Exit[0];
