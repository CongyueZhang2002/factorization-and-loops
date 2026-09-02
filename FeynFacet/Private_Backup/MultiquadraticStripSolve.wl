
(* ==== moved from Private/MultiquadraticStripSolve.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: no reference anywhere (reachability.py 2026-09-02)
   Symbols: multiquadraticFieldResetPathStatistics, multiquadraticStripAssemblePoint
   This file is never loaded by FeynFacet.m. *)


multiquadraticFieldResetPathStatistics[] := (
  $multiquadraticFieldRootFreeFastPathCount = 0;
  $multiquadraticFieldAlgebraicPathCount = 0;
  $multiquadraticFieldComposeCheckCount = 0;
  multiquadraticFieldPathStatistics[]);

multiquadraticStripAssemblePoint[assembly_Association,
    epsilonForms_Association, prime_Integer,
    point : {_Integer, _Integer}] := Module[{result},
  If[! multiquadraticStripCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      ! (3 < prime < 2^31),
    Return[multiquadraticStripFailure["InvalidPointAssemblyInput"]]];
  result = multiquadraticStripAssemblePointInternal[assembly, epsilonForms,
    prime, point];
  If[AssociationQ[result], result,
    multiquadraticStripFailure["PointAssemblyDidNotReturnAssociation"]]
];
multiquadraticStripAssemblePoint[___] :=
  multiquadraticStripFailure["InvalidPointAssemblyArguments"];
