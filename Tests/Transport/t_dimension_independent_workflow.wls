$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
ndA={{0,1,0},{0,0,0},{0,0,0}};ndB={{0,0,0},{0,0,1},{0,0,0}};
Do[
 ndVars=Take[{ndX,ndY,ndZ},ndDimension];ndBase=Table[1/Prime[j+2],{j,ndDimension}];
 ndF=Times@@ndVars;ndG=Total[ndVars^2];
 (* An explicit noncommuting, flat connection with a known fundamental matrix. *)
 ndU=(IdentityMatrix[3]+ndEps ndF ndA).(IdentityMatrix[3]+ndEps ndG ndB);
 ndConnection=Map[Expand,D[ndU,#].Inverse[ndU],{2}]&/@ndVars;
 ndSystem=<|"KinematicVariables"->ndVars,"DimensionalRegulator"->ndEps,
  "DimensionRule"->(D->4-2ndEps),"OriginalMasterIntegralBasis"->Range[3],
  "ConnectionMatrices"->(SparseArray/@(ndConnection/.ndEps->(4-D)/2))|>;
 ndRequest=<|"BasePoint"->ndBase,"RequestedMasterIntegralOrderRanges"->AssociationThread[Range[3],ConstantArray[{0,1},3]],
  "MasterIntegralLaurentLowerBounds"->AssociationThread[Range[3],ConstantArray[-1,3]]|>;
 ndPlan=FeynFacet`DetermineMasterIntegralExpansionOrders[ndSystem,ndRequest];
 FTTest`FTAssert[ToString[ndDimension]<>" variables use the common order planner",
  AssociationQ[ndPlan]&&ndPlan["Status"]==="SufficientForAssumedLaurentBounds"&&
  FreeQ[ndPlan["PreparedDifferentialSystem"]["ConnectionMatrices"],D]];
 ndSolution=FeynFacet`ConstructMasterIntegralSolution[ndSystem,ndRequest,"FlatnessCheck"->"Exact"];
 If[FailureQ[ndSolution],Print[ndSolution]];
 FTTest`FTAssert[ToString[ndDimension]<>" variables produce explicit master coefficients in the same format",
  FeynFacet`MasterIntegralSolutionQ[ndSolution]&&ndSolution["RequestedMasterIntegralEpsilonOrders"]==={0,1}&&
  ndSolution["InitialConstantLaurentLowerBounds"]==={-1,-1,-1}];
 ndCheck=FeynFacet`VerifyMasterIntegralSolution[ndSolution,"IdentityCheck"->"Exact"];
 FTTest`FTAssert[ToString[ndDimension]<>" variable coefficient identities satisfy every PDE and normalization",
  AssociationQ[ndCheck]&&ndCheck["Status"]==="FiniteSolutionCoefficientIdentitiesVerified"&&
  TrueQ[ndCheck["ExactGenericIdentityProof"]]],
 {ndDimension,1,3}];
FTTest`FTReport[];
