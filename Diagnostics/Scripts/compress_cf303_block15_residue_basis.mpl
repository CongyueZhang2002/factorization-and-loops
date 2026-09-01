interface(prettyprint=0):
kernelopts(numcpus=6):
inputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_lazy_chen_operator.maple":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_compressed_residue_basis.maple":
read inputFile:
with(LinearAlgebra):

activeLetters := []:
residues := []:
for letterIndex from 1 to nops(letters) do
  residueMatrix := Matrix(3,3,0):
  for record in diagonalResidueRecords do
    if record[1]=letterIndex then
      residueMatrix[record[2],record[3]-diagonalColumnPositions[1]+1] :=
        record[4]:
    end if:
  end do:
  if not Equal(residueMatrix,Matrix(3,3,0)) then
    activeLetters := [op(activeLetters),letterIndex]:
    residues := [op(residues),residueMatrix]:
  end if:
end do:

flattenMatrix := source -> Vector(9,index ->
  source[iquo(index-1,3)+1,irem(index-1,3)+1]):
basisPositions := []:
basisVectors := Matrix(9,0):
currentRank := 0:
for position from 1 to nops(residues) do
  candidate := <basisVectors|flattenMatrix(residues[position])>:
  candidateRank := Rank(candidate):
  if candidateRank>currentRank then
    basisPositions := [op(basisPositions),position]:
    basisVectors := candidate:
    currentRank := candidateRank:
  end if:
end do:
basisLetterIDs := [seq(activeLetters[position],position in basisPositions)]:
basisResidues := [seq(residues[position],position in basisPositions)]:

decompositionColumns := []:
for position from 1 to nops(residues) do
  decompositionColumns := [op(decompositionColumns),
    map(normal,LinearSolve(basisVectors,flattenMatrix(residues[position])))] :
end do:
compositeKernels := []:
for basisIndex from 1 to currentRank do
  kernelTerms := []:
  for position from 1 to nops(activeLetters) do
    coefficient := normal(decompositionColumns[position][basisIndex]):
    if coefficient<>0 then
      kernelTerms := [op(kernelTerms),[coefficient,activeLetters[position]]]:
    end if:
  end do:
  compositeKernels := [op(compositeKernels),kernelTerms]:
end do:

verified := true:
for position from 1 to nops(residues) do
  reconstructed := Matrix(3,3,0):
  for basisIndex from 1 to currentRank do
    reconstructed := reconstructed+
      decompositionColumns[position][basisIndex]*basisResidues[basisIndex]:
  end do:
  verified := verified and Equal(map(normal,reconstructed-residues[position]),
    Matrix(3,3,0)):
end do:
status := if verified and currentRank=5 then
  "CF303Block15CompressedResidueBasisAcceptedV1"
else
  "CF303Block15CompressedResidueBasisFailedV1"
end if:

fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"originalLetters := %a:\n",letters):
fprintf(fd,"activeLetterIDs := %a:\n",activeLetters):
fprintf(fd,"basisLetterIDs := %a:\n",basisLetterIDs):
fprintf(fd,"basisResidues := %a:\n",
  [seq(convert(basisResidues[i],listlist),i=1..nops(basisResidues))]):
fprintf(fd,"decompositionColumns := %a:\n",decompositionColumns):
fprintf(fd,"compositeKernels := %a:\n",compositeKernels):
fprintf(fd,"kernelConvention := %a:\n",
  "Omega[a]=sum_[coefficient,letterID] coefficient*omega[originalLetters[letterID]]; A15=sum_a basisResidues[a]*Omega[a]"):
fprintf(fd,"counts := %a:\n",["OriginalActiveLetters",nops(activeLetters),
  "ResidueSpanRank",currentRank,"CompositeKernelTerms",
  add(nops(kernel),kernel in compositeKernels)]):
fprintf(fd,"verified := %a:\n",verified):
fclose(fd):
printf("COMPRESSED original=%d rank=%d kernel_terms=%d verified=%a\n",
  nops(activeLetters),currentRank,
  add(nops(kernel),kernel in compositeKernels),verified):
printf("BASIS_LETTERS %a\n",basisLetterIDs):
printf("DONE status=%s output=%s\n",status,outputFile):
quit:
