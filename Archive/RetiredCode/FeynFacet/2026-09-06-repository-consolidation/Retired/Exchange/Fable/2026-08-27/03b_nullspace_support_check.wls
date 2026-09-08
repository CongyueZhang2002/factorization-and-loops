capture = Import["/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_p31_affine9_capture.wxf"];
imgs = capture["Images"];
ns1 = imgs[[1]]["NullspaceBasis"];  (* 52 x 2260 *)
supp = Union @@ (Flatten[Position[#, x_ /; x =!= 0]] & /@ ns1);
Print["nullspace support size (image 1): ", Length[supp]];
suppAll = Union @@ Table[Union @@ (Flatten[Position[#, x_ /; x =!= 0]] & /@
      imgs[[i]]["NullspaceBasis"]), {i, 9}];
Print["union over all 9 images: ", Length[suppAll]];
normCols = capture["NormalizationColumns"];
free = Complement[suppAll, normCols];
Print["support minus the 52 pinned columns: ", Length[free]];
Print["per block (1-8 gauge 256s, 9 residue): ",
  Sort[Tally[If[# <= 2048, Ceiling[#/256], 9] & /@ free]]];
