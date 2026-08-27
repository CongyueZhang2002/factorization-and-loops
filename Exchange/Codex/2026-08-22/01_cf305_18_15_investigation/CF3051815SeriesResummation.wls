root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

outDir = FileNameJoin[{root, "External", "CodexExchange",
  "codex_cf305_18_15_2026-08-22"}];
blockFile = FileNameJoin[{root,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "FamilyEpsFormsSolving", "tworoot_2026-08-22", "CF305",
  "sector_CF305_standard", "CF305_18_15_input.wl"}];
block = FeynFacet`FamilyArtifactRead[blockFile];
{e, c, bbar} = block["Strip"];
vars = block["Variables"];
{x, y} = vars;
ee = block["Regulator"];

{seriesSeconds, obs} = AbsoluteTiming[
  FeynFacet`EpsFormStripObstruction[block,
    "MaximumOrder" -> 10, "TransverseLines" -> 5,
    "Verbose" -> True]];
If[! (AssociationQ[obs] && obs["Status"] === "NoObstructionToOrder" &&
    obs["Order"] === 10),
  Print["RESUMMATION_ABORT: order-by-order construction failed: ",
    KeyTake[obs, {"Status", "Order", "Obstructions"}]];
  Exit[2]];

gaugeSeries = obs["GaugeSeries"];
alphabet = obs["Alphabet"];
residueSeries = obs["ResidueSeries"];
zeroQ[z_] := AllTrue[Flatten[{z}], PossibleZeroQ[Together[#]] &];

(* D_k = -4 D_{k-1} exactly for every k=3,...,10. *)
gaugeRecurrenceChecks = Table[
  zeroQ[gaugeSeries[[k + 1]] + 4 gaugeSeries[[k]]],
  {k, 3, 10}];
Print["GAUGE_RECURRENCE_DK_EQ_MINUS4_PREV_K3_TO_10=",
  gaugeRecurrenceChecks];

residueAtOrder[k_Integer] :=
  SelectFirst[residueSeries, Lookup[#, "Order", -1] === k &]["Residues"];
residueCoefficient[k_Integer] := Module[{assoc = residueAtOrder[k]},
  Table[
    Table[Lookup[Lookup[assoc, letter, <||>], Key[{i, j}], 0],
      {i, 2}, {j, 1}],
    {letter, alphabet}]];
residueCoefficients = Association[
  Table[k -> residueCoefficient[k], {k, 1, 10}]];
residueRecurrenceChecks = Table[
  zeroQ[residueCoefficients[k] + 4 residueCoefficients[k - 1]],
  {k, 3, 10}];
Print["RESIDUE_RECURRENCE_RK_EQ_MINUS4_PREV_K3_TO_10=",
  residueRecurrenceChecks];

(* Sum D(eps)=eps D_1 + eps^2 D_2/(1+4 eps).  The transformed
   off-diagonal one-form is eps times K(eps), with
   K(eps)=R_1 + eps R_2/(1+4 eps). *)
gauge = Map[Together,
  ee gaugeSeries[[2]] + ee^2 gaugeSeries[[3]]/(1 + 4 ee), {2}];
residueMatrices = Map[Together,
  residueCoefficients[1] +
    ee residueCoefficients[2]/(1 + 4 ee), {3}];
dlog = Table[Together[D[Log[alphabet[[a]]], vars[[mu]]]],
  {a, Length[alphabet]}, {mu, 2}];
transformed = Table[Map[Together,
  bbar[[mu]] + ee (e[[mu]].gauge - gauge.c[[mu]]) -
    D[gauge, vars[[mu]]], {2}], {mu, 2}];
target = Table[Map[Together,
  ee Sum[residueMatrices[[a]] dlog[[a, mu]],
    {a, Length[alphabet]}], {2}], {mu, 2}];

{identitySeconds, identityQ} = AbsoluteTiming[
  zeroQ[transformed - target]];
{canonicaSeconds, canonicaDLogQ} = AbsoluteTiming[
  FeynFacet`Private`epsFormStripExactDLogQ[
    gauge, block["Strip"], vars, ee, alphabet]];
lettersEpsFree = FreeQ[alphabet, ee];
residuesKinematicsFree = FreeQ[residueMatrices,
  Alternatives @@ vars];
Print["EXACT_PFAFFIAN_IDENTITY=", identityQ,
  " WALL=", Round[identitySeconds, .01]];
Print["CANONICA_DLOG_CHECK=", canonicaDLogQ,
  " WALL=", Round[canonicaSeconds, .01]];
Print["LETTERS_EPS_FREE=", lettersEpsFree,
  " RESIDUES_KINEMATICS_FREE=", residuesKinematicsFree,
  " RESIDUES_EPS_FREE=", FreeQ[residueMatrices, ee]];
Print["GAUGE_DENOMINATOR_FACTORS=",
  DeleteDuplicates[Rest[FactorList[Denominator[Together[#]]]] & /@
    Flatten[gauge]]];

certificate = <|
  "Family" -> block["Family"],
  "Sector" -> block["Sector"],
  "LowerSector" -> block["LowerSector"],
  "Status" -> If[And @@ Join[gaugeRecurrenceChecks,
      residueRecurrenceChecks] && identityQ && canonicaDLogQ,
    "Certified", "Failed"],
  "Method" -> "OrderByOrderEpsilonSeriesRationalResummation",
  "SeriesMaximumOrder" -> 10,
  "GaugeRecurrence" -> "D_k = -4 D_(k-1), k >= 3",
  "ResidueRecurrence" -> "R_k = -4 R_(k-1), k >= 3",
  "GaugeRecurrenceChecks" -> gaugeRecurrenceChecks,
  "ResidueRecurrenceChecks" -> residueRecurrenceChecks,
  "ExactPfaffianIdentity" -> identityQ,
  "CANONICADLogCheck" -> canonicaDLogQ,
  "LettersEpsFree" -> lettersEpsFree,
  "ResiduesKinematicsFree" -> residuesKinematicsFree,
  "ResiduesEpsFree" -> FreeQ[residueMatrices, ee],
  "SeriesConstructionSeconds" -> seriesSeconds,
  "ExactIdentitySeconds" -> identitySeconds,
  "CANONICACheckSeconds" -> canonicaSeconds|>;
solution = <|
  "Family" -> block["Family"],
  "Sector" -> block["Sector"],
  "LowerSector" -> block["LowerSector"],
  "Status" -> If[certificate["Status"] === "Certified",
    "Solved", "Failed"],
  "Method" -> certificate["Method"],
  "Gauge" -> gauge,
  "Alphabet" -> alphabet,
  "ResidueMatrices" -> residueMatrices,
  "ExactDLog" -> identityQ && canonicaDLogQ,
  "DLogFormCertified" -> identityQ && canonicaDLogQ,
  "ExactPfaffianResidualsZero" -> identityQ,
  "LettersEpsFree" -> lettersEpsFree,
  "ResiduesKinematicsFree" -> residuesKinematicsFree,
  "ResiduesEpsFree" -> FreeQ[residueMatrices, ee],
  "Certificate" -> "ExactPfaffianIdentityAndCANONICACheck",
  "SeriesMaximumOrder" -> 10|>;

FeynFacet`FamilyArtifactWrite[
  certificate,
  FileNameJoin[{outDir, "CF305_18_15_series_certificate.wl"}]];
FeynFacet`FamilyArtifactWrite[
  solution,
  FileNameJoin[{outDir, "CF305_18_15_series_solution.wl"}]];
Print["CERTIFICATE_STATUS=", certificate["Status"]];
Print["SOLUTION_STATUS=", solution["Status"]];
Print["CF305_18_15_SERIES_RESUMMATION_DONE"];
Exit[If[certificate["Status"] === "Certified", 0, 1]];
