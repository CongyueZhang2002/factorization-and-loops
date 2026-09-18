Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Module[{proof,completed,row,kernel,moments,metadata,result,negative,sum,standard},
 (* The fixture's weighted kernel is log(z) log(1-z), manifestly L1.
    Its extension has only ordinary contacts; no physics certificate is fabricated. *)
 kernel=Log[iz]Log[1-iz]/(iz(1-iz));moments=<|0->{7,3}|>;
 proof=<|"Format"->"FeynFacet-MeasuredEndpointContactOrder","Variable"->iz,"Interval"->{0,1},
  "ContactDerivativeOrderBound"->0,"CompleteEnergyMeasurementCoverVerified"->True,
  "RegulatorMeromorphicityVerified"->True,"OriginalExternalPrescriptionsIncluded"->True|>;
 completed=FeynFacet`CompleteUnitIntervalDistributionFromMoments[<|0->kernel|>,moments,{proof},{iz,ie},{0,0}];
 FTTest`FTAssert["moment completion uses a distinct finite-part convention",AssociationQ[completed]&&
   completed["DistributionConvention"]==="LinearEndpointInterpolation"];
 If[!AssociationQ[completed],Print[InputForm[completed]];Exit[1]];row=completed["Coefficients"][0];
 FTTest`FTAssert["the independent moments determine both endpoint contacts",row["DeltaCoefficients"]===<|0->4,1->3|>];
 FTTest`FTAssert["the complete zeroth and first moments are recovered without quadrature",
  FeynFacet`UnitIntervalDistributionMoment[row,iz,0]===7&&FeynFacet`UnitIntervalDistributionMoment[row,iz,1]===3];
 FTTest`FTAssert["a quadratic test function uses the integrable subtracted kernel",
  FullSimplify[FeynFacet`UnitIntervalDistributionMoment[row,iz,2]-(1+Pi^2/6)]===0];
 FTTest`FTAssert["the result displays a distribution rather than an ordinary regular coefficient",
  !KeyExistsQ[row,"RegularCoefficient"]&&!FreeQ[FeynFacet`UnitIntervalDistributionExpression[row,iz],_FeynFacet`IntervalFinitePart]];
 FTTest`FTAssert["uncertified or higher-contact-order data cannot use two moments",
  FailureQ[FeynFacet`CompleteUnitIntervalDistributionFromMoments[<|0->kernel|>,moments,{}, {iz,ie},{0,0}]]&&
  FailureQ[FeynFacet`CompleteUnitIntervalDistributionFromMoments[<|0->kernel|>,moments,
    {Join[proof,<|"ContactDerivativeOrderBound"->1|>]}, {iz,ie},{0,0}]]];
 metadata=<|"Scale"->is,"Variables"->{iz},"DimensionalRegulator"->ie,"Order"->"NLO",
   "Contribution"->"Example","StructureFunctions"->{"Scalar"},
   "DistributionBasis"-><|"Representation"->"UnitIntervalFinitePart","Variable"->iz,"Interval"->{0,1},"Endpoints"->{0,1}|>|>;
 result=FeynFacet`CreatePartonicResult[<|0->row|>,metadata];
 FTTest`FTAssert["the shared result format preserves the distinct finite-part convention",
  AssociationQ[result]&&result["FormatVersion"]===3&&AssociationQ[FeynFacet`ReadPartonicResult[result]]];
 negative=FeynFacet`CreatePartonicResult[<|0->FeynFacet`Private`partonicMap[-#&,row]|>,
   Join[metadata,<|"Contribution"->"Opposite"|>]];
 sum=FeynFacet`CombinePartonicResults[<|"A"->result,"B"->negative|>,<|"Contribution"->"Sum"|>];
 FTTest`FTAssert["full finite-part distributions cancel in the shared assembly algebra",
  AssociationQ[sum]&&FeynFacet`Private`partonicZeroTreeQ[sum["Coefficients"][0]]];
 FTTest`FTAssert["a nonconstant multiplier is rejected until its contact corrections are computed",
  FailureQ[FeynFacet`Private`partonicMap[iz #&,row]]];
 FTTest`FTAssert["the common interior reader removes contacts and retains the complete kernel",
  FeynFacet`PartonicResultInteriorCoefficients[result]["Coefficients"][0]===kernel];
 FTTest`FTAssert["a finite-part row cannot masquerade as an ordinary logarithmic-plus row",
  FailureQ[FeynFacet`CreatePartonicResult[<|0->row|>,
    Join[metadata,<|"DistributionBasis"->Join[metadata["DistributionBasis"],<|"Representation"->"UnitInterval"|>]|>]]]];
 standard=FeynFacet`CreatePartonicResult[<|0-><|"RegularCoefficient"->iz,"DeltaCoefficients"-><|0->2,1->3|>,
   "PlusCoefficients"-><|0-><|0->4|>,1-><|1->5|>|>|>|>,
   Join[metadata,<|"DistributionBasis"->Join[metadata["DistributionBasis"],<|"Representation"->"UnitInterval"|>]|>]];
 result=FeynFacet`ConvertUnitIntervalResultToFinitePart[standard];
 FTTest`FTAssert["conversion preserves original standard-plus moments and their asymmetric contacts",
  AssociationQ[result]&&result["Coefficients"][0]["DeltaCoefficients"]===<|0->-41/6,1->37/3|>&&
  FeynFacet`PartonicResultInteriorCoefficients[result]["Coefficients"]===
   FeynFacet`PartonicResultInteriorCoefficients[standard]["Coefficients"]];
];
Print["INTERVAL MOMENT COMPLETION TEST COMPLETE"];FTTest`FTReport[];
