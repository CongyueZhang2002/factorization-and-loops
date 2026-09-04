#!/usr/bin/env wolframscript
(* The deferred-forcing (DAG) route of the finite-field strip solver
   (FiniteFieldDeferredForcing.wl), round 8 pass 3 with R2's fixes:
   F1 -- an image call is atomic with respect to the bounded image cache:
         crossing the 400,000-entry reset inside one multi-chunk call must
         return every value (R2's fixture P2: cache pre-filled to 399,998,
         batch limit 8, 20 uncached images returned 8 Missing under "OK");
   F2 -- a helper kernel (empty plan registry) rebuilds the plan from the
         descriptor's handle and samples exactly like the solving kernel;
         without the handle the sample returns a typed runtime reason.
   The fixture is the campaign's CF300 (12,9) chart strip (a deferred
   preparation with a rational chart); a missing fixture fails the test. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
inputFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "FamilyEpsFormsSolving", "triple_root_2026-08-28_codex_clean", "CF300", "sector_CF300_standard",
  "CF300_12_9_input.wl"}];
chartFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical", "TransportFamilyCharts.wl"}];
FTAssert["D0 fixture CF300 (12,9) and the family chart file exist",
  FileExistsQ[inputFile] && FileExistsQ[chartFile]];
If[! (FileExistsQ[inputFile] && FileExistsQ[chartFile]), FTSummary[]; Exit[1]];
FeynFacet`LoadFamilyRootData[chartFile];
prime = 2147483423;

(* the plan, as SolveEpsFormStripInFrame builds it *)
{currentRoots, rootIndicesOf, rekey, chartData, pullStrip} = mq /@ {"transportChartCurrentRoots",
  "transportChartRootIndices", "transportChartRekey", "masterTransportChartData", "transportChartPullBackStrip"};
record = FeynFacet`FamilyArtifactRead[inputFile, "Global`"];
variables = record["Variables"]; epsilon = record["Regulator"]; {e, c, bbar} = record["Strip"];
frame = FeynFacet`FamilyRootData[record["Family"]];
allRoots = currentRoots[frame, variables];
dp = record["DeferredPreparation"]; prepSquares = Lookup[dp, "RootSquares", {}];
cls = rootIndicesOf[{e, c}, allRoots];
matchIndex[square_] := First[Flatten[Position[allRoots, r_ /; TrueQ[Together[r["RootSquare"] - square] === 0], {1}, Heads -> False]]];
rootIndices = Sort[DeleteDuplicates[Join[cls["RootIndices"], matchIndex /@ prepSquares]]];
usedRoots = allRoots[[rootIndices]]; rootSquares = Lookup[usedRoots, "RootSquare", {}];
chart = FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[rootSquares, variables];
chartVariables = {Symbol["FeynFacet`Private`stripChartX"], Symbol["FeynFacet`Private`stripChartY"]};
rekeyed = rekey[chart, variables, chartVariables]; data = chartData[rekeyed, variables];
chartRoots = Lookup[rekeyed, "Roots", {}];
rootImages = Table[SelectFirst[chartRoots, TrueQ[Together[#["RootSquare"] - usedRoots[[i]]["RootSquare"]] === 0] &]["Root"], {i, Length[usedRoots]}];
plan = mq["finiteFieldDeferredForcingPlan"][dp, inputFile, data, usedRoots, rootImages, chartVariables, variables, epsilon, Dimensions[First[bbar]]];
FTAssert["D1 the deferred forcing plan is built and registered", plan["Status"] === "OK" && StringQ[plan["Key"]]];
key = plan["Key"];
ImagesRaw = mq["finiteFieldDeferredForcingImages"];
Images[k_, p_, points_] := ImagesRaw[k, p, points, "Threads" -> 2];
cacheOf[] := mq["$finiteFieldDeferredForcingImageCache"];
setCache[v_] := (FeynFacet`Private`$finiteFieldDeferredForcingImageCache = v);
setLimit[n_] := (FeynFacet`Private`$finiteFieldDeferredForcingBatchLimit = n);
images[n_, seed_] := BlockRandom[SeedRandom[seed]; Table[Append[RandomInteger[{2, prime - 2}, 2], RandomInteger[{2, prime - 2}]], {n}]];

(* chunking is invisible: one request or many give the same values *)
im30 = images[30, 11];
setCache[<||>]; rBig = Images[key, prime, im30];
setLimit[7]; setCache[<||>]; rSmall = Images[key, prime, im30]; setLimit[1024];
FTAssert["D2 a batch limit of 7 returns the same two-thread images as one request of 30",
    rBig["Status"] === "OK" && rSmall["Status"] === "OK" && rBig["Values"] === rSmall["Values"] &&
    rSmall["BatchedImages"] === 30 && rBig["Threads"] === 2 && rSmall["Threads"] === 2];

(* R2 F1 (fixture P2): the cache crosses its reset inside one multi-chunk call *)
im20 = images[20, 12];
setCache[<||>]; rRef = Images[key, prime, im20];
setCache[Association @@ Table[{"dummy", k} -> 0, {k, 399998}]];
setLimit[8]; rReset = Images[key, prime, im20]; setLimit[1024];
FTAssert["D3 (R2 F1) a call crossing the cache reset returns OK with every value present and equal to the fresh-cache reference",
  rReset["Status"] === "OK" && FreeQ[rReset["Values"], _Missing, {1}] && rReset["Values"] === rRef["Values"]];
(* the next call starts with the bounded cache: reset, then complete *)
rNext = Images[key, prime, im20];
FTAssert["D4 the call after the threshold resets the cache between calls and is complete",
  rNext["Status"] === "OK" && rNext["Values"] === rRef["Values"] && Length[cacheOf[]] === 20];
(* a hole can never be reported as OK: a value forced Missing is a typed failure *)
setCache[<||>];
Block[{FeynFacet`Private`finiteFieldDeferredForcingPreflights = Function[{p, q, ims}, {}]},
  rHole = Quiet[Images[key, prime, im20[[;; 2]]]]];
FTAssert["D5 a call whose chunk produced no values is a typed failure, never OK",
  rHole["Status"] =!= "OK"];
setCache[<||>];

(* R2 F2: the helper path.  The record the sampler sees (as SolveEpsFormStripInFrame
   builds it): chart strip with the placeholder forcing and the descriptor. *)
census = mq["finiteFieldDeferredForcingCensus"][key, prime, "Threads" -> 2];
FTAssert["D6 the census accepts the strip", census["Status"] === "OK"];
descriptor = <|"Key" -> key, "Census" -> KeyTake[census, {"Letters", "GaugeFactorPowers", "ForcingInfinityDegree"}],
  "Handle" -> mq["finiteFieldDeferredForcingHandle"][plan]|>;
chartBranchRoots = Map[<|"RootSquare" -> Together[#["RootSquare"] /. data["Subst"]]|> &, usedRoots];
chartEC = pullStrip[{e, c, bbar}, data, chartBranchRoots, rootImages];
sampleRecord = <|"Strip" -> {chartEC[[1]], chartEC[[2]], ConstantArray[0, Dimensions[bbar]]},
  "Variables" -> chartVariables, "Regulator" -> epsilon, "DeferredForcing" -> descriptor|>;
preparation = mq["finiteFieldStripPrepare"][sampleRecord];
FTAssert["D7 the sampler's preparation carries the descriptor", AssociationQ[preparation] &&
  AssociationQ[Lookup[preparation, "DeferredForcing", None]] &&
  AssociationQ[preparation["DefiningInput"]]];
stripSeconds[a_] := If[AssociationQ[a], KeySelect[a,
  ! StringEndsQ[ToString[#], "Seconds"] && # =!= "SamplingImagesBatched" &], a];
sampleOptions = {"PointCount" -> 12, "RandomSeed" -> 2540908,
  "BackendThreads" -> 2};
(* the solving kernel's sample *)
main = FeynFacet`SampleEpsFormStripAffine[sampleRecord, 1/13, prime, Sequence @@ sampleOptions,
  "Preparation" -> preparation];
