interface(prettyprint=0):
kernelopts(numcpus=6):
inputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_reduced_kernel_deck.maple":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_lazy_chen_operator.maple":
read inputFile:

# A pure-letter connection is already its own compact Chen solution.
# Store each constant residue once as [letter,row,column,coefficient]; words
# are products of these sparse residue matrices and are expanded only when a
# requested physical coefficient is materialized.
letters := []:
residueRecords := []:
primitiveFree := true:
constantResidues := true:

letterID := proc(label)
  global letters;
  local j;
  for j from 1 to nops(letters) do
    if evalb(letters[j]=label) then return j end if:
  end do:
  letters := [op(letters),label]:
  return nops(letters):
end proc:

for entryIndex from 1 to nops(reducedKernelDeck) do
  reduction := reducedKernelDeck[entryIndex]:
  primitiveFree := primitiveFree and
    evalb(reduction[1][1]=0 and reduction[1][2]=0):
  target := targets[entryIndex]:
  rowIndex := target[1]-22:
  columnIndex := 0:
  for j from 1 to nops(columns) do
    if columns[j]=target[2] then columnIndex := j; break end if:
  end do:
  if columnIndex=0 then error "target column is absent from column table" end if:
  for term in reduction[2] do
    coefficient := normal(term[1]):
    constantResidues := constantResidues and not has(coefficient,u):
    residueRecords := [op(residueRecords),
      [letterID(term[2][1]),rowIndex,columnIndex,coefficient]]:
  end do:
end do:

# Merge coincident triples.  This keeps the provider independent of the
# order in which rational and elliptic Hermite pieces were emitted.
mergedResidueRecords := []:
for letterIndex from 1 to nops(letters) do
  for rowIndex from 1 to 3 do
    for columnIndex from 1 to nops(columns) do
      coefficient := normal(add(record[4],record in select(record ->
        record[1]=letterIndex and record[2]=rowIndex and
        record[3]=columnIndex,residueRecords))):
      if coefficient<>0 then
        mergedResidueRecords := [op(mergedResidueRecords),
          [letterIndex,rowIndex,columnIndex,coefficient]]:
      end if:
    end do:
  end do:
end do:

diagonalPositions := []:
for j from 1 to nops(columns) do
  if member(columns[j],{23,24,25}) then
    diagonalPositions := [op(diagonalPositions),j]:
  end if:
end do:
diagonalResidueRecords := select(record ->
  member(record[3],{op(diagonalPositions)}),mergedResidueRecords):
status := if primitiveFree and constantResidues then
  "CF303Block15LazyChenOperatorAcceptedV1"
else
  "CF303Block15LazyChenOperatorFailedV1"
end if:

fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"P4 := %a:\n",P4):
fprintf(fd,"basePoint := %a:\n",basePoint):
fprintf(fd,"rows := %a:\n",[23,24,25]):
fprintf(fd,"columns := %a:\n",columns):
fprintf(fd,"letters := %a:\n",letters):
fprintf(fd,"residueRecords := %a:\n",mergedResidueRecords):
fprintf(fd,"diagonalColumnPositions := %a:\n",diagonalPositions):
fprintf(fd,"diagonalResidueRecords := %a:\n",diagonalResidueRecords):
fprintf(fd,"schedule := %a:\n",["Low",-1,"Top",4,"KMin",-1,
  "ConstantTop",2]):
fprintf(fd,"coefficientFormula := %a:\n",
  "F[n]=sum(q,w: |w|=n-q) R[w1]...R[wk] B[q] C[q] E4Word[w]"):
fprintf(fd,"counts := %a:\n",["Letters",nops(letters),
  "ResidueCoordinates",nops(mergedResidueRecords),
  "DiagonalResidueCoordinates",nops(diagonalResidueRecords),
  "PrimitiveFree",primitiveFree,"ConstantResidues",constantResidues]):
fclose(fd):

printf("COUNTS letters=%d residue_coordinates=%d diagonal_coordinates=%d\n",
  nops(letters),nops(mergedResidueRecords),
  nops(diagonalResidueRecords)):
printf("ELIGIBILITY primitive_free=%a constant_residues=%a\n",
  primitiveFree,constantResidues):
printf("DONE status=%s output=%s\n",status,outputFile):
quit:
