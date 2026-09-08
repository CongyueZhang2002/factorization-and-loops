
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
source="/FeynFacet/Private/EpsForm/FiniteField/FiniteFieldBasisTransformationReexpression.wl";
prime=1000003;support=Tuples[Range[0,8],2];denSupport=Tuples[Range[0,2],2];
count=Length[support];outputs=32;fibres=12;
BlockRandom[SeedRandom[508913];points=RandomInteger[{2,prime-2},{count+8,2}];
 numeratorCoefficients=RandomInteger[{0,prime-1},{fibres,count,outputs}];
 denominatorCoefficients=RandomInteger[{0,prime-1},{fibres,Length[denSupport]}]];
monomials=FeynFacet`Private`finiteFieldBasisTransformationReexpressionMonomialValues[support,#,prime]& /@ points;
denMonomials=FeynFacet`Private`finiteFieldBasisTransformationReexpressionMonomialValues[denSupport,#,prime]& /@ points;
denValues=Mod[denMonomials.#,prime]& /@ denominatorCoefficients;
values=Table[Mod[(PowerMod[#,-1,prime]& /@ denValues[[i]]) Mod[monomials.numeratorCoefficients[[i]],prime],prime],{i,fibres}];
Block[{$Context="FeynFacet`Private`",$ContextPath={"System`","FeynFacet`"}},Get[DirectoryName[ExpandFileName[$InputFileName]]<>"/before"<>source]];
beforeSeconds=First[AbsoluteTiming[before=Table[
 FeynFacet`Private`finiteFieldBasisTransformationReexpressionFitNumerators[points,values[[i]],support,denSupport,denominatorCoefficients[[i]],prime,4],{i,fibres}]]];
Block[{$Context="FeynFacet`Private`",$ContextPath={"System`","FeynFacet`"}},Get[root<>source]];
afterSeconds=First[AbsoluteTiming[
 data=FeynFacet`Private`finiteFieldBasisTransformationReexpressionNumeratorData[points,support,prime,4];
 denMatrix=FeynFacet`Private`finiteFieldBasisTransformationReexpressionMonomialValues[denSupport,#,prime]& /@ points;
 den=Mod[denMatrix.#,prime]& /@ denominatorCoefficients;
 after=FeynFacet`Private`finiteFieldBasisTransformationReexpressionFitNumeratorBatch[data,values,den,prime]]];
ok=And@@Table[before[[i]]["NumeratorCoefficients"]===after[[i]]["NumeratorCoefficients"]===numeratorCoefficients[[i]],{i,fibres}];
damaged=values;damaged[[3,First[data["ValidationIndices"]],7]]+=1;
bad=FeynFacet`Private`finiteFieldBasisTransformationReexpressionFitNumeratorBatch[data,damaged,den,prime];
damageDetected=Lookup[bad[[3]],"FailedOutputs",{}]==={7} &&
 And@@Table[If[i===3,True,bad[[i]]===after[[i]]],{i,fibres}];
report=<|"Scope"->"Isolated numerator fitting with 32 outputs, corresponding to four entries in an eight-dimensional square-root algebra; not a complete family canonicalization.",
 "BeforeSeconds"->beforeSeconds,"AfterSeconds"->afterSeconds,"SameExactCoefficients"->ok,
 "DamagedHeldOutRowDetected"->damageDetected,"SupportCount"->count,"PointCount"->Length[points],
 "EpsilonSampleCount"->fibres,"OutputCount"->outputs|>;
Export[DirectoryName[ExpandFileName[$InputFileName]]<>"/stage1-numerators.json",report,"RawJSON"];Print[InputForm[report]];
(* A complete source reconstruction with all eight grades of three independent
   roots. The denominator is epsilon-dependent, so lifting is also exercised. *)
Clear[p,q,x,y,eps];
roots=Table[<|"Generator"->Sqrt[r],"QuadraticRadicand"->r|>,{r,{1+x,1+y,1+x+y}}];
images={x+Sqrt[1+x]+Sqrt[1+x+y],y+Sqrt[1+y]};
gauge={{(1+p^2 q+eps p)/(1+eps),(q+p+eps p q)/(1+eps)}};
run[]:=FeynFacet`Private`reexpressBasisTransformationInSourceVariablesFiniteField[
 gauge,1+eps,{p,q},images,{x,y},eps,roots,
 "Primes"->{1000003,2147483423},"MinimumPrimeCount"->2,"MaximumPrimeCount"->2,
 "MaximumKinematicTotalDegree"->6,"MaximumEpsilonTotalDegree"->6,
 "HeldOutPointCount"->4,"SymbolicPreDispatchSeconds"->0];
Block[{$Context="FeynFacet`Private`",$ContextPath={"System`","FeynFacet`"}},Get[DirectoryName[ExpandFileName[$InputFileName]]<>"/before"<>source]];
bt=First[AbsoluteTiming[b=run[]]];
Block[{$Context="FeynFacet`Private`",$ContextPath={"System`","FeynFacet`"}},Get[root<>source]];
at=First[AbsoluteTiming[a=run[]]];
same=Lookup[b,"Status",None]==="FiniteFieldBasisTransformationReexpressionConstructed" &&
 Lookup[a,"Status",None]==="FiniteFieldBasisTransformationReexpressionConstructed" && b["Result"]===a["Result"];
expected=gauge/.Thread[{p,q}->images];
residual=If[same,Flatten[Map[
 FeynFacet`Private`multiquadraticFieldDecompose[#,roots]&,
 a["Result"]-expected,{2}]],{$Failed}];
exact=FreeQ[residual,$Failed] && AllTrue[residual,Together[#]===0&];
r3=<|"Scope"->"Complete synthetic rank-three source-coordinate reconstruction, not a physical family.",
 "BeforeSeconds"->bt,"AfterSeconds"->at,"SameExactResult"->same,"AllEightGradesZeroResidual"->exact,
 "BeforePrimeRecords"->Lookup[b,"PrimeRecords",{}],"AfterPrimeRecords"->Lookup[a,"PrimeRecords",{}]|>;
Export[DirectoryName[ExpandFileName[$InputFileName]]<>"/stage1-rank3.json",KeyDrop[r3,{"BeforePrimeRecords","AfterPrimeRecords"}],"RawJSON"];Print[InputForm[KeyDrop[r3,{"BeforePrimeRecords","AfterPrimeRecords"}]]];
If[!TrueQ[ok && damageDetected && same && exact],Print[{a,b}];Exit[1]];
