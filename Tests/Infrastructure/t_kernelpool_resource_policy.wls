#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Scripts", "KernelPoolResourcePolicy.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

serverText = Import[FileNameJoin[{root, "Scripts", "KernelPool.wls"}],
  "Text"];
serverHeld = Quiet[ToExpression[serverText, InputForm, HoldComplete]];
FTTest`FTAssert["KernelPool server parses after scheduler integration",
  MatchQ[serverHeld, _HoldComplete]];

metadata = KernelPoolResourcePolicy`KernelPoolResourceMetadata[
  "(* FACET_RESOURCE group=CF300 role=family owner=fresh_sol_CF300 *)\n0"];
FTTest`FTAssert["resource metadata identifies one safe family marker",
  metadata === <|"Group" -> "CF300", "Role" -> "family",
    "Owner" -> "fresh_sol_CF300"|>];
FTTest`FTAssert["unmarked missions remain ungrouped",
  KernelPoolResourcePolicy`KernelPoolResourceMetadata["0"] ===
    <|"Group" -> None, "Role" -> "mission", "Owner" -> None|>];
FTTest`FTAssert["ambiguous duplicate markers fail closed to ungrouped",
  KernelPoolResourcePolicy`KernelPoolResourceMetadata[
    "(* FACET_RESOURCE group=A role=family owner=one *)\n" <>
    "(* FACET_RESOURCE group=B role=helper owner=two *)"] ===
      <|"Group" -> None, "Role" -> "mission", "Owner" -> None|>];

allocate[groups_, seats_, cores_, running_: <||>, offset_: 0] :=
  KernelPoolResourcePolicy`KernelPoolResourceAllocate[
    groups, seats, cores, running, offset];

one = allocate[{"A"}, 8, 16, <|"A" -> 1|>];
two = allocate[{"A", "B"}, 8, 16,
  <|"A" -> 1, "B" -> 1|>];
four = allocate[{"A", "B", "C", "D"}, 8, 16];
six = allocate[{"A", "B", "C", "D", "E", "F"}, 8, 16];

FTTest`FTAssert["one family receives all native cores with an eight-thread call cap",
  one["HelperCapacity"] === 7 &&
    one["Groups", "A", "HelperCeiling"] === 7 &&
    one["Groups", "A", "NativeCoreQuota"] === 16 &&
    one["Groups", "A", "NativeThreadsPerWorker"] === 8];
FTTest`FTAssert["adding a second family immediately splits both resources",
  two["HelperCapacity"] === 6 &&
    Lookup[Values[two["Groups"]], "HelperCeiling"] === {3, 3} &&
    Lookup[Values[two["Groups"]], "NativeCoreQuota"] === {8, 8}];
FTTest`FTAssert["four active families receive one helper and four native cores each",
  four["HelperCapacity"] === 4 &&
    Lookup[Values[four["Groups"]], "HelperCeiling"] ===
      ConstantArray[1, 4] &&
    Lookup[Values[four["Groups"]], "NativeCoreQuota"] === {4, 4, 4, 4}];
FTTest`FTAssert["six families share two helper seats without a zero entitlement",
  six["HelperCapacity"] === 2 &&
    Lookup[Values[six["Groups"]], "HelperCeiling"] ===
      ConstantArray[1, 6] &&
    Max[Lookup[Values[six["Groups"]], "NativeCoreQuota"]] -
      Min[Lookup[Values[six["Groups"]], "NativeCoreQuota"]] <= 1];
FTTest`FTAssert["native quotas never exceed the declared aggregate capacity",
  Total[Lookup[Values[six["Groups"]], "NativeCoreQuota"]] <= 16];

busy = allocate[{"A", "B"}, 8, 16,
  <|"A" -> 2, "B" -> 1|>];
FTTest`FTAssert["nested workers divide a family's native quota",
  busy["Groups", "A", "NativeThreadsPerWorker"] === 4 &&
    busy["Groups", "B", "NativeThreadsPerWorker"] === 8];
FTTest`FTAssert["removing a family restores the tail allocation",
  allocate[{"A"}, 8, 16, <|"A" -> 1|>]["Groups", "A"] ===
    one["Groups", "A"]];

records = {
  <|"File" -> "a.wl", "Group" -> "A", "Date" -> 1.|>,
  <|"File" -> "b.wl", "Group" -> "B", "Date" -> 2.|>,
  <|"File" -> "c.wl", "Group" -> "C", "Date" -> 3.|>};
fairAllocation = allocate[{"A", "B", "C"}, 5, 8,
  <|"A" -> 2, "B" -> 1, "C" -> 1|>];
selected = KernelPoolResourcePolicy`KernelPoolResourceSelectHelper[
  records, <|"A" -> 1, "B" -> 0, "C" -> 0|>, fairAllocation,
  <|"A" -> 1., "B" -> 10., "C" -> 5.|>];
FTTest`FTAssert["fair dispatch gives a helper to every family before a second",
  selected["Group"] === "C"];
selected2 = KernelPoolResourcePolicy`KernelPoolResourceSelectHelper[
  DeleteCases[records, selected],
  <|"A" -> 1, "B" -> 0, "C" -> 1|>, fairAllocation,
  <|"A" -> 1., "B" -> 10., "C" -> 20.|>];
FTTest`FTAssert["least-recently-served breaks equal-load ties",
  selected2["Group"] === "B"];
borrowed = KernelPoolResourcePolicy`KernelPoolResourceSelectHelper[
  {First[records]}, <|"A" -> 1|>, fairAllocation, <||>];
FTTest`FTAssert["unused peer entitlement is work-conservingly borrowed",
  borrowed["Group"] === "A"];
orphaned = KernelPoolResourcePolicy`KernelPoolResourceSelectHelper[
  {<|"File" -> "gone.wl", "Group" -> "FinishedFamily",
      "Date" -> 4.|>}, <||>, fairAllocation, <||>];
FTTest`FTAssert["a helper whose family has left is never dispatched",
  MatchQ[orphaned, _Missing]];

shrunkCores = allocate[{"A", "B"}, 8, 6,
  <|"A" -> 1, "B" -> 1|>];
grownCores = allocate[{"A", "B"}, 8, 14,
  <|"A" -> 1, "B" -> 1|>];
FTTest`FTAssert["live core capacity shrinks and grows independently of seats",
  Lookup[Values[shrunkCores["Groups"]], "NativeCoreQuota"] === {3, 3} &&
    Lookup[Values[grownCores["Groups"]], "NativeCoreQuota"] === {7, 7}];

FTTest`FTReport[];