FTAssert["D8 the solving kernel samples the DAG-route strip", AssociationQ[main]];
(* a helper kernel: empty registry, the broker's task function, the files it reads *)
(* the files a real broker writes under its pool directory (taskBrokerDataFile
   needs a live pool); here the same atomic writer into a fresh directory *)
brokerDir = CreateDirectory[];
recordFile = mq["taskBrokerPutAtomic"][sampleRecord,
  FileNameJoin[{brokerDir, "record.wl"}]];
optionsFile = mq["taskBrokerPutAtomic"][sampleOptions, FileNameJoin[{brokerDir, "opts.wl"}]];
FeynFacet`Private`$finiteFieldDeferredForcingRegistry = <||>; setCache[<||>];
helper = mq["taskBrokerSampleTask"][recordFile, {1/13, 2/17}, prime,
  optionsFile];
FTAssert["D9 (R2 F2) a helper with an empty registry rebuilds the plan from the handle and returns the solving kernel's sample",
  ListQ[helper] && Length[helper] === 2 && AssociationQ[First[helper]] &&
    stripSeconds[First[helper]] === stripSeconds[main] &&
    KeyExistsQ[FeynFacet`Private`$finiteFieldDeferredForcingRegistry, key] &&
    TrueQ[FeynFacet`Private`$finiteFieldDeferredForcingRegistry[key]["Slim"]]];
FTAssert["D10 the helper preserves one forcing-image wave across its regulator batch",
  helper[[1]]["SamplingImagesBatched"] > 0 &&
    helper[[2]]["SamplingImagesBatched"] === 0];
FTAssert["D11 the rebuilt plan serves images identical to the original plan's",
  With[{r = Images[key, prime, im20]}, r["Status"] === "OK" && r["Values"] === rRef["Values"]]];
FTAssert["D12 a slim plan refuses a census typed",
  mq["finiteFieldDeferredForcingCensus"][key, prime,
    "Threads" -> 2]["Status"] === "DeferredForcingPlanSlim"];
(* without the handle: a typed runtime result, eligible for one local retry *)
FeynFacet`Private`$finiteFieldDeferredForcingRegistry = <||>;
noHandle = Join[sampleRecord, <|"DeferredForcing" -> KeyDrop[descriptor, "Handle"]|>];
noHandlePreparation = mq["finiteFieldStripPrepare"][noHandle];
bare = Quiet[FeynFacet`SampleEpsFormStripAffine[noHandle, 1/13, prime, Sequence @@ sampleOptions,
  "Preparation" -> noHandlePreparation]];
FTAssert["D13 without a handle a helper's sample returns its typed reason",
  mq["finiteFieldDeferredForcingRuntimeFailureQ"][bare] &&
    bare["Reason"] === "DeferredForcingPlanUnknown" &&
    mq["finiteFieldDeferredForcingLocalRetryQ"][bare] &&
    ! mq["finiteFieldDeferredForcingLocalRetryQ"][
      mq["finiteFieldDeferredForcingRuntimeFailure"]["DeferredForcingBatchFailed"]]];

(* Each rationalized radical receives an independent conjugation sign. *)
rx = Unique["rx"]; ry = Unique["ry"];
radicalExpression = 1 + Sqrt[(1 + rx)^2] + Sqrt[(1 + ry)^2];
radicalVariants = mq["finiteFieldDeferredForcingRadicalVariants"][radicalExpression];
expectedVariants = Flatten[Table[1 + sx (1 + rx) + sy (1 + ry),
  {sx, {1, -1}}, {sy, {1, -1}}]];
FTAssert["D14 two rationalized radicals produce the complete four-element sign orbit",
  Length[radicalVariants] === 4 && AllTrue[expectedVariants,
    Function[expected, AnyTrue[radicalVariants,
      TrueQ[Together[# - expected] === 0] &]]]];

(* A runtime adapter failure is not reinterpreted as an inconsistent ansatz. *)
Block[{FeynFacet`Private`finiteFieldDeferredForcingImages =
    Function[{k0, p0, images0, threadOption},
      <|"Status" -> "SyntheticDeferredBatchFailure"|>]},
  topFailure = Quiet[FeynFacet`SolveEpsFormStripFiniteField[sampleRecord,
    "Primes" -> {prime}, "MaximumPrimeCount" -> 1,
    "PointCount" -> 12, "KernelCount" -> 1, "BackendThreads" -> 2,
    "SupportLearning" -> False, "Verbose" -> False]]];
FTAssert["D15 the top-level solver preserves a typed deferred runtime failure",
  mq["finiteFieldDeferredForcingRuntimeFailureQ"][topFailure] &&
    topFailure["Reason"] === "SyntheticDeferredBatchFailure"];
(* the solving kernel's registry is restored for whatever follows *)
mq["finiteFieldDeferredForcingPlan"][dp, inputFile, data, usedRoots, rootImages, chartVariables, variables, epsilon, Dimensions[First[bbar]]];
Quiet[DeleteDirectory[brokerDir, DeleteContents -> True]];
FTSummary[];
