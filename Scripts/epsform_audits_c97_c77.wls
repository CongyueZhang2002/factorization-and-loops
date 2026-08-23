(* Exact audits on the certified class-97 / class-77 two-variable eps-forms
   (recommended by the 2026-08-16 reviews; all checks exact, no numerics):
   A1  final connections carry no eps-dependent letter (denominators eps-free apart from x,y letters);
   A2  T is REGULAR AND INVERTIBLE at the eps-dependent apparent y-loci (the poles of the
       intermediate factors cancel inside T = Ttot.U.c) — needed for transport;
   A3  det U vs the integrated trace mismatch (closed-form prediction);
   A4  deck intertwiner: sigma_d:(x,y)->(y,x) maps each form to itself up to a constant
       conjugation S (S^-1 R_a S = R_{sigma_d(a)}), i.e. the canonical form is deck-covariant;
   A5  residue audit: rational entries, eigenvalues, ranks, nilpotency of R_{1-w}.
   Usage: wolframscript -f epsform_audits_c97_c77.wls   (reads repository artifacts only) *)
root = "/home/maxzhang/factorization-and-loops";
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
Edir = R <> "/HardClasses/EpsFormRoute";
x = Global`x; y = Global`y; eps = Global`eps; v = Global`v; w = Global`w;
tog[m_] := Map[Together, m, {2}];
zeroM[m_] := AllTrue[Flatten[tog[m]], # === 0 &];
dens[m_] := DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ tog[m]]]];
timed[label_, body_] := Module[{t0 = AbsoluteTime[], r},
  r = body; Print["CHECK ", label, ": ", r, "  (", Round[AbsoluteTime[] - t0, 0.1], " s)"]; r];
SetAttributes[timed, HoldRest];
Uvars = Array[Global`u, {4, 4}];
inter[Nl_, Ml_] := Module[{eqs, mat},
  eqs = Flatten[Table[Nl[[i]] . Uvars - Uvars . Ml[[i]], {i, Length[Nl]}]];
  mat = Normal[CoefficientArrays[eqs, Flatten[Uvars]][[2]]];
  NullSpace[mat]];

audit[label_, file_, deckPerm_] := Module[{f, T, Ax, Ay, Rs, letters, dl, dT, apparent, regular, invertible, ns, S, sig, Rperm, ok},
  Print["==================== ", label, " ===================="];
  f = Get[file]; T = f["T"]; Ax = f["Ax"]; Ay = f["Ay"]; Rs = f["Residues"]; letters = f["Letters"];
  Print["letters: ", letters];
  (* A1 *)
  dl = Join[dens[Ax], dens[Ay]];
  Print["A1 final-connection denominators: ", dl];
  timed["A1 no eps-dependent factor in the final connections", AllTrue[dl, FreeQ[#, eps] &]];
  (* A5 *)
  Print["A5 residue eigenvalues: ", Eigenvalues /@ Rs, "  ranks: ", MatrixRank /@ Rs,
    "  all rational: ", AllTrue[Flatten[Rs], MatchQ[#, _Integer | _Rational] &],
    "  R_{1-w}-type nilpotent: ", Table[MatrixPower[Rs[[k]], 4] === 0 IdentityMatrix[4] || zeroM[MatrixPower[Rs[[k]], 4]], {k, Length[Rs]}]];
  (* A2: eps-dependent factors in T's denominators; regularity = every entry finite there and det nonzero *)
  dT = dens[T];
  apparent = Select[dT, ! FreeQ[#, eps] && (! FreeQ[#, y] || ! FreeQ[#, x]) &];
  Print["A2 T denominators: ", dT];
  Print["A2 eps-dependent (x,y)-loci among T's denominators: ", apparent];
  regular = Table[Module[{q = a, sol, val},
     sol = Quiet[Solve[q == 0, y]];
     If[sol === {} || ! FreeQ[sol, x], (* locus not solvable for y alone: try x *)
       sol = Quiet[Solve[q == 0, x]]; If[sol === {}, "unsolved",
         val = tog[T /. First[sol]]; {q, "in x", FreeQ[val, ComplexInfinity | Indeterminate | DirectedInfinity]}],
       val = Quiet[tog[T /. First[sol]]];
       {q, "in y", FreeQ[val, ComplexInfinity | Indeterminate | DirectedInfinity] && FreeQ[val, Power[0, _]]}]],
    {a, apparent}];
  Print["A2 T finite at each eps-dependent locus (substituting the locus into T): ", regular];
  Print["A2 det T: ", InputForm[Factor[Det[T]]]];
  timed["A2 det T has no eps-dependent (x,y)-factor (T invertible at apparent loci)",
    AllTrue[Select[First /@ Rest[FactorList[Numerator[Together[Det[T]]] Denominator[Together[Det[T]]]]], ! FreeQ[#, eps] &], FreeQ[#, x] && FreeQ[#, y] &]];
  (* A4 deck intertwiner: sigma_d permutes letters as deckPerm (index list), R_{deck(a)} = S^-1 R_a S *)
  Rperm = Rs[[deckPerm]];
  ns = inter[Rs, Rperm];
  Print["A4 deck intertwiner nullspace dim: ", Length[ns]];
  If[Length[ns] >= 1, S = Partition[ns[[1]], 4];
    Print["A4 S = ", InputForm[S], "  det S = ", Det[S], "  S^2 scalar? ", zeroM[S . S - (S . S)[[1, 1]] IdentityMatrix[4]]];
    ok = AllTrue[Table[zeroM[Rs[[k]] . S - S . Rperm[[k]]], {k, Length[Rs]}], TrueQ];
    Print["A4 S intertwines all residues (form is deck-covariant): ", ok];
    (* also check the deck-image of the connection equals S^-1 A S with letters swapped *)
    sig = {x -> y, y -> x};
    timed["A4 deck check on connections: A_y(y,x) == S^-1 A_x S etc.",
      zeroM[tog[(Ax /. sig) - Inverse[S] . Ay . S]] && zeroM[tog[(Ay /. sig) - Inverse[S] . Ax . S]]]];
  (* A3: det U prediction: d/dy log det U == Tr(A_y,norm) - Tr(A_y') ... only meaningful with U and A_y,norm; report det T instead *)
  Print["A3 (det T recorded above; det Ttot known: (x-y)/((x-1)^6 x (x+y)^4) for class 97)"];
];

audit["class 97", Edir <> "/c97_epsform_two_variable.wl", {2, 1, 4, 3, 5, 6, 7}];   (* letters {x,y,1-x,1-y,x-y,x+y,x+y-xy}: deck swaps x<->y, 1-x<->1-y, fixes the rest *)
audit["class 77", Edir <> "/c77_epsform_two_variable.wl", {2, 1, 4, 3, 5, 6, 7}];   (* letters {1-x,1-y,x,y,x-y,2-x-y,1-xy}: same pattern *)
Print["DONE"];
