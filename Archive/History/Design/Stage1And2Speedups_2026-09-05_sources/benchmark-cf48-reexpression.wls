
$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
input=Import[root<>"/ppHX_NNLO_DoubleReal/Results/RequestedMasterIntegralSolutions/CF48/input.wxf","WXF"]["Data"];
matrix=input["BasisTransformationMatrix"];vars=input["CoefficientVariables"];eps=input["DimensionalRegulator"];
presentation=input["CoefficientPresentation"];sourceVars=presentation["SourceVariables"];
rad=presentation["RationalizedSquareRoots"][[1,"SourceRadicand"]];rt=Sqrt[rad];
images={sourceVars[[2]],(rt-sourceVars[[1]])/2};
positions=Take[Reverse[SortBy[Position[matrix,z_/;z=!=0,{2},Heads->False],LeafCount[Extract[matrix,#]]&]],UpTo[2]];
gauge={Extract[matrix,positions]};
denominator=PolynomialLCM@@(Denominator[Together[#]]& /@ Flatten[gauge]);
roots={<|"Generator"->rt,"QuadraticRadicand"->rad|>};
Export[DirectoryName[ExpandFileName[$InputFileName]]<>"/cf48-reexpression-input.wxf",
 <|"MatrixPositions"->positions,"BasisTransformationBlock"->gauge,"Denominator"->denominator,
 "CoefficientVariables"->vars,"InverseCoordinateImages"->images,"SourceVariables"->sourceVars,
 "DimensionalRegulator"->eps,"SquareRootGenerators"->roots|>,"WXF"];
source="/FeynFacet/Private/EpsForm/FiniteField/FiniteFieldBasisTransformationReexpression.wl";
run[]:=FeynFacet`Private`reexpressBasisTransformationInSourceVariablesFiniteField[
 gauge,denominator,vars,images,sourceVars,eps,roots,
 "Primes"->{1000003,2147483423},"MinimumPrimeCount"->2,"MaximumPrimeCount"->2,
 "MaximumKinematicTotalDegree"->12,"MaximumEpsilonTotalDegree"->14,
 "HeldOutPointCount"->4,"SymbolicPreDispatchSeconds"->0];
Block[{$Context="FeynFacet`Private`",$ContextPath={"System`","FeynFacet`"}},Get[DirectoryName[ExpandFileName[$InputFileName]]<>"/before"<>source]];
bt=First[AbsoluteTiming[b=TimeConstrained[run[],120,$Aborted]]];
Print[{"Before",bt,Lookup[b,"Status",None]}];
Block[{$Context="FeynFacet`Private`",$ContextPath={"System`","FeynFacet`"}},Get[root<>source]];
at=First[AbsoluteTiming[a=TimeConstrained[run[],120,$Aborted]]];
Print[{"After",at,Lookup[a,"Status",None]}];
same=Lookup[b,"Status",None]==="FiniteFieldBasisTransformationReexpressionConstructed" &&
 Lookup[a,"Status",None]==="FiniteFieldBasisTransformationReexpressionConstructed" && b["Result"]===a["Result"];
residual=If[same,Flatten[Map[FeynFacet`Private`multiquadraticFieldDecompose[#,roots]&,
 a["Result"]-(gauge/.Thread[vars->images]),{2}]],{$Failed}];
exact=FreeQ[residual,$Failed] && AllTrue[residual,Together[#]===0&];
report=<|"Family"->"CF48","Scope"->"Source-coordinate reconstruction of two largest entries of the saved complete basis transformation; excludes the chart solve.",
 "MatrixPositions"->positions,"BeforeSeconds"->bt,"AfterSeconds"->at,
 "SameExactResult"->same,"AllGradesZeroResidual"->exact|>;
Export[DirectoryName[ExpandFileName[$InputFileName]]<>"/stage1-cf48.json",report,"RawJSON"];Print[InputForm[report]];
If[!TrueQ[same && exact],Print[{a,b}];Exit[1]];
