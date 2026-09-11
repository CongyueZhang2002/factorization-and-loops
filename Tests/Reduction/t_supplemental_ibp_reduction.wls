Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
t={FeynCalc`GLI[GF,{1,1,2,-1}],FeynCalc`GLI[GF,{1,1,1,-2}]};
records={<|"Topology"->FeynCalc`FCTopology[GF,{a,b,c,d},{k},{p},{},{}],"CutIndices"->{1,2}|>};
log="This integral is unreduced: GF[1,1,2,-1] # 7\nunreduced integrals: 1.";
FTTest`FTAssert["unreduced export entries are matched to explicit requested integrals",
 FeynFacet`Private`ibpUnreducedExportIntegrals[log,t,{1}]===Take[t,1]];
FTTest`FTAssert["a count mismatch cannot trigger a partial recovery",
 Quiet[Catch[FeynFacet`Private`ibpUnreducedExportIntegrals[log,t,{2}],FeynFacet`Private`$ibpFailure]]===$Failed];
FTTest`FTAssert["an unrequested dependency is rejected",
 Quiet[Catch[FeynFacet`Private`ibpUnreducedExportIntegrals[log,Rest[t],{1}],FeynFacet`Private`$ibpFailure]]===$Failed];
m=FeynCalc`GLI[GF,{1,1,1,0}];
FTTest`FTAssert["exact nontrivial cut-preserving supplementary reductions are admitted",
 FeynFacet`Private`ibpSupplementalRulesQ[{t[[1]]->2m,t[[2]]->m/3},t,records]];
FTTest`FTAssert["supplementary master declarations cannot masquerade as reductions",
 !FeynFacet`Private`ibpSupplementalRulesQ[{t[[1]]->t[[1]],t[[2]]->m},t,records]];
FTTest`FTAssert["mutually dependent supplementary targets are not accepted",
 !FeynFacet`Private`ibpSupplementalRulesQ[{t[[1]]->t[[2]],t[[2]]->t[[1]]},t,records]];
FTTest`FTAssert["cut pinches and numerical coefficients are rejected",
 !FeynFacet`Private`ibpSupplementalRulesQ[{t[[1]]->FeynCalc`GLI[GF,{0,1,1,0}],t[[2]]->m},t,records]&&
 !FeynFacet`Private`ibpSupplementalRulesQ[{t[[1]]->1.2m,t[[2]]->m},t,records]];
FTTest`FTAssert["padding changes seed degrees without changing sectors or integral indices",
 FeynFacet`Private`ibpSupplementalSeedPadding["- {topologies: [GF], sectors: [b1110], r: 7, s: 3 }",1]===
 "- {topologies: [GF], sectors: [b1110], r: 8, s: 4 }"];
temporary=CreateTemporary[];Export[temporary,"{GF[1,1,1,0] -> ((d-2)/(d-4))*GF[1,1,0,0]}","String"];
imported=Block[{Global`d="caller-data"},Catch[
 FeynFacet`Private`ibpImportRuleTable[GF,temporary],FeynFacet`Private`$ibpFailure]];
FTTest`FTAssert["Kira's dimension variable is independent of a caller value",
 ListQ[imported]&&imported==={FeynCalc`GLI[GF,{1,1,1,0}]->((D-2)/(D-4))*FeynCalc`GLI[GF,{1,1,0,0}]}];
DeleteFile[temporary];
FTTest`FTReport[];
