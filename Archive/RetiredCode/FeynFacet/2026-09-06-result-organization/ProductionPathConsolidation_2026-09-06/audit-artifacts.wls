$HistoryLength=0;
root="/home/maxzhang/factorization-and-loops";
(* This fresh standalone session refuses reads from retired source. *)
Unprotect[Get,Import];
Get[p_String /; StringContainsQ[p,"Private_Backup"]] := (Print["BACKUP READ REFUSED"];Abort[]);
Import[p_String /; StringContainsQ[p,"Private_Backup"],rest___] := (Print["BACKUP READ REFUSED"];Abort[]);
Protect[Get,Import];
Get[root<>"/FeynFacet/FiniteSolutionData.wl"];
campaign=root<>"/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Stage1And2_2026-09-06";
files=Sort[FileNames["solution.wxf",campaign,Infinity]];
retiredNames={"AttachBoundarySelectorsToRationalEpsilonDependentBlock","BoundaryCoefficientOperatorProductQ","BuildSingularPointMatchingData","CanonicalizeClasses","ChangeRationalEpsilonDependentBlockSolutionBasePoint","ChooseRegularBasePointAndFirstPathParameterScale","ClassifyRequestedOutputIteratedIntegralCoefficientInputs","ComposeBoundaryFunctionSolutionMapWithTangentialEvolution","ComposeFactorizedFiniteFieldBoundaryFunctionSolutionMapWithTangentialEvolution","ComposeIteratedIntegralCoefficientMapsAcrossSingularPoint","ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs","ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix","ConstructBoundaryCoefficientOperatorProduct","ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs","ConstructMasterIntegralEpsilonExpansionCoefficient","ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap","ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator","FactorizedFiniteFieldBoundarySolutionCompositionQ","FindRequestedOutputIteratedIntegralCoefficientInputFiles","IteratedIntegralCoefficientOperatorForRequestedOutputsQ","LibraFamilyEpsForm","RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ","RationalEpsilonDependentBlockSolutionQ","ReconstructIteratedIntegralCoefficientMatricesForRequestedOutputs","SelectValidatedFamilyDLogEpsilonFormInputs","SingularPointMatchingDataQ","SolveRationalEpsilonDependentBlockByVariationOfConstants","TangentialBoundaryEvolutionOperatorQ","ValidateBasisTransformationEpsilonValuationsAtRationalPoints","VerifyRationalEpsilonDependentBlockSolution","WriteRequestedOutputIteratedIntegralCoefficientInputSummary"};
checks=Table[
 data=FeynFacetSolution`ReadMasterIntegralSolution[DirectoryName[file]];
 expressions=Values[KeyTake[data,{"Coefficients","MasterIntegralCoefficients",
   "AlgebraicDefinitions","KernelDefinitions","IntegralDefinitions"}]];
 names=DeleteDuplicates[Cases[expressions,s_Symbol:>SymbolName[Unevaluated[s]],{0,Infinity},Heads->True]];
 <|"Family"->data["Family"],"Read"->AssociationQ[data],
   "RetiredSymbols"->Intersection[names,retiredNames],
   "PrivateSymbols"->DeleteDuplicates[Cases[expressions,s_Symbol /;
      StringStartsQ[Context[Unevaluated[s]],"FeynFacet`Private`"]:>
        ToString[Unevaluated[s],InputForm],{0,Infinity},Heads->True]]|>,
 {file,files}];
ok=Length[files]===91 && AllTrue[checks,
 TrueQ[#["Read"]] && #["RetiredSymbols"]==={} && #["PrivateSymbols"]==={}&];
Print["STORED ARTIFACT DEPENDENCY AUDIT count=",Length[checks]," passed=",ok];
Export["/tmp/feynfacet-production-consolidation-20260906/artifact-dependencies.wxf",checks,"WXF"];
Exit[If[ok,0,1]];
