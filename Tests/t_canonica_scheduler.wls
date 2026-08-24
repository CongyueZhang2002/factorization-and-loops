$HistoryLength = 0;
root = ParentDirectory[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

testX = Symbol["FeynFacetCANONICASchedulerTest`x"];
testY = Symbol["FeynFacetCANONICASchedulerTest`y"];
testEpsilon = Symbol["FeynFacetCANONICASchedulerTest`eps"];

(* The exact rational gauge D = 1/x has numerator degree zero. *)
strip = {
  {{{0}}, {{0}}},
  {{{0}}, {{-1/testY}}},
  {{{-1/testX^2}}, {{-testEpsilon/(testX*testY)}}}
};
alphabet = FeynFacet`Private`epsFormStripAlphabet[
  strip, {testX, testY}, testEpsilon];
(* a KernelPool subkernel cannot launch its own subkernels
   (LaunchKernels::subnopar); the scheduler's serial path is the same
   code with kernel count 1, so the test degrades instead of failing
   when it runs inside a pool (was a documented standalone-only red,
   2026-08-23) *)
schedulerKernels = If[$KernelID =!= 0, 1, 2];
result = FeynFacet`Private`epsFormStripRunCanonica[
  strip, {testX, testY}, testEpsilon, alphabet,
  {0, 1}, 1, 20, schedulerKernels];

checks = <|
  "Association" -> AssociationQ[result],
  "ExactCandidate" -> AssociationQ[result] &&
    Length[result["Candidates"]] >= 1 &&
    AllTrue[result["Candidates"],
      TrueQ[FeynFacet`Private`epsFormStripExactDLogQ[
        #["Gauge"], strip, {testX, testY}, testEpsilon,
        alphabet]] &],
  "MinimalDegree" -> AssociationQ[result] &&
    Min[Lookup[result["Candidates"],
      "NumeratorDegree", Infinity]] === 0
|>;

Print[InputForm[checks]];
Exit[If[AllTrue[Values[checks], TrueQ], 0, 1]];
