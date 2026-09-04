#!/usr/bin/env wolframscript
(* Synthetic solvable multiquadratic blocks, ranks 0 to 3, for
   FeynFacet/Private/EpsForm/Multiquadratic/MultiquadraticStripSolve.wl (2026-08-23).

   Construction, in the style of Tests/FiniteField/t_finite_field_adversarial.wls:
   every block is BUILT from a known gauge and known residues.  The
   gauge is written directly in the solver's own ansatz basis

     G_ij = Sum_{grade,monomial} g[i,j,grade,monomial] x^p y^q / Q r_grade

   with the canonical root order taken from the module before the block
   is built, so the known coefficient vector is exactly the vector the
   solver must produce.  With diagonal eps-forms eps e, eps c, target
   residues K and one-forms omega the forcing is

     bbar = eps Sum_a K_a omega_a + dG - eps (e G - G c)

   (the package convention dG = eps (e G - G c) + bbar - eps K omega).

   Acceptance criteria, stated before the run:
     - the terminal status is "ModularConsistent" and NEVER "Solved":
       the route returns closed one-forms, not certified dlog
       potentials (handoff External gap 2);
     - the modular system is consistent at every sampled prime and
       regulator value with one stable rank/nullity/pivot signature,
       and the same signature at an unseen prime and an unseen
       regulator value;
     - without normalization the nullity is exactly the constant-gauge
       freedom (one mode per gauge entry) and the KNOWN vector lies in
       the reported affine solution set at the unseen prime;
     - with that freedom pinned by normalization equations the nullity
       is zero and the exact lift equals the known coefficient vector
       EXACTLY, as rationals, at every sampled regulator value, and the
       exact channel identity holds;
     - the known vector satisfies the transformed system for EVERY
       sign branch at the unseen prime;
     - the direct grade rows agree with the independent split-sign row
       assembly (the differential certificate);
     - "BranchFlipMask" is a typed error on every production entry
       point, an unavailable plan-discovery backend fails closed, an
       undeclared radical fails closed;
     - a corrupted artifact yields a typed failure, and the same valid
       artifact hydrated in two different explicit contexts yields the
       same ABI fingerprint (pool defects 3 and 4). *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FeynFacet`Private`feynFacetPrivateFile["MultiquadraticAlgebra.wl"]];
(* the strip solver is eight files since round 4 (2026-09-02); the manifest
   names them in load order *)
