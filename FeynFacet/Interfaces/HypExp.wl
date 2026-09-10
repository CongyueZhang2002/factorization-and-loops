(* HypExp modifies protected System hypergeometric functions. Run it in a
   separate kernel; no vendor definitions enter the production kernel. *)
BeginPackage["FeynFacet`"];
ExpandHypergeometricLaurentSeries::usage="ExpandHypergeometricLaurentSeries[expression,epsilon,upper] expands parameter-dependent unit-argument hypergeometric functions with HypExp in an isolated kernel, including critical parameter excess. It returns explicit Laurent coefficients and the requested coverage; unexpanded derivatives and vendor functions are rejected.";
Begin["`Private`"];
$hypergeometricLaurentCache=<||>;
ExpandHypergeometricLaurentSeries[expression_,e_Symbol,upper_Integer]:=Module[
 {key={expression,e,upper},hyp,hpl,helper,dir,input,output,run,result,attempt},
 If[KeyExistsQ[$hypergeometricLaurentCache,key],Return[$hypergeometricLaurentCache[[Key[key]]]]];
 hyp=Environment["FEYNFACET_HYPEXP_PATH"];hpl=Environment["FEYNFACET_HPL_PATH"];
 If[!StringQ[hyp]||hyp==="",hyp=FileNameJoin[{$feynFacetRoot,"Addon","Mathematica_Addon","HypExp"}]];
 If[!StringQ[hpl]||hpl==="",hpl=FileNameJoin[{$feynFacetRoot,"Addon","Mathematica_Addon","HPL"}]];
 If[!FileExistsQ[FileNameJoin[{hpl,"HPL.m"}]]&&
   FileExistsQ[FileNameJoin[{hpl,"HPL-2.0","HPL.m"}]],hpl=FileNameJoin[{hpl,"HPL-2.0"}]];
 helper=FileNameJoin[{$feynFacetRoot,"FeynFacet","Tools","hypergeometric_series_worker.wls"}];
 If[!AllTrue[{FileNameJoin[{hyp,"HypExp.m"}],FileNameJoin[{hpl,"HPL.m"}],helper},FileExistsQ],
  Return[Failure["HypExpDependenciesUnavailable",<|"HypExpDirectory"->hyp,"HPLDirectory"->hpl|>]]];
 dir=CreateDirectory[];input=FileNameJoin[{dir,"Input.wl"}];output=FileNameJoin[{dir,"Output.wl"}];
 FeynFacet`FamilyArtifactWrite[<|"Expression"->expression,"DimensionalRegulator"->e,"UpperOrder"->upper|>,input];
 result=Internal`WithLocalSettings[Null,
  run=RunProcess[{"wolframscript","-file",helper,input,output,hpl,hyp}];
  If[Lookup[run,"ExitCode",-1]=!=0||!FileExistsQ[output]||
    !StringContainsQ[Lookup[run,"StandardOutput",""],"COMPLETED HYPERGEOMETRIC SERIES"],
   Failure["IsolatedHypergeometricExpansionFailed",<|"Process"->run|>],
   FeynFacet`FamilyArtifactRead[output]],
  If[DirectoryQ[dir],DeleteDirectory[dir,DeleteContents->True]]];
 If[!AssociationQ[result]||Lookup[result,"Status",None]=!="ExplicitHypergeometricSeries",
  Return[If[FailureQ[result],result,Failure["ExplicitHypergeometricSeriesRequired",<|"Result"->result|>]]]];
 If[Lookup[result,"DimensionalRegulator",None]=!=e||Lookup[result,"KnownThroughOrder",None]=!=upper||
  !FreeQ[result["Polynomial"],e^(a_/;!IntegerQ[a])|_SeriesData|_HypergeometricPFQ|_Hypergeometric2F1|
   _Integrate|_Inactive|_Missing|_Failure]||Cases[result["Polynomial"],_Derivative,{0,Infinity},Heads->True]=!={},
  Return[Failure["UnresolvedHypergeometricLaurentCoefficient",<||>]]];
 AssociateTo[$hypergeometricLaurentCache,key->result];result
];
End[];EndPackage[];
