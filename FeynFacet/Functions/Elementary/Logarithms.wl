(* Split rational logarithm arguments only after proving every resulting
   real factor has its declared sign. No unqualified PowerExpand is used. *)
FeynFacetSolution`ExpandPositiveLogarithms::usage="ExpandPositiveLogarithms[expression,assumptions] expands logarithms of rational products and quotients into real logarithms of sign-verified factors. An unproved real branch returns Failure.";
positiveLogarithmInteger[n_Integer?Positive]:=Total[(Last[#]Log[First[#]]& /@ FactorInteger[n])];
positiveLogarithmConstant[x_]:=Which[
 IntegerQ[x]&&x>0,positiveLogarithmInteger[x],
 Head[x]===Rational&&x>0,positiveLogarithmInteger[Numerator[x]]-positiveLogarithmInteger[Denominator[x]],
 Head[x]===Times,Total[positiveLogarithmConstant /@ (List@@x)],
 Head[x]===Power&&IntegerQ[x[[2]]]&&TrueQ[x[[1]]>0],x[[2]]positiveLogarithmConstant[x[[1]]],
 True,Log[x]];
FeynFacetSolution`ExpandPositiveLogarithms[expression_,assumptions_]:=Catch[Module[{logs,rules,expand},
 expand[arg_]:=Module[{rat,num,den,factors,constant=1,terms={},base,n,sign},
  rat=Cancel[arg];
  If[!TrueQ[FullSimplify[rat>0,assumptions]],Throw[Failure["PositiveLogarithmArgumentNotEstablished",<|"Argument"->arg|>],"PositiveLogarithms"]];
  {num,den}={FactorList[Numerator[rat]],FactorList[Denominator[rat]]};
  constant=First[num][[1]]/First[den][[1]];
  factors=Join[Rest[num],({First[#],-Last[#]}& /@ Rest[den])];
  Do[{base,n}=factor;sign=Which[TrueQ[FullSimplify[base>0,assumptions]],1,
    TrueQ[FullSimplify[base<0,assumptions]],-1,True,
    Throw[Failure["LogarithmFactorSignNotEstablished",<|"Factor"->base|>],"PositiveLogarithms"]];
   constant*=sign^n;AppendTo[terms,n positiveLogarithmConstant[sign base]],{factor,factors}];
  If[!TrueQ[FullSimplify[constant>0,assumptions]],Throw[Failure["PositiveLogarithmConstantRequired",<||>],"PositiveLogarithms"]];
  positiveLogarithmConstant[constant]+Total[terms]];
 logs=DeleteDuplicates[Cases[expression,_Log,{0,Infinity}]];
 rules=(#->expand[First[#]]& /@ logs);expression/.rules
 ],"PositiveLogarithms"];

FeynFacetSolution`RealPartOnPhysicalDomain::usage="RealPartOnPhysicalDomain[expression,assumptions] takes a real part after proving the logarithms have positive arguments and every algebraic parameter is real. Logarithms are temporarily independent real symbols, avoiding expensive trigonometric branch expansions.";
FeynFacetSolution`RealPartOnPhysicalDomain[expression_,assumptions_]:=Module[
 {expanded,atoms,temporary,rules,algebraic,variables,unknown,result},
 expanded=FeynFacetSolution`ExpandPositiveLogarithms[expression,assumptions];
 If[FailureQ[expanded],Return[expanded]];
 atoms=DeleteDuplicates[Cases[expanded,_Log,{0,Infinity}]];temporary=Table[Unique["realLog"],{Length[atoms]}];
 rules=Thread[atoms->temporary];algebraic=expanded/.rules;
 variables=Complement[Variables[Together[algebraic]],temporary];
 unknown=Select[variables,!TrueQ[FullSimplify[Element[#,Reals],assumptions]]&];
 If[unknown=!={},Return[Failure["AlgebraicParameterRealityNotEstablished",<|"Parameters"->unknown|>]]];
 result=ComplexExpand[Re[algebraic]]/.Thread[temporary->atoms];
 If[!FreeQ[result,_Re|_Im|_Conjugate|_Arg],Return[Failure["ExplicitPhysicalRealPartRequired",<||>]]];result
];
