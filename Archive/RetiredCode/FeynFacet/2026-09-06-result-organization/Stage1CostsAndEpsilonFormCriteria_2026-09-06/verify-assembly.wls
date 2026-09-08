
root=DirectoryName[ExpandFileName[$InputFileName],3];
inputDir=Environment["FACET_VERIFICATION_INPUT_DIR"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
normalize[expr_]:=expr/.s_Symbol/;MemberQ[{"x","y","eps","ep"},SymbolName[Unevaluated[s]]]:>Switch[SymbolName[Unevaluated[s]],"x",x,"y",y,_,eps];
record=normalize[Import[FileNameJoin[{inputDir,"CF259-after-assembly.wxf"}],"WXF"]];
a=record["FamilyDifferentialSystem"];ranges=a["Ranges"];n=a["N"];
oldA=normalize[Import[FileNameJoin[{inputDir,"CF259-before-assembled-connection.wxf"}],"WXF"]];
T=ConstantArray[0,{n,n}];Ti=T;
Do[T[[ranges[[k]],ranges[[k]]]]=a["Forms"][[k]]["T"];
 Ti[[ranges[[k]],ranges[[k]]]]=a["TInverse"][[k]],{k,Length[ranges]}];
dT={D[T,x],D[T,y]};
newA={a["Apv"],a["Apw"]};original={a["Av"],a["Aw"]};
points={{1/11,1/17,1/13},{2/13,1/19,-1/11},{1/7,2/23,1/17}};
results=Table[
 rules=Thread[{x,y,eps}->N[pt,80]];
 tn=T/.rules;tin=Ti/.rules;newn=newA/.rules;oldn=oldA/.rules;an=original/.rules;dn=dT/.rules;
 difference=Max[Abs[Flatten[newn-oldn]]];
 residual=Max[Table[Max[Abs[Flatten[an[[k]].tn-dn[[k]]-tn.newn[[k]]]]],{k,2}]];
 inverseResidual=Max[Abs[Flatten[tin.tn-IdentityMatrix[n]]]];
 <|"Point"->ToString[pt,InputForm],"OriginalVsNewConnectionDifference"->ToString[difference,InputForm],
 "GaugeEquationResidual"->ToString[residual,InputForm],"InverseResidual"->ToString[inverseResidual,InputForm],
 "Passed"->TrueQ[Max[difference,residual,inverseResidual]<10^-55]|>,{pt,points}];
Export[FileNameJoin[{inputDir,"assembly-validation.json"}],results,"RawJSON"];
Print[results];Print["CHECKS ",Count[Lookup[results,"Passed"],True]," / ",Length[points]];
Exit[If[And@@Lookup[results,"Passed"],0,1]];
