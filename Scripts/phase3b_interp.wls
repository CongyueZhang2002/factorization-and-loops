(* phase3_interp: reconstruct T2(x,y,eps) entrywise from the phase-2
   slice samples by rational interpolation in y, then run the EXACT
   two-variable gate.  Interpolation is a candidate generator only —
   the gate is the proof. *)
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Scripts", "HardClassToolkit.wl"}]];
x = Global`x; y = Global`y; eps = Global`eps;
here = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/eps0";
SetDirectory[here];
files = FileNames["p2_c97_y*.wl", here];
data = Get /@ files;
pts = #["Y0"] & /@ data;
Print["samples: ", Length[pts], " at y = ", InputForm[pts]];
sn = Get["symnorm_c97.wl"];
Anorm = sn["A"]; Ttot = sn["Ttot"];

(* rational interpolation of one scalar in y, verified on ALL samples *)
ratY[vals_List] := Module[{res = $Failed},
  Do[Do[Module[{dn = dtot - dd, nn, dc, unk, eqs, sol, cand},
     If[dn + dd + 2 <= Length[vals],
      nn = Table[Global`na[k], {k, 0, dn}];
      dc = Append[Table[Global`db[k], {k, 0, dd - 1}], 1];
      unk = Join[nn, Most[dc]];
      eqs = Table[
        vals[[i, 2]] Sum[dc[[k + 1]] vals[[i, 1]]^k, {k, 0, dd}] -
          Sum[nn[[k + 1]] vals[[i, 1]]^k, {k, 0, dn}] == 0,
        {i, Length[vals]}];
      sol = Quiet@Solve[eqs, unk];
      If[sol =!= {},
       cand = Together[
         (Sum[nn[[k + 1]] y^k, {k, 0, dn}] /. sol[[1]] /. Thread[unk -> 0])/
         (Sum[dc[[k + 1]] y^k, {k, 0, dd}] /. sol[[1]] /. Thread[unk -> 0])];
       If[AllTrue[vals, Quiet[Together[(cand /. y -> #[[1]]) - #[[2]]]] === 0 &],
        res = cand]]]],
    {dd, 0, dtot}];
   If[res =!= $Failed, Break[]],
  {dtot, 0, 20}];
  res];

(* T2 entries are rational in x and eps too: interpolate coefficient-wise
   in a common monomial basis *)
(* GAUGE FIX: CANONICA determines T2 only up to right multiplication by
   a constant (in x) matrix, chosen independently per slice.  Normalize
   every sample to T2n(x0) = Id at a common reference point off every
   letter; the normalized transform still yields an eps-form (constant
   conjugation) and is now comparable across slices. *)
x0 = 1/3;
T2s = Table[Module[{T = d["T2"], C},
   C = Together[T /. x -> x0];
   Together[T . Inverse[C]]], {d, data}];
Print["gauge-normalized at x0 = ", x0, "; check T2n(x0)=Id: ",
  AllTrue[T2s, Together[(# /. x -> x0) - IdentityMatrix[4]] ==
    ConstantArray[0, {4, 4}] &]];
dims = Dimensions[T2s[[1]]];
Print["T2 dims: ", dims];
basisOf[e_] := Module[{t = Together[e]},
  {Numerator[t], Denominator[t]}];
T2sym = Table[
  Module[{vals = Table[{pts[[s]], T2s[[s, i, j]]}, {s, Length[pts]}], r},
   r = ratY[vals];
   If[r === $Failed,
    (* entry depends on x/eps: interpolate the coefficient list *)
    Module[{cl = Table[CoefficientRules[Together[T2s[[s, i, j]]], {x, eps}],
        {s, Length[pts]}], keys},
     keys = DeleteDuplicates[Flatten[cl[[All, All, 1]], 1]];
     Total[Table[Module[{cv = Table[{pts[[s]],
          Lookup[Association[cl[[s]]], {kk}, 0] // First // (# /. _Missing -> 0) &},
          {s, Length[pts]}], rr},
        rr = ratY[cv];
        If[rr === $Failed,
        Print["  interp failed: entry (", i, ",", j, ") key ", kk,
          " values ", InputForm[cv[[All, 2]]]];
        Throw[{"entry", i, j, "key", kk}, p3]];
        rr x^kk[[1]] eps^kk[[2]]], {kk, keys}]]],
    r]],
  {i, dims[[1]]}, {j, dims[[2]]}];
Print["interpolation done"];
HCTPut[<|"T2" -> T2sym|>, "c97_T2_symbolic.wl"];

(* EXACT GATE: full transform U = Ttot . T2sym must send the ORIGINAL
   chart system to eps-form *)
cls = Get["classes.wl"];
ent = SelectFirst[cls, #["ClassID"] == 97 &];
v = Global`v; w = Global`w;
vx = Global`xx y; wx = (1 - Global`xx) (1 - y);
Ax = Together[((ent["RepAv"] /. {v -> vx, w -> wx}) y -
    (ent["RepAw"] /. {v -> vx, w -> wx}) (1 - y)) /. Global`xx -> x];
U = Together[Ttot . T2sym];
Anew = Together[Inverse[U] . Ax . U - Inverse[U] . D[U, x]];
epsFree = AllTrue[Flatten[Anew], FreeQ[Cancel[Together[#/eps]], eps] &];
Print[">>> GATE (x-direction): A' = eps * (eps-free): ", epsFree];
If[epsFree,
 Module[{B = Map[Cancel[Together[#/eps]] &, Anew, {2}], letters},
  letters = DeleteDuplicates[Select[Flatten[Map[
     First /@ Rest[FactorList[Denominator[Together[#]]]] &, B, {2}]],
     ! FreeQ[#, x] &]];
  Print[">>> letters: ", InputForm[letters]];
  HCTPut[<|"U" -> U, "Aeps" -> Anew, "Letters" -> letters|>,
    "c97_epsform_xdir.wl"]]];
Print["DONE"];
