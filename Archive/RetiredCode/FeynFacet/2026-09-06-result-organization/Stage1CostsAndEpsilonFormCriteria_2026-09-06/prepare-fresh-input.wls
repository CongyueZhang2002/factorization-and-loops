
$HistoryLength=0;root="/home/maxzhang/factorization-and-loops";
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
dir=root<>"/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/DifferentialEquationDataV2/CF259";
system=FamilyArtifactRead[dir<>"/FamilyDifferentialSystem.wl"];
old=FamilyArtifactRead[dir<>"/FamilyDifferentialSystemBlockDecomposition.wl"];
new=BuildFamilyDifferentialSystemBlockDecomposition[system,old["FamilyDifferentialSystemReference"]];
Print[KeyTake[new,{"Status","DiagonalBlocksInCurrentBasis"}]];
Print["Same partition and order: ",new["DiagonalBlocksInCurrentBasis"]===old["IrreducibleDiagonalBlocks"]];
If[!FamilyDifferentialSystemBlockDecompositionQ[new,system],Exit[1]];
Put[new,"/tmp/feynfacet-stage1-20260906/CF259-block-decomposition.wl"];
