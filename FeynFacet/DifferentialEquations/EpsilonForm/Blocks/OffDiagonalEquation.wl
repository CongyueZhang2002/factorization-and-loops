(* Shared definitions for an off-diagonal epsilon-form block equation.

   For diagonal connections eps e and eps c and an off-diagonal connection
   block B, the off-diagonal block D of the basis transformation obeys

     d_mu D = eps (e_mu D - D c_mu) + F_mu,

   where the transformed off-diagonal connection block must be a dlog
   one-form.  The live solver is SolveOffDiagonalBasisTransformationBlock;
   retired CANONICA and Maple routes are not part of this module.
*)

ClearAll[
  offDiagonalBlockShapeQ,
  offDiagonalBlockAlphabet,
  offDiagonalBlockSafeTag
];

offDiagonalBlockShapeQ[{e_List, c_List, inhomogeneity_List}] := Module[
  {de, dc, db, ni, nj},
  If[Length[e] =!= 2 || Length[c] =!= 2 || Length[inhomogeneity] =!= 2,
    Return[False]];
  de = Dimensions /@ e;
  dc = Dimensions /@ c;
  db = Dimensions /@ inhomogeneity;
  If[! SameQ @@ de || ! SameQ @@ dc || ! SameQ @@ db,
    Return[False]];
  If[Length[de[[1]]] =!= 2 || Length[dc[[1]]] =!= 2 ||
     Length[db[[1]]] =!= 2, Return[False]];
  ni = de[[1, 1]];
  nj = dc[[1, 1]];
  de[[1]] === {ni, ni} && dc[[1]] === {nj, nj} &&
    db[[1]] === {ni, nj}
];

(* CANONICA-free since 2026-09-02 (round 2): the alphabet is the set of
   irreducible, regulator-free denominator factors of the off-diagonal block equation's entries
   (what CANONICA`ExtractIrreducibles enumerated), plus the variables. *)
offDiagonalBlockIrreducibleFactors[expressions_, variables_List, epsilon_Symbol] :=
 Module[{entries, factors},
  entries = Select[Flatten[{expressions}], ! TrueQ[# === 0] &];
  factors = DeleteDuplicates[Flatten[
    (First /@ Rest[FactorList[Denominator[Together[#]]]]) & /@ entries]];
  factors = Select[factors,
    ! FreeQ[#, Alternatives @@ variables] && FreeQ[#, epsilon] &];
  DeleteDuplicates[factors, PossibleZeroQ[#1 - #2] || PossibleZeroQ[#1 + #2] &]
];
offDiagonalBlockRationalZeroCoefficients[expression_, variables_List] :=
  Module[{numerator = Numerator[Together[expression]]},
    If[TrueQ[numerator === 0], {},
      Values[CoefficientRules[Expand[numerator], variables]]]];

offDiagonalBlockAlphabet[{e_, c_, inhomogeneity_}, variables_List, epsilon_Symbol] :=
  Union[variables,
    offDiagonalBlockIrreducibleFactors[{e, c, inhomogeneity}, variables, epsilon]];

offDiagonalBlockSafeTag[tag_] := StringReplace[
  ToString[tag], RegularExpression["[^A-Za-z0-9_-]"] -> "_"];
