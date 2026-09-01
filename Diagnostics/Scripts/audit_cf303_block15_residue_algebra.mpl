interface(prettyprint=0):
kernelopts(numcpus=6):
inputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_lazy_chen_operator.maple":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_residue_algebra.maple":
read inputFile:
with(LinearAlgebra):

residues := []:
activeLetters := []:
for letterIndex from 1 to nops(letters) do
  residueMatrix := Matrix(3,3,0):
  for record in diagonalResidueRecords do
    if record[1]=letterIndex then
      residueMatrix[record[2],record[3]-diagonalColumnPositions[1]+1] :=
        record[4]:
    end if:
  end do:
  if not Equal(residueMatrix,Matrix(3,3,0)) then
    residues := [op(residues),residueMatrix]:
    activeLetters := [op(activeLetters),letterIndex]:
  end if:
end do:

t0 := time():
noncommutingPairs := []:
for i from 1 to nops(residues) do
  for j from i+1 to nops(residues) do
    commutator := map(normal,residues[i].residues[j]
      -residues[j].residues[i]):
    if not Equal(commutator,Matrix(3,3,0)) then
      noncommutingPairs := [op(noncommutingPairs),
        [activeLetters[i],activeLetters[j]]]:
    end if:
  end do:
end do:
seconds := time()-t0:
flatResidues := Matrix(9,nops(residues),
  (row,column) -> residues[column][iquo(row-1,3)+1,
    irem(row-1,3)+1]):
spanRank := Rank(flatResidues):

status := "CF303Block15ResidueAlgebraAcceptedV1":
fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"activeLetters := %a:\n",activeLetters):
fprintf(fd,"residueSpanRank := %a:\n",spanRank):
fprintf(fd,"noncommutingPairs := %a:\n",noncommutingPairs):
fprintf(fd,"counts := %a:\n",["ActiveResidues",nops(residues),
  "Pairs",nops(residues)*(nops(residues)-1)/2,
  "NoncommutingPairs",nops(noncommutingPairs)]):
fprintf(fd,"seconds := %a:\n",seconds):
fclose(fd):
printf("ALGEBRA active=%d span_rank=%d pairs=%d noncommuting=%d seconds=%.3f\n",
  nops(residues),spanRank,nops(residues)*(nops(residues)-1)/2,
  nops(noncommutingPairs),seconds):
printf("DONE status=%s output=%s\n",status,outputFile):
quit:
