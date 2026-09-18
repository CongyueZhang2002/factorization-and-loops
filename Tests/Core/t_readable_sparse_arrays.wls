Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/FeynFacet/Core/RecordFormat.wl"];
directory=CreateDirectory[];file=directory<>"/Sparse.wl";
left=SparseArray[{{1,2}->SparseLeft`x,{3,1}->SparseRight`x},{3,4},SparseDefault`d];
value=<|"Matrix"->left,"Inactive"->Inactive[SparseArray][{{1,1}->SparseLeft`x},{2,2}],
 "Text"->"Inactive[SparseArray] SparseArray[", "Key"-><|HoldComplete[left]->SparseLeft`x|>|>;
Print["WRITING"];If[FeynFacetRecords`WriteRecord[value,file]===$Failed,Print["WRITE FAILED ",FeynFacetRecords`Private`encode[value]];Exit[1]];
text=System`ReadString[file];
If[FeynFacetRecords`Private`recordQualifiedTextQ[text],Print["QUALIFIED OUTPUT"];Exit[1]];
Print["READING"];read=FeynFacetRecords`ReadRecord[file];
If[read=!=value,Print["ROUND TRIP FAILED ",{Head[read],InputForm[read]}];Exit[1]];
Print["PLAIN"];Get[file];
If[!FreeQ[Get[file]["Matrix"],_Inactive],Print["UNEVALUATED ARRAY"];Exit[1]];
FeynFacetRecords`DeleteRecord[file];DeleteDirectory[directory];
Print["READABLE SPARSE ARRAY TESTS PASS 3"];
