#!/usr/bin/env wolframscript
(* Adversarial coverage for the shared exact-rational-image diagonal-span
   solve.  A successful batch must agree with exact symbolic identities; a
   mixed batch must decline the fast route so the caller can preserve the
   individual scalar verdicts. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{affineBatch, spansSampled, spanSampled, spanExact, spanBounded} =
  mq /@ {"multiquadraticOffDiagonalBlockRationalAffineParticularBatch",
    "multiquadraticOffDiagonalBlockDiagonalSpansSampled",
    "multiquadraticOffDiagonalBlockDiagonalSpanSampled",
    "multiquadraticOffDiagonalBlockDiagonalSpan",
    "multiquadraticOffDiagonalBlockDiagonalSpanBoundedExact"};
samplePoints = mq["$multiquadraticOffDiagonalBlockDiagonalSpanSamplePoints"];

Clear[x, y];

(* The low-level shared reduction uses one coefficient matrix and two right
   sides.  Both exact sections are known in advance. *)
matrix = {{1, 0}, {0, 1}, {1, 1}};
rightMatrix = {{2, -1}, {3, 4}, {5, 3}};
affine = affineBatch[matrix, rightMatrix];
FTAssert["B1 the shared affine reduction returns both exact sections",
  AssociationQ[affine] && TrueQ[affine["Consistent"]] &&
    affine["ParticularSolutions"] === {{2, 3}, {-1, 4}}];

inconsistent = affineBatch[matrix, ReplacePart[rightMatrix, {3, 2} -> 99]];
FTAssert["B2 one inconsistent right side refuses the whole shared reduction",
  AssociationQ[inconsistent] && ! TrueQ[inconsistent["Consistent"]]];

(* Rank zero is still the one-grade instance of the same algorithm.  These
   rational one-forms have a three-dimensional constant span. *)
basis = {{1/x, 0}, {0, 1/y},
  {1/(1 - x - y), 1/(1 - x - y)}};
targets = {2 basis[[1]] - 3 basis[[2]] + 5 basis[[3]],
  -basis[[1]] + basis[[2]]};
batch = spansSampled[targets, basis, {}, {x, y}];
FTAssert["B3 a fully spanned batch is certified at held-out exact images",
  MatchQ[batch, {__Association}] && Length[batch] === Length[targets] &&
    AllTrue[batch, TrueQ[Lookup[#, "Spanned", False]] &&
      Lookup[#, "HeldOutPoints", 0] >= 6 &]];
FTAssert["B4 every returned coefficient vector satisfies both components exactly",
  And @@ MapThread[Function[{target, answer},
    And @@ (TrueQ[Together[#] === 0] & /@
      (target - answer["Coefficients"] . basis))], {targets, batch}]];

(* A polynomial target can match a finite construction prefix but is not a
   constant combination of this basis.  Mixing it with a good target must make
   the batch return Missing; scalar fallback then keeps the good and bad
   verdicts separate. *)
outside = {x, 0};
mixed = spansSampled[{First[targets], outside}, basis, {}, {x, y}];
goodScalar = spanSampled[First[targets], basis, {}, {x, y}];
badScalar = spanSampled[outside, basis, {}, {x, y}];
badExact = spanExact[outside, basis, {x, y}];
FTAssert["B5 a mixed spanned/non-spanned batch declines the fast route",
  MissingQ[mixed]];
FTAssert["B6 scalar fallback preserves the good target's positive verdict",
  AssociationQ[goodScalar] && TrueQ[goodScalar["Spanned"]]];
FTAssert["B7 scalar fallback preserves the outside target's negative verdict",
  ! (AssociationQ[badScalar] && TrueQ[Lookup[badScalar, "Spanned", False]]) &&
    MissingQ[badExact]];

(* The original 24-point table can be exhausted by exceptional images.  Make
   every one of those points a pole and require the extended deterministic
   tail to provide the construction plus six held-out images. *)
firstPointAbscissae = DeleteDuplicates[First /@ Take[samplePoints, 24]];
vanisher = Times @@ ((x - #) & /@ firstPointAbscissae);
lateBasis = {{1/vanisher, 0}};
late = spanSampled[3 First[lateBasis], lateBasis, {}, {x, y}];
FTAssert["B8 the extended point tail certifies after the original table is exceptional",
  AssociationQ[late] && TrueQ[late["Spanned"]] &&
    late["Coefficients"] === {3} && late["HeldOutPoints"] >= 6];

(* SolveAlways is an optional compression aid, not a correctness gate.  A
   large inconclusive basis must be retained rather than sent into an
   unbounded symbolic quantifier expansion. *)
largeBasis = Table[{x^(degree - 1), 0}, {degree, 9}];
largeVerdict = spanBounded[{x^9, 0}, largeBasis, {x, y}];
smallVerdict = spanBounded[2 basis[[1]] - basis[[2]],
  basis[[1 ;; 2]], {x, y}];
FTAssert["B9 large exact fallback is skipped with a typed conservative verdict",
  MatchQ[largeVerdict, Missing["ExactSpanSkippedLargeBasis"]]];
FTAssert["B10 small exact fallback remains available",
  AssociationQ[smallVerdict] && TrueQ[smallVerdict["Spanned"]] &&
    smallVerdict["Coefficients"] === {2, -1}];

FTReport[];
