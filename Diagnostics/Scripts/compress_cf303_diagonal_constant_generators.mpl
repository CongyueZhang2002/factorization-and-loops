interface(prettyprint=0):
kernelopts(numcpus=4):
with(LinearAlgebra):

outputRoot := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues":
requestedText := getenv("CF303_CENSUS_BLOCK"):
if requestedText=false or requestedText="" then
  error "CF303_CENSUS_BLOCK must be 17, 21 or 25";
end if:
block := parse(requestedText):
if block=17 then diagonalRows := [28]
elif block=21 then diagonalRows := [37,38]
elif block=25 then diagonalRows := [44,45]
else error "CF303_CENSUS_BLOCK must be 17, 21 or 25"
end if:
dimension := nops(diagonalRows):
inputFile := cat(outputRoot,"/cf303_block",block,
  "_elliptic_layer_census.maple"):
outputFile := cat(outputRoot,"/cf303_block",block,
  "_diagonal_constant_generators.maple"):
read inputFile:

labelPosition := proc(labels,label)
  local i;
  for i from 1 to nops(labels) do
    if evalb(labels[i]=label) then return i end if:
  end do:
  return 0:
end proc:

activeLabels := []:
residueMatrices := []:
epsilonLinear := true:
for targetPosition from 1 to nops(targets) do
  row := targets[targetPosition][1]:
  column := targets[targetPosition][2]:
  if not member(row,diagonalRows) or not member(column,diagonalRows) then
    next:
  end if:
  rowPosition := row-diagonalRows[1]+1:
  columnPosition := column-diagonalRows[1]+1:
  for term in reducedKernelDeck[targetPosition][2] do
    coefficient := normal(term[1]/eps):
    if has(coefficient,eps) then epsilonLinear := false end if:
    letterLabel := term[2][1]:
    position := labelPosition(activeLabels,letterLabel):
    if position=0 then
      activeLabels := [op(activeLabels),letterLabel]:
      residueMatrices := [op(residueMatrices),Matrix(dimension,dimension,0)]:
      position := nops(activeLabels):
    end if:
    residueMatrices[position][rowPosition,columnPosition] := normal(
      residueMatrices[position][rowPosition,columnPosition]+coefficient):
  end do:
end do:

flattenMatrix := source -> Vector(dimension^2,index ->
  source[iquo(index-1,dimension)+1,irem(index-1,dimension)+1]):
residueVectors := Matrix(dimension^2,nops(residueMatrices),
  (row,column) -> flattenMatrix(residueMatrices[column])[row]):
fieldSpanRank := Rank(residueVectors):

# Normalize every matrix only projectively: scalar p/Yc dependence common to
# all of its entries is moved into that letter's one-form.  The remaining
# primitive polynomial matrix is then expanded in p over Q.
normalizedResidues := []:
residueScalars := []:
normalizationAccepted := true:
for residueMatrix in residueMatrices do
  denominatorScale := 1:
  for row from 1 to dimension do
    for column from 1 to dimension do
      if residueMatrix[row,column]<>0 then
        denominatorScale := lcm(denominatorScale,
          denom(normal(residueMatrix[row,column]))):
      end if:
    end do:
  end do:
  polynomialMatrix := map(normal,denominatorScale*residueMatrix):
  commonContent := 0:
  for row from 1 to dimension do
    for column from 1 to dimension do
      if polynomialMatrix[row,column]<>0 then
        if commonContent=0 then
          commonContent := polynomialMatrix[row,column]:
        else
          commonContent := gcd(commonContent,polynomialMatrix[row,column]):
        end if:
      end if:
    end do:
  end do:
  if commonContent=0 then commonContent := 1 end if:
  polynomialMatrix := map(normal,polynomialMatrix/commonContent):
  normalizationAccepted := normalizationAccepted and
    not has(polynomialMatrix,{u,eps,Yc}):
  for row from 1 to dimension do
    for column from 1 to dimension do
      normalizationAccepted := normalizationAccepted and
        evalb(denom(polynomialMatrix[row,column])=1):
    end do:
  end do:
  normalizedResidues := [op(normalizedResidues),polynomialMatrix]:
  residueScalars := [op(residueScalars),
    normal(commonContent/denominatorScale)]:
end do:

