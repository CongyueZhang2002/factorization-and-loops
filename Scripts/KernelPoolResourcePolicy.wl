(* Pure policy for KernelPool's two distinct resources: Wolfram subkernel
   seats and native CPU threads.  It owns no processes and performs no I/O;
   the server publishes its result, while missions read that snapshot only
   at cooperative batch/native-call boundaries. *)

BeginPackage["KernelPoolResourcePolicy`"];

KernelPoolResourceMetadata::usage =
  "KernelPoolResourceMetadata[text] reads the generated mission resource marker.";
KernelPoolResourceAllocate::usage =
  "KernelPoolResourceAllocate[groups, seats, cores, running, offset] returns balanced live grants.";
KernelPoolResourceSelectHelper::usage =
  "KernelPoolResourceSelectHelper[records, running, allocations, last] chooses the next fair helper.";

Begin["`Private`"];

$resourceSchema = "KernelPoolResourceAllocationV1";
$resourceMarker = RegularExpression[
  "FACET_RESOURCE group=([A-Za-z0-9][A-Za-z0-9._-]{0,179}) role=([A-Za-z][A-Za-z0-9._-]{0,63}) owner=([A-Za-z0-9][A-Za-z0-9._-]{0,179})"];

validGroupQ[value_] := StringQ[value] &&
  StringMatchQ[value,
    RegularExpression["[A-Za-z0-9][A-Za-z0-9._-]{0,179}"]];

KernelPoolResourceMetadata[text_String] := Module[{matches},
  matches = StringCases[text, $resourceMarker :> {"$1", "$2", "$3"}];
  If[Length[matches] === 1,
    <|"Group" -> matches[[1, 1]], "Role" -> matches[[1, 2]],
      "Owner" -> matches[[1, 3]]|>,
    <|"Group" -> None, "Role" -> "mission", "Owner" -> None|>]
];
KernelPoolResourceMetadata[___] := <|"Group" -> None,
  "Role" -> "mission", "Owner" -> None|>;

KernelPoolResourceAllocate[groups_List, subkernelCapacity_Integer,
    nativeCoreCapacity_Integer, runningWorkers_: <||>, offset_Integer: 0] :=
 Module[{ordered, count, helperCapacity, helperCeiling, rotated,
   nativeBudget, baseNative, remainder, nativeByGroup, records},
  If[subkernelCapacity < 1 || nativeCoreCapacity < 1 ||
      ! AssociationQ[runningWorkers], Return[$Failed]];
  ordered = Sort[DeleteDuplicates[Select[groups, validGroupQ]]];
  count = Length[ordered];
  If[count === 0, Return[<|
    "Schema" -> $resourceSchema, "SubkernelCapacity" -> subkernelCapacity,
    "NativeCoreCapacity" -> nativeCoreCapacity, "ActiveFamilyCount" -> 0,
    "HelperCapacity" -> subkernelCapacity, "Groups" -> <||>|>]];
  helperCapacity = Max[0, subkernelCapacity - count];
  (* Ceil is intentional: central fair dispatch enforces the physical total
     when the division has a remainder.  With multiple active families this
     is a strict per-family ceiling.  Exact symbolic helper jobs are not
     preemptible; lending every idle seat to one family produced a measured
     257 s queue wait when its peer submitted work two seconds later. *)
  helperCeiling = If[helperCapacity === 0, 0,
    Ceiling[helperCapacity/count]];
  rotated = RotateLeft[ordered, Mod[offset, count]];
  (* A native CALL is capped at eight threads below, but a family may own
     more than eight total cores and spend them on independent workers (for
     example the measured two-image tail wave).  If families outnumber cores,
     one thread each is the unavoidable minimal oversubscription. *)
  nativeBudget = Max[count, nativeCoreCapacity];
  baseNative = Quotient[nativeBudget, count];
  remainder = Mod[nativeBudget, count];
  nativeByGroup = AssociationThread[rotated,
    Table[Max[1, baseNative + Boole[index <= remainder]],
      {index, count}]];
  records = Association@Table[With[
      {workers = Max[1, Lookup[runningWorkers, group, 1]],
       native = nativeByGroup[group]},
      group -> <|"HelperCeiling" -> helperCeiling,
        "NativeCoreQuota" -> native, "RunningWorkers" -> workers,
        "NativeThreadsPerWorker" ->
          Max[1, Min[8, Quotient[native, workers]]]|>],
    {group, ordered}];
  <|"Schema" -> $resourceSchema,
    "SubkernelCapacity" -> subkernelCapacity,
    "NativeCoreCapacity" -> nativeCoreCapacity,
    "ActiveFamilyCount" -> count,
    "HelperCapacity" -> helperCapacity,
    "Groups" -> records|>
];
KernelPoolResourceAllocate[___] := $Failed;

KernelPoolResourceSelectHelper[records_List, runningHelpers_Association,
    allocations_Association, lastDispatch_Association] := Module[
  {valid, groups, underCeiling, candidates, score},
  groups = Lookup[allocations, "Groups", <||>];
  If[! AssociationQ[groups], Return[Missing["NoEligibleHelper"]]];
  valid = Select[records, AssociationQ[#] &&
      StringQ[Lookup[#, "File", None]] &&
      validGroupQ[Lookup[#, "Group", None]] &&
      KeyExistsQ[groups, Lookup[#, "Group", None]] &];
  If[valid === {}, Return[Missing["NoEligibleHelper"]]];
  underCeiling = Select[valid, With[
      {group = #1["Group"], ceiling = Lookup[
          Lookup[groups, #1["Group"], <||>], "HelperCeiling", 0]},
      IntegerQ[ceiling] && ceiling > 0 &&
        Lookup[runningHelpers, group, 0] < ceiling] &];
  (* A sole family owns the complete helper capacity through its allocation.
     With multiple families, never borrow above the published ceiling: an
     already-running symbolic task cannot be reclaimed when a peer queues its
     next phase. *)
  If[underCeiling === {}, Return[Missing["AllGroupsAtHelperCeiling"]]];
  candidates = underCeiling;
  score[record_] := With[{group = record["Group"]}, {
    Lookup[runningHelpers, group, 0],
    Lookup[lastDispatch, group, 0.],
    Lookup[record, "Date", 0.], record["File"]}];
  First[SortBy[candidates, score]]
];
KernelPoolResourceSelectHelper[___] := Missing["NoEligibleHelper"];

End[];
EndPackage[];
