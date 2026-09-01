interface(prettyprint=0):
kernelopts(numcpus=6):
inputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_compressed_residue_basis.maple":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_constant_generators.maple":
read inputFile:
with(LinearAlgebra):
basisResidues := [seq(Matrix(item),item in basisResidues)]:

flattenMatrix := source -> Vector(9,index ->
  source[iquo(index-1,3)+1,irem(index-1,3)+1]):
coefficientMatrices := []:
coefficientOrigins := []:
for basisIndex from 1 to nops(basisResidues) do
  degreeBound := max(op([seq(seq(
    degree(basisResidues[basisIndex][row,column],p),
    column=1..3),row=1..3)])):
  for power from 0 to degreeBound do
    coefficientMatrix := Matrix(3,3,(row,column) ->
      coeff(basisResidues[basisIndex][row,column],p,power)):
    if not Equal(coefficientMatrix,Matrix(3,3,0)) then
      coefficientMatrices := [op(coefficientMatrices),coefficientMatrix]:
      coefficientOrigins := [op(coefficientOrigins),[basisIndex,power]]:
    end if:
  end do:
end do:

generatorMatrices := []:
generatorVectors := Matrix(9,0):
generatorOrigins := []:
currentRank := 0:
for position from 1 to nops(coefficientMatrices) do
  candidate := <generatorVectors|flattenMatrix(coefficientMatrices[position])>:
  candidateRank := Rank(candidate):
  if candidateRank>currentRank then
    generatorMatrices := [op(generatorMatrices),
      coefficientMatrices[position]]:
    generatorVectors := candidate:
    generatorOrigins := [op(generatorOrigins),coefficientOrigins[position]]:
    currentRank := candidateRank:
  end if:
end do:

# First express each polynomial residue basis matrix in the constant
# generators, then absorb those scalar polynomials into its one-form.
generatorKernelCoefficients := Matrix(currentRank,nops(basisResidues),0):
for position from 1 to nops(coefficientMatrices) do
  coordinates := map(normal,LinearSolve(generatorVectors,
    flattenMatrix(coefficientMatrices[position]))):
  basisIndex := coefficientOrigins[position][1]:
  power := coefficientOrigins[position][2]:
  for generatorIndex from 1 to currentRank do
    generatorKernelCoefficients[generatorIndex,basisIndex] := normal(
      generatorKernelCoefficients[generatorIndex,basisIndex]
      +coordinates[generatorIndex]*p^power):
  end do:
end do:

constantCompositeKernels := []:
for generatorIndex from 1 to currentRank do
  kernelTerms := []:
  for basisIndex from 1 to nops(compositeKernels) do
    outerCoefficient := generatorKernelCoefficients[
      generatorIndex,basisIndex]:
    if outerCoefficient=0 then next end if:
    for term in compositeKernels[basisIndex] do
      coefficient := normal(outerCoefficient*term[1]):
      if coefficient<>0 then
        kernelTerms := [op(kernelTerms),[coefficient,term[2]]]:
      end if:
    end do:
  end do:
  constantCompositeKernels := [op(constantCompositeKernels),kernelTerms]:
end do:

verified := true:
for basisIndex from 1 to nops(basisResidues) do
  reconstructed := Matrix(3,3,0):
  for generatorIndex from 1 to currentRank do
    reconstructed := reconstructed+
      generatorKernelCoefficients[generatorIndex,basisIndex]
      *generatorMatrices[generatorIndex]:
  end do:
  verified := verified and Equal(map(normal,
    reconstructed-basisResidues[basisIndex]),Matrix(3,3,0)):
end do:
status := if verified then
  "CF303Block15ConstantGeneratorsAcceptedV1"
else
  "CF303Block15ConstantGeneratorsFailedV1"
end if:

fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"generatorOrigins := %a:\n",generatorOrigins):
fprintf(fd,"generatorMatrices := %a:\n",
  [seq(convert(generatorMatrices[i],listlist),
    i=1..nops(generatorMatrices))]):
fprintf(fd,"basisToGeneratorCoefficients := %a:\n",
  convert(generatorKernelCoefficients,listlist)):
fprintf(fd,"constantCompositeKernels := %a:\n",
  constantCompositeKernels):
fprintf(fd,"counts := %a:\n",["PolynomialCoefficientMatrices",
  nops(coefficientMatrices),"ConstantGeneratorRank",currentRank,
  "CompositeKernelTerms",add(nops(kernel),
    kernel in constantCompositeKernels)]):
fprintf(fd,"verified := %a:\n",verified):
fclose(fd):
printf("CONSTANT_GENERATORS coefficient_matrices=%d rank=%d terms=%d verified=%a\n",
  nops(coefficientMatrices),currentRank,
  add(nops(kernel),kernel in constantCompositeKernels),verified):
printf("DONE status=%s output=%s\n",status,outputFile):
quit:
