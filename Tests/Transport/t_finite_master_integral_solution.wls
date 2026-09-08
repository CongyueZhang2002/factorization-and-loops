#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]];
Clear[xx,yy,eps];
request[vars_,orders_] := <|"BasePoint"->ConstantArray[1/5,Length[vars]],
  "RequestedEpsilonOrders"->orders,"AnalyticDomain"->"A simply connected neighborhood of the base point containing the straight paths.",
  "BranchPrescription"->"Analytic continuation from principal values at the base point."|>;
system[vars_,a_] := <|"KinematicVariables"->vars,"DimensionalRegulator"->eps,
  "ConnectionMatrices"->a|>;
Clear[expandRow];
expandRow[r_,row_,order_] := Module[{v,aa,ff,kk},
  v=MasterIntegralSolutionCoefficient[r,row,order];
  aa=r["AlgebraicDefinitions"]; ff=r["IntegralDefinitions"];
  Do[v=v/.FeynFacetSolution`a[j]->aa[[j]],{j,Length[aa],1,-1}];
  Do[With[{f=ff[[j]]},
    v=v/.FeynFacetSolution`F[j,u_] :>
      Inactive[Integrate][f["Integrand"],{f["IntegrationVariable"],0,u}]],
    {j,Length[ff],1,-1}];
  kk=FeynFacet`Private`solutionResolveKernelDefinitions[r["KernelDefinitions"]];
  v=v/.FeynFacetSolution`K[j_Integer,u_]:>
    (kk[[j]]/.r["KernelDefinitions"][[j,"Parameter"]]->u);
  Simplify[Activate[v]]
];
sol=ConstructMasterIntegralSolution[system[{xx,yy},{{{2 eps xx}},{{eps}}}],
  request[{xx,yy},Range[0,3]]];
Print["scalar result ",If[FailureQ[sol],sol,sol["Status"]]];
FTAssert["multivariate finite solution",MasterIntegralSolutionQ[sol]];
d=xx^2-1/25+yy-1/5;
FTAssert["three nontrivial coefficients agree with exponential",
 And@@Table[expandRow[sol,1,k]==={d^k/Factorial[k]} ||
   Simplify[expandRow[sol,1,k]-{d^k/Factorial[k]}]==={0},{k,0,3}]];
FTAssert["both PDEs",And@@Table[
  Simplify[D[expandRow[sol,1,k],xx]-2 xx expandRow[sol,1,k-1]]==={0} &&
  Simplify[D[expandRow[sol,1,k],yy]-expandRow[sol,1,k-1]]==={0},{k,1,3}]];
FTAssert["normalization",And@@Table[(expandRow[sol,1,k]/.{xx->1/5,yy->1/5})===
  {If[k===0,1,0]},{k,0,3}]];
a0={{0,0,0},{1,0,0},{0,xx,0}};
tri=ConstructMasterIntegralSolution[system[{xx},{a0}],request[{xx},{0,1}]];
FTAssert["epsilon-zero strictly triangular system solved",
 MasterIntegralSolutionQ[tri] &&
 Simplify[expandRow[tri,3,0]-{xx^3/3-xx^2/10+1/750,xx^2/2-1/50,1}]==={0,0,0}];
FTAssert["zero high orders stored explicitly",expandRow[tri,3,1]==={0,0,0}];
nmat={{0,0},{1,0}};
tt={{1,xx/eps},{0,1}};
basisSys=Join[system[{xx,yy},{eps nmat,eps nmat}],<|"BasisTransformationMatrix"->tt|>];
bs=ConstructMasterIntegralSolution[basisSys,request[{xx,yy},Range[-1,2]]];
expected=Expand[tt.(IdentityMatrix[2]+eps (xx+yy-2/5)nmat).
  Inverse[tt/.xx->1/5]];
FTAssert["epsilon-pole basis transformation and initial inverse convolution",
 And@@Flatten[Table[Simplify[expandRow[bs,row,k]-
  Coefficient[expected[[row]],eps,k]]==={0,0},{row,2},{k,-1,2}]]];
hh={{EllipticK[xx]}};
ell=ConstructMasterIntegralSolution[
 Join[system[{xx},{D[hh,xx].Inverse[hh]+eps {{xx}}}],
  <|"HomogeneousFundamentalMatrix"->hh|>],request[{xx},{0,1}]];
FTAssert["supplied elliptic homogeneous solution",
 MasterIntegralSolutionQ[ell] &&
 Simplify[expandRow[ell,1,1]-{EllipticK[xx]/EllipticK[1/5]*(xx^2-1/25)/2}]==={0}];
bad=ConstructMasterIntegralSolution[system[{xx,yy},{{{eps yy}},{{0}}}],
 request[{xx,yy},{0,1}]];
FTAssert["nonflat two-variable system rejected",MatchQ[bad,Failure["ConnectionNotFlat",_]]];
bad=ConstructMasterIntegralSolution[system[{xx},{{{1/eps}}}],request[{xx},{0,1}]];
FTAssert["nonterminating Laurent construction rejected",
 MatchQ[bad,Failure["EpsilonRescalingHasNegativeCycle",_]]];
bad=ConstructMasterIntegralSolution[system[{xx},{{{1}}}],request[{xx},{0,1}]];
FTAssert["scalar homogeneous solution is constructed automatically",
 MasterIntegralSolutionQ[bad] &&
 Simplify[expandRow[bad,1,0]-{Exp[xx-1/5]}]==={0}];
FTAssert["operator-only old solution rejected",!MasterIntegralSolutionQ[
 <|"DataType"->"MasterIntegralSolution","SchemaVersion"->2,
   "SolutionRepresentation"->"OrderedSparseCoefficientOperatorProduct"|>]];
corrupt=sol; corrupt["IntegralDefinitions"]=ReplacePart[corrupt["IntegralDefinitions"], {1,"Integrand"}->FeynFacetSolution`F[1,FeynFacetSolution`t1]];
FTAssert["cyclic function definition rejected",!MasterIntegralSolutionQ[corrupt]];
FTAssert["unstored coefficient rejected",FailureQ[MasterIntegralSolutionCoefficient[sol,1,4]]];
out=FileNameJoin[{$TemporaryDirectory,"feynfacet-finite-solution-test"}];
WriteMasterIntegralSolution[bs,out];
FTAssert["portable separate coefficient files",FileExistsQ[FileNameJoin[{out,"coefficients_order_-1.m"}]] &&
 Get[FileNameJoin[{out,"functions.m"}]]===bs["IntegralDefinitions"]];

expanded=ExpandMasterIntegralSolutionInInitialConstants[sol,{0},{2}];
FTAssert["initial-constant epsilon convolution stored",
 AssociationQ[expanded] &&
 (1/.expanded["MasterIntegralCoefficients"][2])===
   FeynFacetSolution`C[1,2]+
   (MasterIntegralSolutionCoefficient[sol,1,1][[1]]) FeynFacetSolution`C[1,1]+
   (MasterIntegralSolutionCoefficient[sol,1,2][[1]]) FeynFacetSolution`C[1,0]];
