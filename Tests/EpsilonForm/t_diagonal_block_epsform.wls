(* Diagonal-block epsilon form on the finite-field route, pinned on a
   synthetic irreducible 2x2 block with a KNOWN answer: a flat dlog form
   eps (R_x dlog x + R_y dlog y + R_xy dlog(x-y)) with R_xy = -(R_x+R_y)
   (KZ-type, flat by construction) is hidden behind a rational gauge T0
   whose determinant carries an eps-dependent apparent locus, as the raw
   hard-class representatives do.  The route must recover letters,
   residue spectra and a transformation equal to T0 up to a constant
   invertible matrix, and the gate must certify it. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
x = Global`x; y = Global`y; eps = Global`eps;
flags = {};
check[label_, value_] := (AppendTo[flags, label -> TrueQ[value]];
  Print[If[TrueQ[value], "ok   ", "FAIL "], label]);
tog[m_] := Map[Cancel[Together[#]] &, m, {2}];
zeroQ[m_] := AllTrue[Flatten[tog[m]], # === 0 &];
sameLetter[a_, b_] := NumberQ[Cancel[Together[a/b]]];

(* integer spectra throughout: Rx ~ {1,0}, Ry ~ {0,1}, Rxy = -(Rx+Ry) ~ {0,-2} *)
Rx = {{1, 1}, {0, 0}}; Ry = {{0, 0}, {1, 1}}; Rxy = -(Rx + Ry);
check["synthetic residues non-commuting with integer spectra",
  Rx . Ry =!= Ry . Rx && AllTrue[Flatten[Eigenvalues /@ {Rx, Ry, Rxy}], IntegerQ]];
Bx = eps (Rx/x + Rxy/(x - y)); By = eps (Ry/y - Rxy/(x - y));
check["synthetic target is flat", zeroQ[D[Bx, y] - D[By, x] + Bx . By - By . Bx]];
T0 = {{1, eps x/(x - y)}, {y/x, 1 + y}};
T0i = tog[Inverse[T0]];
Ax = tog[T0 . Bx . T0i + D[T0, x] . T0i];
Ay = tog[T0 . By . T0i + D[T0, y] . T0i];
check["source is flat", zeroQ[D[Ax, y] - D[Ay, x] + Ax . Ay - Ay . Ax]];
check["source carries an eps-dependent apparent factor",
  ! FreeQ[FeynFacet`DiagonalBlockLetters[{Ax, Ay}, {x, y}, eps]["ApparentFactors"], eps]];

t0 = AbsoluteTime[];
result = FeynFacet`DiagonalBlockEpsForm[{Ax, Ay}, {x, y}, eps];
Print["DiagonalBlockEpsForm: ", result["Status"], "  (", Round[AbsoluteTime[] - t0, 0.1], " s)  ",
  Lookup[result, "Timing", Missing[]]];
check["route certified", result["Status"] === "Certified"];
If[result["Status"] =!= "Certified", Print[KeyDrop[result, "Transformation"]]];
If[result["Status"] === "Certified",
  T = result["Transformation"];
  conj = tog[Inverse[T0] . T];
  check["T equals T0 up to a constant invertible matrix",
    FreeQ[conj, x | y] && ! TrueQ[Together[Det[conj]] === 0]];
  sameLetter[a_, b_] := NumberQ[Cancel[Together[a/b]]];
  check["letters recovered", Length[result["Letters"]] === 3 &&
    AllTrue[{x, y, x - y}, Function[l, AnyTrue[result["Letters"], sameLetter[l, #] &]]]];
  spectrum[l_, lets_, res_] := Sort[Eigenvalues[res[[SelectFirst[Range[Length[lets]], sameLetter[lets[[#]], l] &]]]]];
  check["residue spectra match", And @@ Table[
    spectrum[l[[1]], result["Letters"], result["Residues"]] === Sort[Eigenvalues[l[[2]]]],
    {l, {{x, Rx}, {y, Ry}, {x - y, Rxy}}}]];
  check["gate recomputed independently",
    zeroQ[tog[Inverse[T] . Ax . T - Inverse[T] . D[T, x]] - result["EpsForm"][[1]]] &&
    zeroQ[tog[Inverse[T] . Ay . T - Inverse[T] . D[T, y]] - result["EpsForm"][[2]]]];
  check["residues constant", FreeQ[result["Residues"], x | y | eps]];
  (* wrong residues must fail the gate *)
  bad = FeynFacet`CertifyDiagonalBlockEpsForm[{Ax, Ay}, {x, y}, eps, T,
    result["Letters"], result["Residues"] /. 1 -> 2];
  check["gate rejects altered residues", bad["Status"] === "GateFailed"];
  (* a regulator-dependent letter is an exact identity but not an eps-form
     (Codex audit 2026-08-21: it used to certify) *)
  epsLetter = FeynFacet`CertifyDiagonalBlockEpsForm[{{{eps/(x + eps)}}, {{0}}}, {x, y}, eps,
    {{1}}, {x + eps}, {{{1}}}];
  check["gate rejects a regulator-dependent letter",
    epsLetter["Status"] === "GateFailed" && epsLetter["LettersEpsFree"] === False &&
    epsLetter["GateX"] && epsLetter["GateY"]];
  check["scalar route refuses a regulator-dependent letter",
    FeynFacet`DiagonalBlockEpsForm[{{{eps/(x + eps)}}, {{0}}}, {x, y}, eps]["Status"] =!= "Certified"];
  (* stage records present *)
  check["slice stage recorded", AssociationQ[result["Slice"]] && result["Slice"]["Status"] === "OK"];
  check["NumericalEps slice engine used", Lookup[result["Slice"], "Engine", None] === "NumericalEps"];
  (* the symbolic engine must agree: same letters, residues conjugate *)
  symbolic = FeynFacet`DiagonalBlockSliceEpsForm[{Ax, Ay}, {x, y}, eps, "Engine" -> "Symbolic"];
  check["symbolic slice engine also normalizes", symbolic["Status"] === "OK"];
  If[symbolic["Status"] === "OK",
    check["numeric and symbolic slice residues have the same spectra",
      (Sort[Eigenvalues[#]] & /@ result["Slice"]["SliceResidues"]) ===
      (Sort[Eigenvalues[#]] & /@ symbolic["SliceResidues"])]];
  check["solve stage exact", TrueQ[result["Solve"]["ExactXEquation"]]]];

(* --- zero block ------------------------------------------------------ *)
zero = FeynFacet`DiagonalBlockEpsForm[{ConstantArray[0, {2, 2}], ConstantArray[0, {2, 2}]}, {x, y}, eps];
check["zero block certified as the identity", zero["Status"] === "Certified" &&
  zero["Transformation"] === IdentityMatrix[2] && zero["Method"] === "ZeroBlock"];

(* --- scalar block with a letter quadratic in both variables ------------ *)
q = x^2 + x y + y^2 - y;
As = {{{(2 + eps) D[q, x]/q + eps/x}}, {{(2 + eps) D[q, y]/q}}};
scalar = FeynFacet`DiagonalBlockEpsForm[As, {x, y}, eps];
check["scalar block certified", scalar["Status"] === "Certified" && scalar["Method"] === "ScalarDLog"];
check["scalar gauge is q^2", TrueQ[Cancel[Together[scalar["Transformation"][[1, 1]]/q^2]] === 1] ||
  NumberQ[Cancel[Together[scalar["Transformation"][[1, 1]]/q^2]]]];
check["scalar letters are q and x with unit residues",
  Sort[ToString /@ Flatten[scalar["Residues"]]] === {"1", "1"} &&
  AllTrue[{q, x}, Function[l, AnyTrue[scalar["Letters"], sameLetter[l, #] &]]]];

(* --- degenerate slice direction: x-residue scalar, y-direction irreducible *)
Ry = {{0, 1}, {0, 0}}; Ry1 = {{0, 0}, {1, 0}};
Bdx = eps IdentityMatrix[2]/x; Bdy = eps (Ry/y + Ry1/(y - 1));
check["degenerate-direction target flat", zeroQ[D[Bdx, y] - D[Bdy, x] + Bdx . Bdy - Bdy . Bdx]];
Td = {{1, x}, {y/(x - 1), 1}}; Tdi = tog[Inverse[Td]];
Adx = tog[Td . Bdx . Tdi + D[Td, x] . Tdi]; Ady = tog[Td . Bdy . Tdi + D[Td, y] . Tdi];
deg = FeynFacet`DiagonalBlockEpsForm[{Adx, Ady}, {x, y}, eps];
check["degenerate x-direction certified via another frame", deg["Status"] === "Certified" &&
  deg["Frame"] =!= "Slicex"];
If[deg["Status"] === "Certified",
  check["degenerate case: T equals Td up to a constant invertible matrix",
    With[{c = tog[Inverse[Td] . deg["Transformation"]]}, FreeQ[c, x | y] && ! TrueQ[Together[Det[c]] === 0]]]];

failures = Select[flags, ! Last[#] &];
Print[Length[flags] - Length[failures], "/", Length[flags], " checks passed"];
If[failures =!= {}, Print["FAILED: ", First /@ failures]; Exit[1]];
Exit[0];
