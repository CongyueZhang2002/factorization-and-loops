$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],4];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
base=root<>"/Archive/ProjectLayouts/2026-09-08/ppHX_NLO_qqprime/Results/Validation/PreMasterOptimization_2026-09-08";
rows={};record[label_,condition_,seconds_:0.]:=(AppendTo[rows,<|"Check"->label,"Passed"->TrueQ[condition],"Seconds"->seconds|>];Print[InputForm[Last[rows]]]);
old=Get[base<>"/BaselineCoefficients/CoefficientResult.wl"];new=Get[base<>"/FinalCoefficients/CoefficientResult.wl"];
semanticKeys={"Expression","Masters","Remainder","PreFactor","HadronicNormalization","FractionMeasure","PhaseSpace","Topologies","ReverseRules","DimensionRule"};
record["Exact reconstructed coefficient and master equality",KeyTake[old,semanticKeys]===KeyTake[new,semanticKeys]];
Do[old=Get[base<>"/AcceptedHardFunctions/"<>spin<>"_HardFunction.wl"];new=Get[root<>"/Archive/ProjectLayouts/2026-09-08/ppHX_NLO_qqprime/Results/"<>spin<>"_HardFunction.wl"];
 record[spin<>" final hard function byte-equivalent Mathematica expression",old===new],{spin,{"UU","LL","TT"}}];
(* Code provenance changes on purpose; every other family field is retained. *)
pairSemanticPayload[value_List] := {Take[value,4],
  Function[family, Append[KeyDrop[family,"AnalyticContext"],
    "AnalyticContext" -> KeyDrop[family["AnalyticContext"],{"FeynFacetSourceHash","Fingerprint"}]]] /@ Last[value]};
nnloBase=root<>"/Archive/ProjectLayouts/2026-09-08/ppHX_NNLO_DoubleReal/Results/Validation/PreMasterOptimization_2026-09-08";
Do[old=Get[nnloBase<>"/BaselineHardPairs/pair_"<>pair<>".wl"];new=Get[nnloBase<>"/OptimizedHardPairs/pair_"<>pair<>".wl"];
 record["NNLO pair "<>pair<>" exact mathematical equality",pairSemanticPayload[old]===pairSemanticPayload[new]],{pair,{"27_24","27_19"}}];
Do[context=FeynFacet`Private`kiraStreamReadRecord[root<>"/Archive/ProjectLayouts/2026-09-08/ppHX_NNLO_DoubleReal/Results/"<>resultName<>"/KiraStream/Context.wxf"];
 {seconds,passed}=AbsoluteTiming[FeynFacet`Private`checkCompletedPropagators[context["Setup"],context["Topologies"],context["Masters"]]];
 record[resultName<>" positive denominator support of "<>ToString[Length[context["Masters"]]]<>" masters",passed===True,seconds],
 {resultName,{"UU_08_10_canonical","UU_Ghost_08_10_shared"}}];
Put[rows,base<>"/ExactComparisons.wl.tmp"];RenameFile[base<>"/ExactComparisons.wl.tmp",base<>"/ExactComparisons.wl",OverwriteTarget->True];
Print["PREMASTER_COMPARISONS_PASSED ",AllTrue[rows,TrueQ[#["Passed"]]&]];Exit[If[AllTrue[rows,TrueQ[#["Passed"]]&],0,1]];