FTAssert["missing convolution orders are not silently omitted",
 FailureQ[ExpandMasterIntegralSolutionInInitialConstants[sol,{-2},{3}]]];
unknown=ConstructMasterIntegralSolution[
 Join[system[{xx},{{{D[unknownH[xx],xx]/unknownH[xx]}}}],
  <|"HomogeneousFundamentalMatrix"->{{unknownH[xx]}}|>],request[{xx},{0}]];
FTAssert["an undefined homogeneous function is not accepted as a solution",
 MatchQ[unknown,Failure["UnspecifiedSpecialFunctionOrUnevaluatedOperation",_]]];
corrupt=sol;
corrupt["IntegralDefinitions"]=ReplacePart[corrupt["IntegralDefinitions"],
 {1,"Integrand"}->lazyGenerator[xx]];
FTAssert["undefined generator in a stored integrand rejected",!MasterIntegralSolutionQ[corrupt]];

onlyNegative=ConstructMasterIntegralSolution[system[{xx},{{{eps}}}],request[{xx},{-2,-1}]];
FTAssert["orders below the Laurent lower bound are explicit zero",
 MasterIntegralSolutionQ[onlyNegative] &&
 MasterIntegralSolutionCoefficient[onlyNegative,1,-2]==={0}];
mixed=ConstructMasterIntegralSolution[
 system[{xx},{{{0,eps xx},{eps^2,0}}}],request[{xx},Range[0,3]]];
FTAssert["noncommuting kernels at different epsilon orders",
 MasterIntegralSolutionQ[mixed] &&
 Simplify[expandRow[mixed,1,3]-{xx^3/3-xx^2/10+1/750,0}]==={0,0} &&
 Simplify[expandRow[mixed,2,3]-{0,xx^3/6-xx/50+1/375}]==={0,0}];

autoRequest=Join[KeyDrop[request[{xx},{0}],"RequestedEpsilonOrders"],
 <|"RequestedMasterIntegralEpsilonOrders"->{0,1},
   "InitialConstantLaurentLowerBounds"->{-1}|>];
auto=ConstructMasterIntegralSolution[system[{xx},{{{eps}}}],autoRequest];
FTAssert["master demands automatically determine the fundamental-matrix range",
 MasterIntegralSolutionQ[auto] && auto["RequestedEpsilonOrders"]==={0,1,2} &&
 auto["RequestedMasterIntegralEpsilonOrders"]==={0,1} &&
 KeyExistsQ[auto,"MasterIntegralCoefficients"]];

badConstants=auto;
badConstants["MasterIntegralCoefficients"]=<|0->{1->lazyGenerator[xx]},1->{1->0}|>;
FTAssert["undefined generator in final master coefficients rejected",
 !MasterIntegralSolutionQ[badConstants]];
badConstants["MasterIntegralCoefficients"]=<|0->{1->FeynFacetSolution`C[1,0]^2},1->{1->0}|>;
FTAssert["nonlinear dependence on initial constants rejected",!MasterIntegralSolutionQ[badConstants]];
autoDir=FileNameJoin[{$TemporaryDirectory,"feynfacet-finite-auto-solution-test"}];
WriteMasterIntegralSolution[auto,autoDir];
FTAssert["actual master epsilon coefficients are written",
 Get[FileNameJoin[{autoDir,"master_integrals_order_0.m"}]]===auto["MasterIntegralCoefficients"][0]];

movingPole=ConstructMasterIntegralSolution[system[{xx},{{{eps/(xx-1/5+eps)}}}],
 request[{xx},{0,1}]];
FTAssert["a moving epsilon pole cannot invalidate the ordinary base point silently",
 MatchQ[movingPole,Failure["BasePointSingularForEpsilonExpandedConnection",_]]];

negative=ConstructMasterIntegralSolution[
 system[{xx},{{{0,1/eps},{eps^2,0}}}],request[{xx},Range[-1,2]]];
FTAssert["a positive-weight cycle with a negative edge has finite coefficients",
 MasterIntegralSolutionQ[negative] &&
 Simplify[expandRow[negative,1,-1]-{0,xx-1/5}]==={0,0} &&
 Simplify[expandRow[negative,1,1]-{(xx-1/5)^2/2,(xx-1/5)^5/120}]==={0,0}];
reordered=ConstructMasterIntegralSolution[
 system[{xx},{{{0,1},{0,0}}}],request[{xx},{0}]];
FTAssert["acyclic epsilon-zero systems need not arrive in triangular order",
 Simplify[expandRow[reordered,1,0]-{1,xx-1/5}]==={0,0}];

verified=VerifyMasterIntegralSolution[negative,"IdentityCheck"->"Exact"];
FTAssert["generic identities verify original-basis coefficients with epsilon poles",
 AssociationQ[verified] && verified["Status"]==="FiniteSolutionCoefficientIdentitiesVerified"];
tampered=negative;
tampered["Coefficients"]=ReplacePart[tampered["Coefficients"],{1,1,2,1}->999];
FTAssert["generic verifier rejects changed output coefficients",
 FailureQ[VerifyMasterIntegralSolution[tampered]]];
Get[FileNameJoin[{root,"FeynFacet", "Solution.m"}]];
WriteMasterIntegralSolution[negative,FileNameJoin[{$TemporaryDirectory,"finite-negative-quadrature"}]];
read=FeynFacetSolution`ReadMasterIntegralSolution[FileNameJoin[{$TemporaryDirectory,"finite-negative-quadrature"}]];
numerical=FeynFacetSolution`EvaluateMasterIntegralSolution[read,{2/5},"QuadratureOrder"->8];
FTAssert["standalone quadrature evaluates actual finite nested integrals",
 AssociationQ[numerical] &&
 Abs[numerical["EpsilonCoefficients"][1][[1,2]]-N[(1/5)^5/120,50]]<10^-35];

nilpotent={{1,1},{-1,-1}};
cancelledCycle=ConstructMasterIntegralSolution[
 system[{xx},{nilpotent/eps}],request[{xx},{-1,0}]];
FTAssert["a constant nilpotent negative cycle is resolved by a common flag",
 MasterIntegralSolutionQ[cancelledCycle] &&
 Simplify[expandRow[cancelledCycle,1,-1]-(xx-1/5){1,1}]==={0,0} &&
 AssociationQ[VerifyMasterIntegralSolution[cancelledCycle]]];

sampled=VerifyMasterIntegralSolution[negative];
FTAssert["numerical verification is explicitly distinguished from a generic proof",
 AssociationQ[sampled] && sampled["IdentityCheckMethod"]==="NumericalPoints" &&
 sampled["ExactGenericIdentityProof"]===False];
FTAssert["exact symbolic verification remains available",
 TrueQ[verified["ExactGenericIdentityProof"]]];
corruptK=negative;
corruptK["KernelDefinitions"]=ReplacePart[corruptK["KernelDefinitions"],
 {1,"Expression"}->17];
FTAssert["sampled verification detects a changed explicit kernel",
 FailureQ[VerifyMasterIntegralSolution[corruptK]]];
wrongSource=Join[system[{xx},{{{eps}}}],<|"OriginalConnectionMatrices"->{{{2 eps}}}|>];
FTAssert["sampled input-basis checking rejects an inconsistent original DE",
 FailureQ[ConstructMasterIntegralSolution[wrongSource,request[{xx},{0,1}]]]];
essential=ConstructMasterIntegralSolution[
 system[{xx},{{{Exp[1/eps]}}}],request[{xx},{0,1}],
 "AutomaticPreparation"->False];
FTAssert["an essential regulator singularity is not a finite Laurent expansion",FailureQ[essential]];

cacheDir=FileNameJoin[{$TemporaryDirectory,"finite-integration-block-cache"}];
preparedScalar=PrepareDifferentialSystemForFiniteIntegration[system[{xx},{{{1}}}],
 "IntermediateOutputDirectory"->cacheDir];
cachedScalar=FamilyArtifactRead[FileNameJoin[{cacheDir,"block_1.m"}]];
FTAssert["reusable zero-order reductions preserve the input differential equation",
 AssociationQ[PrepareDifferentialSystemForFiniteIntegration[system[{xx},{{{1}}}],
 "BlockReductionData"->{cachedScalar}]]];
FTAssert["a zero-order reduction from another equation is rejected",
 FailureQ[PrepareDifferentialSystemForFiniteIntegration[system[{xx},{{{2}}}],
 "BlockReductionData"->{cachedScalar}]]];

algebraicZero=xx/(xx+1)-1+1/(xx+1);
zeroKernel=ConstructMasterIntegralSolution[
 system[{xx},{{{0,algebraicZero},{1,0}}}],request[{xx},{0}],
 "AutomaticPreparation"->False];
FTAssert["verified zero entries become literal zeros before naming kernels",
 zeroKernel["KernelMatrices"][0][[1,2]]===0 &&
 AssociationQ[VerifyMasterIntegralSolution[zeroKernel,"IdentityCheck"->"Exact"]]];
preparedNegative=PrepareDifferentialSystemForFiniteIntegration[
 system[{xx},{{{0,1/eps},{eps^2,0}}}]];
appliedNegative=ApplyFiniteIntegrationPreparation[
 system[{xx},{{{0,1/eps},{eps^2,0}}}],preparedNegative];
conjugatedNegative=ConstructMasterIntegralSolution[appliedNegative,
 request[{xx},Range[-1,2]],"AutomaticPreparation"->False];
FTAssert["coefficient-wise basis transformation agrees with direct expansion",
 MasterIntegralSolutionQ[conjugatedNegative] &&
 And@@Flatten[Table[
 Simplify[expandRow[conjugatedNegative,row,k]-expandRow[negative,row,k]]==={0,0},
 {row,2},{k,-1,2}]]];
FTAssert["coefficient-wise preparation satisfies the original DE",
 AssociationQ[VerifyMasterIntegralSolution[conjugatedNegative,"IdentityCheck"->"Exact"]]];

FTAssert["exact coefficient identities do not promote sampled flatness to proof",
 VerifyMasterIntegralSolution[negative,"IdentityCheck"->"Exact",
   "RecheckFlatness"->False]["ExactGenericIdentityProof"]===False];
FTReport[];








