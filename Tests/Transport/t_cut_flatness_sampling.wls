Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Clear[flatX,flatZ];checks=0;
check[label_,value_]:=If[TrueQ[value],checks++,Print["FAIL ",label];Exit[1]];
connection={SparseArray[{{0,1/flatZ},{0,0}}],SparseArray[{{0,0},{0,1/flatZ}}]};
points={{flatX->1/3,flatZ->2/5},{flatX->2/7,flatZ->3/8}};
sample=Catch[FeynFacet`Private`cutDifferentialFlatnessCheck[connection,{flatX,flatZ},points],"CutFamily"];
exact=Catch[FeynFacet`Private`cutDifferentialFlatnessCheck[connection,{flatX,flatZ},{}],"CutFamily"];
check["noncommuting flat connection rational samples",AssociationQ[sample]&&TrueQ[sample["FlatnessPassed"]]];
check["same connection exact functions",AssociationQ[exact]&&TrueQ[exact["FlatnessPassed"]]];
bad=ReplacePart[connection,2->SparseArray[{{0,0},{0,-1/flatZ}}]];
check["nonflat connection rejected",FailureQ[Catch[
 FeynFacet`Private`cutDifferentialFlatnessCheck[bad,{flatX,flatZ},points],"CutFamily"]]];
check["singular point rejected",FailureQ[Quiet[Catch[
 FeynFacet`Private`cutDifferentialFlatnessCheck[connection,{flatX,flatZ},{{flatX->1/3,flatZ->0}}],"CutFamily"]]]];
check["incomplete point rejected",FailureQ[Catch[
 FeynFacet`Private`cutDifferentialFlatnessCheck[connection,{flatX,flatZ},{{flatX->1/3}}],"CutFamily"]]];
check["zero one-variable curvature",AssociationQ[Catch[
 FeynFacet`Private`cutDifferentialFlatnessCheck[{First[connection]},{flatX},points],"CutFamily"]]];
Print["CUT FLATNESS TESTS PASS ",checks];
