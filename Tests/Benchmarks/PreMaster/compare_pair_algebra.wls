$HistoryLength=0;$MaxExtraPrecision=50;SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],4];args=Rest[$ScriptCommandLine];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
input=Get[args[[1]]];output=ExpandFileName[args[[2]]];If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
Options[referenceCalc]=Options[FeynCalc`Calc];Attributes[referenceCalc]=Attributes[FeynCalc`Calc];
DownValues[referenceCalc]=DownValues[FeynCalc`Calc]/.FeynCalc`Calc->referenceCalc;
algebraRows={};
Options[compareCapturedAlgebra]=Options[referenceCalc];
compareCapturedAlgebra[expr_,opts:OptionsPattern[]]:=Module[{ref,seconds,candidate,quickSeconds,checkSeconds,equal,traces,prepared},
 {seconds,ref}=AbsoluteTiming[referenceCalc[expr,opts]];
 Print["TRACE_LENGTHS ",Length /@ Cases[expr,HoldPattern[FeynCalc`DiracTrace[chain_,___]]:>chain,{0,Infinity}]];
 Print["REFERENCE_CALC ",seconds," input bytes ",ByteCount[expr]," trace count ",Length[Cases[expr,_FeynCalc`DiracTrace,{0,Infinity}]]];
 (* DiracTrace handles the closed chains produced by FermionSpinSum.
    Run the ordinary simplifier afterwards for any remaining open chains. *)
 {quickSeconds,candidate}=AbsoluteTiming[
  prepared=FeynCalc`SUNSimplify[expr,Explicit->False];
  traces=DeleteDuplicates[Cases[prepared,_FeynCalc`DiracTrace,{0,Infinity}]];
  prepared=prepared/.Normal[AssociationMap[FeynCalc`DiracSimplify,traces]];
  referenceCalc[prepared,opts]];
 {checkSeconds,equal}=AbsoluteTiming[TrueQ[Expand[ref-candidate]===0]];
 AppendTo[algebraRows,<|"ReferenceSeconds"->seconds,"TraceFirstSeconds"->quickSeconds,"ExactEqual"->equal,"CheckSeconds"->checkSeconds|>];
 Put[algebraRows,output<>"/algebra.wl.tmp"];RenameFile[output<>"/algebra.wl.tmp",output<>"/algebra.wl",OverwriteTarget->True];
 Print["ALGEBRA_COMPARISON ",InputForm[Last[algebraRows]]];ref];
Clear[FeynFacet`Private`collinearContractAmplitude];
FeynFacet`Private`collinearContractAmplitude[expr_,assumptions_]:=compareCapturedAlgebra[expr,Assumptions->assumptions];
card=FeynFacet`ReadProcessCard[root<>"/"<>input["Project"],input["Card"]];
Do[setup=Join[card,<|"ForwardAmplitudes"->Join[card["ForwardAmplitudes"],<|"SelectedIndex"->pair[[1]]|>],
 "ConjugateAmplitudes"->Join[card["ConjugateAmplitudes"],<|"SelectedIndex"->pair[[2]]|>]|>];
 res=TimeConstrained[FeynFacet`CollinearFactorizePreIBP[setup],600,$Aborted];
 If[!MatchQ[res,{_,_,_,_,_List}],Print["PAIR_FAILED"];Exit[1]],{pair,input["Pairs"]}];
Print["ALGEBRA_COMPARISON_PASSED ",AllTrue[algebraRows,TrueQ[#["ExactEqual"]]&]];
Exit[If[AllTrue[algebraRows,TrueQ[#["ExactEqual"]]&],0,1]];
