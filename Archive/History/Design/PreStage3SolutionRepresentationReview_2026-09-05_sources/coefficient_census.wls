$HistoryLength=0;
base="/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/DifferentialEquationDataV2";
Clear[runCensus];
runCensus[family_] := Module[{record,matrices,n,terms,next,summary={},seconds,nnz,file,k},
 record=Get[FileNameJoin[{base,family,"FamilyDLogEpsilonForm.wl"}]];
 matrices=SparseArray /@ record["ConstantResidueMatrices"];
 n=Length[record["OriginalMasterIntegralBasis"]];
 terms={{{},IdentityMatrix[n,SparseArray]}};
 Do[
  next=TimeConstrained[Reap[
    Do[With[{product=SparseArray[matrices[[j]].term[[2]]]},
      If[Length[product["NonzeroPositions"]]>0,
        Sow[{Prepend[term[[1]],j],product}]]],
      {term,terms},{j,Length[matrices]}]
    ][[2]],45,$Aborted];
  If[next===$Aborted,Print[family," weight ",k," timed out"];Break[]];
  terms=If[next==={}, {},First[next]];
  nnz=Total[Length[#[[2]]["NonzeroPositions"]]& /@ terms];
  file=FileNameJoin[{"/tmp/feynfacet-prestage3-review",family<>"_canonical_coefficients_order_"<>ToString[k]<>".wl"}];
  Put[terms,file];
  AppendTo[summary,<|"EpsilonOrder"->k,"NonzeroLetterSequences"->Length[terms],
    "ScalarNonzeroCoefficients"->nnz,"WolframBytes"->ByteCount[terms],"TextBytes"->FileByteCount[file]|>];
  Print[family," ",InputForm[Last[summary]]];
  If[Length[terms]>50000,Break[]],
 {k,1,4}];
 <|"Family"->family,"MasterCount"->n,"LetterCount"->Length[matrices],
   "Scope"->"Canonical fundamental-matrix coefficients only; not original-basis master solutions or established epsilon-order coverage",
   "Orders"->summary|>
];
results=runCensus /@ {"CF269","CF48"};
Export["/tmp/feynfacet-prestage3-review/coefficient_census.json",results,"RawJSON"];
