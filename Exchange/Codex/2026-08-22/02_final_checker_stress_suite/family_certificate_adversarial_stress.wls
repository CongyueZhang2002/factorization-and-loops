(* Targeted adversarial stress tests for the modular whole-family certificate.
   This is an external diagnostic only; it does not modify FeynFacet. *)

root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0;
fail = 0;
check[label_, condition_] := If[
  TrueQ[condition],
  pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]
];

status[c_] := Lookup[c, "Status", Missing["Status"]];
checks[c_] := Lookup[c, "Checks", <||>];
certificate[c_] := Lookup[c, "EpsilonFormCertificate", <||>];
modular[c_] := Lookup[certificate[c], "Modular", <||>];
dlog[c_] := Lookup[certificate[c], "DLog", <||>];

record1[name_, bx_, by_] := <|
  "Family" -> name,
  "Variables" -> {x, y},
  "Regulator" -> eps,
  "Chart" -> None,
  "TTotal" -> IdentityMatrix[1],
  "TTotalInverse" -> IdentityMatrix[1],
  "Blocks" -> {{{1}, 1}},
  "Ranges" -> {{1}},
  "EpsFormX" -> bx,
  "EpsFormY" -> by
|>;

record2[name_, bx_, by_] := <|
  "Family" -> name,
  "Variables" -> {x, y},
  "Regulator" -> eps,
  "Chart" -> None,
  "TTotal" -> IdentityMatrix[2],
  "TTotalInverse" -> IdentityMatrix[2],
  "Blocks" -> {{{1}, 1}, {{2}, 2}},
  "Ranges" -> {{1}, {2}},
  "EpsFormX" -> bx,
  "EpsFormY" -> by
|>;

certify[r_, method_: "Modular", primes_: 3, points_: 12] :=
  FeynFacet`CertifyFamilyEpsilonForm[
    r,
    <|"Av" -> r["EpsFormX"], "Aw" -> r["EpsFormY"]|>,
    "SourceVariables" -> {x, y},
    "Chart" -> None,
    "IdentityMethod" -> method,
    "ModularPrimes" -> primes,
    "ModularPoints" -> points
  ];

(* Install a deterministic RandomPrime only inside the dynamic scope of expr.
   This lets the stress test exercise bad-characteristic and repeated-prime
   behavior reproducibly without changing package code. *)
SetAttributes[withForcedPrimes, HoldRest];
withForcedPrimes[primeList_List, expr_] := Module[{primeIndex = 0},
  Internal`InheritedBlock[{RandomPrime},
    Unprotect[RandomPrime];
    ClearAll[RandomPrime];
    RandomPrime[_] := primeList[[Min[++primeIndex, Length[primeList]]]];
    Protect[RandomPrime];
    expr
  ]
];

