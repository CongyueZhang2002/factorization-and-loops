(* This file is a static/no-kernel adversarial fixture.  It models state that
   can remain in Global` after unrelated persistent-kernel missions. *)

Global`checkpointFile =
  "/tmp/FeynFacet-solver-configuration-test-poison/checkpoint.wl";
Global`arguments = "poisoned-arguments";
Global`files = <|"Poison" -> True|>;
Global`target = "poisoned-target";
Global`results = "poisoned-results";
Global`x = "poisoned-x";
Global`y = "poisoned-y";
Global`eps = "poisoned-eps";
Global`image = "poisoned-image";
Global`prior = "poisoned-prior";
Global`fullRank = "poisoned-full-rank";

Global`hashes[] := <|"Poison" -> "hash"|>;
Global`stableInputsQ[] := False;
Global`fingerprint[_] := "poisoned-fingerprint";
Global`artifactRead[_] := $Failed;
Global`loadSource[_] := $Failed;
Global`makeNonce[___] := {0, 0};
Global`modRational[___] := $Failed;
Global`buildTarget[___] := $Failed;
Global`containmentProjection[___] := $Failed;
Global`nativeRank[___] := $Failed;
Global`rankImage[___] := $Failed;
Global`readCheckpoint[___] := $Failed;
Global`writeCheckpoint[___] := $Failed;

SetAttributes[Global`stableInputsQ, Protected];
SetAttributes[Global`fingerprint, {Protected, Locked}];
SetAttributes[Global`nativeRank, Protected];
SetAttributes[Global`writeCheckpoint, Protected];
SetAttributes[Global`x, Protected];
SetAttributes[Global`y, Listable];
