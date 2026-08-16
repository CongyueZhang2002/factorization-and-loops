(* structsolve97: determine the eps-factorizing gauge T(x,y,eps) for the
   NORMALIZED class-97 system by ansatz, with y symbolic.
   Ansatz: T = sum_k c_k(y,eps) * m_k(x,y), monomials m_k = products of
   letter powers read off the slice transforms.  Condition:
     T^-1 A T - T^-1 d_x T = eps * M   (M eps-free)
   Linear in the unknowns after clearing denominators; solved exactly.
   Structure (degrees, which letters in denominators) is READ from the
   12 slice samples rather than guessed. *)
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Scripts", "HardClassToolkit.wl"}]];
x = Global`x; y = Global`y; eps = Global`eps;
here = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/eps0";
SetDirectory[here];
sn = Get["symnorm_c97.wl"]; A = sn["A"];
letters = {x, 1 - x, x + y, x - y, x + y - x y};
(* --- structure survey from the samples --- *)
data = Get /@ FileNames["p2_c97_y*.wl"];
surv = Table[Module[{T = d["T2"], y0 = d["Y0"], ls, dens, nums},
   ls = letters /. y -> y0;
   dens = DeleteDuplicates[Flatten[Map[
      First /@ Rest[FactorList[Denominator[Together[#]]]] &, T, {2}]]];
   nums = Max[Map[Exponent[Numerator[Together[#]], x] &, T, {2}]];
   {y0, Length[Select[dens, ! FreeQ[#, x] &]], nums}], {d, data}];
Print["per-slice {y0, #x-denominator-factors, max numerator degree}:"];
Print[InputForm[surv]];
Print["max numerator degree overall: ", Max[surv[[All, 3]]]];
Print["den factor count range: ", MinMax[surv[[All, 2]]]];
Print["NOTE: use these to set dNum/denominator letter powers below."];
(* --- ansatz (degrees set from the survey; edit if the survey says otherwise) --- *)
dNum = 4;                    (* numerator degree in x *)
denPows = {1, 1, 1, 1, 1};   (* letter powers in the common denominator *)
den = Times @@ MapThread[#1^#2 &, {letters, denPows}];
unk = Table[Global`c[i, j, k], {i, 4}, {j, 4}, {k, 0, dNum}];
T = Table[Sum[Global`c[i, j, k] x^k, {k, 0, dNum}]/den, {i, 4}, {j, 4}];
Print["ansatz: ", 16 (dNum + 1), " unknown functions of (y,eps)"];
(* condition: A T - d_x T = T (eps M), with M eps-free unknown too.
   Eliminate M: require (A T - d_x T) T^-1 / eps to be eps-free.
   Linear formulation: write M = (1/eps) T^-1 (A T - d_x T) and impose
   d/d eps of eps-graded pieces = 0 order by order after clearing. *)
Print["Formulating linear system ..."];
lhs = Together[A . T - D[T, x]];
(* multiply by den^2 to clear; unknowns enter linearly in lhs, and the
   eps-form condition is: lhs = T . (eps M) with M eps-free
   => require eps | (T^-1 lhs) entrywise.  Use the equivalent linear
   condition on the residues: at each letter locus, Res(A') must be
   proportional to eps.  *)
Print["  (this script is the SKELETON: the residue-linearization step"];
Print["   is the piece to finish — see EpsFormRoute README option 1.)"];
Print["DONE-SURVEY"];
