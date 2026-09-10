(* Shared exact algebra, basis definitions, and result metadata. *)

NA = Missing["NotApplicable"];

(* --- installation geometry ---------------------------------------- *)

(* The directory under which the package creates its OWN scratch
   workspaces (Kira projects, coefficient stores).  That is a property
   of the installation, not of the package's parent directory: a user
   whose result tree lives on one filesystem and whose scratch space
   lives on another sets Global`$FACETWorkspaceRoot before loading.  The
   default is the repository root, which is where every workspace this
   repository already contains was created (generality pass
   2026-08-23). *)
$feynFacetWorkspaceRoot = If[StringQ[Global`$FACETWorkspaceRoot],
  Global`$FACETWorkspaceRoot,
  $feynFacetRoot
];

(* Machine size.  The kernel ceiling 8 and the CPU-list width 16 used to
   be literals; they are MEASURED caps of this installation (the shared
   licence accepts 8 subkernels; the CPU list was written for a 16-core
   budget) and stay as caps, but the machine size behind them is now
   read from the system.  The two counts differ and both are needed:
   $ProcessorCount is what the Wolfram kernel will parallelize over (8
   on this box), while a taskset CPU list must name OPERATING-SYSTEM
   cpus (20 on this box), so the OS count is read where the kernel can
   see it and $ProcessorCount is the floor. *)
$facetKernelCeiling = 8;
$facetCPUCap = 16;

facetProcessorCount[] := facetProcessorCount[] = Module[{count = 0, text},
  If[FileExistsQ["/proc/cpuinfo"],
    text = Quiet @ Check[Import["/proc/cpuinfo", "Text"], $Failed];
    If[StringQ[text],
      count = Length @ StringCases[text,
        StartOfLine ~~ "processor" ~~ WhitespaceCharacter ... ~~ ":"]]];
  Max[count, $ProcessorCount, 1]
];

GlobalBasisGram = {
  {0, 1, 0, 0},
  {1, 0, 0, 0},
  {0, 0, -1, 0},
  {0, 0, 0, -1}
};

globalBasis = Missing["NotSet"];
internalSetEvanescentZero = Missing["NotSet"];

facetKernelCount[requested_: Automatic, workload_: Infinity] := Module[
  {environment, ceiling, count},
  environment = Environment["FACET_KERNEL_COUNT"];
  ceiling = Which[
    ValueQ[Global`$FACETKernelLimit] &&
        IntegerQ[Global`$FACETKernelLimit] &&
        Global`$FACETKernelLimit > 0,
      Global`$FACETKernelLimit,
    StringQ[environment] && StringLength[environment] > 0 &&
        IntegerQ[Quiet[Check[ToExpression[environment], $Failed]]] &&
        ToExpression[environment] > 0,
      ToExpression[environment],
    True, $facetKernelCeiling
  ];
  (* OMP_NUM_THREADS=1 can make $ProcessorCount equal 1 even when the
     process affinity includes many CPUs. It limits in-kernel threading,
     not the number of independently requested Wolfram subkernels. *)
  ceiling = Min[$facetKernelCeiling, facetProcessorCount[], ceiling];
  count = If[IntegerQ[requested] && requested > 0,
    Min[requested, ceiling], ceiling];
  If[IntegerQ[workload] && workload > 0, Min[count, workload], count]
];

facetCPUList[] := Module[
  {value = Environment["FACET_CPU_LIST"], width, fallback, parts, cpus},
  width = Min[$facetCPUCap, facetProcessorCount[]];
  fallback = StringRiffle[ToString /@ Range[0, width - 1], ","];
  If[! StringQ[value] ||
      ! StringMatchQ[value,
        RegularExpression["[0-9]+(?:[-,][0-9]+)*"]],
    Return[fallback]];
  parts = StringSplit[value, ","];
  cpus = Flatten[parts /. part_String :>
      If[StringContainsQ[part, "-"],
        With[{bounds = ToExpression /@ StringSplit[part, "-"]},
          If[bounds[[1]] <= bounds[[2]], Range @@ bounds, {}]],
        {ToExpression[part]}]];
  cpus = Take[DeleteDuplicates[cpus], UpTo[width]];
  If[cpus === {}, fallback, StringRiffle[ToString /@ cpus, ","]]
];
