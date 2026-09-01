(* Pure policy for KernelPool's distinct Wolfram-seat and native-core pools. *)

BeginPackage["KernelPoolResourcePolicy`"];

KernelPoolResourceMetadata::usage =
  "KernelPoolResourceMetadata[text] reads a mission resource marker.";
KernelPoolResourceAllocate::usage =
  "KernelPoolResourceAllocate[groups,seats,cores,running,offset] returns live grants.";
KernelPoolResourceSelectHelper::usage =
  "KernelPoolResourceSelectHelper[records,running,allocations,last] chooses a fair helper.";

Begin["`Private`"];

$resourceSchema = "KernelPoolResourceAllocationV1";
$resourceMarker = RegularExpression[
  "FACET_RESOURCE group=([A-Za-z0-9][A-Za-z0-9._-]{0,179}) role=([A-Za-z][A-Za-z0-9._-]{0,63}) owner=([A-Za-z0-9][A-Za-z0-9._-]{0,179})"];

validGroupQ[value_] := StringQ[value] && StringMatchQ[value,
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
  helperCeiling = If[helperCapacity === 0, 0,
    Ceiling[helperCapacity/count]];
  rotated = RotateLeft[ordered, Mod[offset, count]];
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
  {valid, groups, underCeiling, score},
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
  If[underCeiling === {},
    Return[Missing["AllGroupsAtHelperCeiling"]]];
  score[record_] := With[{group = record["Group"]}, {
    Lookup[runningHelpers, group, 0],
    Lookup[lastDispatch, group, 0.],
    Lookup[record, "Date", 0.], record["File"]}];
  First[SortBy[underCeiling, score]]
];
KernelPoolResourceSelectHelper[___] := Missing["NoEligibleHelper"];

End[];
EndPackage[];
