
#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[x,y,ep];zero={{{0}},{{0}}};
record[b_]:=<|"Variables"->{x,y},"Regulator"->ep,
 "OffDiagonalBlockEquation"->{zero,zero,b}|>;
r=AnalyzeOffDiagonalBlockEpsilonFormObstructions[
 record[{{{ep/(1+x^2)}},{{0}}}],"MaximumOrder"->1,"Alphabet"->{1+x^2},
 "TransverseLines"->2];
FTAssert["different constant residues on geometric components do not certify nonexistence",
 r["Status"]==="ResidueComponentsNotResolved" &&
 !r["ConclusionScope"]["GenericNonexistenceProved"] &&
 Together[1/(1+x^2)-(D[Log[x-I],x]-D[Log[x+I],x])/(2I)]===0];
r=AnalyzeOffDiagonalBlockEpsilonFormObstructions[record[{{{1/ep}},{{0}}}],"MaximumOrder"->1];
FTAssert["a Taylor diagnostic refuses inputs needing a Laurent lower order",
 r["Status"]==="LaurentExpansionLowerOrderRequired" &&
 !r["ConclusionScope"]["GenericNonexistenceProved"]];
r=AnalyzeOffDiagonalBlockEpsilonFormObstructions[record[{{{ep/Sqrt[1+x]}},{{0}}}],"MaximumOrder"->1];
FTAssert["the rational diagnostic does not make claims on an algebraic coefficient field",
 r["Status"]==="UnsupportedCoefficientField"];
r=AnalyzeOffDiagonalBlockEpsilonFormObstructions[record[{{{ep}},{{0}}}],
 "MaximumOrder"->1,"TransverseLines"->0];
FTAssert["zero residue samples are not accepted as evidence",r["Status"]==="InvalidExpansionDiagnosticOptions"];
screen=FeynFacet`Private`multiquadraticOffDiagonalBlockIntegrabilityScreen;
nonclosed=screen[record[{{{ep y}},{{0}}}],{},
 {<|"Letter"->Missing["Supplied"],"OneForm"->{y,0}|>},"PointCount"->2,"ScoreLetters"->False];
FTAssert["elimination of the gauge requires closed target one-forms",
 nonclosed["Status"]==="IntegrabilityScreenNotApplicable" &&
 nonclosed["Reason"]==="TargetOneFormsNotClosed"];
fixed=screen[record[{{{ep y}},{{0}}}],{},
 {<|"Letter"->x,"OneForm"->{1/x,0}|>},"PointCount"->2,"ScoreLetters"->False];
FTAssert["a sampled inconsistency records its fixed target and arithmetic scope",
 fixed["Status"]==="AlphabetDLogAnsatzInconsistentAtFiniteFieldImage" &&
 fixed["ConclusionScope"]["GaugeAnsatzEliminated"] &&
 !fixed["ConclusionScope"]["GenericNonexistenceProved"] &&
 !fixed["ConclusionScope"]["AlphabetCompletenessProved"] &&
 !fixed["ConclusionScope"]["OtherBasesExcluded"]];
FTAssert["production letter-rank diagnostics are opt in",
 Lookup[Options[FeynFacet`Private`solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators],
 "IntegrabilityScreenScoreLetters",None]===False];
strictRecord=<|"Variables"->{x,y},"Regulator"->ep,
 "OffDiagonalBlockEquation"->{{{{1/x}},{{0}}},zero,{{{ep/(1+x)^2}},{{0}}}}|>;
strictPreparation=FeynFacet`Private`PrepareOffDiagonalBlockFiniteFieldSystem[strictRecord];
dependentRecord=ReplacePart[strictRecord,{"OffDiagonalBlockEquation",1,1,1,1}->1/(ep x)];
dependentPreparation=FeynFacet`Private`PrepareOffDiagonalBlockFiniteFieldSystem[dependentRecord];
FTAssert["kinematic pole bounds require epsilon-independent diagonal coefficients",
 strictPreparation["SupportCensus"]["CertifiedQ"] &&
 !dependentPreparation["SupportCensus"]["CertifiedQ"] &&
 !dependentPreparation["SupportCensus"]["DiagonalConnectionsEpsilonIndependentQ"] &&
 !strictPreparation["SupportCensus"]["RegulatorInterpolationCompletenessProved"]];
FTReport[];

