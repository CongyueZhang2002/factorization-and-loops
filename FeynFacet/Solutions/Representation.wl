(* Shared mathematical heads of the stored finite solution.
   Integer indices and epsilon-order labels must survive numerical evaluation.
   No construction, backend or physics package is loaded here. *)
SetAttributes[FeynFacetSolution`C,NHoldAll];
SetAttributes[FeynFacetSolution`a,NHoldAll];
SetAttributes[{FeynFacetSolution`F,FeynFacetSolution`K},NHoldFirst];

SetAttributes[{FeynFacetSolution`B,FeynFacetSolution`OrdinaryPointCoefficient},NHoldAll];