Get[FeynFacet`Private`feynFacetPrivateFile[#]] & /@
  Select[Lookup[Get[FileNameJoin[{root, "FeynFacet", "Private", "LoadOrder.wl"}]],
    "EpsForm"], StringStartsQ[FileNameTake[#], "MultiquadraticStrip"] &];

pass = 0; fail = 0; statuses = {};
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{solve, prepare, compile, assembleSample, affineSolve, transformSample,
  gaugeIndex, residueIndex, rootOrder, artifactWrite, artifactRead,
  differentialCheck} =
 mq /@ {"solveEpsFormStripMultiquadratic", "multiquadraticStripPrepare",
   "multiquadraticStripCompile", "multiquadraticStripAssembleSample",
   "multiquadraticStripAffineSolve", "multiquadraticStripTransformSampleToSigns",
   "multiquadraticStripGaugeIndex", "multiquadraticStripResidueIndex",
   "multiquadraticStripRootOrder", "multiquadraticStripArtifactWrite",
   "multiquadraticStripReadPreparedArtifact",
   "multiquadraticStripDifferentialCheckPoint"};

Clear[x, y, eps, v, w, cx, cy];
frame = BuildSquareRootGeneratorsAndQuadraticRelations[{v, w, 1 + v + w}, {v, w}, {cx, cy}];
check["the rank-three multiquadratic frame is exact",
  AssociationQ[frame] && frame["Status"] === "ExactFrame"];

dlog[letter_] := {D[Log[letter], x], D[Log[letter], y]};
letters = {x, y, 1 - x - y};
oneForms = dlog /@ letters;
(* the engine canonicalizes a supplied gauge denominator (unit leading
   coefficient per factor: 1 - x - y becomes -1 + x + y); the planted
   coefficients, the pinned normalizations and the packed vector must
   all refer to that form *)
denominator = FeynFacet`Private`multiquadraticStripMergeGaugeDenominator[
  1 - x - y, 1, {x, y}];
support = Sort[{{0, 0}, {0, 1}, {1, 0}}];
diagonalForm[residues_List] := Table[
  Sum[residues[[a]] oneForms[[a, mu]], {a, Length[letters]}], {mu, 2}];

(* the canonical root order is read from the module BEFORE the block is
   built, so the known vector is expressed in the solver's own ABI *)
canonicalRoots[indices_] := Module[{order = rootOrder[frame, {x, y}, indices, eps]},
  If[Lookup[order, "Status", None] =!= "StableRootOrder", $Failed,
    Lookup[order["Roots"], "Root", {}]]];

gradeFactor[grade_, roots_] :=
  Product[If[BitGet[grade, k - 1] === 1, roots[[k]], 1], {k, Length[roots]}];

buildGauge[coefficients_, dimensions_, roots_] := Table[
  Sum[coefficients[[i, j, grade + 1, monomial]]
      x^support[[monomial, 1]] y^support[[monomial, 2]] gradeFactor[grade, roots]/
      denominator,
    {grade, 0, 2^Length[roots] - 1}, {monomial, Length[support]}],
  {i, dimensions[[1]]}, {j, dimensions[[2]]}];

buildForcing[e_, c_, gauge_, residues_] := Table[
  Map[Together, Sum[residues[[a]] eps oneForms[[a, mu]], {a, Length[letters]}] +
    D[gauge, {x, y}[[mu]]] - eps (e[[mu]] . gauge - gauge . c[[mu]]), {2}],
  {mu, 2}];

packVector[preparation_, coefficients_, residues_] := Module[
  {vector = ConstantArray[0, preparation["UnknownCount"]],
   dimensions = preparation["Dimensions"],
   gradeCount = preparation["GradeCount"],
   supportCount = Length[preparation["GaugeSupport"]],
   gaugeUnknownCount = preparation["GaugeUnknownCount"]},
  Do[vector[[gaugeIndex[dimensions[[1]], dimensions[[2]], gradeCount,
      supportCount, i, j, grade, monomial]]] =
    coefficients[[i, j, grade + 1, monomial]],
    {i, dimensions[[1]]}, {j, dimensions[[2]]}, {grade, 0, gradeCount - 1},
    {monomial, supportCount}];
  Do[vector[[residueIndex[gaugeUnknownCount, dimensions[[1]], dimensions[[2]],
      letter, i, j]]] = residues[[letter, i, j]],
    {letter, Length[letters]}, {i, dimensions[[1]]}, {j, dimensions[[2]]}];
  vector];

(* one constant-gauge mode per entry: pin the grade-0 constant monomial *)
normalizationsFor[coefficients_, dimensions_] := Flatten[Table[
  <|"Kind" -> "GaugeCoefficient", "Upper" -> i, "Lower" -> j, "Grade" -> 0,
    "Monomial" -> {0, 0}, "Value" -> coefficients[[i, j, 1,
      First[Flatten[Position[support, {0, 0}, {1}, Heads -> False]]]]]|>,
  {i, dimensions[[1]]}, {j, dimensions[[2]]}], 1];

randomCoefficients[dimensions_, gradeCount_, seed_] := BlockRandom[
  SeedRandom[seed];
  Table[RandomInteger[{-6, 6}] + RandomChoice[{0, 1/2, 1/3, -2/5}],
    {dimensions[[1]]}, {dimensions[[2]]}, {gradeCount}, {Length[support]}]];

randomResidues[dimensions_, seed_] := BlockRandom[SeedRandom[seed];
  Table[RandomInteger[{-4, 4}] + RandomChoice[{0, 1/4, -1/7}],
    {Length[letters]}, {dimensions[[1]]}, {dimensions[[2]]}]];

randomDiagonal[size_, seed_] := BlockRandom[SeedRandom[seed];
  diagonalForm[Table[RandomInteger[{-2, 2}, {size, size}], {Length[letters]}]]];

runCase[name_String, indices_List, dimensions_List, seed_Integer] := Module[
  {roots, gradeCount, coefficients, residues, gauge, e, c, bbar, record,
   preparation, assembly, known, knownImage, normalizations, plain, pinned,
   heldSample, heldPrime, branchResiduals},
  roots = canonicalRoots[indices];
  gradeCount = 2^Length[indices];
  coefficients = randomCoefficients[dimensions, gradeCount, seed];
  residues = randomResidues[dimensions, seed + 1];
  gauge = buildGauge[coefficients, dimensions, roots];
  e = randomDiagonal[dimensions[[1]], seed + 2];
  c = randomDiagonal[dimensions[[2]], seed + 3];
  bbar = buildForcing[e, c, gauge, residues];
  record = <|"Family" -> name, "Sector" -> 4, "LowerSector" -> 2,
    "Variables" -> {x, y}, "Regulator" -> eps, "Strip" -> {e, c, bbar}|>;
  normalizations = normalizationsFor[coefficients, dimensions];

  plain = solve[record, frame, "OneForms" -> oneForms,
    "GaugeDenominator" -> denominator, "Support" -> support];
  AppendTo[statuses, Lookup[plain, "Status", None]];
  check[name <> ": modular consistency without normalization",
    AssociationQ[plain] && plain["Status"] === "ModularConsistent"];
  If[! (AssociationQ[plain] && plain["Status"] === "ModularConsistent"),
    Print["     ", Short[plain, 6]]; Return[plain]];
  check[name <> ": the solver never reports Solved",
    plain["Status"] =!= "Solved" && plain["SolutionContract"] === "OneFormsNotCertified"];
  check[name <> ": the declared rank is the rank of the block",
    plain["RootCount"] === Length[indices] &&
      plain["GradeCount"] === gradeCount &&
      plain["RootIndices"] === indices];
  check[name <> ": the nullity is exactly the constant-gauge freedom",
    plain["Nullity"] === Times @@ dimensions];
  check[name <> ": every sign branch is satisfied by the modular solution",
    Length[plain["BranchCertificate"]] === gradeCount &&
      AllTrue[plain["BranchCertificate"], TrueQ[#["ResidualZero"]] &]];
  check[name <> ": the direct rows agree with the split-sign assembly",
    plain["DifferentialCheck"]["Status"] ===
      "MultiquadraticPointDifferentialPassed"];

  preparation = prepare[record, frame, "OneForms" -> oneForms,
    "GaugeDenominator" -> denominator, "Support" -> support];
  assembly = compile[preparation];
  known = packVector[preparation, coefficients, residues];
  check[name <> ": the preparation reproduces the ansatz the block was built in",
    preparation["GaugeSupport"] === support &&
      Lookup[preparation["Roots"], "Root", {}] === roots &&
      Length[known] === preparation["UnknownCount"]];
  heldPrime = plain["HeldOutPrime"];
  (* the known coefficients are rationals: Mod on a Rational is the
     rational remainder, so the field image is taken explicitly *)
  knownImage = FeynFacet`Private`multiquadraticStripModRational[#, heldPrime] & /@
    known;
  heldSample = assembleSample[assembly, plain["HeldOutRegulatorValue"], heldPrime,
    "SplitPointsOnly" -> True];
  check[name <> ": the held-out sample reassembles at the unseen prime",
    Lookup[heldSample, "Status", None] === "AssembledMultiquadraticSampleV1" &&
      TrueQ[heldSample["SplitPointsOnly"]]];
  check[name <> ": the known gauge satisfies the system at the unseen prime",
    AllTrue[Mod[heldSample["Matrix"] . knownImage - heldSample["RightHandSide"],
      heldPrime], # === 0 &]];
  check[name <> ": fresh reconstruction checks replace the duplicate held-out solve",
    plain["HeldOutSolution"]["Status"] ===
        "SupersededByReconstructionFreshChecks" &&
      plain["PostReconstructionAffineSolveCount"] === 0 &&
      plain["FullAffineSolveCount"] ===
        plain["RegulatorReconstruction"]["FullAffineSolveCount"]];
  branchResiduals = Table[
    Module[{transformed = transformSample[assembly, heldSample, heldPrime, mask]},
      Lookup[transformed, "Status", None] ===
          "TransformedMultiquadraticSampleToSignsV1" &&
        AllTrue[Mod[transformed["Rows"] . knownImage -
          transformed["RightHandSide"], heldPrime], # === 0 &]],
    {mask, 0, gradeCount - 1}];
  check[name <> ": the known gauge satisfies every sign branch at the unseen prime",
    Length[branchResiduals] === gradeCount && AllTrue[branchResiduals, TrueQ]];

  pinned = solve[record, frame, "OneForms" -> oneForms,
    "GaugeDenominator" -> denominator, "Support" -> support,
    "NormalizationEquations" -> normalizations];
  AppendTo[statuses, Lookup[pinned, "Status", None]];
  check[name <> ": modular consistency with the constant gauge pinned",
    AssociationQ[pinned] && pinned["Status"] === "ModularConsistent" &&
      pinned["Nullity"] === 0];
  If[! (AssociationQ[pinned] && pinned["Status"] === "ModularConsistent"),
    Print["     ", Short[pinned, 6]]; Return[pinned]];
  check[name <> ": the exact lift reproduces the known gauge exactly",
    AllTrue[pinned["RegulatorValues"],
      pinned["ExactLift"][#] === "LiftedMultiquadraticVector" &&
        pinned["ExactLiftVectors"][#] === known &]];
  check[name <> ": the reconstructed identity carries its selected verification contract",
    AllTrue[pinned["RegulatorValues"],
      pinned["ExactChannelResidual"][#] === If[
        pinned["RegulatorReconstruction"]["ExactVerification"] ===
          "ProviderPoints", "ProviderPointwiseResidualZero",
        "ExactChannelResidualZero"] &]];
  check[name <> ": the reconstructed gauge equals the known gauge",
    AllTrue[Flatten[Map[Together, pinned["Gauge"] - gauge, {2}]], # === 0 &]];
  check[name <> ": the reconstructed residues equal the known residues",
    AllTrue[Flatten[pinned["Residues"] - residues], # === 0 &]];
  check[name <> ": reconstruction reuses the constrained elimination plan",
    pinned["RegulatorReconstruction"]["FullAffineSolveCount"] >= 1 &&
      pinned["RegulatorReconstruction"]["ConstrainedSolveCount"] >= 1 &&
      AllTrue[Lookup[pinned["RegulatorReconstruction"]["ImagePhaseRecords"],
        "SolvePath", {}], StringQ]];
  check[name <> ": sampling and elimination have disjoint telemetry",
    AllTrue[Lookup[pinned["RegulatorReconstruction"]["PhaseSeconds"],
      {"Sampling", "Elimination"}, {}], NumericQ[#] && # >= 0 &]];
  check[name <> ": top-level adds no affine solve after reconstruction",
    pinned["PostReconstructionAffineSolveCount"] === 0 &&
      pinned["FullAffineSolveCount"] ===
        pinned["RegulatorReconstruction"]["FullAffineSolveCount"]];
  pinned];

results = <||>;
Do[
  Module[{name = specification[[1]], seconds, result},
    {seconds, result} = AbsoluteTiming[runCase[name, specification[[2]],
      specification[[3]], specification[[4]]]];
    results[name] = result;
    Print["     ", name, ": ", Round[seconds, 0.01], " s"]],
  {specification, {
    {"RANK0_1x1", {}, {1, 1}, 101},
    {"RANK1_1x1", {1}, {1, 1}, 202},
    {"RANK2_2x1", {1, 2}, {2, 1}, 303},
    {"RANK3_1x1", {1, 2, 3}, {1, 1}, 404}}}];

check["no case ever returned Solved",
  statuses =!= {} && FreeQ[statuses, "Solved"] &&
    AllTrue[statuses, # === "ModularConsistent" &]];

(* ---- typed rejections on the production path ---- *)
rank1 = results["RANK1_1x1"];
record1 = <|"Family" -> "REJECT", "Sector" -> 4, "LowerSector" -> 2,
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {diagonalForm[{{{1}}, {{-1}}, {{2}}}],
    diagonalForm[{{{-2}}, {{1}}, {{0}}}],
    Table[Together[eps oneForms[[1, mu]] {{Sqrt[x]}} +
      D[{{Sqrt[x] x/denominator}}, {x, y}[[mu]]]], {mu, 2}]}|>;
preparation1 = prepare[record1, frame, "OneForms" -> oneForms,
  "GaugeDenominator" -> denominator, "Support" -> support];
assembly1 = compile[preparation1];
check["the rejection fixture prepares and compiles",
  Lookup[preparation1, "Status", None] === "PreparedMultiquadraticStripV1" &&
    Lookup[assembly1, "Status", None] === "CompiledMultiquadraticStripV1"];
check["BranchFlipMask is a typed error in the production sampler",
  Lookup[assembleSample[assembly1, 1/13, 2147483423, "BranchFlipMask" -> 1],
    "Status", None] === "BranchFlipMaskNotAvailableInProduction"];
check["BranchFlipMask is a typed error in the top-level solver",
  Lookup[solve[record1, frame, "OneForms" -> oneForms,
    "GaugeDenominator" -> denominator, "BranchFlipMask" -> 0],
    "Status", None] === "BranchFlipMaskNotAvailableInProduction"];
check["BranchFlipMask is a typed error in the preparation",
  Lookup[prepare[record1, frame, "BranchFlipMask" -> 1], "Status", None] ===
    "BranchFlipMaskNotAvailableInProduction"];
check["an unknown option is a typed error, not a silent default",
  Lookup[solve[record1, frame, "NoSuchOption" -> 1], "Status", None] ===
    "UnknownOption"];
check["a branch flip is still available to the differential certificate",
  AllTrue[Range[0, 1], Lookup[differentialCheck[assembly1, 1/13, 2147483423,
    First[assembleSample[assembly1, 1/13, 2147483423,
      "SplitPointsOnly" -> True]["AcceptedPoints"]], #], "Status", None] ===
    "MultiquadraticPointDifferentialPassed" &]];
check["an unavailable plan-discovery backend fails closed",
  Block[{FeynFacet`Private`$feynFacetDirectory =
      FileNameJoin[{$TemporaryDirectory, "cffr-definitely-absent"}]},
    Lookup[solve[record1, frame, "OneForms" -> oneForms,
      "PlanDiscoveryBackend" -> "FLINTAffineRREF"], "Status", None] ===
      "PlanDiscoveryBackendUnavailable"]];
check["an undeclared radical fails closed",
  Lookup[solve[<|"Family" -> "UNDECLARED", "Variables" -> {x, y},
    "Regulator" -> eps, "Strip" -> {diagonalForm[{{{1}}, {{0}}, {{0}}}],
      diagonalForm[{{{0}}, {{1}}, {{0}}}],
      Table[{{Sqrt[1 - x] eps oneForms[[1, mu]]}}, {mu, 2}]}|>, frame],
    "Status", None] === "StripContainsUndeclaredRadicals"];

(* ---- artifacts: explicit context, corrupted payload ---- *)
artifactDirectory = FileNameJoin[{$TemporaryDirectory,
  "multiquadratic_artifact_" <> ToString[$ProcessID]}];
artifactFile = FileNameJoin[{artifactDirectory, "preparation.wl"}];
corruptFile = FileNameJoin[{artifactDirectory, "corrupt.wl"}];
truncatedFile = FileNameJoin[{artifactDirectory, "truncated.wl"}];
written = artifactWrite[preparation1, artifactFile];
check["the artifact is written atomically with its hash",
  Lookup[written, "Status", None] === "MultiquadraticArtifactWritten" &&
    FileExistsQ[artifactFile] && StringLength[written["SHA256"]] === 64];
hydratedA = artifactRead[artifactFile, "FeynFacet`MultiquadraticArtifactA`"];
hydratedB = artifactRead[artifactFile, "FeynFacet`MultiquadraticArtifactB`"];
(* Context holds its argument (handoff pool defect 6): the symbol has
   to be handed over evaluated, or the held First[...] is inspected. *)
check["the artifact hydrates in an explicit context, not Global`",
  Lookup[hydratedA, "Status", None] === "HydratedMultiquadraticPreparation" &&
    Context[Evaluate[First[hydratedA["Preparation"]["Variables"]]]] ===
      "FeynFacet`MultiquadraticArtifactA`"];
check["the ABI fingerprint does not depend on the artifact context",
  Lookup[hydratedB, "Status", None] === "HydratedMultiquadraticPreparation" &&
    hydratedA["ABIFingerprint"] === hydratedB["ABIFingerprint"] ===
      preparation1["ABIFingerprint"]];
artifactWrite[Append[preparation1, "GaugeSupport" -> {{0, 0}}], corruptFile];
check["a corrupted artifact is a typed failure",
  Lookup[artifactRead[corruptFile, "FeynFacet`MultiquadraticArtifactC`"],
    "Status", None] === "ArtifactPreparationABIInvalid"];
Export[truncatedFile, "<|\"Status\" -> \"PreparedMultiquadraticStripV1\"", "Text"];
check["a truncated artifact is a typed failure, not an exception",
  MatchQ[Lookup[artifactRead[truncatedFile, "FeynFacet`MultiquadraticArtifactD`"],
    "Status", None], "ArtifactReadAborted" | "ArtifactNotAnAssociation" |
      "ArtifactSchemaUnknown" | "ArtifactPreparationABIInvalid"]];
check["a missing artifact is a typed failure",
  Lookup[artifactRead[FileNameJoin[{artifactDirectory, "absent.wl"}],
    "FeynFacet`MultiquadraticArtifactE`"], "Status", None] ===
    "ArtifactFileMissing"];
Quiet[DeleteDirectory[artifactDirectory, DeleteContents -> True]];

Print["t_multiquadratic_strip_solve: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
