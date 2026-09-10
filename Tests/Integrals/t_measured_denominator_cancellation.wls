$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[t,kappa,nc,dim];
fixture=<|"Format"->"FeynFacet-MeasuredCutIntegrand",
 "FreeScalarProductVariables"->{t},"OrdinaryUnitCutPolynomials"->{t,t+1,kappa},
 "OrdinaryPowerBounds"->{1,1,0},
 "Terms"->{<|"Powers"->{1,0,0},"Numerator"->(nc^2+dim)/(nc^2(dim-2))|>,
  <|"Powers"->{1,1,0},"Numerator"->-(nc^2+dim)/(nc^2(dim-2))|>},
 "SourceDefinition"-><|"OffShell"->t+cutMass|>,"OrdinaryPrescriptionCertificate"->"Original"|>;
cancelled=CancelMeasuredCutIntegrandDenominators[fixture];
density[data_]:=Total[(#["Numerator"]Times@@MapThread[Power,
 {data["OrdinaryUnitCutPolynomials"],-#["Powers"]}])&/@data["Terms"]];
FTAssert["a removable denominator cancels across different products at generic color and dimension",
 cancelled["RationalCancellation"]["Status"]==="Completed"&&
 MemberQ[cancelled["RationalCancellation"]["CancelledOrdinaryFactorIndices"],1]&&
 Cancel[Together[density[cancelled]-(nc^2+dim)/(nc^2(dim-2)(t+1))]]===0];
FTAssert["cancellation leaves the unrestricted definition and original prescription proof intact",
 cancelled["SourceDefinition"]===fixture["SourceDefinition"]&&
 cancelled["OrdinaryPrescriptionCertificate"]===fixture["OrdinaryPrescriptionCertificate"]];
nonzero=fixture;nonzero["Terms"]=Take[fixture["Terms"],1];
nonzero=CancelMeasuredCutIntegrandDenominators[nonzero];
FTAssert["a genuine pole is retained",nonzero["OrdinaryPowerBounds"][[1]]===1&&
 Cancel[Together[density[nonzero]-density[Join[fixture,<|"Terms"->Take[fixture["Terms"],1]|>]]]]===0];
noCoefficient=Join[fixture,<|"Terms"->{<|"Powers"->{1,0,0},"Numerator"->1|>,
 <|"Powers"->{1,1,0},"Numerator"->-1|>}|>];
noCoefficient=CancelMeasuredCutIntegrandDenominators[noCoefficient];
FTAssert["the same operation works without color or dimension coefficient variables",
 noCoefficient["RationalCancellation"]["Status"]==="Completed"&&
 Cancel[Together[density[noCoefficient]-1/(1+t)]]===0];
multiplePoles=fixture;
multiplePoles["Terms"]=Map[Join[#,<|"Numerator"->#["Numerator"]/(dim-3)|>]&,fixture["Terms"]];
multiplePoles=CancelMeasuredCutIntegrandDenominators[multiplePoles];
FTAssert["several dimension poles are cleared before coefficient-monomial cancellation",
 multiplePoles["RationalCancellation"]["Status"]==="Completed"&&
 Cancel[Together[density[multiplePoles]-density[cancelled]/(dim-3)]]===0];
FTReport[];
