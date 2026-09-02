interface(prettyprint=0):

repositoryRoot := "/home/maxzhang/factorization-and-loops-codex":
runtime := cat(repositoryRoot,
  "/Runtime/2026-08-31_cf303_native_dlog_residues"):
inputFile := cat(runtime,"/cf303_hybrid_baseline90_transfer.maple"):
outputFile := cat(runtime,"/cf303_exception_k_leaves.wl"):
serializerFile := cat(repositoryRoot,
  "/Diagnostics/Scripts/maple_wolfram_serializer.mpl"):

read inputFile:
if not member(status,{
      "CF303Block25GeneralEllipticTransferAcceptedV1",
      "CF303Block25HybridBaselineTransferWithZeroBlock1V1"}) or
    nops(entryRecords)<>90 then
  error "merged transfer is not the accepted 90-entry deck",status,
    nops(entryRecords):
end if:

exceptionRecords := entryRecords[77..88]:
read serializerFile:
payload := cat(
  "<|\n",
  "  \"Status\" -> \"CF303ExceptionKLeavesAcceptedV1\",\n",
  "  \"Family\" -> \"CF303\",\n",
  "  \"Block\" -> 25,\n",
  "  \"SourceEntryIndices\" -> Range[77, 88],\n",
  "  \"EntryRecords\" -> ",wlExpr(exceptionRecords),",\n",
  "  \"EntryConvention\" -> \"{target,epsilonProfile,primitivePair,letterTerms}\",\n",
  "  \"Source\" -> ",wlExpr(inputFile),"\n",
  "|>\n"):
fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"%s",payload):
fclose(fd):
printf("CF303 EXCEPTION LEAVES exported %d entries to %s\n",
  nops(exceptionRecords),outputFile):
quit:
