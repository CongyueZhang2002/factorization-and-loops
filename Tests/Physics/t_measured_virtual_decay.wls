Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
directory=root<>"/Projects/EE_EEC/Raw/NNLO/q-qb";
squareCard=FeynFacet`ReadContributionCard[directory,"Virtual.OneLoopSquared"];
square=FeynFacet`IntegrateMeasuredCurrentVirtual[squareCard,"resume"];
FTTest`FTAssert["generated one-loop square retains the complex modulus without an extra interference factor",
 AssociationQ[square]&&square["ConjugateInterferenceAdded"]===False&&square["KnownThroughOrder"]===0];
zeroCard=FeynFacet`ReadContributionCard[directory,"Virtual.LoopInducedGluons"];
zero=FeynFacet`IntegrateMeasuredCurrentVirtual[zeroCard,"all"];
FTTest`FTAssert["complete generated vector-current two-gluon diagrams cancel in color and spin algebra",
 AssociationQ[zero]&&TrueQ[zero["GeneratedExactZero"]]&&AllTrue[Values[zero["ContactIntegrals"]],#["Value"]===0&]];
oneCard=FeynFacet`ReadContributionCard[root<>"/Projects/EE_EEC/Raw/NLO/q-qb","Virtual"];
one=FeynFacet`IntegrateMeasuredCurrentVirtual[oneCard,"all"];
loop=FeynFacet`FamilyArtifactRead[oneCard["WorkDirectory"]<>"/ScalarLoopIntegrals.wl"];
e=Global`Epsilon;request=FeynFacet`ProjectAssemblyRequest[oneCard];
loopValue=FeynFacet`EvaluateOneLoopScalarFunctions[loop["InteriorValues"]["Scalar"]/.D->4-2e,e,request["Assumptions"]];
bornCard=FeynFacet`ReadContributionCard[root<>"/Projects/EE_EEC/Raw/LO/q-qb","Born"];
born=FeynFacet`ConstructCurrentIntegrands[FeynFacet`ReadProcessCard[bornCard],FeynFacet`ProjectAssemblyRequest[bornCard]];
momenta=Take[oneCard["FinalMomenta"],2];q=oneCard["Assembly"]["PhaseSpace"]["TotalMomentum"];s=oneCard["Assembly"]["Scale"];
kin=FeynCalc`FCI[{FeynCalc`SPD[momenta[[1]]]->0,FeynCalc`SPD[momenta[[2]]]->0,FeynCalc`SPD@@momenta->s/2}];
bornValue=(FeynCalc`ExpandScalarProduct[born["Values"]["Scalar"]/.q->Total[momenta]]/.kin)/.D->4-2e;
geometry=Join[oneCard["Assembly"]["PhaseSpace"],<|"Name"->testMeasuredVirtual,"FinalMomenta"->momenta|>];
rows=FeynFacet`PrepareFinalStateMeasurementIntegrands[1,geometry,oneCard["Assembly"]["FinalStateMeasurement"]];
phase=FeynFacet`IntegrateMasslessInvariantMoments[First[rows]["PreparedIntegrand"],e]["Value"];
(* A massless vector current has one on-shell form factor, A1/A0.
   This independent check uses one-loop tensor reduction and Gamma functions,
   not the two-loop IBP reduction or the conjugate-bubble scalar-library entry. *)
Do[
 numericalRules={s->point[[1]],Global`muR2->point[[2]],Global`nf->3,FeynCalc`CA->3,FeynCalc`CF->4/3};
 lv=FeynFacet`SubstituteScalarPowers[loopValue,request["BareCouplingRules"]]/.
  numericalRules/.FeynFacet`\[Alpha]s->1;
 prefactor=(request["CurrentNormalization"]oneCard["SymmetryFactor"]oneCard["FlavorMultiplicity"]phase/bornValue)/.numericalRules;
 lower=FeynFacet`DetermineMeromorphicLaurentLowerBound[lv,e];
 through=-lower-FeynFacet`DetermineMeromorphicLaurentLowerBound[prefactor,e];
 loopSeries=FeynFacet`ExpandLaurentCoefficientVector[{lv},e,{{lower,through}}];
 If[!AssociationQ[loopSeries],Print[InputForm[loopSeries]];Exit[1]];
 loopCoefficients=N[loopSeries["Coefficients"],60];
 expected=prefactor Sum[loopCoefficients[{1,n}]e^n,{n,lower,through}]*
  Sum[Conjugate[loopCoefficients[{1,n}]]e^n,{n,lower,through}];
 expected=Normal[Series[expected,{e,0,0}]];
 actual=square["ContactIntegrals"]["Scalar1"]["Value"]/.numericalRules/.FeynFacet`\[Alpha]s->1;
 differences=Table[N[Coefficient[Expand[e^4(actual-expected)],e,n+4],45],{n,-4,0}];
 If[!AllTrue[differences,NumericQ[#]&&Abs[#]<10^-35&],
  Print["SQUARE CHECK DIFFERENCES ",InputForm[differences]];
  Print["ONE LOOP INPUT ",InputForm[lv]];
  Print["BORN INPUT ",InputForm[bornValue/.numericalRules]]];
 FTTest`FTAssert["all five square coefficients agree with independently integrated one-loop form factors at "<>ToString[point],
  AllTrue[differences,NumericQ[#]&&Abs[#]<10^-35&]],
 {point,{{2,3},{5,7}}}];
FTTest`FTAssert["two-body ordered measurements have equal endpoint weights",
 square["ContactIntegrals"]["Scalar1"]["Value"]===square["ContactIntegrals"]["Scalar2"]["Value"]];
Do[
 temporary=CreateDirectory[];originalCard=entry[[1]];originalResult=entry[[2]];
 Do[file=originalCard["WorkDirectory"]<>"/"<>name<>".wl";
  If[FileExistsQ[file],FeynFacet`FamilyArtifactWrite[FeynFacet`FamilyArtifactRead[file],temporary<>"/"<>name<>".wl",Compression->Automatic]],
  {name,{"Integrands","Reduction","VirtualIntegration"}}];
 changedCard=Join[originalCard,<|"WorkDirectory"->temporary,
   "FlavorMultiplicity"->2originalCard["FlavorMultiplicity"]|>];
 changed=FeynFacet`IntegrateMeasuredCurrentVirtual[changedCard,"resume"];
 FTTest`FTAssert["changing the derived flavor multiplicity invalidates the normalized cache for "<>ToString[originalCard["AmplitudeLoops"]],
  AssociationQ[changed]&&!TrueQ[changed["Reused"]]&&
  FeynFacet`CancelRationalCoefficients[{changed["ContactIntegrals"]["Scalar1"]["Value"]-
    2originalResult["ContactIntegrals"]["Scalar1"]["Value"]}]==={0}];
 If[StringStartsQ[ExpandFileName[temporary],ExpandFileName[$TemporaryDirectory]<>"/"],DeleteDirectory[temporary,DeleteContents->True]],
 {entry,{{oneCard,one},{squareCard,square}}}];
Print["MEASURED VIRTUAL DECAY TEST COMPLETE"];
FTTest`FTReport[];
