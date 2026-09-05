(* Adversarial test set for the finite-field off-diagonal block solver
   (2026-08-22).  Every block is CONSTRUCTED from a known rational gauge
   D and known residues K: with diagonal eps-forms eps e, eps c and a
   target coupling B' = eps Sum_a K_a dlog L_a, the inhomogeneity is
     inhomogeneity = B' + dD - eps (e D - D c)
   (the solver's convention dD = eps (e D - D c) + inhomogeneity - eps K dlog), so
   the solver must recover a gauge equivalent to D.  Each case targets one
   assumption that failed on the real families today:
     A  residues of ~80 digits               (prime sequence must extend)
     B  numerator far outside the bidegree rectangle (x^7 with a
        denominator of x-degree 1)           (support = certified simplex)
     C  eps^0 dlog part in the inhomogeneity        (regulator pole in K,
                                              no obstruction)
     D  e = c (pure constant-gauge null directions)
                                              (normalization by gauge columns)
     E  a support that is smaller at one regulator value (support learning
        must fall back)
     F  a pole of the inhomogeneity at a schedule value eps = 1/3 and 1/2
                                              (regulator values discarded)
     G  eps-dependent residues K(eps) = K/(1 + 4 eps) (allowed)
     H  an eps-dependent LETTER -> must be rejected (NotDLogForm), not
        accepted
   The acceptance test for each solvable case is the exact Pfaffian
   identity of the returned gauge (VerifyOffDiagonalBasisTransformationBlock "Exact"), never a
   comparison with D itself (the gauge is unique only up to constants). *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
pass = 0; fail = 0;
check[label_, ok_] := (If[TrueQ[ok], pass++; Print["OK   ", label], fail++; Print["FAIL ", label]]);
Clear[x, y, eps];
dlog[L_] := {D[Log[L], x], D[Log[L], y]};
(* e, c: residue forms of the diagonal eps-forms (constant residue matrices times dlog letters) *)
form[residues_List, letters_List] := Table[Sum[residues[[a]] dlog[letters[[a]]][[mu]], {a, Length[letters]}], {mu, 2}];
(* the inhomogeneity for a chosen gauge D (upper x lower) and target residues K_a *)
inhomogeneity[e_, c_, offDiagonalBasisTransformationBlock_, kRes_, letters_] := Table[Together[
  eps Sum[kRes[[a]] dlog[letters[[a]]][[mu]], {a, Length[letters]}] +
    D[offDiagonalBasisTransformationBlock, {x, y}[[mu]]] - eps (e[[mu]] . offDiagonalBasisTransformationBlock - offDiagonalBasisTransformationBlock . c[[mu]])], {mu, 2}];
record[name_, e_, c_, inhomogeneity_] := <|"Family" -> name, "Sector" -> 2, "LowerSector" -> 1,
  "Variables" -> {x, y}, "Regulator" -> eps, "OffDiagonalBlockEquation" -> {e, c, inhomogeneity}|>;
solve[rec_, opts___] := FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[rec, "KernelCount" -> 1, "FinalCheck" -> "Exact",
  "ArtifactDirectory" -> FileNameJoin[{$TemporaryDirectory, "ffadv_" <> rec["Family"] <> "_" <> ToString[$ProcessID]}],
  "Verbose" -> False, opts];
exactQ[rec_, sol_] := AssociationQ[sol] && sol["Status"] === "Solved" &&
  TrueQ[Lookup[FeynFacet`VerifyOffDiagonalBasisTransformationBlock[rec, sol, "Method" -> "Exact", "KernelCount" -> 1], "DLogFormCertified", False]];
letters = {x, y, 1 - x - y, x + 2 y - 3};
e1 = form[{{{1}}, {{-1}}, {{2}}, {{0}}}, letters];        (* 1x1 upper *)
c1 = form[{{{-2}}, {{1}}, {{0}}, {{1}}}, letters];        (* 1x1 lower *)
Q = (1 - x - y) (x + 2 y - 3);

(* A: tall residues *)
tall = 123456789012345678901234567890123456789012345678901234567890123456789012345678901/7;
kA = {{{tall}}, {{-tall/3}}, {{2}}, {{0}}};
dA = {{(x^2 + 3 y)/(1 - x - y)}};
recA = record["ADV_A_tall_residues", e1, c1, inhomogeneity[e1, c1, dA, kA, letters]];
{tA, sA} = AbsoluteTiming[solve[recA]];
check["A tall residues solved exactly (" <> ToString[Lookup[sA, "ModularPrimeCount", "?"]] <> " primes, " <> ToString[Round[tA, 0.1]] <> " s)", exactQ[recA, sA]];
check["A needed more than the 11 configured primes", AssociationQ[sA] && Lookup[sA, "ModularPrimeCount", 0] > 11];

(* B: numerator x^7 over a denominator of x-degree 1 *)
dB = {{(x^7 + y^2 - 5)/(1 - x - y)}};
kB = {{{1}}, {{2}}, {{-3}}, {{1/2}}};
recB = record["ADV_B_off_rectangle", e1, c1, inhomogeneity[e1, c1, dB, kB, letters]];
{tB, sB} = AbsoluteTiming[solve[recB]];
check["B off-rectangle numerator solved (" <> ToString[Round[tB, 0.1]] <> " s)", exactQ[recB, sB]];
check["B solved at the first probe (simplex)", AssociationQ[sB] && Lookup[sB, "ProbeCount", 9] === 1];

(* C: eps^0 dlog part in the inhomogeneity: inhomogeneity has K0 dlog with K0 constant -> K = K0/eps + K1 *)
kC = {{{3/eps + 1}}, {{-2/eps}}, {{1}}, {{0}}};
dC = {{x y/(x + 2 y - 3)}};
recC = record["ADV_C_regulator_pole", e1, c1, inhomogeneity[e1, c1, dC, kC, letters]];
{tC, sC} = AbsoluteTiming[solve[recC]];
check["C eps^0 dlog part: solved with regulator-pole residues (" <> ToString[Round[tC, 0.1]] <> " s)", exactQ[recC, sC]];
obsC = FeynFacet`AnalyzeOffDiagonalBlockEpsilonFormObstructions[recC, "MaximumOrder" -> 2];
check["C obstruction certificate: no obstruction, RegulatorPoleResidues flagged", AssociationQ[obsC] && obsC["Status"] === "NoObstructionToOrder" && TrueQ[obsC["RegulatorPoleResidues"]]];

(* D: e = c (2x2 upper = 2x2 lower), constant commuting gauge modes *)
e2 = form[{{{1, 0}, {0, -1}}, {{0, 1}, {1, 0}}, {{2, 0}, {0, 2}}, {{0, 0}, {0, 1}}}, letters];
dD = {{x/(1 - x - y), 0}, {y^2/(x + 2 y - 3), (x + y)/(1 - x - y)}};
kD = {{{1, 2}, {0, -1}}, {{0, 0}, {1, 1}}, {{1, 0}, {0, 0}}, {{0, 1}, {1, 0}}};
recD = record["ADV_D_equal_diagonals", e2, e2, inhomogeneity[e2, e2, dD, kD, letters]];
{tD, sD} = AbsoluteTiming[solve[recD]];
check["D equal diagonal blocks (pure gauge null modes) solved (" <> ToString[Round[tD, 0.1]] <> " s)", exactQ[recD, sD]];

(* E: support smaller at the pilot regulator value 1/21: coefficient (1 - 21 eps) x^2 *)
dE = {{((1 - 21 eps) x^2 + y + 1)/(1 - x - y)}};
recE = record["ADV_E_pilot_zero", e1, c1, inhomogeneity[e1, c1, dE, kB, letters]];
{tE, sE} = AbsoluteTiming[solve[recE]];
check["E coefficient vanishing at the pilot value: solved (learning fallback) (" <> ToString[Round[tE, 0.1]] <> " s)", exactQ[recE, sE]];

(* F: poles of the inhomogeneity at schedule values 1/3 (k = 10) and 1/2 (k = 20) *)
kF = {{{1/(1 - 3 eps)}}, {{2/(1 - 2 eps)}}, {{1}}, {{0}}};
dF = {{(x + y)/((1 - 3 eps) (1 - x - y))}};
recF = record["ADV_F_schedule_pole", e1, c1, inhomogeneity[e1, c1, dF, kF, letters]];
{tF, sF} = AbsoluteTiming[solve[recF]];
check["F poles at schedule regulator values: solved (" <> ToString[Round[tF, 0.1]] <> " s)", exactQ[recF, sF]];

(* G: eps-dependent residues K/(1 + 4 eps) *)
kG = {{{2/(1 + 4 eps)}}, {{-1/(1 + 4 eps)}}, {{eps/(1 + 4 eps)}}, {{0}}};
dG = {{eps (x^2 - y)/((1 + 4 eps) (x + 2 y - 3))}};
recG = record["ADV_G_resonance", e1, c1, inhomogeneity[e1, c1, dG, kG, letters]];
{tG, sG} = AbsoluteTiming[solve[recG]];
check["G resonance residues eps/(1+4 eps): solved (" <> ToString[Round[tG, 0.1]] <> " s)", exactQ[recG, sG]];

(* H: a coupling whose only pole is an eps-dependent letter, eps dlog(1 - x - y + eps),
   between eps-free diagonal blocks: no rational gauge and no eps-free
   alphabet can make it eps dlog -> must be rejected, never "Solved" *)
recH = record["ADV_H_eps_letter", e1, c1, Table[eps D[Log[1 - x - y + eps], {x, y}[[mu]]] {{1}}, {mu, 2}]];
sH = Quiet[solve[recH]];
check["H eps-dependent letter rejected (not Solved)", ! (AssociationQ[sH] && sH["Status"] === "Solved")];
check["H rejected means the exact identity cannot hold", ! exactQ[recH, sH]];

(* I: the trivial block (already dlog, D = 0) solves quickly *)
recI = record["ADV_I_already_dlog", e1, c1, inhomogeneity[e1, c1, {{0}}, kB, letters]];
{tI, sI} = AbsoluteTiming[solve[recI]];
check["I already-dlog block solved in under 10 s (" <> ToString[Round[tI, 0.1]] <> " s)", exactQ[recI, sI] && tI < 10];

Print["t_finite_field_adversarial: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
