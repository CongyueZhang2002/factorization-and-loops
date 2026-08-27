(* Proposed managed-kernel regression. This audit did not execute it. *)

ClearAll[fail];
fail[status_String, data_: <||>] := (
  Print[InputForm[Join[<|"Status" -> status|>, data]]];
  Exit[1]);

If[Length[$ScriptCommandLine] =!= 2,
  fail["Usage", <|"Expected" -> "wolframscript -file <this-file> ADAPTER"|>]];

adapter = ExpandFileName[$ScriptCommandLine[[2]]];
If[! FileExistsQ[adapter], fail["AdapterMissing", <|"Adapter" -> adapter|>]];
Get[adapter];

prime = 10007;
size = 1028;
automaticIdentity = IdentityMatrix[size];
denseIdentity = Normal[automaticIdentity];
corruptInverse = ReplacePart[denseIdentity, {1, 1} -> 2];
corruptMatrix = ReplacePart[denseIdentity, {size, size} -> 2];

checks = <|
  "AutomaticIdentityIsNotOrdinaryList" -> (Head[automaticIdentity] =!= List),
  "NormalMaterializesOrdinaryList" -> (Head[denseIdentity] === List),
  "RawSameQExposesRepresentationDifference" ->
    (denseIdentity =!= automaticIdentity),
  "GoodDenseInverseAccepted" -> TrueQ[
    CodexFLINTAffineRREFAdapter`Private`cffrInverseWitnessQ[
      denseIdentity, denseIdentity, size, prime]],
  "CorruptInverseRejected" -> ! TrueQ[
    CodexFLINTAffineRREFAdapter`Private`cffrInverseWitnessQ[
      denseIdentity, corruptInverse, size, prime]],
  "CorruptMatrixRejected" -> ! TrueQ[
    CodexFLINTAffineRREFAdapter`Private`cffrInverseWitnessQ[
      corruptMatrix, denseIdentity, size, prime]]|>;

result = <|
  "Status" -> If[And @@ Values[checks],
    "LargeIdentityRepresentationRegressionPassed",
    "LargeIdentityRepresentationRegressionFailed"],
  "Size" -> size,
  "Prime" -> prime,
  "AutomaticIdentityHead" -> ToString[Head[automaticIdentity], InputForm],
  "Checks" -> checks|>;
Print[InputForm[result]];
Exit[If[result["Status"] === "LargeIdentityRepresentationRegressionPassed", 0, 1]];
