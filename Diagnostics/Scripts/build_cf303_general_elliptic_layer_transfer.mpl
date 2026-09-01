interface(prettyprint=0):
kernelopts(numcpus=4):
outputRoot := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues":
serializerFile := "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/maple_wolfram_serializer.mpl":
requestedText := getenv("CF303_GENERAL_LAYER_BLOCK"):
if requestedText=false or requestedText="" then requestedText := "25" end if:
requestedBlock := parse(requestedText):
if requestedBlock<>25 then error "only block 25 is currently scheduled" end if:
inputFile := cat(outputRoot,"/cf303_block25_elliptic_layer_census.maple"):
outputMaple := cat(outputRoot,
  "/cf303_block25_general_elliptic_transfer.maple"):
outputWolfram := cat(outputRoot,
  "/cf303_block25_general_elliptic_transfer.wl"):
compressionFile := cat(outputRoot,
  "/cf303_block25_diagonal_constant_generators.maple"):
read inputFile:

# The accepted solved-form deck intentionally omitted five path-only
# exceptions.  Their direct-u Hermite censuses use the same entry contract,
# so append them before building the final transfer.
combinedTargets := targets:
combinedProfiles := epsilonProfiles:
combinedDeck := reducedKernelDeck:
exceptionBlocks := [1,2,11,14,18]:
exceptionStatuses := []:
for exceptionBlock in exceptionBlocks do
  exceptionFile := cat(outputRoot,"/cf303_block25_exception_",
    exceptionBlock,"_elliptic_layer_census.maple"):
  read exceptionFile:
  if status<>"CF303EllipticLayerCensusAcceptedV1" then
    error "exception census is not accepted",exceptionBlock,status;
  end if:
  exceptionStatuses := [op(exceptionStatuses),[exceptionBlock,status]]:
  combinedTargets := [op(combinedTargets),op(targets)]:
  combinedProfiles := [op(combinedProfiles),op(epsilonProfiles)]:
  combinedDeck := [op(combinedDeck),op(reducedKernelDeck)]:
end do:
targets := combinedTargets:
epsilonProfiles := combinedProfiles:
reducedKernelDeck := combinedDeck:
if nops(targets)<>90 or nops({op(targets)})<>90 then
  error "complete block-25 deck must contain 90 distinct entries";
end if:

uniquePreserve := proc(values)
  local result,value;
  result := []:
  for value in values do
    if not member(value,{op(result)}) then result := [op(result),value] end if:
  end do:
  return result:
end proc:
rows := uniquePreserve([seq(target[1],target in targets)]):
columns := uniquePreserve([seq(target[2],target in targets)]):
dimension := nops(rows):
diagonalPositions := []:
for j from 1 to nops(columns) do
  if member(columns[j],{op(rows)}) then
    diagonalPositions := [op(diagonalPositions),j]:
  end if:
end do:

entryRecords := []:
primitiveCount := 0:
eta2Count := 0:
for entryIndex from 1 to nops(reducedKernelDeck) do
  reduction := reducedKernelDeck[entryIndex]:
  if reduction[1][1]<>0 or reduction[1][2]<>0 then
    primitiveCount := primitiveCount+1:
  end if:
  eta2Count := eta2Count+nops(select(term ->
    term[2][1][1]="E4Eta2",reduction[2])):
  entryRecords := [op(entryRecords),[targets[entryIndex],
    epsilonProfiles[entryIndex],reduction[1],reduction[2]]]:
end do:

# The final block can have general off-diagonal forms, but its homogeneous
# diagonal is still eligible for the fast constant-generator Chen operator.
diagonalLetters := []:
diagonalResidueRecords := []:
diagonalPure := true:
diagonalEntryCount := 0:
diagonalLetterID := proc(label)
  global diagonalLetters;
  local j;
  for j from 1 to nops(diagonalLetters) do
    if evalb(diagonalLetters[j]=label) then return j end if:
  end do:
  diagonalLetters := [op(diagonalLetters),label]:
  return nops(diagonalLetters):
end proc:
for entryIndex from 1 to nops(targets) do
  target := targets[entryIndex]:
  if not member(target[2],{op(rows)}) then next end if:
  epsilonProfileRecord := epsilonProfiles[entryIndex]:
  reduction := reducedKernelDeck[entryIndex]:
  diagonalEntryCount := diagonalEntryCount+1:
  diagonalPure := diagonalPure and
    evalb(reduction[1][1]=0 and reduction[1][2]=0):
  for side from 1 to 2 do
    if epsilonProfileRecord[side][1]="Zero" then next end if:
    diagonalPure := diagonalPure and
      evalb(epsilonProfileRecord[side][1]="FiniteLaurent"
        and epsilonProfileRecord[side][2]=[1]):
  end do:
  rowIndex := 0: localColumn := 0:
  for j from 1 to dimension do
    if rows[j]=target[1] then rowIndex := j end if:
    if rows[j]=target[2] then localColumn := j end if:
  end do:
  for term in reduction[2] do
    coefficient := normal(term[1]/eps):
    diagonalPure := diagonalPure and not has(coefficient,{u,eps}):
    diagonalResidueRecords := [op(diagonalResidueRecords),[
      diagonalLetterID(term[2][1]),rowIndex,localColumn,coefficient]]:
  end do:
end do:

constantGeneratorMatrices := []:
constantCompositeKernels := []:
for rowIndex from 1 to dimension do
  for localColumn from 1 to dimension do
    kernelTerms := []:
    for letterIndex from 1 to nops(diagonalLetters) do
      coefficient := normal(add(record[4],record in select(record ->
        record[1]=letterIndex and record[2]=rowIndex and
        record[3]=localColumn,diagonalResidueRecords))):
      if coefficient<>0 then
        kernelTerms := [op(kernelTerms),[coefficient,letterIndex]]:
      end if:
    end do:
    if nops(kernelTerms)>0 then
      generatorMatrix := [seq([seq(`if`(i=rowIndex and j=localColumn,
        1,0),j=1..dimension)],i=1..dimension)]:
      constantGeneratorMatrices := [op(constantGeneratorMatrices),
        generatorMatrix]:
      constantCompositeKernels := [op(constantCompositeKernels),
        kernelTerms]:
    end if:
  end do:
end do:

read compressionFile:
compressionStatus := status:
compressionVerified := verified:
compressedLabels := activeLabels:
compressedMatrices := generatorMatrices:
compressedKernelCoordinates := generatorCompositeKernels:
if compressionStatus<>"CF303DiagonalConstantGeneratorsAcceptedV1"
    or not compressionVerified then
  printf("REFUSED: block 25 diagonal compression is not accepted\n"):
  quit:
end if:
constantGeneratorMatrices := compressedMatrices:
constantCompositeKernels := [seq([
  seq([compressedKernelCoordinates[generatorIndex][termIndex][1],
    diagonalLetterID(compressedLabels[
      compressedKernelCoordinates[generatorIndex][termIndex][2]])],
    termIndex=1..nops(compressedKernelCoordinates[generatorIndex]))],
  generatorIndex=1..nops(compressedKernelCoordinates))]:

status := if diagonalPure and diagonalEntryCount=dimension^2
    and nops(constantGeneratorMatrices)>0 then
  "CF303Block25GeneralEllipticTransferAcceptedV1"
else
  "CF303Block25GeneralEllipticTransferIncompleteV1"
end if:
schedule := ["Low",-4,"Top",2,"KMin",0,"ConstantTop",2]:
fd := fopen(outputMaple,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"block := 25:\n"):
fprintf(fd,"P4 := %a:\n",P4):
fprintf(fd,"rows := %a:\n",rows):
fprintf(fd,"columns := %a:\n",columns):
fprintf(fd,"entryRecords := %a:\n",entryRecords):
fprintf(fd,"diagonalLetters := %a:\n",diagonalLetters):
fprintf(fd,"constantGeneratorMatrices := %a:\n",
  constantGeneratorMatrices):
fprintf(fd,"constantCompositeKernels := %a:\n",
  constantCompositeKernels):
fprintf(fd,"schedule := %a:\n",schedule):
fprintf(fd,"counts := %a:\n",["Entries",nops(entryRecords),
  "PrimitiveEntries",primitiveCount,"Eta2Entries",eta2Count,
  "ExceptionBlocks",exceptionBlocks,
  "DiagonalLetters",nops(diagonalLetters),
  "DiagonalGenerators",nops(constantGeneratorMatrices),
  "DiagonalEntries",diagonalEntryCount,
  "DiagonalPure",diagonalPure]):
fclose(fd):

read serializerFile:
operatorText := cat(
  "<|\n",
  "  \"Status\" -> ",wlExpr(status),",\n",
  "  \"Block\" -> 25,\n",
  "  \"Curve\" -> ",wlExpr(P4),",\n",
  "  \"BasePoint\" -> 1/2,\n",
  "  \"Rows\" -> ",wlExpr(rows),",\n",
  "  \"Columns\" -> ",wlExpr(columns),",\n",
  "  \"EntryRecords\" -> ",wlExpr(entryRecords),",\n",
  "  \"ExceptionBlocks\" -> ",wlExpr(exceptionBlocks),",\n",
  "  \"ExceptionStatuses\" -> ",wlExpr(exceptionStatuses),",\n",
  "  \"EntryConvention\" -> \"{target,epsilonProfile,primitivePair,letterTerms}; integrate each requested epsilon coefficient with word-length-decreasing Hermite IBP\",\n",
  "  \"DiagonalLetters\" -> ",wlExpr(diagonalLetters),",\n",
  "  \"ConstantGeneratorMatrices\" -> ",
    wlExpr(constantGeneratorMatrices),",\n",
  "  \"ConstantCompositeKernels\" -> ",
    wlExpr(constantCompositeKernels),",\n",
  "  \"Schedule\" -> ",wlExpr(schedule),"\n",
  "|>\n"):
fd := fopen(outputWolfram,WRITE,TEXT):
fprintf(fd,"%s",operatorText):
fclose(fd):
printf("BLOCK 25 TRANSFER status=%s entries=%d primitives=%d eta2=%d diagonal_letters=%d diagonal_generators=%d\n",
  status,nops(entryRecords),primitiveCount,eta2Count,
  nops(diagonalLetters),nops(constantGeneratorMatrices)):
printf("OUTPUT_MAPLE %s\nOUTPUT_WOLFRAM %s\n",outputMaple,
  outputWolfram):
quit:
