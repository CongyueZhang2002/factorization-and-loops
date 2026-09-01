interface(prettyprint=0):
kernelopts(numcpus=6):
operatorFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_lazy_chen_operator.maple":
compressedFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_compressed_residue_basis.maple":
constantFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_constant_generators.maple":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_lazy_chen_operator.wl":
read operatorFile:
read compressedFile:
read constantFile:
with(StringTools):

# Minimal expression-tree serializer.  It does not parse printed Maple text,
# so nested signs, powers, and the inert marked-sheet value Yc(c) retain their
# exact structure in Wolfram Language.
wlExpr := proc(value)
  local childValues,headString,numeratorValue,denominatorValue;
  if type(value,string) then
    return cat("\"",SubstituteAll(value,"\"","\\\""),"\""):
  elif type(value,integer) then
    return sprintf("%a",value):
  elif type(value,rational) then
    numeratorValue := numer(value):
    denominatorValue := denom(value):
    return cat("(",wlExpr(numeratorValue),")/(",
      wlExpr(denominatorValue),")"):
  elif type(value,list) then
    return cat("{",Join(map(wlExpr,value),", "),"}"):
  elif type(value,`+`) then
    childValues := [op(value)]:
    return cat("(",Join(map(wlExpr,childValues)," + "),")"):
  elif type(value,`*`) then
    childValues := [op(value)]:
    return cat("(",Join(map(wlExpr,childValues)," * "),")"):
  elif type(value,`^`) then
    return cat("(",wlExpr(op(1,value)),")^(",
      wlExpr(op(2,value)),")"):
  elif type(value,function) then
    headString := convert(op(0,value),string):
    childValues := [op(value)]:
    return cat(headString,"[",Join(map(wlExpr,childValues),", "),"]"):
  elif type(value,name) then
    if value=true then return "True"
    elif value=false then return "False"
    else return convert(value,string)
    end if:
  end if:
  error "unsupported Maple expression type in Wolfram exporter",value:
end proc:

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
