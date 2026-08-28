capture = Import["/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_p31_affine9_capture.wxf"];
p = capture["Prime"];
imgs = capture["Images"];
eps = #["EpsilonMod"] & /@ imgs;
canon = #["CanonicalValues"] & /@ imgs;
n = Length[canon[[1]]];
normCols = capture["NormalizationColumns"];
Print["prime ", p, "  images ", Length[imgs], "  coords ", n, "  eps ", eps];
presc = canon[[All, normCols]];
Print["prescription identical across images: ", Length[DeleteDuplicates[presc]] === 1];
Print["image-1 prescription (first 8): ", presc[[1, ;; 8]]];
powers = Table[PowerMod[eps[[i]], k, p], {i, 9}, {k, 0, 8}];
fitQ[vals_] := Module[{ok = False, t, pn, qd, m, ns, dvals, j},
  Do[
    Do[qd = t - pn;
      m = Table[Join[powers[[i, 1 ;; pn + 1]],
          Mod[-vals[[i]]*powers[[i, 1 ;; qd + 1]], p]], {i, 9}];
      ns = NullSpace[m, Modulus -> p];
      If[ns =!= {},
        Do[dvals = Table[Mod[ns[[j, pn + 2 ;;]] . powers[[i, 1 ;; qd + 1]], p], {i, 9}];
          If[FreeQ[dvals, 0], ok = True; Break[]], {j, Length[ns]}]];
      If[ok, Break[]], {pn, 0, t}];
    If[ok, Break[]], {t, 0, 7}];
  ok];
failing = Reap[Do[If[! fitQ[canon[[All, c]]], Sow[c]], {c, n}]][[2]];
failing = If[failing === {}, {}, failing[[1]]];
Print["no rational fit at total degree <= 7: ", Length[failing], " coordinates"];
blockOf[c_] := If[c <= 2048, Ceiling[c/256], 9];
tally = Sort[Tally[blockOf /@ failing]];
Print["failing per block (1-8 = gauge grade blocks of 256; 9 = residue tail 212): ", tally];
If[Length[failing] > 0,
  Module[{blk, blkAll, cands, pats, works, cnt},
    blk = First[MaximalBy[tally, Last]][[1]];
    blkAll = Select[failing, blockOf[#] === blk &];
    cands = blkAll[[;; Min[3, Length[blkAll]]]];
    Print["sign search in block ", blk, " on ", cands];
    pats = Tuples[{1, p - 1}, 8];
    works = Select[pats, Function[s,
       AllTrue[cands, fitQ[Mod[canon[[All, #]]*Prepend[s, 1], p]] &]]];
    Print["patterns repairing all three: ", Length[works]];
    If[Length[works] > 0,
      Print["pattern (img2..9; 1=+, ", p - 1, "=-): ", works[[1]]];
      cnt = Count[blkAll, c_ /; fitQ[Mod[canon[[All, c]]*Prepend[works[[1]], 1], p]]];
      Print["that one pattern repairs ", cnt, " of ", Length[blkAll],
        " failing coordinates in block ", blk]]]];
Print["DONE"];
