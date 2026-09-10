(* Algebraic substitution of declared scalar integer powers. ReplaceAll
   alone cannot replace g^4 using a rule for g^2. No square-root branch is
   inferred: an unpaired power of g is retained explicitly. *)
BeginPackage["FeynFacet`"];
SubstituteScalarPowers::usage="SubstituteScalarPowers[expression,rules] applies exact scalar substitutions, extending a rule g^n->a to integer powers g^m=a^Quotient[m,n] g^Mod[m,n]. Unpaired powers remain; no root branch is inferred.";
Begin["`Private`"];
SubstituteScalarPowers[expression_,rules_List]:=Fold[Function[{value,rule},
 If[MatchQ[rule,HoldPattern[Power[_,_Integer?Positive]->_]],
  With[{base=rule[[1,1]],n=rule[[1,2]],replacement=Last[rule]},
   value/.HoldPattern[Power[base,m_Integer]]:>
    replacement^Quotient[m,n]base^Mod[m,n]],
  value/.rule]],expression,rules];
End[];EndPackage[];
