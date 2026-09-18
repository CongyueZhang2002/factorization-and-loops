(* Select exact combinations of moment insertions covered by retained rules.
   An uncovered GLI remains independent; no IBP irreducibility is inferred. *)
BeginPackage["FeynFacet`"];
ReduceMeasurementMomentCombinations::usage="ReduceMeasurementMomentCombinations[moments,reduction] applies retained exact integral rules to polynomial measurement moments and finds combinations, with coefficients independent of the measurement variable, whose unreduced integrals cancel identically. It returns measured rows in the declared basis and the matching inclusive integrals. It does not generate IBPs, evaluate inclusive values, continue endpoint integrals or establish rank on unknown DE constants.";
Begin["`Private`"];
ReduceMeasurementMomentCombinations[moments:{__Association},reduction_Association]:=Catch[Module[
 {z,e,basis,rules,images,parsed,outside,coefficientRows,matrixRows={},denominator,polynomials,
  degree,kernel,results={},coefficients,image,inclusive,terms,rows,families,signature,groups},
 If[!AllTrue[moments,Lookup[#,"Format",None]==="FeynFacet-PolynomialMeasurementMoment"&&
    TrueQ[Lookup[#,"CommonConvergenceDomainExists",False]]&],
  cutFamilyFail["VerifiedPolynomialMeasurementMomentsRequired"]];
 z=First[moments]["Variable"];e=First[moments]["DimensionalRegulator"];
 If[!AllTrue[moments,#["Variable"]===z&&#["DimensionalRegulator"]===e&&
    #["Interval"]==={0,1}&&#["ParameterConditions"]===First[moments]["ParameterConditions"]&],
  cutFamilyFail["CommonMeasurementMomentConventionsRequired"]];
 basis=Lookup[reduction,"Masters",None];rules=Lookup[reduction,"Rules",None];
 If[!MatchQ[basis,{__FeynCalc`GLI}]||!DuplicateFreeQ[basis]||!MatchQ[rules,{(_Rule)...}]||
   !DuplicateFreeQ[First/@rules],cutFamilyFail["ExactMomentReductionAndBasisRequired"]];
 families=Join[Lookup[reduction,"Families",{}],Lookup[moments,"MeasuredFamily",{}],
   Lookup[moments,"UnmeasuredFamily",{}]];
 If[!MatchQ[Lookup[reduction,"Families",{}],{__Association}]||
   !AllTrue[moments,AssociationQ[Lookup[#,"MeasuredFamily",None]]&&AssociationQ[Lookup[#,"UnmeasuredFamily",None]]&]||
   !AllTrue[families,ContainsAll[Keys[#],{"Topology","Cuts","MeasurePrefactor"}]&&
     MatchQ[#["Topology"],_FeynCalc`FCTopology]&],
  cutFamilyFail["MomentAndReductionFamilyDefinitionsRequired"]];
 signature[family_]:={Rest[List@@family["Topology"]],cutDefinitionConventions[family],
   family["Cuts"],Lookup[family,"OrdinaryPropagatorPrescriptions",None]};
 groups=GatherBy[families,First[#["Topology"]]&];
 If[!AllTrue[groups,Length[DeleteDuplicates[signature/@#]]===1&],
  cutFamilyFail["MomentReductionFamilyDefinitionMismatch"]];
 If[!ContainsAll[First[#["Topology"]]&/@families,
    Union[First/@Cases[Join[Lookup[moments,"MeasuredIntegrals"],Lookup[moments,"UnmeasuredIntegrals"],basis,rules],
      _FeynCalc`GLI,{0,Infinity}]]],cutFamilyFail["EveryMomentIntegralFamilyMustBeDeclared"]];
 If[rules=!={},parsed=linearIntegralSum/@(Last/@rules);
  If[!AllTrue[parsed,linearIntegralSumQ[#]&&Cancel[Together[#["Remainder"]]]===0&&
    ContainsAll[basis,Keys[#["Terms"]]]&],cutFamilyFail["ClosedMomentReductionRulesRequired"]]];
 images=ibpCanonicalIntegralImages[(#["Weight"]#["MeasuredIntegrals"]&/@moments)/.Dispatch[rules]];
 If[!ListQ[images],cutFamilyFail["CanonicalMomentIntegralImagesRequired"]];
 parsed=linearIntegralSum/@images;
 If[!AllTrue[parsed,linearIntegralSumQ[#]&&#["Remainder"]===0&],
  cutFamilyFail["LinearMomentIntegralImagesRequired"]];
 rows=Lookup[parsed,"Terms"];
 outside=Complement[Union[Flatten[Keys/@rows]],basis];
 (* Clear denominators separately for each outside GLI. Coefficients of every
    power of z constrain the same constant combination; a single z sample
    would incorrectly admit variable-dependent cancellations. *)
 Do[
  coefficients=Cancel[Together[#]]&/@Lookup[rows,integral,0];
  If[!AllTrue[coefficients,exactIntegralCoefficientQ],cutFamilyFail["RationalMomentRowsRequired"]];
  denominator=Fold[PolynomialLCM,1,Denominator/@coefficients];
  polynomials=Cancel[denominator #]&/@coefficients;
  If[!AllTrue[polynomials,PolynomialQ[#,z]&],cutFamilyFail["PolynomialMeasurementDependenceRequired"]];
  degree=Max[0,Sequence@@(Exponent[#,z]&/@polynomials)];
  matrixRows=Join[matrixRows,Table[Coefficient[polynomials,z,j],{j,0,degree}]],
 {integral,outside}];
 matrixRows=DeleteCases[matrixRows,row_/;AllTrue[row,#===0&]];
 kernel=If[matrixRows==={},IdentityMatrix[Length[moments]],NullSpace[matrixRows]];
 If[!MatrixQ[kernel]&&kernel=!={},cutFamilyFail["ExactConstantMomentKernelRequired"]];
 Do[
  If[!FreeQ[combination,z],cutFamilyFail["MeasurementIndependentMomentCombinationRequired"]];
  image=First[ibpCanonicalIntegralImages[{combination.images}]];
  terms=linearIntegralSum[image]["Terms"];
  If[!ContainsAll[basis,Keys[terms]],cutFamilyFail["UncoveredMomentColumnsDidNotCancel"]];
  If[terms===<||>,Continue[]];
  inclusive=First[ibpCanonicalIntegralImages[{combination.Lookup[moments,"UnmeasuredIntegrals"]}]];
  AppendTo[results,<|"CombinationCoefficients"->combination,
    "MeasuredMasterCoefficients"->Lookup[terms,basis,0],"UnmeasuredIntegrals"->inclusive,
    "OutsideSpanCancellationVerifiedExactly"->True|>],
 {combination,kernel}];
 <|"Format"->"FeynFacet-ReducedMeasurementMomentCombinations","Variable"->z,
   "DimensionalRegulator"->e,"MasterIntegralBasis"->basis,"SourceMoments"->moments,
   "ReducedInsertionImages"->images,"UncoveredIntegrals"->outside,
   "MeasurementIndependentCombinationBasis"->kernel,"MomentRows"->results,
   "IntegralIdentitiesVerifiedExactly"->True,"NewIBPEquationsGenerated"->False,
   "MomentValuesEvaluated"->False,"PhysicalConstantRankEstablished"->False,
   "Scope"->"Exact linear combinations of the supplied moments whose uncovered columns cancel using retained integral identities. A missing combination is only a bounded coverage failure; endpoint continuation, epsilon orders and rank on homogeneous DE solutions remain required."|>
],"CutFamily"];
ReduceMeasurementMomentCombinations[___]:=Failure["MomentRecordsAndExactReductionRequired",<||>];
End[];EndPackage[];
