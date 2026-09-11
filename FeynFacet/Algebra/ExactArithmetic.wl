(* Exact scalar arithmetic shared by the symbolic algorithms. *)
termList[expr_] := With[{expanded = Expand[expr]},
  If[Head[expanded] === Plus, List @@ expanded, {expanded}]
];

exactZeroQ[expr_] := TrueQ[
  Quiet[Cancel[Together[expr]]] === 0
];

exactRationalQ[value_] := MatchQ[value, _Integer | _Rational];

inexactNumberQ[value_] := NumberQ[value] && Precision[value] =!= Infinity;

(* Inexact numbers are Real atoms or Complex atoms with inexact components.
   Restrict the predicate to those heads instead of evaluating NumberQ at
   every node of a large rational reduction. *)
exactDataQ[expression_] := FreeQ[
  HoldComplete[expression],
  _Real | _Complex?inexactNumberQ |
    _SparseArray?(Not[exactDataQ[{#["ExplicitValues"],#["ImplicitValue"]}]]&)
];


(* Exact linear algebra shared by DE and Laurent-basis calculations. *)
exactRationalMatrix[m_] := Map[Cancel[Together[#]]&,Normal[m],{2}];
exactIndependentRowIndices[matrix_List] := Module[{reduced},
 If[matrix==={},Return[{}]];
 reduced=RowReduce[Transpose[matrix]];
 DeleteCases[Map[Function[row,SelectFirst[Range[Length[row]],
   row[[#]]=!=0&,Missing["ZeroRow"]]],reduced],_Missing]
];
exactRationalLaurentValuation[value_,e_] := Module[{num,den},
 If[value===0,Return[Infinity]];
 {num,den}=NumeratorDenominator[Cancel[Together[value]]];
 If[num===0,Infinity,Exponent[num,e,Min]-Exponent[den,e,Min]]
];
