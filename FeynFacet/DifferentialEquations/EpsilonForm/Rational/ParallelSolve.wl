(* Task-broker client of the finite-field off-diagonal block equation sampler: the helper-side
   task, the memory-bounded worker cap and the mission-side batch that
   replaces ParallelMap over regulator values.  Moved here verbatim from
   Infrastructure/TaskBroker.wl (layer pass 2026-09-02): these three
   functions call ComputeOffDiagonalBlockFiniteFieldImage and finiteFieldOffDiagonalBlockPrepare
   (FiniteFieldOffDiagonalBlockSolve.wl, EpsForm), and
   the generic broker (Infrastructure) must not reference EpsForm.  The
   helper kernels evaluate taskBrokerSampleTask by its full name
   FeynFacet`Private`taskBrokerSampleTask from the task code string, so
   the function must be defined in every kernel that loads FeynFacet. *)

ClearAll[
  taskBrokerSampleTask,
  taskBrokerSampleWorkerLimit,
  taskBrokerSampleBatch,
  $taskBrokerHelperFailureCount
];

(* helper side: one task = several regulator values of one prime on the
   same off-diagonal block equation; record, preparation and options are read once per kernel *)
taskBrokerSampleTask[recordFile_String, values_List, prime_Integer,
    optionsFile_String] :=
 Module[{record, preparation, options},
  record = taskBrokerRead[recordFile];
  options = DeleteCases[taskBrokerRead[optionsFile],
    "DeferredInhomogeneityWaveValues" -> _];
  preparation = taskBrokerCached[{"preparation", recordFile},
    Module[{p = finiteFieldOffDiagonalBlockPrepare[record]},
      If[AssociationQ[p] && SameQ[p["DefiningInput"],
          finiteFieldOffDiagonalBlockDefiningInput[record]], p, $Failed]]];
  If[preparation === $Failed, Return[$Failed]];
  ComputeOffDiagonalBlockFiniteFieldImage[record, #, prime,
    "DeferredInhomogeneityWaveValues" -> values, Sequence @@ options,
    "Preparation" -> preparation] & /@ values];

(* A fixed-core sample holds a dense modular matrix in Wolfram and another
   native copy while FLINT solves it.  The peak scales quadratically with the
   affine unknown count.  On the measured 11,764-unknown block, seven workers
   consumed all 48 GiB and killed the controller; two workers remain safely
   below the same machine's available-memory budget.  This cap is based only
   on problem size and live available memory, so easy blocks retain the full
   pool and a busy host automatically receives fewer workers. *)
taskBrokerSampleWorkerLimit[sampleOptions_List, requested_Integer,
    availableBytes_: Automatic] := Module[
  {plan, unknowns, available, estimatedPeak, memoryLimit},
  If[requested < 1, Return[1]];
  plan = Lookup[sampleOptions, "EliminationPlan", None];
  unknowns = If[AssociationQ[plan],
    Lookup[plan, "UnknownCount", 0], 0];
  If[! IntegerQ[unknowns] || unknowns < 1, Return[requested]];
  available = Replace[availableBytes, Automatic :> Quiet[Check[
      QuantityMagnitude[UnitConvert[
        SystemInformation["Machine", "MemoryAvailable"], "Bytes"]],
      Infinity]]];
  If[! NumericQ[available] || available <= 0, Return[requested]];
  (* 56 n^2 bytes fits the observed Wolfram matrix, square core, native
     copy and solve workspace; 256 MiB covers fixed per-worker state. *)
  estimatedPeak = 2^28 + 56 unknowns^2;
  memoryLimit = Max[1, Floor[(3 available/5)/estimatedPeak]];
  Min[requested, memoryLimit]
];
taskBrokerSampleWorkerLimit[___] := 1;

(* mission side: replaces the ParallelMap over regulator values.  Any
   task that fails is recomputed locally, so the result is exactly what
   the serial path would have produced. *)
taskBrokerSampleBatch[record_Association, values_List, prime_Integer, sampleOptions_List] :=
 Module[{preparation, cacheID, recordFile, options, optionsFile, free, batches,
   workerCount, requestedWorkers, threadsPerWorker, balancedOptions,
   codes, handle, local, recomputed,
   results, flat, retry},
  preparation = Lookup[sampleOptions, "Preparation", Automatic];
  If[! AssociationQ[preparation] ||
      ! SameQ[Lookup[preparation, "DefiningInput", None],
        finiteFieldOffDiagonalBlockDefiningInput[record]],
    preparation = finiteFieldOffDiagonalBlockPrepare[record]];
  If[! AssociationQ[preparation], Return[$Failed]];
  cacheID = preparation["SamplingCacheID"];
  recordFile = taskBrokerDataFile["record_" <> cacheID, record];
  balancedOptions = Append[DeleteCases[sampleOptions, "Preparation" -> _],
      "Preparation" -> preparation] /. Rule["BackendThreads",
      requested_Integer] :> Rule["BackendThreads",
        taskBrokerNativeThreadLimit[requested]];
  balancedOptions = DeleteCases[balancedOptions,
    "DeferredInhomogeneityWaveValues" -> _];
  requestedWorkers = Min[taskBrokerFreeKernels[] + 1, Length[values]];
  workerCount = taskBrokerSampleWorkerLimit[
    sampleOptions, requestedWorkers];
  If[TrueQ[$taskBrokerLog] && workerCount < requestedWorkers,
    Print["[broker] sample worker memory cap: requested ",
      requestedWorkers, ", using ", workerCount, ", unknowns ",
      Lookup[Lookup[sampleOptions, "EliminationPlan", <||>],
        "UnknownCount", Missing["NotAvailable"]]]];
  free = Min[taskBrokerFreeKernels[], Length[values] - 1,
    workerCount - 1];
  (* no helper free: compute locally rather than queue behind the others *)
  If[free < 1,
    Return[ComputeOffDiagonalBlockFiniteFieldImage[record, #, prime,
      "DeferredInhomogeneityWaveValues" -> values,
      Sequence @@ balancedOptions] & /@ values]];
  (* free + 1 shares: the helpers take the first `free`, this kernel the last *)
  batches = Partition[values, UpTo[Max[1, Ceiling[Length[values]/(free + 1)]]]];
  workerCount = Length[batches];
  threadsPerWorker = Max[1, Quotient[
    taskBrokerNativeCoreQuota[], workerCount]];
  balancedOptions = sampleOptions /. Rule["BackendThreads",
      requested_Integer] :> Rule["BackendThreads",
        Min[requested, threadsPerWorker]];
  options = DeleteCases[balancedOptions, "Preparation" -> _];
  optionsFile = taskBrokerDataFile["opts_" <> cacheID <> "_" <>
    StringDelete[CreateUUID[], "-"], options];
  codes = StringJoin["FeynFacet`Private`taskBrokerSampleTask[\"", recordFile, "\", ",
    ToString[#, InputForm], ", ", ToString[prime], ", \"", optionsFile, "\"]"] & /@ Most[batches];
  handle = taskBrokerSubmit[codes, "Label" -> "ff" <> ToString[prime]];
  local = ComputeOffDiagonalBlockFiniteFieldImage[record, #, prime,
      "DeferredInhomogeneityWaveValues" -> Last[batches],
      Sequence @@ balancedOptions] & /@ Last[batches];
  results = Append[taskBrokerCollect[handle], local];
  flat = Flatten[MapThread[Function[{batch, r},
    If[ListQ[r] && Length[r] === Length[batch], r, ConstantArray[$Failed, Length[batch]]]],
    {batches, results}], 1];
  (* A broker transport failure ($Failed), or the one helper-local failure
     that the solving kernel can repair (an absent plan), gets one local
     retry.  Every other typed deferred failure is mathematical or native
     runtime data and propagates without a duplicate computation. *)
  retry = DeleteDuplicates[Join[
    Flatten[Position[flat, $Failed, {1}, Heads -> False]],
    Select[Range[Length[flat]],
      finiteFieldDeferredInhomogeneityLocalRetryQ[flat[[#]]] &]]];
  If[retry =!= {},
    recomputed = ComputeOffDiagonalBlockFiniteFieldImage[record, #, prime,
        "DeferredInhomogeneityWaveValues" -> values[[retry]],
        Sequence @@ balancedOptions] & /@ values[[retry]];
    Do[flat[[retry[[k]]]] = recomputed[[k]], {k, Length[retry]}]];
  flat];