Clear[x, y, eps];
primeList = NestList[NextPrime, NextPrime[2^23], 2];
p = First[primeList];
Print["forced primes: ", primeList, "; all prime = ", And @@ (PrimeQ /@ primeList)];
check["forced primes lie in checker interval",
  And @@ (2^23 <= # <= 2^24 & /@ primeList)];

(* 1. Zero form is the only valid dlog form with an empty alphabet. *)
zeroRecord = record1["SYN_EMPTY_ZERO", {{0}}, {{0}}];
zeroModular = certify[zeroRecord];
zeroSymbolic = certify[zeroRecord, "Symbolic"];
Print["zero empty alphabet: modular=", status[zeroModular],
  ", symbolic=", status[zeroSymbolic]];
check["zero empty-alphabet form passes both methods",
  status[zeroModular] === "ExactEpsilonForm" &&
  status[zeroSymbolic] === "ExactEpsilonForm"];

(* 2. A nonzero polynomial one-form has no denominator letters and cannot be
      a rational dlog form.  The modular checker currently leaves DLog=True. *)
polyRecord = record1["SYN_EMPTY_NONZERO", {{eps}}, {{0}}];
polyModular = certify[polyRecord];
polySymbolic = certify[polyRecord, "Symbolic"];
Print["nonzero empty alphabet: modular=", status[polyModular],
  ", symbolic=", status[polySymbolic],
  ", modular checks=", checks[polyModular],
  ", modular dlog=", dlog[polyModular]];
check["EXPOSE empty-alphabet bypass (modular accepts, symbolic rejects)",
  status[polyModular] === "ExactEpsilonForm" &&
  status[polySymbolic] =!= "ExactEpsilonForm" &&
  Lookup[checks[polyModular], "DLog", False] === True &&
  Lookup[dlog[polyModular], "Letters", Missing[]] === {}];

(* 3a. A rational entry presented as an uncombined sum has raw denominator 1.
       The evaluator compiles it through Together, but familyCertLetters only
       inspects Together when the raw denominator is non-polynomial.  Thus the
       x letter is missed and the empty-alphabet bypass is reached. *)
mixedRawRecord = record1["SYN_DLOG_PLUS_POLY_RAW", {{eps (1/x + 1)}}, {{0}}];
mixedRawModular = certify[mixedRawRecord];
mixedRawSymbolic = certify[mixedRawRecord, "Symbolic"];
Print["raw-sum dlog + polynomial: modular=", status[mixedRawModular],
  ", symbolic=", status[mixedRawSymbolic],
  ", letters=", Lookup[dlog[mixedRawModular], "Letters", Missing[]],
  ", modular checks=", checks[mixedRawModular]];
check["EXPOSE raw-sum denominator letter is missed",
  status[mixedRawModular] === "ExactEpsilonForm" &&
  status[mixedRawSymbolic] =!= "ExactEpsilonForm" &&
  Lookup[dlog[mixedRawModular], "Letters", Missing[]] === {}];

(* 3b. With exactly the same expression explicitly combined, x is found and
       the polynomial contamination is caught by the residue solve. *)
mixedTogetherRecord = record1[
  "SYN_DLOG_PLUS_POLY_TOGETHER",
  {{Together[eps (1/x + 1)]}},
  {{0}}
];
mixedTogetherModular = certify[mixedTogetherRecord];
mixedTogetherSymbolic = certify[mixedTogetherRecord, "Symbolic"];
Print["Together dlog + polynomial: modular=", status[mixedTogetherModular],
  ", symbolic=", status[mixedTogetherSymbolic],
  ", letters=", Lookup[dlog[mixedTogetherModular], "Letters", Missing[]],
  ", modular checks=", checks[mixedTogetherModular]];
check["nonempty-alphabet polynomial contamination is rejected",
  status[mixedTogetherModular] =!= "ExactEpsilonForm" &&
  status[mixedTogetherSymbolic] =!= "ExactEpsilonForm" &&
  Lookup[checks[mixedTogetherModular], "DLog", True] === False];

(* 4. Nonlinear regulator dependence must be caught. *)
nonlinearRecord = record1[
  "SYN_EPS_NONLINEAR",
  {{eps/x + eps^2/(x + 1)}},
  {{0}}
];
nonlinearModular = certify[nonlinearRecord];
Print["nonlinear eps: ", status[nonlinearModular],
  "; checks=", checks[nonlinearModular]];
check["nonlinear regulator dependence is rejected",
  status[nonlinearModular] =!= "ExactEpsilonForm" &&
  Lookup[checks[nonlinearModular], "EpsFactored", True] === False];

(* 5. Two distinct characteristic-zero letters collide modulo p:
      L1=x and L2=x+p y.  The exact form is valid, but the modular dlog
      design matrix has rank 1 for 2 letters.  Rank is recorded, not gated. *)
collisionBx = eps DiagonalMatrix[{1/x, 1/(x + p y)}];
collisionBy = eps DiagonalMatrix[{0, p/(x + p y)}];
collisionRecord = record2["SYN_RANK_COLLISION", collisionBx, collisionBy];
collisionModular = withForcedPrimes[{p}, certify[collisionRecord, "Modular", 1, 6]];
collisionSymbolic = certify[collisionRecord, "Symbolic"];
collisionPointData = Lookup[modular[collisionModular], "PointsDone", {}];
Print["rank collision: modular=", status[collisionModular],
  ", symbolic=", status[collisionSymbolic],
  ", point data=", collisionPointData];
check["EXPOSE rank deficiency is accepted",
  status[collisionModular] === "ExactEpsilonForm" &&
  status[collisionSymbolic] === "ExactEpsilonForm" &&
  Length[collisionPointData] === 1 &&
  collisionPointData[[1, "DlogRank"]] < collisionPointData[[1, "Letters"]]];

(* 6. The checker samples primes with replacement.  Forcing the same prime
      three times exposes both the duplicate list and the Association-key
      collapse in PointsDone while the error exponent still counts three. *)
repeatedModular = withForcedPrimes[
  {p, p, p},
  certify[collisionRecord, "Modular", 3, 6]
];
Print["repeated primes: primes=", Lookup[modular[repeatedModular], "Primes", {}],
  ", points records=", Lookup[modular[repeatedModular], "PointsDone", {}],
  ", error bound=", Lookup[certificate[repeatedModular], "IdentityErrorBound", Missing[]]];
check["EXPOSE duplicate primes counted as independent but result keys collapse",
  Lookup[modular[repeatedModular], "Primes", {}] === ConstantArray[p, 3] &&
  Length[Lookup[modular[repeatedModular], "PointsDone", {}]] === 1];

(* 7. A fixed nonzero polynomial contamination whose integer content is the
      product of the selected primes vanishes identically in every sampled
      characteristic.  The reported bound only contains d/p and omits this
      bad-characteristic event. *)
badContent = Times @@ primeList;
aliasRecord = record1[
  "SYN_BAD_CHARACTERISTIC_CONTENT",
  {{eps (1/x + badContent)}},
  {{0}}
];
aliasModular = withForcedPrimes[
  primeList,
  certify[aliasRecord, "Modular", Length[primeList], 8]
];
aliasSymbolic = certify[aliasRecord, "Symbolic"];
Print["bad-characteristic content bits=", IntegerLength[badContent, 2],
  ": modular=", status[aliasModular],
  ", symbolic=", status[aliasSymbolic],
  ", sampled primes=", Lookup[modular[aliasModular], "Primes", {}],
  ", reported error=", Lookup[certificate[aliasModular], "IdentityErrorBound", Missing[]]];
check["EXPOSE bad-characteristic alias is absent from reported error bound",
  status[aliasModular] === "ExactEpsilonForm" &&
  status[aliasSymbolic] =!= "ExactEpsilonForm" &&
  Lookup[modular[aliasModular], "Primes", {}] === primeList];

(* 8. Residues are reconstructed from the first 24-bit prime only and failure
      or disagreement at later primes does not gate the verdict.  Here the
      true residue is p, so it becomes zero at the first selected prime. *)
largeResidueRecord = record1[
  "SYN_RESIDUE_RECONSTRUCTION",
  {{eps p/x}},
  {{0}}
];
largeResidueModular = withForcedPrimes[
  primeList,
  certify[largeResidueRecord, "Modular", Length[primeList], 8]
];
largeResidueData = modular[largeResidueModular];
Print["residue reconstruction: status=", status[largeResidueModular],
  ", stored residues=", Lookup[dlog[largeResidueModular], "Residues", Missing[]],
  ", verified later=", Lookup[largeResidueData, "ResiduesVerifiedAtOtherPrimes", Missing[]]];
check["EXPOSE wrong/unverified residue does not gate exact status",
  status[largeResidueModular] === "ExactEpsilonForm" &&
  Lookup[largeResidueData, "ResiduesVerifiedAtOtherPrimes", True] =!= True];

(* 9. Verification is not sticky.  A mismatch at the middle prime is reset to
      True when the stored (wrong) residue happens to agree again at the last
      prime.  The true residue p1*p3 is 0 mod p1 and p3, but not mod p2. *)
stickyResidue = primeList[[1]] primeList[[3]];
stickyRecord = record1[
  "SYN_RESIDUE_VERIFICATION_NOT_STICKY",
  {{eps stickyResidue/x}},
  {{0}}
];
stickyModular = withForcedPrimes[
  primeList,
  certify[stickyRecord, "Modular", Length[primeList], 8]
];
stickyData = modular[stickyModular];
Print["non-sticky residue verification: true residue=", stickyResidue,
  ", stored residues=", Lookup[dlog[stickyModular], "Residues", Missing[]],
  ", final verified flag=", Lookup[stickyData, "ResiduesVerifiedAtOtherPrimes", Missing[]]];
check["EXPOSE a later match erases an earlier residue mismatch",
  status[stickyModular] === "ExactEpsilonForm" &&
  Lookup[dlog[stickyModular], "Residues", Missing[]] === {{{0}}} &&
  TrueQ[Lookup[stickyData, "ResiduesVerifiedAtOtherPrimes", False]]];

(* 10. The degree envelope has no source-flatness term.  With S=I and B=0,
       its gauge term sees only n_A+d_A+2, while differentiating two generic
       rational source entries and combining their squared denominators can
       have substantially larger numerator degree. *)
degreeAv = {{(x^5 + x y + y)/(x^4 + x y + y + 1)}};
degreeAw = {{(y^5 + x y + x)/(y^4 + x y + x + 2)}};
degreeProbe = FeynFacet`Private`familyCertificateModular[
  {{{0}}, {{0}}},
  IdentityMatrix[1],
  IdentityMatrix[1],
  {x, y},
  eps,
  {degreeAv, degreeAw},
  {x, y},
  None,
  "Points" -> 2,
  "Primes" -> 1
];
sourceFlatExpr = Together[
  D[degreeAv[[1, 1]], y] - D[degreeAw[[1, 1]], x]
];
sourceFlatNumerator = Expand[Numerator[sourceFlatExpr]];
sourceFlatRules = CoefficientRules[sourceFlatNumerator, {x, y, eps}];
actualSourceFlatDegree = Max[Total /@ Keys[sourceFlatRules]];
reportedDegree = degreeProbe["DegreeBound"];
Print["source-flatness degree counterexample: reported=", reportedDegree,
  ", actual numerator degree=", actualSourceFlatDegree,
  ", source-flat check=", degreeProbe["SourceFlatness"]];
check["EXPOSE reported degree bound underestimates source flatness",
  actualSourceFlatDegree > reportedDegree &&
  degreeProbe["SourceFlatness"] === False];

Print["SUMMARY ", pass, " expected observations OK, ", fail, " unexpected outcomes"];
Exit[If[fail === 0, 0, 1]];
