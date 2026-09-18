Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
card=FeynFacet`ReadContributionCard[root<>"/Projects/SIDIS_HighPT_TT_SpinTransfer/Raw/NLO/q-q","Real.SameFlavor"];
request=FeynFacet`ProjectAssemblyRequest[card];
data=FeynFacet`FamilyArtifactRead[card["WorkDirectory"]<>"/IntegralDecomposition.wl"];
source=FeynFacet`FamilyArtifactRead[card["WorkDirectory"]<>"/AngularDensity.wl"];
If[!AssociationQ[data]||!AssociationQ[source],Print["Completed angular density required"];Exit[1]];
e=request["DimensionalRegulator"];
points={{x->1/3,z->2/5,w->3/4,e->-13/4},{x->3/5,z->1/4,w->2/3,e->-17/4}};
normalization=request["CurrentNormalization"]Lookup[card,"SymmetryFactor",1]Lookup[card,"FlavorMultiplicity",1];
fixed={Q2->1,muR2->1,FeynCalc`CA->3,FeynCalc`CF->4/3,FeynCalc`TR->1/2,
 eU->2/3,eD->-1/3,nU->2,nD->3,FeynFacet`\[Alpha]s->1};
Do[
 rules=Join[point,fixed];
 (* Directly sum the retained individual primitive values, without the
    optimized global seed collector or its rational cancellations. *)
 iv=Map[Function[row,N[row["AnalyticExpression"]/.rules,45]],source["IntegralEvaluations"]];
 FTTest`FTAssert["all primitive values are numerical",AllTrue[Values[iv],NumericQ]];
 Do[
  direct=Total[KeyValueMap[(#2/.D->4-2e)iv[#1]&,data["Coefficients"][name]]];
  direct=N[FeynFacet`SubstituteScalarPowers[normalization direct,request["BareCouplingRules"]]/.rules,35];
  compact=N[source["Values"][name]/.rules,35];
  residual=Abs[direct-compact]/Max[1,Abs[direct],Abs[compact]];
  Print["ANGULAR COMBINATION RESIDUAL ",name," ",residual];
  FTTest`FTAssert["collected density agrees with the original primitive sum",NumericQ[residual]&&residual<10^-25],
 {name,Keys[source["Values"]]}],{point,points}];
Print["ANGULAR COMBINATION TEST COMPLETE"];FTTest`FTReport[];
