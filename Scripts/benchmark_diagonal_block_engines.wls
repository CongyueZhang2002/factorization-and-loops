(* Apples-to-apples timing of the two stage-1 engines on the class
   representatives: CANONICA (the production ladder of CanonicalBlocks.wl:
   RecursivelyTransformSectors at ansatz degrees 0,1,2 with the exact
   ValidateCanonicalForm gate, 300 s per degree) versus the finite-field
   route (DiagonalBlockEpsForm: Libra slice -> FF ODE solve -> exact
   completion -> exact gate).  BOTH engines receive the SAME system: the
   class representative in the frame of its ledger record (original
   (v,w), or the ledger's chart when the ledger used one), so chart
   discovery is not timed for either.  One engine per kernel, serial.
   Args: ENGINE (CANONICA|FiniteField) OUTDIR [CLASSIDS comma list | ALL] [SKIP comma list] [KERNELS]
   KERNELS > 0 runs the classes on that many subkernels under one main
   kernel (one class per subkernel at a time; per-class wall times are
   then measured under 4-way sharing of the machine). Resumes: classes
   already in bench_<engine>.wl are skipped. *)
root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
R = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
engine = $ScriptCommandLine[[2]]; out = $ScriptCommandLine[[3]];
which = If[Length[$ScriptCommandLine] >= 4, $ScriptCommandLine[[4]], "ALL"];
skip = If[Length[$ScriptCommandLine] >= 5 && $ScriptCommandLine[[5]] =!= "", ToExpression /@ StringSplit[$ScriptCommandLine[[5]], ","], {}];
kernels = If[Length[$ScriptCommandLine] >= 6, ToExpression[$ScriptCommandLine[[6]]], 0];
If[! DirectoryQ[out], CreateDirectory[out, CreateIntermediateDirectories -> True]];
v = Global`v; w = Global`w; x = Global`x; y = Global`y; t = Global`t; eps = Global`eps;
cls = FeynFacet`FamilyArtifactRead[FileNameJoin[{R, "BlockClasses", "classes.wl"}]];
ids = If[which === "ALL", Lookup[cls, "ClassID"], ToExpression /@ StringSplit[which, ","]];
ids = Complement[ids, skip];
resultFile = FileNameJoin[{out, "bench_" <> engine <> ".wl"}];
results = If[FileExistsQ[resultFile], FeynFacet`FamilyArtifactRead[resultFile], {}];
If[! ListQ[results], results = {}];
done = Lookup[results, "ClassID"];
tog[m_] := Map[Cancel[Together[#]] &, m, {2}];

(* the system in the ledger frame *)
frameSystem[ent_] := Module[{rec, chart, av = ent["RepAv"], aw = ent["RepAw"], vars, sys},
  rec = FeynFacet`FamilyArtifactRead[FileNameJoin[{R, "ClassForms", "class" <> ToString[ent["ClassID"]] <> ".wl"}]];
  chart = If[AssociationQ[rec], Lookup[rec, "Chart", None], None];
  Which[
    chart === None || MissingQ[chart], {tog /@ {av, aw}, {v, w}, "vw"},
    AssociationQ[chart] && KeyExistsQ[chart, "Fixed"],
      {sys, vars} = FeynFacet`Private`canonicalBlocksApplyChart[{av, aw}, chart, {v, w}, t];
      {tog /@ sys, vars, "conic"},
    AssociationQ[chart] && Lookup[chart, "Kind", None] === "TwoVariable",
      Module[{sub = chart["Subst"], cv = chart["Variables"], sv, sw},
        sv = v /. sub; sw = w /. sub;
        {tog /@ {(av /. sub) D[sv, cv[[1]]] + (aw /. sub) D[sw, cv[[1]]],
                 (av /. sub) D[sv, cv[[2]]] + (aw /. sub) D[sw, cv[[2]]]}, cv, "twovariable"}],
    True, {tog /@ {av, aw}, {v, w}, "vw"}]];

runCanonica[sys_, vars_, dim_] := Module[{converted, attempt, t0 = AbsoluteTime[]},
  FeynFacet`Private`canonicalBlocksLoadCanonica[];
  converted = sys /. FeynFacet`Private`canonicalBlocksToCanonica[eps];
  attempt = FeynFacet`Private`canonicalBlocksAttempt[converted, dim, vars, {0, 1, 2}, 300, 12 10^9,
    FeynFacet`Private`canonicalBlocksSolve[Automatic], eps, False];
  <|"Status" -> If[AssociationQ[attempt], "Certified", "Unresolved"],
    "AnsatzDegree" -> If[AssociationQ[attempt], attempt["AnsatzDegree"], None],
    "Seconds" -> AbsoluteTime[] - t0|>];

runFiniteField[sys_, vars_, dim_] := Module[{letters, order, res, t0 = AbsoluteTime[]},
  letters = FeynFacet`DiagonalBlockLetters[sys, vars, eps]["Letters"];
  (* slice in a variable in which every letter is linear; first variable preferred *)
  order = SelectFirst[{{1, 2}, {2, 1}}, With[{sv = vars[[#[[1]]]]}, AllTrue[letters, Exponent[#, sv] <= 1 &]] &, {1, 2}];
  res = TimeConstrained[
    FeynFacet`DiagonalBlockEpsForm[sys[[order]], vars[[order]], eps], 900, <|"Status" -> "TimedOut"|>];
  <|"Status" -> res["Status"], "Seconds" -> AbsoluteTime[] - t0,
    "Timing" -> Lookup[res, "Timing", Missing[]],
    "SliceVariable" -> vars[[order[[1]]]],
    "Detail" -> Which[
      res["Status"] === "Certified", <|"Primes" -> res["Solve"]["PrimeCount"], "Unknowns" -> res["Solve"]["UnknownCount"], "Balances" -> res["Slice"]["BalanceCount"]|>,
      KeyExistsQ[res, "Slice"], <|"Slice" -> Lookup[res["Slice"], "Status", "-"], "Solve" -> Lookup[Lookup[res, "Solve", <||>], "Status", "-"], "Completion" -> Lookup[Lookup[res, "Completion", <||>], "Status", "-"]|>,
      True, <||>]|>];

runOne[id_] := Module[{ent = SelectFirst[cls, #["ClassID"] == id &], sys, vars, frame, r},
  {sys, vars, frame} = frameSystem[ent];
  r = If[engine === "CANONICA", runCanonica[sys, vars, ent["Dim"]], runFiniteField[sys, vars, ent["Dim"]]];
  Join[<|"ClassID" -> id, "Dim" -> ent["Dim"], "Frame" -> frame, "Variables" -> vars, "Engine" -> engine|>, r]];
report[r_] := (AppendTo[results, r];
  FeynFacet`FamilyArtifactWrite[results, resultFile];
  Print["BENCH ", engine, " class ", r["ClassID"], " dim ", r["Dim"], " frame ", r["Frame"], " -> ", r["Status"],
    " ", Round[r["Seconds"], 0.1], " s ", Lookup[r, "AnsatzDegree", ""], " ", Lookup[r, "Detail", ""]]);
todo = Select[ids, ! MemberQ[done, #] &];
If[kernels > 0,
  (* one main + `kernels` subkernels; each subkernel loads the full stack
     (and CANONICA / Libra on first use); classes are handed out one at a
     time as subkernels free up *)
  launched = LaunchKernels[kernels];
  Print["launched ", Length[launched], " subkernels"];
  With[{loader = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]},
    ParallelEvaluate[Block[{$Output = {}}, Get[loader]]; $KernelID]];
  DistributeDefinitions[R, engine, cls, v, w, x, y, t, eps, tog, frameSystem, runCanonica, runFiniteField, runOne];
  queue = todo; running = {};
  While[queue =!= {} || running =!= {},
    While[queue =!= {} && Length[running] < kernels,
      With[{id = First[queue]}, AppendTo[running, ParallelSubmit[runOne[id]]]];
      queue = Rest[queue]];
    If[running =!= {},
      {result, finished, running} = WaitNext[running];
      If[AssociationQ[result], report[result], Print["BENCH ", engine, " FAILED evaluation: ", Short[result]]]]];
  CloseKernels[launched],
  Do[report[runOne[id]], {id, todo}]];
Print["DONE ", engine, " ", Length[results], " classes"];
