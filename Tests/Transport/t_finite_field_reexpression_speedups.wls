
#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
prime=1000003;support=Tuples[Range[0,9],2];denSupport=Tuples[Range[0,2],2];
count=Length[support];outputs=3;
BlockRandom[SeedRandom[594190];points=RandomInteger[{2,prime-2},{count+8,2}];
 numerators=RandomInteger[{0,prime-1},{count,outputs}];
 denominator=RandomInteger[{1,prime-1},Length[denSupport]]];
monomials=FeynFacet`Private`finiteFieldBasisTransformationReexpressionMonomialValues[support,#,prime]& /@ points;
denMonomials=FeynFacet`Private`finiteFieldBasisTransformationReexpressionMonomialValues[denSupport,#,prime]& /@ points;
denValues=Mod[denMonomials.denominator,prime];
values=Mod[(PowerMod[#,-1,prime]& /@ denValues) Mod[monomials.numerators,prime],prime];
fit=FeynFacet`Private`finiteFieldBasisTransformationReexpressionFitDenominator[
 points,values,Range[outputs],support,denSupport,prime];
FTAssert["Schur complement recovers the exact normalized denominator",
 fit["DenominatorCoefficients"]===Mod[denominator PowerMod[First[denominator],-1,prime],prime] &&
 fit["NumeratorUnknownsEliminated"] && fit["SolvedUnknownCount"]===Length[denSupport]];
data=FeynFacet`Private`finiteFieldBasisTransformationReexpressionNumeratorData[points,support,prime,4];
all=FeynFacet`Private`finiteFieldBasisTransformationReexpressionFitNumeratorBatch[
 data,{values,values},{denValues,denValues},prime];
FTAssert["batched right-hand sides recover every numerator exactly",
 And@@(#["NumeratorCoefficients"]===numerators& /@ all)];
badValues=values;badValues[[First[data["ValidationIndices"]],2]]+=1;
bad=FeynFacet`Private`finiteFieldBasisTransformationReexpressionFitNumeratorBatch[
 data,{values,badValues},{denValues,denValues},prime];
FTAssert["a damaged unused row fails only its own epsilon sample",
 bad[[1]]===all[[1]] && Lookup[bad[[2]],"FailedOutputs",{}]==={2}];
badDen=denValues;badDen[[1]]=0;
bad=FeynFacet`Private`finiteFieldBasisTransformationReexpressionFitNumeratorBatch[
 data,{values,values},{badDen,denValues},prime];
FTAssert["a singular denominator cannot corrupt neighboring fits",
 Lookup[bad[[1]],"Status",None]==="FiniteFieldBasisTransformationReexpressionReducedDenominatorSingular" &&
 bad[[2]]===all[[2]]];
(* The caller may explicitly request no extra rows. *)
squareData=FeynFacet`Private`finiteFieldBasisTransformationReexpressionNumeratorData[
 points[[data["ConstructionIndices"]]],support,prime,0];
square=FeynFacet`Private`finiteFieldBasisTransformationReexpressionFitNumeratorBatch[
 squareData,{values[[data["ConstructionIndices"]]]},{denValues[[data["ConstructionIndices"]]]},prime];
FTAssert["a square interpolation problem preserves explicit zero validation rows",
 square[[1]]["NumeratorCoefficients"]===numerators && square[[1]]["ValidationPointCount"]===0];
(* Exact zero remains valid even with symbolic composition disabled. *)
Do[
 zeroRoots = Take[<|"Generator" -> Sqrt[#], "QuadraticRadicand" -> #|> & /@
   {1+x,1+y,1+x+y}, rank];
 zeroResult = FeynFacet`Private`reexpressBasisTransformationInSourceVariablesFiniteField[
   ConstantArray[0,{4,1}],1,{p,q},{x,y},{x,y},eps,zeroRoots,
   "SymbolicPreDispatchSeconds"->0];
 FTAssert["exact zero reconstruction, root count "<>ToString[rank],
   Lookup[zeroResult,"Status",None]==="FiniteFieldBasisTransformationReexpressionConstructed" &&
   zeroResult["Result"]===ConstantArray[0,{4,1}] &&
   zeroResult["Model"]==="ExactZero" && zeroResult["Primes"]==={} &&
   zeroResult["CoefficientRepresentation"]["GradeCount"]===2^rank &&
   Dimensions[zeroResult["CoefficientRepresentation"]["NumeratorCoefficientPairs"]]==={4,2^rank,1} &&
   AllTrue[Flatten[zeroResult["CoefficientRepresentation"]["NumeratorCoefficientPairs"]],
    #["NumeratorCoefficients"]==={0} && #["DenominatorCoefficients"]==={1}&]],
 {rank,{0,3}}];
zeroCommon = FeynFacet`Private`finiteFieldBasisTransformationReexpressionCommon[
 {{0}},1,{p,q},{x,y},{x,y},eps,{}];
FTAssert["common reconstruction also accepts exact zero without prime fits",
 zeroCommon["Result"]==={{0}} && zeroCommon["Primes"]==={}];
invalidRoots = FeynFacet`Private`reexpressBasisTransformationInSourceVariablesFiniteField[
 {{0}},1,{p,q},{x,y},{x,y},eps,{<||>},"SymbolicPreDispatchSeconds"->0];
FTAssert["zero reconstruction still validates the declared root relations",
 invalidRoots["Status"]==="FiniteFieldBasisTransformationReexpressionRootFrameInvalid"];
FTReport[];

