$HistoryLength=0;$MaxExtraPrecision=50;
Print["FEYNFACET DRIVER ENTERED"];
root=Directory[];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];$PrePrint=.;
base=FileNameJoin[{root,"Projects","SIDIS_UU_NNLO","NNLO","q-q","Results","DoubleReal","CompleteChannels"}];
names={"ExactReduction.wl","ReducedDifferentialSystem.wl","RegularDifferentialSystem.wl",
 "DifferentialRelationClosure.wl","RegularBasisReduction.wl","RegularPhysicalMasterCoefficients.wl",
 "RegularScalarSolutionRequest.wl","EndpointAssemblyPlan.wl"};
records=Association@Table[
 data=FeynFacet`FamilyArtifactRead[FileNameJoin[{base,name}]];
 If[!AssociationQ[data],Print["FAILED ",name];Exit[1]];
 Print["RECORD ",name," KEYS ",Keys[data]];
 basis=Lookup[data,"MasterIntegralBasis",Lookup[data,"Masters",Lookup[data,"CurrentMasterIntegralBasis",Missing["Absent"]]]];
 item=<|"Source"->FileNameJoin[{"Projects","SIDIS_UU_NNLO","NNLO","q-q","Results","DoubleReal","CompleteChannels",name}],"Keys"->Keys[data]|>;
 If[ListQ[basis],AssociateTo[item,{"BasisCount"->Length[basis],"UniqueBasisCount"->Length[DeleteDuplicates[basis]],"FamilyLabelCount"->Length[DeleteDuplicates[First/@basis]]}]];
 Do[If[KeyExistsQ[data,key]&&ListQ[data[key]],AssociateTo[item,key<>"Count"->Length[data[key]]]],{key,{"Targets","Families","Rows","Contributions","Jobs","Coefficients","SourceGroups","Outputs"}}];
 If[KeyExistsQ[data,"ConnectionMatrices"],AssociateTo[item,"ConnectionDimensions"->(Dimensions/@Values[AssociationThread[Range[Length[data["ConnectionMatrices"]]],If[AssociationQ[data["ConnectionMatrices"]],Values[data["ConnectionMatrices"]],data["ConnectionMatrices"]]]])]];
 Do[If[KeyExistsQ[data,key],AssociateTo[item,key->data[key]]],{key,{"Dimension","Verification","Status","MasterMinimality","Complete","DifferentialSystemFile","PhysicalCoefficientFile"}}];
 Print["SUMMARY ",InputForm[item]];
 name->item,{name,names}];
If[!AllTrue[{"ExactReduction.wl","ReducedDifferentialSystem.wl","RegularDifferentialSystem.wl","RegularBasisReduction.wl","RegularPhysicalMasterCoefficients.wl"},IntegerQ[Lookup[records[#],"BasisCount",None]]&],Print["FAILED COUNT EXTRACTION"];Exit[1]];
FeynFacet`FamilyArtifactWrite[<|"ReadbackOnly"->True,"DataType"->"StoredMasterCountAudit","Scope"->"SIDIS UU/LL shared double-real production records; no new reduction or paper-basis mapping","Records"->records|>,FileNameJoin[{DirectoryName[$InputFileName],"StoredCounts.wl"}],Compression->False];
Print["MASTER COUNT AUDIT COMPLETE"];
