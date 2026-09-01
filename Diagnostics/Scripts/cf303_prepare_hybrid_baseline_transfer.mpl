interface(prettyprint=0):

# Build the exact 90-shaped input used for the baseline path-gauge recurrence.
# The 76-entry accepted transfer and the 12 accepted exception entries are
# preserved verbatim.  Block 1 is represented by two explicit zero records;
# its separately accepted arithmetic circuit is added after this recurrence.

runtimeRoot := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues":
baseFile := cat(runtimeRoot,
  "/cf303_block25_general_elliptic_transfer.maple"):
outputFile := cat(runtimeRoot,
  "/cf303_hybrid_baseline90_transfer.maple"):
sourceRows := [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,
  21,22,26,27,29,30,31,32,33,34,35,36,39,40,41,42,43,23,24,25,28,37,38]:
exceptionBlocks := [2,11,14,18]:

read baseFile:
if status<>"CF303Block25GeneralEllipticTransferAcceptedV1"
    or block<>25 or rows<>[44,45] or nops(entryRecords)<>76 then
  printf("REFUSED: the accepted 76-entry base transfer is required\n"):
  quit:
end if:
baseCurve := P4:
baseEntries := entryRecords:
baseDiagonalLetters := diagonalLetters:
baseGeneratorMatrices := constantGeneratorMatrices:
baseCompositeKernels := constantCompositeKernels:
baseSchedule := schedule:

combinedEntries := baseEntries:
exceptionCounts := []:
for exceptionBlock in exceptionBlocks do
  exceptionFile := cat(runtimeRoot,"/cf303_block25_exception_",
    exceptionBlock,"_elliptic_layer_census.maple"):
  read exceptionFile:
  if status<>"CF303EllipticLayerCensusAcceptedV1"
      or normal(P4-baseCurve)<>0
      or nops(targets)<>nops(reducedKernelDeck)
      or nops(targets)<>nops(epsilonProfiles) then
    printf("REFUSED: accepted compatible exception census required block=%d\n",
      exceptionBlock):
    quit:
  end if:
  for entryIndex from 1 to nops(targets) do
    combinedEntries := [op(combinedEntries),[
      targets[entryIndex],epsilonProfiles[entryIndex],
      reducedKernelDeck[entryIndex][1],reducedKernelDeck[entryIndex][2]]]:
  end do:
  exceptionCounts := [op(exceptionCounts),[exceptionBlock,nops(targets)]]:
end do:

zeroProfile := [["Zero"],["Zero"]]:
zeroPrimitive := [0,0]:
combinedEntries := [op(combinedEntries),
  [[44,1],zeroProfile,zeroPrimitive,[]],
  [[45,1],zeroProfile,zeroPrimitive,[]]]:

targetsSeen := [seq(record[1],record in combinedEntries)]:
if nops(combinedEntries)<>90 or nops({op(targetsSeen)})<>90 then
  printf("REFUSED: hybrid baseline must contain 90 distinct coordinates\n"):
  quit:
end if:
expectedTargets := {seq(seq([row,column],
  column in [op(sourceRows),44,45]),row in [44,45])}:
if {op(targetsSeen)}<>expectedTargets then
  printf("REFUSED: hybrid baseline coordinate layout is incomplete\n"):
  quit:
end if:

status := "CF303Block25HybridBaselineTransferWithZeroBlock1V1":
fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"block := 25:\n"):
fprintf(fd,"P4 := %a:\n",baseCurve):
fprintf(fd,"rows := %a:\n",[44,45]):
fprintf(fd,"columns := %a:\n",[op(sourceRows),44,45]):
fprintf(fd,"entryRecords := %a:\n",combinedEntries):
fprintf(fd,"diagonalLetters := %a:\n",baseDiagonalLetters):
fprintf(fd,"constantGeneratorMatrices := %a:\n",baseGeneratorMatrices):
fprintf(fd,"constantCompositeKernels := %a:\n",baseCompositeKernels):
fprintf(fd,"schedule := %a:\n",baseSchedule):
fprintf(fd,"provenance := %a:\n",[
  "BaseEntries",76,"ExceptionCounts",exceptionCounts,
  "ZeroPlaceholderTargets",[[44,1],[45,1]],
  "Block1Correction","cf303_block1_full_exact_circuit.json"]):
fclose(fd):

printf("CF303 HYBRID BASELINE TRANSFER status=%s entries=%d output=%s\n",
  status,nops(combinedEntries),outputFile):
quit:
