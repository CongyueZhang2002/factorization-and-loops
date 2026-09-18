Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
geometry=<|"Coordinates"->{ss,vv,ww},"EndpointVariable"->ww,"DimensionalRegulator"->ee,
 "ExternalMomenta"->{pa,pb,kc},"KinematicRules"->{FeynCalc`SPD[pa]->0,FeynCalc`SPD[pb]->0,FeynCalc`SPD[kc]->0,
 FeynCalc`SPD[pa,pb]->ss/2,FeynCalc`SPD[pa,kc]->ss(1-vv)/2,FeynCalc`SPD[pb,kc]->ss vv ww/2},
 "DensityPrefactor"->1/(2ss),"Assumptions"->ss>0&&0<vv<1&&0<ww<=1|>;
map[role_,p_]:=FeynFacet`ConstructCollinearMomentumMap[geometry,<|"Role"->role,"Momentum"->p,"Variable"->ff|>];
a=map["PDF",pa];b=map["PDF",pb];c=map["FF",kc];
FTTest`FTAssert["all three invariant maps are derived",AllTrue[{a,b,c},AssociationQ]];
FTTest`FTAssert["incoming flux cancels the canonical current Mellin weight",AssociationQ[a]&&a["RegularMeasure"]===1&&b["RegularMeasure"]===1];
FTTest`FTAssert["outgoing weight follows dimensional operator sewing",AssociationQ[c]&&FullSimplify[c["RegularMeasure"]==ff^(-2+2ee),0<ff<1&&Element[ee,Reals]]];
FTTest`FTAssert["incoming B endpoint fraction is derived",AssociationQ[b]&&Together[b["Fraction"]-(1-vv)/(1-vv ff)]===0];
FTTest`FTAssert["outgoing endpoint fraction is derived",AssociationQ[c]&&Cancel[c["Fraction"]-(1-vv+vv ff)]===0];
g2=<|"Coordinates"->{qq,xx,zz,ww},"EndpointVariable"->ww,"DimensionalRegulator"->ee,
 "ExternalMomenta"->{p,q,k},"KinematicRules"->{FeynCalc`SPD[p]->0,FeynCalc`SPD[q]->-qq,FeynCalc`SPD[k]->0,
 FeynCalc`SPD[p,q]->qq/(2xx),FeynCalc`SPD[p,k]->qq zz/(2xx),
 FeynCalc`SPD[q,k]->qq(1-xx-zz-(1-xx)(1-zz)(1-ww))/(2xx)},
 "DensityPrefactor"->1,"Assumptions"->qq>0&&0<xx<1&&0<zz<1&&0<ww<=1|>;
d=FeynFacet`ConstructCollinearMomentumMap[g2,<|"Role"->"PDF","Momentum"->p,"Variable"->ff|>];
f=FeynFacet`ConstructCollinearMomentumMap[g2,<|"Role"->"FF","Momentum"->k,"Variable"->ff|>];
FTTest`FTAssert["fixed current incoming measure is generated",AssociationQ[d]&&d["RegularMeasure"]===1/ff];
FTTest`FTAssert["fixed current rescaling maps are derived",AssociationQ[d]&&AssociationQ[f]&&Together[d["Fraction"]-(xx+(1-xx)ff)]===0&&Together[f["Fraction"]-(zz+(1-zz)ff)]===0];
op=FeynFacet`BareCollinearOperatorNormalization["FF","g",zz,4-2ee];
FTTest`FTAssert["gluon and quark canonical sewing weights agree without extra final average",
 FullSimplify[op["PairingWeight"]==FeynFacet`BareCollinearOperatorNormalization["FF","q",zz,4-2ee]["PairingWeight"],0<zz<1&&Element[ee,Reals]]&&op["OutgoingColorAverage"]===1];
FTTest`FTAssert["NNLO pole times dimensional weight retains the finite log squared",
 FullSimplify[SeriesCoefficient[ff^(2ee)(b0+ee b1+ee^2 b2)/ee^2,{ee,0,0}]-b2-2Log[ff]b1-2Log[ff]^2 b0,0<ff<1]===0];
Print["DERIVED COLLINEAR NORMALIZATION COMPLETED"];FTTest`FTReport[];
