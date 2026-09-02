
(* ==== moved from Private/CanonicalBlocks.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: no reference anywhere (reachability.py 2026-09-02)
   Symbols: canonicalBlocksOrbitAct
   This file is never loaded by FeynFacet.m. *)


(* The group element (swap, q) acting on a raw block: relabel the
   variables if asked, then conjugate the basis.  Row i of the result is
   row q[[i]] of the source. *)
canonicalBlocksOrbitAct[{av_, aw_}, swapQ_, permutation_, variables_] :=
  Module[{pair},
    pair = If[TrueQ[swapQ],
      canonicalBlocksSwapPair[{av, aw}, variables],
      {av, aw}];
    {pair[[1]][[permutation, permutation]],
      pair[[2]][[permutation, permutation]]}
  ];
