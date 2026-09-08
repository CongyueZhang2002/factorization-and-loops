(* Independent entry points and an actual data-only catalog extension. *)
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Get[FileNameJoin[{root,"FeynFacet","Solution.m"}]];
FTTest`FTAssert["reader loads without FeynCalc or symbolic construction",
 !MemberQ[$Packages,"FeynCalc`"] &&
 Length[DownValues[FeynFacetSolution`ReadMasterIntegralSolution]]===1 &&
 System`Names["FeynFacet`Private`solutionFail"]==={}];
Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]];
FTTest`FTAssert["symbolic entry leaves epsilon form unloaded",
 !TrueQ[FeynFacet`Private`$feynFacetEpsilonFormLoaded] &&
 DownValues[FeynFacet`DiagonalBlockEpsForm]==={}];
FTTest`FTAssert["symbolic source provenance is initialized for topology records",
 StringQ[FeynFacet`Private`$feynFacetSourceHash] && StringLength[FeynFacet`Private`$feynFacetSourceHash]>0];
entrySolution=FeynFacet`ConstructMasterIntegralSolution[
 <|"KinematicVariables"->{entryX},"DimensionalRegulator"->entryEpsilon,
   "ConnectionMatrices"->{{{entryEpsilon}}}|>,
 <|"BasePoint"->{0},"RequestedEpsilonOrders"->{0,1,2},
   "AnalyticDomain"->"A neighborhood of the origin.",
   "BranchPrescription"->"Continuation from the origin."|>];
FTTest`FTAssert["finite solver works without epsilon form",
 FeynFacet`MasterIntegralSolutionQ[entrySolution] &&
 !TrueQ[FeynFacet`Private`$feynFacetEpsilonFormLoaded]];
entryMap=<|"Name"->"OneSquareRootExample","ParametrizingVariables"->{entryP,entryQ},
 "SourceVariableSubstitution"->{entryU->entryP^2,entryV->entryQ},
 "RationalizedSquareRoots"->{<|"SourceRadicand"->entryU,"RationalRoot"->entryP|>}|>;
entryCount=Length[FeynFacet`RationalizingParametrizationCatalog[]];
entryRegistered=FeynFacet`RegisterRationalizingParametrizations[<|"OneSquareRootExample"->entryMap|>];
FTTest`FTAssert["new rationalizing map is a verified data entry",
 AssociationQ[entryRegistered] && !FailureQ[entryRegistered] &&
 Length[FeynFacet`RationalizingParametrizationCatalog[]]===entryCount+1 &&
 TrueQ[FeynFacet`VerifyRationalizingParametrization[
  FeynFacet`RationalizingParametrizationCatalog[]["OneSquareRootExample"]]["Verified"]]];
entryInvalid=Join[entryMap,<|"Name"->"InvalidRootExample",
 "RationalizedSquareRoots"->{<|"SourceRadicand"->entryU,"RationalRoot"->entryP+1|>}|>];
FTTest`FTAssert["invalid registration changes nothing",
 FailureQ[FeynFacet`RegisterRationalizingParametrizations[<|"InvalidRootExample"->entryInvalid|>]] &&
 Length[FeynFacet`RationalizingParametrizationCatalog[]]===entryCount+1];
FTTest`FTAssert["conflicting name changes nothing",
 FailureQ[FeynFacet`RegisterRationalizingParametrizations[
 <|"OneSquareRootExample"->Join[entryMap,<|"Notes"->"conflicting entry"|>]|>]] &&
 Length[FeynFacet`RationalizingParametrizationCatalog[]]===entryCount+1];
Get[FileNameJoin[{root,"FeynFacet","EpsilonForm.m"}]];
FTTest`FTAssert["optional entry adds epsilon-form algorithms",
 TrueQ[FeynFacet`Private`$feynFacetEpsilonFormLoaded] &&
 Length[DownValues[FeynFacet`DiagonalBlockEpsForm]]>0];
entryWorkers=LaunchKernels[2];
With[{loader=FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}],
 additions=FeynFacet`Private`$feynFacetAdditionalLoadFiles},
 entryWorkerState=ParallelEvaluate[
  Block[{$Output={}},Get[loader];Scan[Get,additions]];
  {TrueQ[FeynFacet`Private`$feynFacetEpsilonFormLoaded],
   Length[DownValues[FeynFacet`DiagonalBlockEpsForm]]>0},entryWorkers]];
FTTest`FTAssert["worker bootstrap inherits optional algorithms",
 entryWorkerState==={{True,True},{True,True}}];
CloseKernels[entryWorkers];
Get[FileNameJoin[{root,"FeynFacet","Solution.m"}]];
FTTest`FTAssert["reader works after symbolic and optional loading",
 Length[DownValues[FeynFacetSolution`EvaluateMasterIntegralSolution]]>0 &&
 FeynFacet`MasterIntegralSolutionQ[entrySolution]];
Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]];
FTTest`FTAssert["Get reload resets optional algorithms and catalog additions",
 !TrueQ[FeynFacet`Private`$feynFacetEpsilonFormLoaded] &&
 DownValues[FeynFacet`DiagonalBlockEpsForm]==={} &&
 Length[FeynFacet`RationalizingParametrizationCatalog[]]===entryCount];
FTTest`FTReport[];
