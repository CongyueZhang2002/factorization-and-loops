interface(prettyprint=0):
kernelopts(numcpus=6):
operatorFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_lazy_chen_operator.maple":
compressedFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_compressed_residue_basis.maple":
constantFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_constant_generators.maple":
serializerFile := "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/maple_wolfram_serializer.mpl":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_lazy_chen_operator.wl":
read operatorFile:
read compressedFile:
read constantFile:
read serializerFile:

residueRules := [seq([record[1],record[2],record[3],record[4]],
  record in residueRecords)]:
operatorText := cat(
  "<|\n",
  "  \"Status\" -> \"CF303Block15LazyChenOperatorAcceptedV1\",\n",
  "  \"Curve\" -> ",wlExpr(P4),",\n",
  "  \"BasePoint\" -> ",wlExpr(basePoint),",\n",
  "  \"Rows\" -> ",wlExpr(rows),",\n",
  "  \"Columns\" -> ",wlExpr(columns),",\n",
  "  \"Letters\" -> ",wlExpr(originalLetters),",\n",
  "  \"ResidueRecords\" -> ",wlExpr(residueRules),",\n",
  "  \"DiagonalColumnPositions\" -> ",
    wlExpr(diagonalColumnPositions),",\n",
  "  \"DiagonalCompressed\" -> <|\n",
  "    \"BasisLetterIDs\" -> ",wlExpr(basisLetterIDs),",\n",
  "    \"BasisResidues\" -> ",
    wlExpr([seq(convert(basisResidues[i],listlist),
      i=1..nops(basisResidues))]),",\n",
  "    \"CompositeKernels\" -> ",wlExpr(compositeKernels),",\n",
  "    \"ConstantGeneratorMatrices\" -> ",
    wlExpr(generatorMatrices),",\n",
  "    \"ConstantCompositeKernels\" -> ",
    wlExpr(constantCompositeKernels),",\n",
  "    \"PreferredGeneratorCount\" -> ",
    wlExpr(nops(generatorMatrices)),",\n",
  "    \"Convention\" -> \"Omega[a] is the listed linear combination of original one-form letters; A15,15 is Sum[BasisResidues[a] Omega[a],a]\"\n",
  "  |>,\n",
  "  \"Schedule\" -> <|\"Low\" -> -1, \"Top\" -> 4, \"KMin\" -> -1, \"ConstantTop\" -> 2|>,\n",
  "  \"WordConvention\" -> \"d E4Word[{a1,...,ak};u] = Omega[a1](u) E4Word[{a2,...,ak};u], with base point u=1/2\"\n",
  "|>\n"):
fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"%s",operatorText):
fclose(fd):
printf("EXPORTED bytes=%d output=%s\n",FileTools:-Size(outputFile),outputFile):
quit:
