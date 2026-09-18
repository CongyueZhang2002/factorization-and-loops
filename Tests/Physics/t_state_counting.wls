Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Normalization/StateCounting.wl"];
FTTest`FTAssert["two unobserved identical gluons",FeynFacet`FinalStateSymmetryFactor[{"g","g"}]===1/2];
FTTest`FTAssert["tag distinguishes one identical particle",FeynFacet`FinalStateSymmetryFactor[{"g","g","g"},{1}]===1/2];
FTTest`FTAssert["fully integrated identical triple",FeynFacet`FinalStateSymmetryFactor[{"g","g","g"}]===1/6];
FTTest`FTAssert["a quark and antiquark are distinct",FeynFacet`FinalStateSymmetryFactor[{{"q","u"},{"qb","u"}}]===1];
FTTest`FTAssert["invalid tag rejected",FailureQ[FeynFacet`FinalStateSymmetryFactor[{"g"},{2}]]];
classes=<|"Up"-><|"Members"->{"u","c","t"},"Multiplicity"->nU|>,"Down"-><|"Members"->{"d","s","b"},"Multiplicity"->nD|>|>;
m[parts_,fixed_,summed_]:=FeynFacet`FlavorAssignmentMultiplicity[parts,fixed,summed,classes];
FTTest`FTAssert["different up pair excludes external flavor",m[{{"q","c"},{"qb","c"}},{{"q","u"}},{"c"}]["Multiplicity"]===nU-1];
FTTest`FTAssert["different charge class is counted separately",m[{{"q","d"},{"qb","d"}},{{"q","u"}},{"d"}]["Multiplicity"]===nD];
FTTest`FTAssert["two unlabeled distinct pairs counted once",Expand[m[{{"q","c"},{"qb","c"},{"q","t"},{"qb","t"}},{{"q","u"}},{"c","t"}]["Multiplicity"]-(nU-1)(nU-2)/2]===0];
FTTest`FTAssert["unlike particle roles distinguish flavor bindings",Expand[m[{{"q","c"},{"qb","t"}},{{"q","u"}},{"c","t"}]["Multiplicity"]-(nU-1)(nU-2)]===0];
FTTest`FTAssert["fixed external flavor cannot be a dummy",FailureQ[m[{{"q","u"}},{{"q","u"}},{"u"}]]];
FTTest`FTAssert["flavor representative relabeling leaves count invariant",m[{{"q","c"},{"qb","c"}},{{"q","u"}},{"c"}]["Multiplicity"]===m[{{"q","t"},{"qb","t"}},{{"q","u"}},{"t"}]["Multiplicity"]];
FTTest`FTAssert["identical state factor and distinct flavor orbit are separate",m[{{"q","c"},{"q","c"}},{{"q","u"}},{"c"}]["Multiplicity"]FeynFacet`FinalStateSymmetryFactor[{{"q","c"},{"q","c"}}]===(nU-1)/2];

full=FeynFacet`FinalStateMeasurementNormalization[{"g","g","g"},<|"Representation"->"FullTupleSum"|>];
self=FeynFacet`FinalStateMeasurementNormalization[{"g","g","g"},<|"Representation"->"OneTuplePerOrbit","Tuple"->{1,1},"Ordered"->True|>];
distinct=FeynFacet`FinalStateMeasurementNormalization[{"g","g","g"},<|"Representation"->"OneTuplePerOrbit","Tuple"->{1,2},"Ordered"->True|>];
unordered=FeynFacet`FinalStateMeasurementNormalization[{"g","g","g"},<|"Representation"->"OneTuplePerOrbit","Tuple"->{1,2},"Ordered"->False|>];
FTTest`FTAssert["self pairs use the one-particle stabilizer",self["Factor"]===3full["Factor"]&&self["Factor"]===1/2];
FTTest`FTAssert["ordered distinct pairs use the two-particle stabilizer",distinct["Factor"]===6full["Factor"]&&distinct["Factor"]===1];
FTTest`FTAssert["unordered distinct pairs carry no hidden factor two",unordered["Factor"]===3full["Factor"]&&unordered["Factor"]===1/2];
Do[
 concrete=DeleteDuplicates[Sort[{{"q",#[[1]]},{"qb",#[[1]]},{"q",#[[2]]},{"qb",#[[2]]}}]&/@
  Select[Tuples[Range[2,n],2],DuplicateFreeQ]];
 counted=m[{{"q","c"},{"qb","c"},{"q","t"},{"qb","t"}},{{"q","u"}},{"c","t"}]["Multiplicity"]/.nU->n;
 FTTest`FTAssert["two-new-flavor count agrees with explicit assignments at N="<>ToString[n],counted===Length[concrete]],
 {n,1,5}];
row[parts_,sum_,context_:0]:=<|"UnobservedPartons"->parts,"FlavorSum"->sum,"Context"->context|>;
pair[label_]:={{"q",label},{"qb",label}};
coverage[rows_]:=FeynFacet`VerifyDisjointFlavorStateSums[rows,{{"q","u"}},classes];
FTTest`FTAssert["renamed dummy sums cannot be added twice",FailureQ[coverage[<|"A"->row[pair["c"],{"c"}],"B"->row[pair["t"],{"t"}]|>]]];
FTTest`FTAssert["fixed representative overlapping an inclusive sum is rejected",FailureQ[coverage[<|"A"->row[pair["c"],{"c"}],"B"->row[pair["t"],{}]|>]]];
FTTest`FTAssert["different complete perturbative contributions may share final species",coverage[<|"A"->row[pair["c"],{"c"},0],"B"->row[pair["c"],{"c"},1]|>]===True];
FTTest`FTAssert["same and different flavor states are disjoint",coverage[<|"A"->row[pair["c"],{"c"}],"B"->row[pair["u"],{}]|>]===True];
FTTest`FTAssert["different model classes are disjoint",coverage[<|"A"->row[pair["c"],{"c"}],"B"->row[pair["d"],{"d"}]|>]===True];
Get[root<>"/FeynFacet/Physics/Measurements.wl"];
measurement=Get[root<>"/Projects/EE_EEC/Common-Card.wl"]["Assembly"]["FinalStateMeasurement"];
momenta={eventP1,eventP2,eventP3};
terms=FeynFacet`FinalStateMeasurementTerms[measurement,momenta];
eventRules=Join[(FeynCalc`SPD[q,#]->1/3&/@momenta),
 Flatten[Table[FeynCalc`SPD[momenta[[i]],momenta[[j]]]->If[i===j,0,1/6],{i,3},{j,3}]],{Q2->1}];
FTTest`FTAssert["EEC actual card has unit event energy weight",Total[Lookup[terms,"Weight"]/.eventRules]===1];
FTTest`FTAssert["EEC actual card has half-weight angular first moment",Total[(#["Weight"]#["Observable"]&/@terms)/.eventRules]===1/2];
FTTest`FTAssert["one cut ghost pair has the Grassmann minus sign",
 FeynFacet`Private`assemblyGhostSign[<|"Partons"->({}-> {FeynArts`U[5],-FeynArts`U[5]})|>]===-1];
FTTest`FTAssert["two ghosts without conjugate partners are rejected",
 FeynFacet`Private`assemblyGhostSign[<|"Partons"->({}-> {FeynArts`U[5],FeynArts`U[5]})|>]===$Failed];
Print["STATE COUNTING COMPLETED"];FTTest`FTReport[];
