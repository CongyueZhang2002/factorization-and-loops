
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];
prime=1000003;support=Tuples[Range[0,8],2];denSupport=Tuples[Range[0,2],2];
count=Length[support];outputs=32;fibres=12;
BlockRandom[SeedRandom[508913];points=RandomInteger[{2,prime-2},{count+8,2}];
 numeratorCoefficients=RandomInteger[{0,prime-1},{fibres,count,outputs}];
 denominatorCoefficients=RandomInteger[{0,prime-1},{fibres,Length[denSupport]}]];
monomials=FeynFacet`Private`finiteFieldBasisTransformationReexpressionMonomialValues[support,#,prime]& /@ points;
denMonomials=FeynFacet`Private`finiteFieldBasisTransformationReexpressionMonomialValues[denSupport,#,prime]& /@ points;
denValues=Mod[denMonomials.#,prime]& /@ denominatorCoefficients;
If[!FreeQ[denValues,0],Print["Degenerate benchmark denominator"];Exit[1]];
values=Table[Mod[(PowerMod[#,-1,prime]& /@ denValues[[i]]) Mod[monomials.numeratorCoefficients[[i]],prime],prime],{i,fibres}];
baselineSeconds=First[AbsoluteTiming[baseline=Table[
 FeynFacet`Private`finiteFieldBasisTransformationReexpressionFitNumerators[points,values[[i]],support,denSupport,denominatorCoefficients[[i]],prime,4],
 {i,fibres}]]];
setupSeconds=First[AbsoluteTiming[
 indices=FeynFacet`Private`finiteFieldOffDiagonalBlockIndependentRows[Developer`ToPackedArray[monomials],count,prime];
 solver=LinearSolve[Developer`ToPackedArray[monomials[[indices]]],Modulus->prime];
 validation=Complement[Range[Length[points]],indices]]];
reusedSeconds=First[AbsoluteTiming[reused=Table[
 rhs=Developer`ToPackedArray[Mod[values[[i,indices]] denValues[[i,indices]],prime]];
 fitted=solver[rhs];
 checked=Mod[monomials[[validation]].fitted-denValues[[i,validation]] values[[i,validation]],prime]===ConstantArray[0,{Length[validation],outputs}];
 <|"NumeratorCoefficients"->fitted,"ValidationPassed"->checked|>,{i,fibres}]]];
ok=And@@Table[AssociationQ[baseline[[i]]] && baseline[[i]]["NumeratorCoefficients"]===reused[[i]]["NumeratorCoefficients"] &&
 reused[[i]]["ValidationPassed"]===True,{i,fibres}];

batchSetupSeconds=First[AbsoluteTiming[
 numeratorMatrix=Developer`ToPackedArray[FeynFacet`Private`finiteFieldBasisTransformationReexpressionMonomialValues[support,#,prime]& /@ points];
 denominatorMatrix=Developer`ToPackedArray[FeynFacet`Private`finiteFieldBasisTransformationReexpressionMonomialValues[denSupport,#,prime]& /@ points];
 chosen=FeynFacet`Private`finiteFieldOffDiagonalBlockIndependentRows[numeratorMatrix,count,prime];
 validationRows=Complement[Range[Length[points]],chosen];
 denominators=Mod[denominatorMatrix.#,prime]& /@ denominatorCoefficients;
 rightSides=Table[Mod[values[[i,chosen]] denominators[[i,chosen]],prime],{i,fibres}];
 joined=Join[Sequence@@rightSides,2]]];
batchFitSeconds=First[AbsoluteTiming[
 joinedSolution=LinearSolve[numeratorMatrix[[chosen]],joined,Modulus->prime];
 batch=Table[joinedSolution[[All,(i-1)outputs+1;;i outputs]],{i,fibres}];
 batchOK=And@@Table[batch[[i]]===baseline[[i]]["NumeratorCoefficients"] &&
  Mod[numeratorMatrix[[validationRows]].batch[[i]]-denominators[[i,validationRows]] values[[i,validationRows]],prime]===ConstantArray[0,{Length[validationRows],outputs}],{i,fibres}]]];
report=<|"Scope"->"Synthetic isolated numerator fitting; 32 outputs can represent four entries in an eight-dimensional square-root algebra. Not a family speedup measurement.",
 "SupportCount"->count,"PointCount"->Length[points],"OutputCount"->outputs,"EpsilonFibreCount"->fibres,
 "ExistingSeconds"->baselineSeconds,"ReusableFunctionSetupSeconds"->setupSeconds,
 "ReusableFunctionFitsSeconds"->reusedSeconds,
 "BatchedSetupSeconds"->batchSetupSeconds,"BatchedFitAndCheckSeconds"->batchFitSeconds,
 "SameCoefficientsAndAllResidualsZero"->(ok && batchOK)|>;
Export[DirectoryName[ExpandFileName[$InputFileName]]<>"/numerator-reuse.json",report,"RawJSON"];Print[InputForm[report]];
If[!TrueQ[ok && batchOK],Exit[1]];
