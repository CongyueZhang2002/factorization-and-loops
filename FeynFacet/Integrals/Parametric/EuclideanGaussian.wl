
(* Schwinger parameters for positive Euclidean quadratic forms. Rank-two
   denominators are allowed; an ordinary graph interpretation is unnecessary. *)
Begin["FeynFacet`Private`"];
FeynFacet`ConstructEuclideanParameterIntegral::usage="ConstructEuclideanParameterIntegral[data] integrates Euclidean loop vectors by Gaussian integration and returns explicit unit-cube Schwinger-parameter terms, preserving additional parameter integrals and normalization.";
FeynFacet`ConstructEuclideanParameterIntegral[data_Association] := Catch[Module[
 {eps=data["DimensionalRegulator"],dim=data["LoopDimension"],gram=Normal[data["ExternalGramMatrix"]],
 denominators=data["QuadraticDenominators"],additional=Lookup[data,"AdditionalIntegrationVariables",{}],
 pref=Lookup[data,"Prefactor",1],n,loops,external,powers,parameters,matrices,linear,constant,
 a,b,w,matrix,jvec,cvalue,u,f,adjugate,substitution,unitParameters,factors,term,
 scalarPref,positive,form,nu,determinantAtOne,minimumAtOne,condition,certificate},
 n=Length[denominators];If[n<1,boundaryIntegrationFail["EuclideanDenominatorsRequired"]];
 loops=Length[denominators[[1,"SquaredForms",1,"LoopCoefficients"]]];
 external=Length[gram];powers=Lookup[denominators,"Power"];
 If[!MatrixQ[gram,NumberQ]||Dimensions[gram]=!={external,external}||gram=!=Transpose[gram]||
   !AllTrue[Subsets[Range[external],{1,external}],Det[gram[[#,#]]]>=0&]||
   !AllTrue[powers,IntegerQ[#]&&#>0&],
   boundaryIntegrationFail["PositiveEuclideanGramAndIntegerPowersRequired"]];
 parameters=Table[Unique["schwingerParameter"],{n}];
 matrices=ConstantArray[0,{n,loops,loops}];linear=ConstantArray[0,{n,loops,external}];constant=ConstantArray[0,n];
 Do[
  Do[
   a=form["LoopCoefficients"];b=form["ExternalCoefficients"];w=Lookup[form,"Weight",1];
   If[Length[a]=!=loops||Length[b]=!=external||!FreeQ[{a,b,w},eps]||
     !VectorQ[a,NumberQ]||!VectorQ[b,NumberQ]||!PolynomialQ[w,additional],
    boundaryIntegrationFail["EuclideanSquaredFormInvalid"]];
   condition=And@@Join[Thread[additional>0],Thread[additional<1],{w<0}];
   positive=If[additional==={},TrueQ[w>=0],
     TrueQ[With[{xs=additional,q=condition},TimeConstrained[Resolve[Exists[xs,q],Reals],10,$Failed]]===False]];
   If[!positive,boundaryIntegrationFail["EuclideanSquaredFormWeightNotPositive"]];
   matrices[[k]]+=w Outer[Times,a,a];linear[[k]]+=w Outer[Times,a,b];constant[[k]]+=w b.gram.b,
  {form,denominators[[k,"SquaredForms"]]}],
 {k,n}];
 matrix=Total[MapThread[Times,{parameters,matrices}]];
 jvec=Total[MapThread[Times,{parameters,linear}]];
 cvalue=parameters.constant;u=Factor[Det[matrix]];
 If[u===0,Return[<|"DataType"->"EuclideanParameterIntegral","Representation"->"UnitCube",
   "DimensionalRegulator"->eps,"Terms"->{<|"IntegrationVariables"->{},"Prefactor"->0|>},
   "Scaleless"->True,"ScalelessReason"->"An unconstrained Euclidean loop direction."|>]];
 adjugate=Map[Cancel[Together[#]]&,u Inverse[matrix],{2}];
 f=Factor[u cvalue-Tr[adjugate.jvec.gram.Transpose[jvec]]];
 If[f===0,Return[<|"DataType"->"EuclideanParameterIntegral","Representation"->"UnitCube",
   "DimensionalRegulator"->eps,"Terms"->{<|"IntegrationVariables"->{},"Prefactor"->0|>},
   "Scaleless"->True,"ScalelessReason"->"No scale remains after a common shift of the Euclidean loop vectors.",
   "FirstSymanzikPolynomial"->u,"SecondSymanzikPolynomial"->f|>]];
 determinantAtOne=Cancel[u/.Thread[parameters->1]];
 minimumAtOne=Cancel[f/.Thread[parameters->1]];
 condition=And@@Join[Thread[additional>0],Thread[additional<1],
   {determinantAtOne<=0||minimumAtOne<=0}];
 positive=If[additional==={},TrueQ[determinantAtOne>0&&minimumAtOne>0],
   TrueQ[With[{xs=additional,q=condition},TimeConstrained[Resolve[Exists[xs,q],Reals],10,$Failed]]===False]];
 If[!positive,boundaryIntegrationFail["EuclideanGaussianInteriorPositivityNotEstablished"]];
 (* Cheng-Wu: the last Schwinger parameter is one; each other coordinate
    is t/(1-t). This avoids an unnecessary sum over primary sectors. *)
 unitParameters=Table[Unique["projectiveParameter"],{n-1}];
 substitution=Join[Thread[Most[parameters]->(#/(1-#)&/@unitParameters)],{Last[parameters]->1}];
 nu=Total[powers];
 scalarPref=pref Pi^(loops dim/2) Gamma[nu-loops dim/2]/Times@@(Gamma/@powers);
 factors=Join[
  MapThread[{#1,#2-1}&,{unitParameters,Most[powers]}],
  MapThread[{1-#1,-#2-1}&,{unitParameters,Most[powers]}],
  MapThread[{#1,#2}&,{additional,Lookup[data,"EndpointPowers",ConstantArray[0,Length[additional]]]}],
  MapThread[{1-#1,#2}&,{additional,Lookup[data,"UpperEndpointPowers",ConstantArray[0,Length[additional]]]}],
  {{u/.substitution,nu-(loops+1)dim/2},{f/.substitution,loops dim/2-nu}}];
 term=positiveRationalEulerTerm[Join[additional,unitParameters],factors,scalarPref];
 <|"DataType"->"EuclideanParameterIntegral","Representation"->"UnitCube","DimensionalRegulator"->eps,
  "Terms"->{term},"LoopCount"->loops,"LoopDimension"->dim,"Scaleless"->False,
  "SchwingerParameters"->parameters,"FirstSymanzikPolynomial"->u,"SecondSymanzikPolynomial"->f,
  "GaussianMatrix"->matrix,"GaussianExternalCoefficients"->jvec,"GaussianConstantTerm"->cvalue,
  "OriginalQuadraticForms"->denominators,"ExternalGramMatrix"->gram,"ProjectiveCoordinateMap"->substitution,
  "Scope"->"The meromorphic Euclidean integral. Any identification with a physical asymptotic coefficient requires a separate region/completeness proof.",
  "NormalizationChanged"->False|>
 ],"BoundaryIntegration"];
End[];
