interface(prettyprint=0):
kernelopts(numcpus=4):
outputRoot := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues":
serializerFile := "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/maple_wolfram_serializer.mpl":
requestedText := getenv("CF303_LAYER_BLOCK"):
if requestedText=false or requestedText="" then
  error "CF303_LAYER_BLOCK must be 17 or 21";
end if:
requestedBlock := parse(requestedText):
if not member(requestedBlock,{17,21}) then
  error "CF303_LAYER_BLOCK must be 17 or 21";
end if:
inputFile := cat(outputRoot,"/cf303_block",requestedBlock,
  "_elliptic_layer_census.maple"):
outputMaple := cat(outputRoot,"/cf303_block",requestedBlock,
  "_pure_elliptic_operator.maple"):
outputWolfram := cat(outputRoot,"/cf303_block",requestedBlock,
  "_pure_elliptic_operator.wl"):
read inputFile:

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
  rowIndex := 0: columnIndex := 0:
  for j from 1 to nops(rows) do
    if rows[j]=target[1] then rowIndex := j; break end if:
  end do:
  for j from 1 to nops(columns) do
    if columns[j]=target[2] then columnIndex := j; break end if:
  end do:
  for term in reduction[2] do
    coefficient := normal(term[1]/eps):
    constantResidues := constantResidues and
      not has(coefficient,{u,eps}):
    residueRecords := [op(residueRecords),
      [letterID(term[2][1]),rowIndex,columnIndex,coefficient]]:
  end do:
end do:

diagonalPositions := []:
for j from 1 to nops(columns) do
  if member(columns[j],{op(rows)}) then
    diagonalPositions := [op(diagonalPositions),j]:
  end if:
end do:
diagonalResidueRecords := select(record ->
  member(record[3],{op(diagonalPositions)}),residueRecords):

# A matrix-unit basis makes every repeated homogeneous residue constant.
# For dimensions one and two this uses at most d^2 generators and moves all
# p/Yc dependence into explicitly stored composite elliptic kernels.
generatorMatrices := []:
constantCompositeKernels := []:
generatorCoordinates := []:
for rowIndex from 1 to dimension do
  for localColumn from 1 to dimension do
    columnIndex := diagonalPositions[localColumn]:
    kernelTerms := []:
    for letterIndex from 1 to nops(letters) do
      coefficient := normal(add(record[4],record in select(record ->
        record[1]=letterIndex and record[2]=rowIndex and
        record[3]=columnIndex,diagonalResidueRecords))):
      if coefficient<>0 then
        kernelTerms := [op(kernelTerms),[coefficient,letterIndex]]:
      end if:
    end do:
    if nops(kernelTerms)>0 then
      generatorMatrix := [seq([seq(`if`(i=rowIndex and j=localColumn,
        1,0),j=1..dimension)],i=1..dimension)]:
      generatorMatrices := [op(generatorMatrices),generatorMatrix]:
      constantCompositeKernels := [op(constantCompositeKernels),
        kernelTerms]:
      generatorCoordinates := [op(generatorCoordinates),
        [rowIndex,localColumn]]:
    end if:
  end do:
end do:

if requestedBlock=17 then
  schedule := ["Low",-1,"Top",4,"KMin",0,"ConstantTop",2]:
else
  schedule := ["Low",0,"Top",4,"KMin",0,"ConstantTop",2]:
end if:
status := if primitiveFree and constantResidues then
  cat("CF303Block",requestedBlock,"PureEllipticOperatorAcceptedV1")
else
  cat("CF303Block",requestedBlock,"PureEllipticOperatorFailedV1")
end if:

fd := fopen(outputMaple,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"block := %a:\n",requestedBlock):
fprintf(fd,"P4 := %a:\n",P4):
fprintf(fd,"rows := %a:\n",rows):
fprintf(fd,"columns := %a:\n",columns):
fprintf(fd,"letters := %a:\n",letters):
fprintf(fd,"residueRecords := %a:\n",residueRecords):
fprintf(fd,"diagonalColumnPositions := %a:\n",diagonalPositions):
fprintf(fd,"generatorCoordinates := %a:\n",generatorCoordinates):
fprintf(fd,"constantGeneratorMatrices := %a:\n",generatorMatrices):
fprintf(fd,"constantCompositeKernels := %a:\n",
  constantCompositeKernels):
fprintf(fd,"schedule := %a:\n",schedule):
fprintf(fd,"counts := %a:\n",["Letters",nops(letters),
  "ResidueCoordinates",nops(residueRecords),
  "HomogeneousGenerators",nops(generatorMatrices),
  "CompositeKernelTerms",add(nops(kernel),
    kernel in constantCompositeKernels),"PrimitiveFree",primitiveFree,
  "ConstantResidues",constantResidues]):
fclose(fd):

read serializerFile:
operatorText := cat(
  "<|\n",
  "  \"Status\" -> ",wlExpr(status),",\n",
  "  \"Block\" -> ",wlExpr(requestedBlock),",\n",
  "  \"Curve\" -> ",wlExpr(P4),",\n",
  "  \"BasePoint\" -> 1/2,\n",
  "  \"Rows\" -> ",wlExpr(rows),",\n",
  "  \"Columns\" -> ",wlExpr(columns),",\n",
  "  \"Letters\" -> ",wlExpr(letters),",\n",
  "  \"ResidueRecords\" -> ",wlExpr(residueRecords),",\n",
  "  \"DiagonalColumnPositions\" -> ",
    wlExpr(diagonalPositions),",\n",
  "  \"ConstantGeneratorMatrices\" -> ",
    wlExpr(generatorMatrices),",\n",
  "  \"ConstantCompositeKernels\" -> ",
    wlExpr(constantCompositeKernels),",\n",
  "  \"Schedule\" -> ",wlExpr(schedule),",\n",
  "  \"WordConvention\" -> \"d E4Word[{a1,...,ak};u] = Omega[a1](u) E4Word[{a2,...,ak};u], base u=1/2\"\n",
  "|>\n"):
fd := fopen(outputWolfram,WRITE,TEXT):
fprintf(fd,"%s",operatorText):
fclose(fd):
printf("BLOCK %d OPERATOR status=%s rows=%d columns=%d letters=%d residues=%d generators=%d terms=%d\n",
  requestedBlock,status,dimension,nops(columns),nops(letters),
  nops(residueRecords),nops(generatorMatrices),
  add(nops(kernel),kernel in constantCompositeKernels)):
printf("OUTPUT_MAPLE %s\nOUTPUT_WOLFRAM %s\n",outputMaple,
  outputWolfram):
quit:
