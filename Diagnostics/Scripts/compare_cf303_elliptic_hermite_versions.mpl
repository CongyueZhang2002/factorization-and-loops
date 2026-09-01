interface(prettyprint=0):
oldFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_row25_block15_elliptic_hermite.maple":
newFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_row25_block15_elliptic_hermite_complete.maple":
read oldFile:
oldRecords := hermiteRecords:
read newFile:
newRecords := hermiteRecords:
sameExistingDecompositions := true:
allQuadraticCoefficientsZero := true:
for i from 1 to nops(oldRecords) do
  for j from 1 to nops(oldRecords[i]) do
    sameExistingDecompositions := sameExistingDecompositions and
      evalb(oldRecords[i][j][1]=newRecords[i][j][1]) and
      evalb(normal(oldRecords[i][j][2]-newRecords[i][j][2])=0) and
      evalb(normal(oldRecords[i][j][3]-newRecords[i][j][3])=0) and
      evalb(normal(oldRecords[i][j][4]-newRecords[i][j][4])=0) and
      evalb(normal(oldRecords[i][j][5]-newRecords[i][j][5])=0) and
      evalb(normal(oldRecords[i][j][6]-newRecords[i][j][6])=0):
    allQuadraticCoefficientsZero := allQuadraticCoefficientsZero and
      evalb(normal(newRecords[i][j][7][3])=0):
  end do:
end do:
printf("sameExistingDecompositions=%a quadraticCoefficientsZero=%a\n",
  sameExistingDecompositions,allQuadraticCoefficientsZero):
if not (sameExistingDecompositions and allQuadraticCoefficientsZero) then
  error "complete reducer changed an accepted CF303 decomposition";
end if:
quit:
