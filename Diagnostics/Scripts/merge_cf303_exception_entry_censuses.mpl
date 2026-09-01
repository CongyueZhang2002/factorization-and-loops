interface(prettyprint=0):

outputRoot := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues":
blockText := getenv("CF303_EXCEPTION_BLOCK"):
entryCountText := getenv("CF303_EXCEPTION_ENTRY_COUNT"):
if blockText=false or blockText="" or
    entryCountText=false or entryCountText="" then
  error "CF303_EXCEPTION_BLOCK and CF303_EXCEPTION_ENTRY_COUNT are required";
end if:
requestedBlock := parse(blockText):
entryCount := parse(entryCountText):
if not type(requestedBlock,posint) or not type(entryCount,posint) then
  error "block and entry count must be positive integers";
end if:

allTargets := []:
allKernelPairs := []:
allProfiles := []:
allDeck := []:
allLetters := []:
compileSeconds := 0:
reduceSeconds := 0:
for entryIndex from 1 to entryCount do
  inputFile := cat(outputRoot,"/cf303_block25_exception_",
    requestedBlock,"_elliptic_layer_census_entry",entryIndex,".maple"):
  read inputFile:
  if status<>"CF303EllipticLayerCensusAcceptedV1" or
      block<>requestedBlock or nops(targets)<>1 or
      nops(kernelPairs)<>1 or nops(epsilonProfiles)<>1 or
      nops(reducedKernelDeck)<>1 or failures<>[] then
    error "entry census is not accepted",entryIndex;
  end if:
  allTargets := [op(allTargets),op(targets)]:
  allKernelPairs := [op(allKernelPairs),op(kernelPairs)]:
  allProfiles := [op(allProfiles),op(epsilonProfiles)]:
  allDeck := [op(allDeck),op(reducedKernelDeck)]:
  allLetters := [op(allLetters),op(distinctLetters)]:
  compileSeconds := compileSeconds+timings[2]:
  reduceSeconds := reduceSeconds+timings[4]:
end do:

targets := allTargets:
kernelPairs := allKernelPairs:
epsilonProfiles := allProfiles:
reducedKernelDeck := allDeck:
distinctLetters := [op({op(allLetters)})]:
failures := []:
primitiveCount := nops(select(reduction ->
  reduction[1][1]<>0 or reduction[1][2]<>0,reducedKernelDeck)):
letterCount := add(nops(reduction[2]),reduction in reducedKernelDeck):
gplCount := add(nops(select(term ->
  substring(term[2][1][1],1..3)="GPL",reduction[2])),
  reduction in reducedKernelDeck):
e4Count := add(nops(select(term ->
  substring(term[2][1][1],1..2)="E4",reduction[2])),
  reduction in reducedKernelDeck):
eta2Count := add(nops(select(term ->
  term[2][1][1]="E4Eta2",reduction[2])),
  reduction in reducedKernelDeck):
status := "CF303EllipticLayerCensusAcceptedV1":
counts := ["Entries",entryCount,"Nonzero",entryCount,
  "PrimitiveNonzero",primitiveCount,"LetterOccurrences",letterCount,
  "DistinctLetters",nops(distinctLetters),"GPL",gplCount,"E4",e4Count,
  "Eta2",eta2Count]:
timings := ["Compile",compileSeconds,"Reduce",reduceSeconds]:

outputFile := cat(outputRoot,"/cf303_block25_exception_",
  requestedBlock,"_elliptic_layer_census.maple"):
fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"block := %a:\n",requestedBlock):
fprintf(fd,"P4 := %a:\n",P4):
fprintf(fd,"Dcurve := %a:\n",Dcurve):
fprintf(fd,"targets := %a:\n",targets):
fprintf(fd,"kernelPairs := %a:\n",kernelPairs):
fprintf(fd,"epsilonProfiles := %a:\n",epsilonProfiles):
fprintf(fd,"reducedKernelDeck := %a:\n",reducedKernelDeck):
fprintf(fd,"distinctLetters := %a:\n",distinctLetters):
fprintf(fd,"failures := []:\n"):
fprintf(fd,"counts := %a:\n",counts):
fprintf(fd,"timings := %a:\n",timings):
fclose(fd):
printf("MERGED CF303 EXCEPTION block=%d entries=%d primitives=%d letters=%d distinct=%d output=%s\n",
  requestedBlock,entryCount,primitiveCount,letterCount,
  nops(distinctLetters),outputFile):
quit:
