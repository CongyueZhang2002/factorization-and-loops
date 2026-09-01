interface(prettyprint=0):
kernelopts(numcpus=6):
inputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_path_kernels.maple":
libraryFile := "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/algebraic_curve_word_transport.mpl":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_reduced_kernel_deck.maple":
read inputFile:
read libraryFile:
ConfigureAlgebraicWordTransport(P4,u,1/2,Y0):

t0 := time():
reducedKernelDeck := []:
allVerified := true:
primitiveNonzeroCount := 0:
letterLabels := []:
for i from 1 to nops(kernelPairs) do
  reduction := reduceForm(kernelPairs[i]):
  reducedKernelDeck := [op(reducedKernelDeck),reduction]:
  allVerified := allVerified and reduction[3]:
  if not pairZero(reduction[1]) then
    primitiveNonzeroCount := primitiveNonzeroCount+1:
  end if:
  for entry in reduction[2] do
    letterLabels := [op(letterLabels),entry[2][1]]:
  end do:
end do:
reduceSeconds := time()-t0:
distinctLetters := [op({op(letterLabels)})]:
eta2Count := nops(select(label -> label[1]="E4Eta2",letterLabels)):
gplFactorCount := nops(select(label -> label[1]="GPLFactor",
  letterLabels)):
e4FactorCount := nops(select(label -> label[1]="E4Factor",
  letterLabels)):
status := if allVerified and nops(reducedKernelDeck)=nops(kernelPairs) then
  "CF303Block15ReducedKernelDeckAcceptedV1"
else
  "CF303Block15ReducedKernelDeckFailedV1"
end if:

fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"P4 := %a:\n",P4):
fprintf(fd,"basePoint := %a:\n",1/2):
fprintf(fd,"columns := %a:\n",columns):
fprintf(fd,"targets := %a:\n",targets):
fprintf(fd,"kernelPairs := %a:\n",kernelPairs):
fprintf(fd,"reducedKernelDeck := %a:\n",reducedKernelDeck):
fprintf(fd,"distinctLetters := %a:\n",distinctLetters):
fprintf(fd,"counts := %a:\n",["Entries",nops(kernelPairs),
  "PrimitiveNonzero",primitiveNonzeroCount,
  "LetterOccurrences",nops(letterLabels),
  "DistinctLetters",nops(distinctLetters),"Eta2",eta2Count,
  "GPLFactor",gplFactorCount,"E4Factor",e4FactorCount]):
fprintf(fd,"reduceSeconds := %a:\n",reduceSeconds):
fclose(fd):
printf("COUNTS entries=%d primitive_nonzero=%d letters=%d distinct=%d eta2=%d gpl_q=%d e4_q=%d\n",
  nops(kernelPairs),primitiveNonzeroCount,nops(letterLabels),
  nops(distinctLetters),eta2Count,gplFactorCount,e4FactorCount):
printf("DONE %.3f status=%s output=%s\n",
  reduceSeconds,status,outputFile):
quit:
