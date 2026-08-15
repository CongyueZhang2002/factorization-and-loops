(* Cut and propagator definitions for the families involved in the
   PID 1 / 6 / 7 realization transfers.  Extracted verbatim from
   Kira integralfamilies.yaml by Scripts/extract_families.py so that
   the transfer test does not depend on a gitignored workspace.
   Momenta are recorded as coefficient associations over the basis
   {ka, kb, kc, ke, kf}. *)
<|
  "CF1" -> <|
    "LoopMomenta" -> {ke, kf},
    "CutPropagators" -> {1, 2, 5},
    "Propagators" -> {
      <|"Type" -> "Square", "Momentum" -> <|"kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "kc" -> 1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "kb" -> -1, "kc" -> 1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kb" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"ka" -> 1|>, <|"ke" -> 1|>}, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"ka" -> 1|>, <|"kf" -> 1|>}, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"kb" -> 1|>, <|"ke" -> 1|>}, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"kc" -> 1|>, <|"ke" -> 1|>}, "Mass" -> 0|>}|>,
  "CF124" -> <|
    "LoopMomenta" -> {ke, kf},
    "CutPropagators" -> {1, 2, 7},
    "Propagators" -> {
      <|"Type" -> "Square", "Momentum" -> <|"kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "kb" -> -1, "kc" -> 1, "ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kb" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"ka" -> 1|>, <|"ke" -> 1|>}, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"kb" -> 1|>, <|"ke" -> 1|>}, "Mass" -> 0|>}|>,
  "CF300" -> <|
    "LoopMomenta" -> {ke, kf},
    "CutPropagators" -> {1, 2, 8},
    "Propagators" -> {
      <|"Type" -> "Square", "Momentum" -> <|"kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kb" -> -1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kb" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"kc" -> 1|>, <|"kf" -> 1|>}, "Mass" -> 0|>}|>,
  "CF299" -> <|
    "LoopMomenta" -> {ke, kf},
    "CutPropagators" -> {1, 2, 8},
    "Propagators" -> {
      <|"Type" -> "Square", "Momentum" -> <|"kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kb" -> -1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kb" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"kc" -> 1|>, <|"kf" -> 1|>}, "Mass" -> 0|>}|>,
  "CF21" -> <|
    "LoopMomenta" -> {ke, kf},
    "CutPropagators" -> {1, 2, 8},
    "Propagators" -> {
      <|"Type" -> "Square", "Momentum" -> <|"kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "kc" -> 1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "kb" -> -1, "kc" -> 1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kb" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"kc" -> 1|>, <|"ke" -> 1|>}, "Mass" -> 0|>}|>,
  "CF226" -> <|
    "LoopMomenta" -> {ke, kf},
    "CutPropagators" -> {1, 2, 7},
    "Propagators" -> {
      <|"Type" -> "Square", "Momentum" -> <|"kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kb" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"kb" -> 1|>, <|"ke" -> 1|>}, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"kc" -> 1|>, <|"kf" -> 1|>}, "Mass" -> 0|>}|>,
  "CF23" -> <|
    "LoopMomenta" -> {ke, kf},
    "CutPropagators" -> {1, 2, 8},
    "Propagators" -> {
      <|"Type" -> "Square", "Momentum" -> <|"kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "kc" -> 1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "kb" -> -1, "kc" -> 1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kb" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"ka" -> 1|>, <|"ke" -> 1|>}, "Mass" -> 0|>}|>,
  "CF248" -> <|
    "LoopMomenta" -> {ke, kf},
    "CutPropagators" -> {1, 2, 8},
    "Propagators" -> {
      <|"Type" -> "Square", "Momentum" -> <|"kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "ke" -> 1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kb" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"kb" -> 1|>, <|"ke" -> 1|>}, "Mass" -> 0|>}|>,
  "CF253" -> <|
    "LoopMomenta" -> {ke, kf},
    "CutPropagators" -> {1, 2, 8},
    "Propagators" -> {
      <|"Type" -> "Square", "Momentum" -> <|"kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "ke" -> 1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kb" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"kb" -> 1|>, <|"ke" -> 1|>}, "Mass" -> 0|>}|>,
  "CF53" -> <|
    "LoopMomenta" -> {ke, kf},
    "CutPropagators" -> {1, 2, 8},
    "Propagators" -> {
      <|"Type" -> "Square", "Momentum" -> <|"kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kb" -> -1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kb" -> -1, "ke" -> 1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kb" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"ka" -> 1|>, <|"ke" -> 1|>}, "Mass" -> 0|>}|>,
  "CF57" -> <|
    "LoopMomenta" -> {ke, kf},
    "CutPropagators" -> {1, 2, 8},
    "Propagators" -> {
      <|"Type" -> "Square", "Momentum" -> <|"kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kb" -> -1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kb" -> -1, "ke" -> 1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kb" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"ka" -> 1|>, <|"ke" -> 1|>}, "Mass" -> 0|>}|>,
  "CF91" -> <|
    "LoopMomenta" -> {ke, kf},
    "CutPropagators" -> {1, 2, 8},
    "Propagators" -> {
      <|"Type" -> "Square", "Momentum" -> <|"kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kb" -> -1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "kc" -> 1, "ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kb" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"kc" -> 1|>, <|"kf" -> 1|>}, "Mass" -> 0|>}|>,
  "CF97" -> <|
    "LoopMomenta" -> {ke, kf},
    "CutPropagators" -> {1, 2, 8},
    "Propagators" -> {
      <|"Type" -> "Square", "Momentum" -> <|"kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ke" -> 1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kb" -> -1, "kf" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> -1, "kc" -> 1, "ke" -> 1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Square", "Momentum" -> <|"ka" -> 1, "kb" -> 1, "kc" -> -1, "ke" -> -1, "kf" -> -1|>, "Mass" -> 0|>,
      <|"Type" -> "Bilinear", "Momenta" -> {<|"ka" -> 1|>, <|"ke" -> 1|>}, "Mass" -> 0|>}|>
|>
