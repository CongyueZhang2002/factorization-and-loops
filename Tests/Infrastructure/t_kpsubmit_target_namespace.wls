#!/usr/bin/env wolframscript
(* Live KernelPool regression for syntax-validation namespace neutrality.

   Get evaluates a file expression by expression.  The first expression
   below therefore runs before TestKit is loaded.  A prior held parse in the
   ordinary Global` context nevertheless interns the later bare FTAssert and
   FTReport names and makes this test fail before TestKit can mask the defect.
   Submit this test as a fresh_* mission with helper ceiling zero. *)

leakedBeforeTestKit =
  Join[System`Names["Global`FTAssert"],
    System`Names["Global`FTReport"]];
If[leakedBeforeTestKit =!= {},
  Print["KPSUBMIT TARGET NAMESPACE LEAK BEFORE TESTKIT: ",
    System`InputForm[leakedBeforeTestKit]];
  Exit[1]];

Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]], "TestKit.wl"}]];

FTAssert[
  "target syntax validation interns no TestKit names in Global`",
  System`Names["Global`FTAssert"] === {} &&
    System`Names["Global`FTReport"] === {}];
FTAssert[
  "target and wrapper syntax-validation contexts are removed",
  System`Names["KernelPoolTargetParse`*"] === {} &&
    System`Names["KernelPoolWrapperParse`*"] === {}];

FTReport[];
