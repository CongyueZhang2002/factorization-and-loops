(* Signature canonicalization modulo the trace-variable field.

   Trace classes are equal modulo the multiplicative group of the
   rational function field of the trace variables: the rational factor
   of a signature folds into the coefficient (Codex convention,
   2026-08-11).  Measured defect this removes: master 107 fragmented
   into 9 buckets differing only by 2^k, master 1 into 13 buckets of a
   single rational class.

   Acceptance criteria (exactness first, then bucket identity):
   A. 2^(2 eps - 4): fold 1/16, canonical 2^(2 eps).
   B. 4^eps lands in the SAME canonical class as 2^(2 eps), fold 1.
   C. 2^(3/2 + eps): fold 2, the half-integer root stays canonical.
   D. Scale and coupling monomials are never folded and keep their
      structural Exponent reading.
   E. A signature entirely rational in trace variables folds to class 1.
   F. Symbolic rational-function factors fold; integer parts of their
      exponents split off exactly.
   G. Prime accumulation: same-prime and composite-base inputs merge,
      opposite-exponent pairs collapse to pure rationals.
   H. Non-rational constants (Pi, I) are untouched.
   I. Every fold is exact: fold x canonical == original signature. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

canonicalize = FeynFacet`Private`finiteFieldCanonicalizeSignature;

eps = FeynCalc`Epsilon;
excluded = {Global`qTest, FeynFacet`\[Alpha]s};

exactSame[left_, right_] :=
  TrueQ @ FeynFacet`Private`exactZeroQ[left - right];

(* I. helper: the split must be an exact factorization of the input *)
splitExact[held_HoldComplete] := Module[{split},
  split = canonicalize[held, excluded];
  exactSame[Last[split] ReleaseHold[First[split]], ReleaseHold[held]]
];

(* A *)
splitA = canonicalize[HoldComplete @@ {2^(2 eps - 4)}, excluded];
FTTest`FTAssert["A1. 2^(2 eps - 4) folds 1/16",
  Last[splitA] === 1/16];
FTTest`FTAssert["A2. canonical residue is 2^(2 eps)",
  First[splitA] === HoldComplete @@ {2^(2 eps)}];

(* B *)
splitB = canonicalize[HoldComplete @@ {4^eps}, excluded];
FTTest`FTAssert["B1. 4^eps folds nothing",
  Last[splitB] === 1];
FTTest`FTAssert["B2. 4^eps and 2^(2 eps - 4) share one canonical class",
  First[splitB] === First[splitA]];

(* C *)
splitC = canonicalize[HoldComplete @@ {2^(3/2 + eps)}, excluded];
FTTest`FTAssert["C1. 2^(3/2 + eps) folds the integer part 2",
  Last[splitC] === 2];
FTTest`FTAssert["C2. the half-integer root stays in the signature",
  First[splitC] === HoldComplete @@ {2^(1/2 + eps)}];

(* D *)
splitD = canonicalize[
  HoldComplete @@ {Global`qTest^4 FeynFacet`\[Alpha]s^2 2^(eps - 3)},
  excluded
];
FTTest`FTAssert["D1. the monomial variables are not folded",
  Last[splitD] === 1/8];
FTTest`FTAssert["D2. the scale power still reads off structurally",
  Exponent[ReleaseHold[First[splitD]], Global`qTest] === 4 &&
    Exponent[ReleaseHold[First[splitD]], FeynFacet`\[Alpha]s] === 2];

(* E *)
splitE = canonicalize[
  HoldComplete @@ {(1 - 2 eps)^3/(3 - 2 eps)},
  excluded
];
FTTest`FTAssert["E1. a trace-rational signature folds entirely",
  First[splitE] === HoldComplete[1] &&
    exactSame[Last[splitE], (1 - 2 eps)^3/(3 - 2 eps)]];

(* F *)
splitF = canonicalize[
  HoldComplete @@ {(1 - Global`xTest)^(3/2 - eps)},
  excluded
];
FTTest`FTAssert["F1. an integer power of a rational-function base splits",
  exactSame[Last[splitF], 1 - Global`xTest] &&
    First[splitF] === HoldComplete @@ {(1 - Global`xTest)^(1/2 - eps)}];

(* G *)
splitG1 = canonicalize[HoldComplete @@ {6^(1 + eps)}, excluded];
splitG2 = canonicalize[HoldComplete @@ {2^eps 3^eps 6}, excluded];
FTTest`FTAssert["G1. composite bases decompose over primes: fold 6",
  Last[splitG1] === 6 && Last[splitG2] === 6];
FTTest`FTAssert["G2. 6^(1+eps) and 6 2^eps 3^eps share one class",
  First[splitG1] === First[splitG2]];
splitG3 = canonicalize[HoldComplete @@ {2^(1 - eps) 2^eps}, excluded];
FTTest`FTAssert["G3. opposite exponents collapse to the rational 2",
  First[splitG3] === HoldComplete[1] && Last[splitG3] === 2];

(* H *)
splitH = canonicalize[HoldComplete @@ {Pi^eps 2^(eps - 1)}, excluded];
FTTest`FTAssert["H1. Pi^eps is untouched, the rational part still folds",
  Last[splitH] === 1/2 &&
    ! FreeQ[ReleaseHold[First[splitH]], Pi] &&
    exactSame[
      Last[splitH] ReleaseHold[First[splitH]],
      Pi^eps 2^(eps - 1)
    ]];

(* I *)
FTTest`FTAssert["I1. every split above is an exact factorization",
  AllTrue[
    {
      HoldComplete @@ {2^(2 eps - 4)},
      HoldComplete @@ {4^eps},
      HoldComplete @@ {2^(3/2 + eps)},
      HoldComplete @@ {Global`qTest^4 FeynFacet`\[Alpha]s^2 2^(eps - 3)},
      HoldComplete @@ {(1 - 2 eps)^3/(3 - 2 eps)},
      HoldComplete @@ {(1 - Global`xTest)^(3/2 - eps)},
      HoldComplete @@ {6^(1 + eps)},
      HoldComplete @@ {Sqrt[2] 3^(2 eps - 2) Pi^eps}
    },
    splitExact
  ]];

FTTest`FTReport[];
