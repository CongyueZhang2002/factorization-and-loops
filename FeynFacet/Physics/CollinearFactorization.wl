(* Apply collinear correlators and construct the factorized pre-IBP pipeline. *)


FeynFacet`ContractPartonicSpinDensities::usage="ContractPartonicSpinDensities[interference,legs,request] closes generated spin chains with the normalized PDF/FF insertions defined in Distributions.wl, includes incoming color averages, and contracts tensor algebra. Request declares additional PhysicalMomenta, MasslessMomenta, UnobservedGluonStates (or a single SummedGluons entry) and Assumptions. It does not supply phase space or flux.";
FeynFacet`ContractPartonicSpinDensities[interference_,legs_List,request_Association]:=
 contractPreparedPartonicSpinDensities[interference,legs,PartonicSpinDensity/@legs,request];

(* Only internal, mathematically established joint current-density insertions
   bypass the standalone density constructor. All spin/color normalization
   records and the contraction algorithm remain shared. *)
contractPreparedPartonicSpinDensities[interference_,legs_List,densities_List,request_Association]:=Catch[Module[
 {quarks,tags,result,missing,remaining,rules,physical,massless,
  momentum,mu,nu,plus,minus,indices,spin,color,assumptions,states,summed,
  started=AbsoluteTime[],printTimings=Lookup[request,"PrintTimings",False],backend,formResult,allMomenta,formScheme},
 If[!AllTrue[legs,AssociationQ]||!DuplicateFreeQ[Lookup[legs,"Momentum"]],
  fail["PartonicLegs",legs,"Each density leg needs a distinct momentum."]];
 If[!AllTrue[densities,AssociationQ],fail["PartonicSpinDensities",densities,"A declared spin density is unsupported."]];
 quarks=Select[densities,#["Species"]=!="g"&];
 tags=If[quarks==={},<||>,AssociationThread[Lookup[quarks,"Momentum"],Unique["partonicSpin$"]&/@quarks]];
 result=tagExternalSpinors[FeynCalc`FCI[interference],tags];
 missing=If[result===0,{},Select[Values[tags],FreeQ[result,#]&]];
 result=FeynCalc`FermionSpinSum[result];
 partonicContractionProgress[printTimings,"Fermion spin sums",started,result];
 result=contractColorFactors[result];
 partonicContractionProgress[printTimings,"Color contraction",started,result];
 rules=Flatten[Table[Thread[FeynCalc`FCI[{FeynCalc`GS[tags[density["Momentum"]]],
  FeynCalc`GSD[tags[density["Momentum"]]]}]->FeynCalc`FCI[density["SpinDensity"]]],{density,quarks}]];
 result=result/.rules;
 remaining=Select[Values[tags],!FreeQ[result,#]&];
 If[missing=!={}||remaining=!={},fail["PartonicSpinDensities",{missing,remaining},"Every declared quark density must replace its spin sum."]];
 Do[
  If[leg["Species"]=!="g"||result===0,Continue[]];
  momentum=leg["Momentum"];{mu,nu}=leg["Indices"];
  plus=FeynCalc`Momentum[FeynCalc`Polarization[momentum,I],D];
  minus=FeynCalc`Momentum[FeynCalc`Polarization[momentum,-I],D];
  If[polarizationDegree[result,plus]=!=1||polarizationDegree[result,minus]=!=1,
   fail["PartonicGluonDensity",momentum,"Expected one polarization on each amplitude side."]];
  spin=First[Select[densities,#["Momentum"]===momentum&]]["SpinDensity"];
  result=(result/.{plus->FeynCalc`LorentzIndex[mu,D],minus->FeynCalc`LorentzIndex[nu,D]}) FeynCalc`FCI[spin],
 {leg,legs}];
 massless=Lookup[request,"MasslessMomenta",{}];
 summed=Lookup[request,"SummedGluons",{}];
 states=Lookup[request,"UnobservedGluonStates",
   (<|"Momentum"->#,"Sum"->"Covariant"|>&/@summed)];
 If[!ListQ[states]||!AllTrue[states,AssociationQ]||
   (KeyExistsQ[request,"UnobservedGluonStates"]&&summed=!={}),
  fail["UnobservedGluonStates",request,"Declare each unobserved gluon state once."]];
 summed=If[states==={},{},Lookup[states,"Momentum",None]];
 If[!ContainsAll[massless,summed]||Intersection[summed,Lookup[legs,"Momentum",{}]]=!={},
  fail["MasslessSummedGluons",request,"Unobserved gluons must be massless and distinct from PDF/FF legs."]];
 result=SumUnobservedGluonPolarizations[result,states];
 If[FailureQ[result],fail["UnobservedGluonStates",result,"Use physical projectors, with at most one covariant sum unless ghost states are included."]];
 If[!FreeQ[result,_FeynCalc`Polarization],fail["UncontractedPolarizations",result,"All external gluon states must be declared."]];
 physical=DeleteDuplicates[Join[Lookup[Select[legs,#["MomentumSpace"]==="Physical4"&],"Momentum",{}],
  Cases[Lookup[densities,"SpinVector",None],s_Symbol/;s=!=None],
  Lookup[request,"PhysicalMomenta",{}]]];
 massless=Lookup[request,"MasslessMomenta",{}];assumptions=Lookup[request,"Assumptions",True];
 If[!MatchQ[physical,{_Symbol...}]||!MatchQ[massless,{_Symbol...}],
  fail["PartonicKinematics",request,"Physical and massless momenta must be explicit symbol lists."]];
 result=result/.Thread[(FeynCalc`Momentum[#,D]&/@physical)->(FeynCalc`Momentum/@physical)];
 result=setMassZero[result,massless];
 If[TrueQ[Lookup[request,"ContractLorentzIndices",False]],
  result=FeynCalc`Contract[result];
  partonicContractionProgress[printTimings,"Lorentz contractions before the Dirac trace",started,result]];
 color=If[densities==={},1,Times@@Lookup[densities,"ColorAverage"]];
 partonicContractionProgress[printTimings,"Spin-density insertions",started,result];
 backend=Lookup[request,"DiracAlgebraBackend","Automatic"];
 If[!MemberQ[{"Automatic","FORM","FeynCalc"},backend],fail["DiracAlgebraBackend",backend,"Select Automatic, FORM or FeynCalc."]];
 allMomenta=DeleteDuplicates[Join[Lookup[request,"Momenta",massless],physical]];
 formScheme=If[!FreeQ[result,FeynCalc`DiracGamma[5|6|7]|_FeynCalc`Eps]&&
  FeynCalc`FCGetDiracGammaScheme[]==="BMHV","BMHV","Nonchiral"];
 If[backend==="FORM"||(backend==="Automatic"&&
   (FreeQ[result,FeynCalc`DiracGamma[5|6|7]|_FeynCalc`Eps]||formScheme==="BMHV")&&
   FileExistsQ[FileNameJoin[{$feynFacetAddonRoot,"Addon","Other_Addon","FORM","bin","form"}]]),
  formResult=FeynFacet`EvaluateFORMDiracExpression[result,Join[
   Lookup[request,"FORMOptions",<||>],<|"Momenta"->allMomenta,"PhysicalMomenta"->physical,"MasslessMomenta"->massless,"Gamma5Scheme"->formScheme|>,
   KeyTake[request,{"KinematicRules"}]]];
  If[AssociationQ[formResult],
   partonicContractionProgress[printTimings,"FORM Dirac and Lorentz algebra",started,formResult["Value"]];
   Return[color formResult["Value"]]];
  If[!FailureQ[formResult],fail["FORMDiracAlgebra",Head[formResult],"Expected a completed FORM result or an explicit failure."]];
  If[backend==="FORM"||!MemberQ[{"FORMMomentumOutsideDeclaredSpan","FORMGammaArgumentUnsupported",
    "FORMIndexDimensionUnsupported","UnrestrictedPhysicalProjectorRequiresBMHVBackend"},First[formResult]],
   fail["FORMDiracAlgebra",formResult,"The declared FORM contraction did not complete."]]];
 color setMassZero[partonicContractAmplitude[result,printTimings,Lookup[request,"KernelCount",1]],massless]
],$collinearFailure];


(* Normalized partonic insertions have no fraction square roots to simplify.
   Close tensor/Dirac algebra once; avoid Calc's five repeated power/color
   simplification passes over an already scalar rational expression. *)
partonicContractionProgress[enabled_,stage_,started_,expression_]:=If[TrueQ[enabled],
 Print[stage,": ",Round[AbsoluteTime[]-started,0.01]," s; ",Round[ByteCount[expression]/1024.^2,0.01]," MB"]];
partonicEvaluateTrace[trace_]:=If[FreeQ[trace,FeynCalc`DiracGamma[5|6|7]],
 FeynCalc`DiracSimplify[trace,FeynCalc`FCDiracIsolate->False,FeynCalc`Expanding->False,FeynCalc`ExpandScalarProduct->False],
 (* West's chiral recursion requires fully expanded noncommutative products.
    Inhibiting that preparatory expansion can leave nested DOTs after BMHV splitting. *)
 FeynCalc`DiracSimplify[trace,FeynCalc`ExpandScalarProduct->False]];
partonicTraceValues[traces_List,requested_]:=Module[{count,opened={},result,load,scheme},
 count=If[Length[traces]>=24,facetKernelCount[requested,Length[traces]],1];
 If[count===1,Return[partonicEvaluateTrace/@traces]];
 If[Kernels[]==={},opened=facetLaunchKernels[count]];
 If[Kernels[]==={},Return[$Failed]];
 load=$feynFacetLoader;scheme=FeynCalc`FCGetDiracGammaScheme[];
 Internal`WithLocalSettings[
  With[{file=load,gammaScheme=scheme},ParallelEvaluate[
   If[!ValueQ[FeynCalc`$FeynCalcDirectory],Block[{$Output={}},Get[file]]];
   FeynCalc`FCSetDiracGammaScheme[gammaScheme];
   $HistoryLength=0;$MaxExtraPrecision=50;
   SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}]]],
  result=ParallelMap[partonicEvaluateTrace,traces,
   Method->"FinestGrained",DistributedContexts->None],
  If[opened=!={},CloseKernels[opened]]];
 result
];
partonicContractAmplitude[expression_,printTimings_:False,requestedKernels_:1]:=Module[
 {result,traces,values,started=AbsoluteTime[]},
 (* Contracting linear momenta into an open trace first expanded 64 NNLO
    traces into 1936. Evaluate each original trace once, keeping momentum
    sums factored; contract the resulting tensors afterward. *)
 traces=DeleteDuplicates[Cases[expression,_FeynCalc`DiracTrace,{0,Infinity}]];
 If[Length[traces]<24,
  result=FeynCalc`Contract[expression];result=FeynCalc`DiracSimplify[result];
  Return[FeynCalc`ExpandScalarProduct[FeynCalc`EpsEvaluate[FeynCalc`Contract[result]]]]];
 If[traces==={},result=expression,
  values=partonicTraceValues[traces,requestedKernels];
  If[!ListQ[values]||Length[values]=!=Length[traces]||
   !FreeQ[values,$Failed|$Aborted|_Failure|_FeynCalc`DiracTrace],
   fail["PartonicDiracTraces",values,"Every closed spin trace must be evaluated."]];
  result=expression/.Dispatch[Thread[traces->values]]];
 partonicContractionProgress[printTimings,"Distinct Dirac traces",started,result];
 result=FeynCalc`Contract[result,FeynCalc`ExpandScalarProduct->False];
 result=FeynCalc`EpsEvaluate[result];
 partonicContractionProgress[printTimings,"Lorentz contraction after traces",started,result];
 result
];

convertAmplitudeSide[process_Association, name_String] := Module[
  {side, amplitudeFA, converted, momenta, selectedDiagram, currents},

  side = process["Sides"][name];
  momenta = {
    Lookup[process["Incoming"], "Momentum"],
    Lookup[process["Outgoing"], "Momentum"]
  };
  selectedDiagram = FeynArts`DiagramExtract[
    side["Diagrams"],
    side["DiagramIndex"]
  ];
  (* Restore each virtual integration measure. The common -I in the
     FeynArts default is an overall amplitude phase and cancels in the
     interference; (2 Pi)^(-D LoopNumber) does not cancel. *)
  amplitudeFA = FeynArts`CreateFeynAmp[
    selectedDiagram,
    FeynArts`Truncated -> False,
    FeynArts`PreFactor -> (2 Pi)^(-D FeynArts`LoopNumber)
  ];
  amplitudeFA = modelResolveFlavorSums[amplitudeFA,process];
  currents = Lookup[process, "Currents", {}];
  converted = FeynCalc`FCFAConvert[
    amplitudeFA,
    FeynCalc`IncomingMomenta -> momenta[[1]],
    FeynCalc`OutgoingMomenta -> momenta[[2]],
    FeynCalc`LoopMomenta -> side["LoopMomenta"],
    FeynCalc`ChangeDimension -> D,
    FeynCalc`DropSumOver -> True,
    FeynCalc`UndoChiralSplittings -> True,
    FeynCalc`SMP -> True,
    FeynCalc`Contract -> (currents === {}),
    FeynCalc`TransversePolarizationVectors -> {},
    List -> True
  ] /. modelMasslessQuarkMassRules[process];

  If[! ListQ[converted] || Length[converted] =!= 1,
    fail[
      "DiagramsBySide[\"" <> name <> "\"]",
      side["DiagramIndex"],
      "The selected diagram did not convert to exactly one amplitude."
    ]
  ];

  If[currents === {},First[converted],
    Fold[amputateCurrentPolarization[#1,#2,name]&,First[converted],currents]]
];

convertAmplitudePair[process_Association] := AssociationMap[
  convertAmplitudeSide[process, #] &,
  sideNames
];


splitAmplitude[expr_, side_] := Module[
  {
    external, terms, factorLists, propagatorLists, commonPropagators,
    numeratorLists, propagators, numerator, remaining
  },

  external = ToFeynFacetForm[expr];
  If[external === $Failed, Return[$Failed]];
  external = Expand[external, _FeynCalc`FAD|_FeynCalc`SFAD];
  terms = If[Head[external] === Plus, List @@ external, {external}];
  factorLists = topLevelFactors /@ terms;
  propagatorLists = Cases[#, HoldPattern[(FeynCalc`FAD|FeynCalc`SFAD)[___]]] & /@
    factorLists;
  commonPropagators = commonFactorMultiset[propagatorLists];
  numeratorLists = Fold[removeFactorOnce[#1, #2] &, #,
      commonPropagators] & /@ factorLists;
  propagators = Times @@ commonPropagators;
  numerator = Total[Times @@@ numeratorLists];
  remaining = DeleteDuplicates @ Cases[
    numerator,
    HoldPattern[(FeynCalc`FAD|FeynCalc`SFAD)[___]],
    Infinity
  ];
  If[remaining =!= {},
    Message[CollinearFactorize::propagators, side, remaining];
    Throw[$Failed, $collinearFailure]
  ];

  {numerator, propagators}
];


splitFactorsByMomentum[expr_, {}] := {expr, 1};

splitFactorsByMomentum[expr_, momenta_List] := Module[
  {factors, independent, dependent},

  factors = topLevelFactors[expr];
  independent = Select[
    factors,
    FreeQ[#, Alternatives @@ momenta] &
  ];
  dependent = Select[
    factors,
    ! FreeQ[#, Alternatives @@ momenta] &
  ];
  {Times @@ independent, Times @@ dependent}
];

splitPropagatorsByMomentum[expr_, momenta_List] := Module[
  {split},

  If[momenta === {}, Return[{expr, 1}]];
  split = FeynCalc`FeynAmpDenominatorSplit[
    FeynCalc`FCI[expr],
    FeynCalc`Momentum -> momenta,
    FeynCalc`FCI -> True,
    FeynCalc`FCE -> True
  ];
  splitFactorsByMomentum[split, momenta]
];


(* Apply the declared gluon correlator to each external polarization pair. *)
polarizationDegree[expr_, vector_] := Module[{degrees},
 If[expr===vector,Return[1]];
 If[FreeQ[expr,vector],Return[0]];
 If[Head[expr]===Power && IntegerQ[expr[[2]]],
  degrees=polarizationDegree[expr[[1]],vector];Return[If[IntegerQ[degrees],expr[[2]]degrees,None]]];
 If[!MemberQ[{Plus,Times,FeynCalc`DOT,Dot,FeynCalc`DiracGamma,FeynCalc`DiracTrace,
    FeynCalc`Pair,FeynCalc`Eps},Head[expr]],Return[None]];
 degrees=polarizationDegree[#,vector]& /@ List@@expr;
 If[!VectorQ[degrees,IntegerQ],Return[None]];
 If[Head[expr]===Plus,If[Length[DeleteDuplicates[degrees]]===1,First[degrees],None],Total[degrees]]
];

gluonDensityProject[expr_, process_Association] := Module[
 {result=expr, legs, side, k, reference, mu, nu, plus, minus, tensor},
 legs=Join[({#, "Incoming"}& /@ process["Incoming"]),
   ({#, "Outgoing"}& /@ process["Outgoing"])];
 Do[
  If[MissingQ[leg["HadronMomentum"]] || !MatchQ[leg["Parton"],FeynArts`V[5]],Continue[]];
  side=entry[[2]];k=leg["Momentum"];
  reference=Lookup[Lookup[process,"GluonPolarizationReferences",<||>],k,leg["DualDirection"]];
  If[leg["TransSpin"]=!=0,
   fail["HadronTransSpin",leg["TransSpin"],"A spin-one-half hadron has no collinear gluon transversity projector."]];
  mu=Unique["gluonMu$"];nu=Unique["gluonNu$"];
  plus=FeynCalc`Momentum[FeynCalc`Polarization[k,I],D];
  minus=FeynCalc`Momentum[FeynCalc`Polarization[k,-I],D];
  If[result===0,Continue[]];
  If[polarizationDegree[result,plus]=!=1 || polarizationDegree[result,minus]=!=1,
   fail["GluonPolarizations",k,"Each interference must be linear in each external polarization vector."]];
  tensor=twist2GluonCorrelator[leg["Fraction"],k,leg["LongSpin"],reference,mu,nu,side];
  result=(result /. {plus->FeynCalc`LorentzIndex[mu,D],minus->FeynCalc`LorentzIndex[nu,D]}) FeynCalc`FCI[tensor],
  {entry,legs},{leg,{entry[[1]]}}];
 result
];

sumUnobservedPolarizations[expr_, process_Association] := Module[
  {momenta, result, remaining},

  momenta = Lookup[#, "Momentum"] & /@ Select[
    process["Outgoing"],
    MatchQ[#["Parton"], FeynArts`V[__]] &&
      MissingQ[#["HadronMomentum"]] &
  ];
  result = Fold[
    Function[{current, momentum},
      Quiet[
        FeynCalc`DoPolarizationSums[current, momentum, 0],
        FeynCalc`PolarizationSum::notmassless
      ]
    ],
    expr,
    DeleteDuplicates[momenta]
  ];
  remaining = DeleteDuplicates @ Cases[
    result,
    FeynCalc`Polarization[___],
    Infinity
  ];
  If[remaining =!= {},
    Message[CollinearFactorize::polarization, momenta, remaining];
    Throw[$Failed, $collinearFailure]
  ];
  result
];


unresolvedAlgebraObjects[expr_] := DeleteDuplicates @ Cases[
  FeynCalc`FCI[expr],
  object_ /; MemberQ[
    {
      FeynCalc`Calc,
      FeynCalc`DiracTrace,
      FeynCalc`DiracGamma,
      FeynCalc`DOT,
      FeynCalc`Polarization,
      FeynCalc`LorentzIndex,
      FeynCalc`CartesianIndex,
      FeynCalc`SUNIndex,
      FeynCalc`SUNT,
      FeynCalc`SUNF,
      FeynCalc`SUNDelta
    },
    Head[Unevaluated[object]]
  ] :> object,
  Infinity
];


densityHead[parton_, side_] := Which[
  MatchQ[parton, FeynArts`F[__]],
    If[side === "Incoming", \[CapitalPhi], \[CapitalDelta]],
  MatchQ[parton, -FeynArts`F[__]],
    If[side === "Incoming", \[CapitalPhi]b, \[CapitalDelta]b],
  True,
    fail[
      "Partons",
      parton,
      "A hadron-associated leg must currently be a quark or antiquark."
    ]
];

densityLegs[process_Association] := Select[
  Join[process["Incoming"], process["Outgoing"]],
  ! MissingQ[#["HadronMomentum"]] &
];

externalSpinTags[process_Association] := Module[{legs},
 legs=Select[densityLegs[process],!MatchQ[#["Parton"],FeynArts`V[__]]&];
 If[legs==={},Return[<||>]];
 AssociationThread[Lookup[legs,"Momentum"],Unique["externalSpin$"]&/@legs]
];

tagExternalSpinors[expr_, tags_Association] := expr /.
  spinor_FeynCalc`Spinor :> (spinor /. Normal[tags]);

densityRule[leg_Association, side_, tags_Association] := Module[
  {head, normalization, spinMomentum},

  If[MissingQ[leg["HadronMomentum"]] || MatchQ[leg["Parton"], FeynArts`V[__]], Return[{}]];
  head = densityHead[leg["Parton"], side];
  spinMomentum = Lookup[tags, leg["Momentum"]];
  normalization = FeynCalc`SPD[
    leg["HadronMomentum"],
    leg["DualDirection"]
  ];
  If[side === "Outgoing",
    normalization *= 2/leg["Fraction"]^3
  ];

  Thread[
    FeynCalc`FCI[{
      FeynCalc`GS[spinMomentum],
      FeynCalc`GSD[spinMomentum]
    }] -> normalization head[
      leg["Fraction"],
      leg["HadronMomentum"],
      leg["LongSpin"],
      leg["TransSpin"],
      leg["LongDirection"]
    ]
  ]
];

densityRules[process_Association, tags_Association] := Join[
  Flatten[densityRule[#, "Incoming", tags] & /@ process["Incoming"]],
  Flatten[densityRule[#, "Outgoing", tags] & /@ process["Outgoing"]]
];


setDistributionsZero[expr_, {}] := expr;

distributionZeroRule[head_Symbol] := With[
  {distributionHead = head},
  HoldPattern[distributionHead[___]] :> 0
];

distributionZeroRule[object_] := With[
  {distributionObject = object},
  HoldPattern[distributionObject] :> 0
];

setDistributionsZero[expr_, specifications_List] :=
  expr /. (distributionZeroRule /@ specifications);


containsListedMomentumQ[expr_, momenta_List] :=
  ! FreeQ[Unevaluated[expr], Alternatives @@ momenta];

setEvanescentZero[expr_, {}] := expr;

setEvanescentZero[expr_, momenta_List] := Module[{external},
  external = ToFeynFacetForm[FeynCalc`ExpandScalarProduct[expr]];
  If[external === $Failed, Return[$Failed]];
  FeynCalc`FCI[external /. {
    HoldPattern[FeynCalc`SPE[a_, b_]] /;
      containsListedMomentumQ[{a, b}, momenta] :> 0,
    HoldPattern[FeynCalc`SPE[a_]] /;
      containsListedMomentumQ[a, momenta] :> 0,
    HoldPattern[FeynCalc`SP[a_, b_]] /;
      containsListedMomentumQ[{a, b}, momenta] :> FeynCalc`SPD[a, b],
    HoldPattern[FeynCalc`SP[a_]] /;
      containsListedMomentumQ[a, momenta] :> FeynCalc`SPD[a]
  }]
];


setMassZero[expr_, {}] := expr;

setMassZero[expr_, momenta_List] :=
  FeynCalc`FCI[expr] /.
    Thread[FeynCalc`FCI[FeynCalc`SPD /@ momenta] -> 0];


applyKinematicZeros[expr_, process_Association] := setMassZero[
  setEvanescentZero[expr, process["SetEvanescentZero"]],
  process["SetMassZero"]
];


fractionMeasure[process_Association] := Module[{fractions},
  fractions = DeleteDuplicates @ Select[
    Lookup[Join[process["Incoming"], process["Outgoing"]], "Fraction"],
    ! MissingQ[#] &
  ];
  Times @@ (dFraction /@ fractions)
];


factorizePair[config_Association, conjugateSeed_:Automatic] := Catch[
  Module[
    {
      process, eliminationRule, phase, amplitudes, completePair, splitPair,
      result, spinTags, taggedNumerator, missingSpinTags,
      remainingSpinTags, cutLoopMomenta, allLoopMomenta, preFactor, integrand,
      commonFactor, key, converted,
      cutNormalizationFactor, loopNormalizationFactor,
      externalCuts, loopCuts, externalPropagators,
      ordinaryPropagators, propagators,
      remainingPropagators,
      remainingAlgebra, contraction
    },

    If[! MatchQ[globalBasis, {_, _, _, _}],
      Message[CollinearFactorize::basis];
      Throw[$Failed, $collinearFailure]
    ];
    declareGlobalBasis[globalBasis];

    process = prepareProcess[
      normalizeProcess[config],
      Lookup[config, "DiagramsBySide", Missing["NotAvailable"]]
    ];
    eliminationRule = momentumEliminationRule[process];
    phase = buildPhaseData[process, eliminationRule];
    cutLoopMomenta = remainingPhaseSpaceMomenta[process];
    allLoopMomenta = DeleteDuplicates @ Join[
      cutLoopMomenta,
      process["VirtualLoopMomenta"]
    ];
    loopNormalizationFactor =
      (I Pi^(D/2))^Length[allLoopMomenta];
    cutNormalizationFactor =
      (I Pi^(D/2))^Length[cutLoopMomenta];
    {externalCuts, loopCuts} = splitFactorsByMomentum[phase["Cuts"], allLoopMomenta];
    If[conjugateSeed === Automatic,
    amplitudes = convertAmplitudePair[process];
    completePair = <|
      "Amplitude" -> amplitudes["Amplitude"],
      "Conjugate" -> conjugatePhysicalAmplitude[amplitudes["Conjugate"],config]
    |>;
    splitPair = AssociationMap[
      splitAmplitude[completePair[#], ToLowerCase[#]] &,
      sideNames
    ];
    If[MemberQ[Values[splitPair], $Failed],
      fail[
        "CollinearFactorize",
        splitPair,
        "An amplitude could not be converted to compact FeynCalc syntax."
      ]
    ];
    {externalPropagators, ordinaryPropagators} =
      splitPropagatorsByMomentum[
        Times @@ (Last /@ Values[splitPair]) /. eliminationRule,
        allLoopMomenta
      ];

    spinTags = externalSpinTags[process];
    taggedNumerator = tagExternalSpinors[
      Times @@ (First /@ Values[splitPair]),
      spinTags
    ];
    missingSpinTags = If[taggedNumerator===0,{},Select[Values[spinTags], FreeQ[taggedNumerator, #] &]];
    result = FeynCalc`FermionSpinSum[taggedNumerator];
    (* Close color contractions before polarization sums expand the Lorentz
       tensor. Repeating the same color algebra in every expanded scalar term
       causes a large avoidable expression growth in gluon interferences. *)
    result = contractColorFactors[result];
    result = gluonDensityProject[result, process];
    result = sumUnobservedPolarizations[result, process];

    result = result /. densityRules[process, spinTags];
    remainingSpinTags = Select[Values[spinTags], ! FreeQ[result, #] &];
    If[missingSpinTags =!= {} || remainingSpinTags =!= {},
      Message[
        CollinearFactorize::spinprojector,
        missingSpinTags,
        remainingSpinTags
      ];
      Throw[$Failed, $collinearFailure]
    ];
    result = setDistributionsZero[
      result,
      process["SetDistributionZero"]
    ];
    result = applyKinematicZeros[result, process];
    result = collinearContractAmplitude[result, process],
    {result,externalPropagators,ordinaryPropagators} =
      Lookup[conjugateSeed,{"Numerator","ExternalPropagators","OrdinaryPropagators"}]
    ];
    (* Save the physical contraction before routing reduction or i*pi^(D/2)
       normalization. Its Hermitian partner never conjugates an abstract GLI. *)
    contraction=<|"Numerator"->result,"ExternalPropagators"->externalPropagators,
      "OrdinaryPropagators"->ordinaryPropagators|>;
    result = applyKinematicZeros[result, process];
    result = applyKinematicZeros[result /. eliminationRule, process];
    result = reduceCollinearLoopProducts[
      result,
      process,
      allLoopMomenta
    ];
    remainingAlgebra = unresolvedAlgebraObjects[result];
    If[remainingAlgebra =!= {},
      Message[
        CollinearFactorize::algebra,
        Take[remainingAlgebra, UpTo[10]]
      ];
      Throw[$Failed, $collinearFailure]
    ];

    result = result /. FeynCalc`SMP["g_s"] -> Sqrt[4 Pi \[Alpha]s];
    commonFactor = CommonFactorSafe[
      result,
      allLoopMomenta
    ];
    If[commonFactor === $Failed,
      fail[
        "CollinearFactorize",
        result,
        "The result could not be converted to compact FeynCalc syntax."
      ]
    ];
    {preFactor, integrand} = commonFactor;
    remainingPropagators = DeleteDuplicates @ Cases[
      integrand,
      HoldPattern[(FeynCalc`FAD | FeynCalc`SFAD)[___]],
      Infinity
    ];
    If[remainingPropagators =!= {},
      Message[
        CollinearFactorize::propagators,
        "contracted integrand",
        remainingPropagators
      ];
      Throw[$Failed, $collinearFailure]
    ];

    preFactor = Factor[
      phase["Prefactor"] loopNormalizationFactor preFactor
        FeynCalc`FeynAmpDenominatorExplicit[
          externalPropagators,
          FeynCalc`ExpandScalarProduct -> False,
          FeynCalc`FCE -> True
        ] /.
        FeynCalc`SMP["g_s"] -> Sqrt[4 Pi \[Alpha]s]
    ];
    propagators = loopCuts ordinaryPropagators;
    result = <|
      "Process" -> process,
      "Contraction" -> contraction,
      "FractionMeasure" -> fractionMeasure[process],
      "PreFactor" -> preFactor,
      "PhaseSpace" -> phase["Measure"] externalCuts/cutNormalizationFactor,
      "Integrand" -> integrand,
      "Propagators" -> propagators,
      "LoopMomenta" -> allLoopMomenta
    |>;

    Do[
      converted = ToFeynFacetForm[result[key]];
      If[converted === $Failed,
        fail[
          "CollinearFactorize",
          key,
          "The output could not be converted to compact FeynCalc syntax."
        ]
      ];
      AssociateTo[result, key -> converted],
      {key, {
        "FractionMeasure", "PreFactor", "PhaseSpace", "Integrand",
        "Propagators"
      }}
    ];

    If[! FreeQ[
        Lookup[result, {
          "FractionMeasure", "PreFactor", "PhaseSpace", "Integrand",
          "Propagators", "LoopMomenta"
        }],
        process["IntegratedMomentum"]
      ],
      fail[
        "PartonIntegrated",
        process["IntegratedMomentum"],
        "The eliminated momentum survived in the output."
      ]
    ];
    If[
      ! exactDataQ @ Lookup[result, {
        "FractionMeasure", "PreFactor", "PhaseSpace", "Integrand",
        "Propagators", "LoopMomenta"
      }],
      fail[
        "CollinearFactorize",
        result,
        "The analytic result contains inexact numerical data."
      ]
    ];

    result
  ],
  $collinearFailure
];

(* Evaluate each distinct closed trace before expanding products of traces.
   FermionSpinSum has already closed the external spin chains. Keeping Calc
   afterwards also handles open chains and the remaining color/Lorentz algebra. *)
(* Isolate color products so SUNSimplify never expands their Lorentz
   coefficients. Equivalent color products are evaluated only once. *)
contractColorFactors[expression_]:=Module[{head,isolated,objects},
 isolated=FeynCalc`FCColorIsolate[FeynCalc`FCTraceFactor[expression,FeynCalc`FCI->True],Head->head,
  FeynCalc`Collecting->False,FeynCalc`Factoring->False,FeynCalc`FCI->True];
 objects=DeleteDuplicates[Cases[isolated,object_head:>object,{0,Infinity}]];
 isolated/.((#->FeynCalc`SUNSimplify[First[#],Explicit->False])&/@objects)
];

(* The process supplies the physical four-dimensional span explicitly. FORM
   keeps phase-space and virtual momenta in D dimensions, including their
   evanescent components; it never changes a propagator prescription. *)
collinearContractAmplitude[expression_, process_Association] := Module[
 {momenta,physical,request,result,scheme},
 If[expression===0,Return[0]];
 If[!FileExistsQ[FileNameJoin[{$feynFacetAddonRoot,"Addon","Other_Addon","FORM","bin","form"}]],
  Return[collinearContractAmplitude[expression,process["Assumptions"]]]];
 momenta=DeleteDuplicates@Join[process["SetEvanescentZero"],
   process["PhaseSpaceMomenta"],process["VirtualLoopMomenta"]];
 momenta=Select[momenta,!FreeQ[expression,#]&];
 If[momenta==={},Return[collinearContractAmplitude[expression,process["Assumptions"]]]];
 physical=Intersection[momenta,process["SetEvanescentZero"]];
 scheme=If[FeynCalc`FCGetDiracGammaScheme[]==="BMHV","BMHV","Nonchiral"];
 If[scheme==="Nonchiral"&&!FreeQ[expression,FeynCalc`DiracGamma[5|6|7]|_FeynCalc`Eps],
  Return[collinearContractAmplitude[expression,process["Assumptions"]]]];
 request=<|"Momenta"->momenta,"PhysicalMomenta"->physical,
   "MasslessMomenta"->Intersection[momenta,process["SetMassZero"]],"Gamma5Scheme"->scheme|>;
 result=FeynFacet`EvaluateFORMDiracExpression[expression,request];
 If[AssociationQ[result],Return[result["Value"]]];
 If[FailureQ[result]&&MemberQ[{"FORMMomentumOutsideDeclaredSpan","FORMGammaArgumentUnsupported",
   "FORMIndexDimensionUnsupported","UnrestrictedPhysicalProjectorRequiresBMHVBackend"},First[result]],
  Return[collinearContractAmplitude[expression,process["Assumptions"]]]];
 fail["FORMDiracAlgebra",result,"The declared Dirac and Lorentz contraction did not complete."]
];

collinearContractAmplitude[expression_, assumptions_] := Module[{prepared, traces},
  (* Early chiral traces create large Levi-Civita products in BMHV.
     Contract these chains in Calc's original order before expanding traces. *)
  If[! FreeQ[expression, HoldPattern[FeynCalc`DiracGamma[5 | 6 | 7]]],
    Return[FeynCalc`Calc[expression, Assumptions -> assumptions]]];
  prepared = contractColorFactors[expression];
  (* Pure Lorentz/color tensors need one complete contraction. The legacy
     Calc fixed point repeats scalar power simplification up to five times,
     even though no Dirac algebra is present. Keep the exact scalar expression
     for later kinematic substitution and for the sum of interferences. *)
  If[FreeQ[prepared,_FeynCalc`DiracGamma|_FeynCalc`DiracTrace|_FeynCalc`DOT|_Dot],
    Return[FeynCalc`ExpandScalarProduct[FeynCalc`Contract[prepared]]]];

  traces = DeleteDuplicates[Cases[prepared, _FeynCalc`DiracTrace, {0, Infinity}]];
  prepared = prepared /. Normal[AssociationMap[FeynCalc`DiracSimplify, traces]];
  FeynCalc`Calc[prepared, Assumptions -> assumptions]
];

CollinearFactorize[config_Association] := Module[{result = factorizePair[config]},
  If[result === $Failed,
    $Failed,
    Lookup[result, {
      "FractionMeasure",
      "PreFactor",
      "PhaseSpace",
      "Integrand",
      "Propagators",
      "LoopMomenta"
    }]
  ]
];

CollinearFactorize[config_] := (
  Message[CollinearFactorize::config, config];
  $Failed
);

CollinearFactorizePreIBP::config =
  "Expected one complete configuration Association, but received `1`.";

CollinearFactorizePreIBP::missing =
  "Setup is missing required amplitude keys `1`.";

CollinearFactorizePreIBP::stage =
  "The pre-IBP pipeline failed at stage `1`.";

$preIBPFailure = "FeynFacetPreIBPFailure";


preIBPFail[stage_] := (
  Message[CollinearFactorizePreIBP::stage, stage];
  Throw[$Failed, $preIBPFailure]
);

completeTopologyRecord[
    family_Association,
    pair_Association,
    context_Association
  ] := Module[
  {
    topology, propagatorCount, cutIndices, cutDirections, record
  },

  topology = family["Topology"];
  propagatorCount = Length[topology[[2]]];
  cutIndices = family["CutIndices"];
  cutDirections = family["CutDirections"];

  If[
    Length[cutIndices] =!= Length[cutDirections] ||
      ! DuplicateFreeQ[cutIndices] ||
      ! AllTrue[cutIndices, IntegerQ[#] && 1 <= # <= propagatorCount &] ||
      ! AllTrue[cutDirections, MemberQ[{1, -1}, #] &],
    Return[$Failed]
  ];

  record = Join[
    family,
    <|
      "Type" -> "FeynFacetTopologyRecord",
      "Version" -> 3,
      "DiagramPair" -> pair,
      "AnalyticContext" -> context
    |>
  ];
  If[! topologyRecordQ[record], Return[$Failed]];
  record
];

Options[CollinearFactorizePreIBP]={"PrintDiagrams"->False,"PreparedDiagrams"->Automatic};
CollinearFactorizePreIBP[config_Association,OptionsPattern[]] := Catch[
  Module[
    {
      amplitudeKeys, missing, forwardAmplitudes,
      conjugateAmplitudes, diagrams, pipelineConfig, factorized,
      fractions, families, pair, topologies, shiftedIntegrand, context,
      forbiddenMomenta, remainingMomenta
    },

    amplitudeKeys = {"ForwardAmplitudes", "ConjugateAmplitudes"};
    missing = Complement[amplitudeKeys, Keys[config]];
    If[missing =!= {},
      Message[CollinearFactorizePreIBP::missing, missing];
      Throw[$Failed, $preIBPFailure]
    ];

    forwardAmplitudes = config["ForwardAmplitudes"];
    conjugateAmplitudes = config["ConjugateAmplitudes"];
    If[
      ! AllTrue[
        {forwardAmplitudes, conjugateAmplitudes},
        AssociationQ[#] && KeyExistsQ[#, "SelectedIndex"] &
      ],
      preIBPFail["diagram selection"]
    ];
    diagrams = GenerateDiagram[config, "PreparedDiagrams" -> OptionValue["PreparedDiagrams"]];
    If[diagrams === $Failed, preIBPFail["GenerateDiagram"]];
    If[TrueQ[OptionValue["PrintDiagrams"]],printSelectedDiagrams[diagrams, config]];

    pipelineConfig = Join[
      config,
      <|
        "DiagramsBySide" -> diagrams
      |>
    ];
    factorized = factorizePair[pipelineConfig];
    If[! AssociationQ[factorized],
      preIBPFail["CollinearFactorize"]
    ];
    factorizedToPreIBP[config, factorized]
  ], $preIBPFailure
];

factorizedToPreIBP[config_Association,factorized_Association] := Catch[Module[
  {fractions,families,context,pair,topologies,shiftedIntegrand,forbiddenMomenta,remainingMomenta,prescribed},
    If[factorized["Integrand"]===0,Return[Join[
      Lookup[factorized,{"FractionMeasure","PreFactor","PhaseSpace"}],{0,{}}]]];
    prescribed=preIBPOrdinaryPrescription[config,factorized];
    fractions = Block[{$ordinaryPrescriptionLimitEstablished=
      TrueQ[Lookup[Lookup[prescribed,"Certificate",<||>],"OrdinaryPrescriptionRemoved",False]]},
      PartialFraction[prescribed["Propagators"],factorized["LoopMomenta"],
        FeynCalc`FDS->False,FeynCalc`DropScaleless->False]];
    If[fractions === $Failed, preIBPFail["PartialFraction"]];
    families = BuildTopologies[
      fractions,
      factorized["LoopMomenta"],
      config
    ];
    If[families === $Failed, preIBPFail["BuildTopologies"]];

    context = analyticContext[factorized["Process"]];
    If[context === $Failed, preIBPFail["BMHV analytic context"]];
    pair = <|
      "Forward" -> config["ForwardAmplitudes"]["SelectedIndex"],
      "Conjugate" -> config["ConjugateAmplitudes"]["SelectedIndex"]
    |>;
    topologies = completeTopologyRecord[
        #,
        pair,
        context
      ] & /@ families;
    If[MemberQ[topologies, $Failed], preIBPFail["topology metadata"]];
    If[KeyExistsQ[prescribed,"Certificate"],topologies=Join[#,<|
      "SourceOrdinaryPrescriptionCertificate"->prescribed["Certificate"],
      "OriginalPrescribedPropagators"->factorized["Propagators"]|>]& /@ topologies];

    shiftedIntegrand = DimensionalShift[
      factorized["Integrand"],
      topologies,
      factorized["LoopMomenta"]
    ];
    If[shiftedIntegrand === $Failed, preIBPFail["DimensionalShift"]];
    (* Tensor reduction introduces external Gram products again. Apply the
       already declared on-shell and physical-space identities before writing
       hundreds of pair coefficients or reconstructing their rational sums. *)
    shiftedIntegrand = applyKinematicZeros[shiftedIntegrand,factorized["Process"]];
    shiftedIntegrand = ToFeynFacetForm[shiftedIntegrand];
    If[shiftedIntegrand === $Failed,
      preIBPFail["compact expression conversion"]
    ];
    topologies = Select[topologies,Function[record,
      With[{name=record["Topology"][[1]]},
        !FreeQ[shiftedIntegrand,HoldPattern[FeynCalc`GLI[name,_List]]]]]];
    If[checkCompletedPropagators[config, topologies,
        DeleteDuplicates[Cases[shiftedIntegrand, _FeynCalc`GLI, {0, Infinity}]]] =!= True,
      preIBPFail["active phase-space denominators"]];
    forbiddenMomenta = DeleteDuplicates @ Join[
      Lookup[config, "PhaseSpaceMomentum", {}],
      factorized["LoopMomenta"]
    ];
    remainingMomenta = remainingDeclaredMomenta[
      shiftedIntegrand,
      forbiddenMomenta
    ];
    If[remainingMomenta =!= {},
      Message[DimensionalShift::numerator, remainingMomenta];
      preIBPFail["loop-dependent master coefficient"]
    ];

    Join[
      Lookup[factorized, {"FractionMeasure", "PreFactor", "PhaseSpace"}],
      {shiftedIntegrand, topologies}
    ]
  ],
  $preIBPFailure
];

CollinearFactorizePreIBP[config_] := (
  Message[CollinearFactorizePreIBP::config, config];
  $Failed
);

GenerateCollinearFactorizePreIBPResult::setup =
  "Setup must contain a nonempty CardName and positive selected forward and conjugate diagram indices.";

GenerateCollinearFactorizePreIBPResult::failed =
  "At least one supplied pre-IBP output contains $Failed.";

GenerateCollinearFactorizePreIBPResult::topologies =
  "Topologies contains an invalid or pair-inconsistent topology record.";


sourceNotebookFile[] := Module[{file},
  file = Quiet @ Check[NotebookFileName[], $Failed];
  If[StringQ[file] && StringLength[file] > 0,
    ExpandFileName[file],
    Missing["NotAvailable"]
  ]
];

GenerateCollinearFactorizePreIBPResult[
    setup_Association,
    fractionMeasure_,
    preFactor_,
    phaseSpace_,
    integrand_,
    topologies_List,
    resultDirectory_: Automatic
  ] := Module[
  {
    cardName, pair, sourceNotebook, directory, contexts, process, context,
    expressionFields
  },
  cardName = Lookup[setup, "CardName", Missing["NotAvailable"]];
  pair = selectedPairFromSetup[setup];
  If[
    ! StringQ[cardName] || StringLength[StringTrim[cardName]] === 0 ||
      pair === $Failed,
    Message[GenerateCollinearFactorizePreIBPResult::setup];
    Return[$Failed]
  ];
  If[
    ! FreeQ[
      HoldComplete[
        fractionMeasure, preFactor, phaseSpace, integrand, topologies
      ],
      $Failed
    ],
    Message[GenerateCollinearFactorizePreIBPResult::failed];
    Return[$Failed]
  ];
  If[! AllTrue[topologies, topologyRecordQ[#, pair] &],
    Message[GenerateCollinearFactorizePreIBPResult::topologies];
    Return[$Failed]
  ];
  contexts = DeleteDuplicates[Lookup[topologies, "AnalyticContext"], SameQ];
  context = If[
    topologies === {},
    process = Catch[normalizeProcess[setup], $collinearFailure];
    If[! AssociationQ[process], $Failed, analyticContext[process]],
    If[Length[contexts] === 1, First[contexts], $Failed]
  ];
  If[context === $Failed,
    Message[GenerateCollinearFactorizePreIBPResult::topologies];
    Return[$Failed]
  ];
  If[
    ! exactDataQ @ HoldComplete[
      setup, fractionMeasure, preFactor, phaseSpace, integrand, topologies,
      context
    ],
    Message[GenerateCollinearFactorizePreIBPResult::failed];
    Return[$Failed]
  ];
  expressionFields = ToFeynFacetForm /@ {
    fractionMeasure, preFactor, phaseSpace, integrand
  };
  If[MemberQ[expressionFields, $Failed],
    Message[GenerateCollinearFactorizePreIBPResult::failed];
    Return[$Failed]
  ];
  sourceNotebook = Lookup[setup, "SourceNotebook", Automatic];
  sourceNotebook = If[
    sourceNotebook === Automatic,
    sourceNotebookFile[],
    If[
      StringQ[sourceNotebook] && StringLength[sourceNotebook] > 0,
      ExpandFileName[sourceNotebook],
      Missing["NotAvailable"]
    ]
  ];
  directory = Replace[
    resultDirectory,
    Automatic :> Lookup[setup, "ResultDirectory", Missing["NotAvailable"]]
  ];
  directory = If[
    StringQ[directory] && StringLength[StringTrim[directory]] > 0,
    ExpandFileName[directory],
    Missing["NotAvailable"]
  ];
  Join[resultHeader["FeynFacet-CollinearFactorizePreIBP", 4], <|
    "CardName" -> StringTrim[cardName],
    "Pair" -> pair,
    "ResultDirectory" -> directory,
    "ExpressionForm" -> "FeynCalcExternal",
    "AnalyticContext" -> context,
    "SourceNotebook" -> sourceNotebook,
    "Setup" -> setup,
    "FractionMeasure" -> expressionFields[[1]],
    "PreFactor" -> expressionFields[[2]],
    "PhaseSpace" -> expressionFields[[3]],
    "Integrand" -> expressionFields[[4]],
    "Topologies" -> topologies
  |>]
];

GenerateCollinearFactorizePreIBPResult[___] := (
  Message[GenerateCollinearFactorizePreIBPResult::setup];
  $Failed
);


(* Validator of the pre-IBP result record this file produces (moved
   here verbatim from Reduction/Reduction.wl, layer pass 2026-09-02):
   the Process family registry (CanonicalFamilies.wl) validates saved
   results with it, and Reduction loads after Process. *)
ClearAll[validPreIBPResultQ];
validPreIBPResultQ[result_] := Module[{pair, context},
  If[
    ! artifactHeaderQ[
        result,
        "FeynFacet-CollinearFactorizePreIBP",
        4
      ] ||
      ! And @@ (KeyExistsQ[result, #] & /@ {
        "CardName", "Pair", "Setup", "FractionMeasure",
        "PreFactor", "PhaseSpace", "Integrand", "Topologies",
        "ResultDirectory", "AnalyticContext", "ExpressionForm"
      }),
    Return[False]
  ];
  pair = result["Pair"];
  context = result["AnalyticContext"];
  AssociationQ[pair] &&
    result["ExpressionForm"] === "FeynCalcExternal" &&
    feynFacetFormQ @ Lookup[result, {
      "FractionMeasure", "PreFactor", "PhaseSpace", "Integrand"
    }] &&
    IntegerQ[Lookup[pair, "Forward", None]] &&
    IntegerQ[Lookup[pair, "Conjugate", None]] &&
    analyticContextQ[context] &&
    ListQ[result["Topologies"]] &&
    AllTrue[
      result["Topologies"],
      topologyRecordQ[#, pair] &&
        SameQ[#1["AnalyticContext"], context] &
    ] &&
    exactDataQ @ Lookup[result, {
      "Setup", "FractionMeasure", "PreFactor", "PhaseSpace",
      "Integrand", "Topologies", "AnalyticContext"
    }]
];