coefficientMatrices := []:
coefficientOrigins := []:
for residueIndex from 1 to nops(normalizedResidues) do
  degreeBound := max(op([seq(seq(
    degree(normalizedResidues[residueIndex][row,column],p),
    column=1..dimension),row=1..dimension)])):
  for power from 0 to degreeBound do
    coefficientMatrix := Matrix(dimension,dimension,(row,column) ->
      coeff(normalizedResidues[residueIndex][row,column],p,power)):
    if not Equal(coefficientMatrix,Matrix(dimension,dimension,0)) then
      coefficientMatrices := [op(coefficientMatrices),coefficientMatrix]:
      coefficientOrigins := [op(coefficientOrigins),[residueIndex,power]]:
    end if:
  end do:
end do:

generatorMatrices := []:
generatorVectors := Matrix(dimension^2,0):
generatorOrigins := []:
constantGeneratorRank := 0:
for position from 1 to nops(coefficientMatrices) do
  candidate := <generatorVectors|flattenMatrix(coefficientMatrices[position])>:
  candidateRank := Rank(candidate):
  if candidateRank>constantGeneratorRank then
    generatorMatrices := [op(generatorMatrices),coefficientMatrices[position]]:
    generatorVectors := candidate:
    generatorOrigins := [op(generatorOrigins),coefficientOrigins[position]]:
    constantGeneratorRank := candidateRank:
  end if:
end do:

generatorCoordinatesByResidue := []:
generatorCompositeKernels := [seq([],generatorIndex=1..
  constantGeneratorRank)]:
verified := epsilonLinear and normalizationAccepted and
  evalb(nops(activeLabels)>0):
for residueIndex from 1 to nops(normalizedResidues) do
  coordinates := map(normal,LinearSolve(generatorVectors,
    flattenMatrix(normalizedResidues[residueIndex]))):
  generatorCoordinatesByResidue := [op(generatorCoordinatesByResidue),
    convert(coordinates,list)]:
  reconstructed := Matrix(dimension,dimension,0):
  for generatorIndex from 1 to constantGeneratorRank do
    reconstructed := reconstructed+coordinates[generatorIndex]
      *generatorMatrices[generatorIndex]:
    if coordinates[generatorIndex]<>0 then
      generatorCompositeKernels[generatorIndex] := [
        op(generatorCompositeKernels[generatorIndex]),
        [normal(residueScalars[residueIndex]
          *coordinates[generatorIndex]),residueIndex]]:
    end if:
  end do:
  verified := verified and Equal(map(normal,reconstructed
    -normalizedResidues[residueIndex]),Matrix(dimension,dimension,0)):
end do:
status := if verified then
  "CF303DiagonalConstantGeneratorsAcceptedV1"
else
  "CF303DiagonalConstantGeneratorsFailedV1"
end if:

fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"block := %a:\n",block):
fprintf(fd,"diagonalRows := %a:\n",diagonalRows):
fprintf(fd,"activeLabels := %a:\n",activeLabels):
fprintf(fd,"residueMatrices := %a:\n",
  [seq(convert(residueMatrices[i],listlist),i=1..nops(residueMatrices))]):
fprintf(fd,"residueScalars := %a:\n",residueScalars):
fprintf(fd,"normalizedResidues := %a:\n",
  [seq(convert(normalizedResidues[i],listlist),
    i=1..nops(normalizedResidues))]):
fprintf(fd,"generatorOrigins := %a:\n",generatorOrigins):
fprintf(fd,"generatorMatrices := %a:\n",
  [seq(convert(generatorMatrices[i],listlist),
    i=1..nops(generatorMatrices))]):
fprintf(fd,"generatorCoordinatesByResidue := %a:\n",
  generatorCoordinatesByResidue):
fprintf(fd,"generatorCompositeKernels := %a:\n",
  generatorCompositeKernels):
fprintf(fd,"counts := %a:\n",["ActiveDiagonalForms",nops(activeLabels),
  "FieldSpanRank",fieldSpanRank,
  "PolynomialCoefficientMatrices",nops(coefficientMatrices),
  "ConstantGeneratorRank",constantGeneratorRank]):
fprintf(fd,"epsilonLinear := %a:\n",epsilonLinear):
fprintf(fd,"verified := %a:\n",verified):
fclose(fd):
printf("DIAGONAL block=%d active=%d field_rank=%d coefficient_matrices=%d constant_rank=%d epslinear=%a verified=%a output=%s\n",
  block,nops(activeLabels),fieldSpanRank,nops(coefficientMatrices),
  constantGeneratorRank,epsilonLinear,verified,outputFile):
quit:
