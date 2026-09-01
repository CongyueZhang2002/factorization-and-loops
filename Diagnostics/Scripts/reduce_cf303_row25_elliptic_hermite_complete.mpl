interface(prettyprint=0):
kernelopts(numcpus=6):

inputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_row25_block15_generic_epsilon_kernels.maple":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_row25_block15_elliptic_hermite_complete.maple":
read inputFile:

curveGCD := gcd(P4,diff(P4,u)):
curveDiscriminant := factor(discrim(P4,u)):

# Reduce R(u) du/Y on the fixed-p quartic Y^2=curvePolynomial.  The finite
# denominator of the algebraic primitive is the repeated part gcd(D,D').
# A complete quartic reduction also needs a polynomial primitive for source
# polynomial degree >=3 and a remainder through degree two at infinity.
hermiteEllipticComplete := proc(sourceKernel,curvePolynomial)
  local denPoly,branchGCD,repeated,squarefree,degreeRepeated,
    degreeSquarefree,sourcePolynomialPart,sourcePolynomialDegree,
    primitivePolynomialDegree,aVariables,bVariables,fVariables,variables,
    aPoly,bPoly,fPoly,primitive,exactKernel,remainderKernel,
    equationNumerator,equations,solution,primitiveReduced,remainderReduced,
    residual,solveSeconds,properNumerator,properDenominator,polynomialPart,
    properRemainder,factorization,poleRecords,factorRecord,factorPolynomial,
    factorDegree,roots,pole,poleCoefficient,ySquare,normalizedCoefficient,
    poleReconstruction,poleResidual,baseRegular,verified,basisShift,
    basisCoefficients,basisResidual,basisVerified,a,b,f,c0,c1,c2,i;

  if sourceKernel=0 then
    return [0,0,0,[0,0,0],[],[1,[]],0.,true,true,true,true,-1];
  end if;
  if degree(curvePolynomial,u)<>4 or
      degree(gcd(curvePolynomial,diff(curvePolynomial,u)),u)>0 then
    error "elliptic Hermite reduction requires a square-free quartic";
  end if;

  denPoly := primpart(denom(sourceKernel),u):
  branchGCD := gcd(denPoly,curvePolynomial):
  if degree(branchGCD,u)>0 then
    error "branch-point denominator requires a separate lowering rule";
  end if:
  repeated := gcd(denPoly,diff(denPoly,u)):
  squarefree := normal(denPoly/repeated):
  degreeRepeated := degree(repeated,u):
  degreeSquarefree := degree(squarefree,u):

  sourcePolynomialPart := quo(numer(sourceKernel),denom(sourceKernel),u):
  if sourcePolynomialPart=0 then
    sourcePolynomialDegree := -1:
  else
    sourcePolynomialDegree := degree(sourcePolynomialPart,u):
  end if:
  if sourcePolynomialDegree>=3 then
    primitivePolynomialDegree := sourcePolynomialDegree-3:
  else
    primitivePolynomialDegree := -1:
  end if:

  if degreeRepeated>0 then
    aVariables := [seq(a[i],i=0..degreeRepeated-1)]:
    aPoly := add(aVariables[i+1]*u^i,i=0..degreeRepeated-1):
  else
    aVariables := []:
    aPoly := 0:
  end if:
  if degreeSquarefree>0 then
    bVariables := [seq(b[i],i=0..degreeSquarefree-1)]:
    bPoly := add(bVariables[i+1]*u^i,i=0..degreeSquarefree-1):
  else
    bVariables := []:
    bPoly := 0:
  end if:
  if primitivePolynomialDegree>=0 then
    fVariables := [seq(f[i],i=0..primitivePolynomialDegree)]:
    fPoly := add(fVariables[i+1]*u^i,i=0..primitivePolynomialDegree):
  else
    fVariables := []:
    fPoly := 0:
  end if:

  variables := [op(aVariables),op(bVariables),op(fVariables),c0,c1,c2]:
  primitive := aPoly/repeated+fPoly:
  exactKernel := normal(curvePolynomial*diff(primitive,u)
    +diff(curvePolynomial,u)*primitive/2):
  remainderKernel := bPoly/squarefree+c0+c1*u+c2*u^2:
  equationNumerator := numer(normal(
    sourceKernel-exactKernel-remainderKernel)):
  equations := {seq(coeff(equationNumerator,u,i)=0,
    i=0..degree(equationNumerator,u))}:
  solveSeconds := time():
  solution := solve(equations,{op(variables)}):
  solveSeconds := time()-solveSeconds:
  if solution=NULL or nops(solution)<>nops(variables) then
    error "complete Hermite linear system did not have one solution";
  end if:

  primitiveReduced := normal(subs(solution,primitive)):
  remainderReduced := normal(subs(solution,remainderKernel)):
  residual := normal(sourceKernel-(curvePolynomial*diff(
    primitiveReduced,u)+diff(curvePolynomial,u)*primitiveReduced/2)
    -remainderReduced):
  verified := evalb(residual=0):

  properNumerator := numer(remainderReduced):
  properDenominator := denom(remainderReduced):
  polynomialPart := quo(properNumerator,properDenominator,u):
  properRemainder := normal(remainderReduced-polynomialPart):

  # Express the polynomial remainder in the quartic basis
  # {du/Y, u du/Y, (u^2+a3/(2a4)u)du/Y}.
  basisShift := normal(coeff(curvePolynomial,u,3)
    /(2*coeff(curvePolynomial,u,4))):
  basisCoefficients := [coeff(polynomialPart,u,0),
    normal(coeff(polynomialPart,u,1)
      -basisShift*coeff(polynomialPart,u,2)),
    coeff(polynomialPart,u,2)]:
  basisResidual := normal(polynomialPart-(basisCoefficients[1]
    +basisCoefficients[2]*u
    +basisCoefficients[3]*(u^2+basisShift*u))):
  basisVerified := evalb(basisResidual=0):

  factorization := factors(denom(properRemainder)):
  poleRecords := []:
  poleReconstruction := polynomialPart:
  baseRegular := true:
  for factorRecord in factorization[2] do
    factorPolynomial := factorRecord[1]:
    factorDegree := degree(factorPolynomial,u):
    if factorDegree=0 then next end if:
    if factorRecord[2]<>1 or factorDegree>2 then
      error "reduced kernel is not split by simple linear/quadratic factors";
    end if:
    roots := [solve(factorPolynomial=0,u)]:
    if nops(roots)<>factorDegree then
      error "pole factor did not split into the expected number of roots";
    end if:
    if normal(subs(u=1/2,factorPolynomial))=0 then
      baseRegular := false:
    end if:
    for pole in roots do
      poleCoefficient := normal(subs(u=pole,numer(properRemainder))
        /subs(u=pole,diff(denom(properRemainder),u))):
      ySquare := normal(subs(u=pole,curvePolynomial)):
      normalizedCoefficient := normal(poleCoefficient/sqrt(ySquare)):
      poleRecords := [op(poleRecords),[factorPolynomial,pole,
        poleCoefficient,ySquare,normalizedCoefficient]]:
      poleReconstruction := poleReconstruction+poleCoefficient/(u-pole):
    end do:
  end do:
  poleResidual := normal(remainderReduced-poleReconstruction):
  return [primitiveReduced,remainderReduced,polynomialPart,
    basisCoefficients,poleRecords,factorization,solveSeconds,verified,
    evalb(poleResidual=0),baseRegular,basisVerified,
    primitivePolynomialDegree];
end proc:

# Tests that specifically fail for the old c0+c1*u/proper-primitive ansatz.
testCurve := u^4+1:
testQuadratic := hermiteEllipticComplete(1/u^2,testCurve):
testPolynomialPrimitive := hermiteEllipticComplete(
  diff(testCurve,u)/2,testCurve):
testHighDegree := hermiteEllipticComplete(u^7,testCurve):
testSimplePole := hermiteEllipticComplete(1/(u-2),testCurve):
adversarialChecks := [
  ["quadratic_remainder_exact",testQuadratic[8]],
  ["quadratic_remainder_present",evalb(normal(testQuadratic[4][3]-1)=0)],
  ["constant_polynomial_primitive",evalb(normal(
    testPolynomialPrimitive[1]-1)=0
    and normal(testPolynomialPrimitive[2])=0)],
  ["high_degree_polynomial_primitive",evalb(testHighDegree[8]
    and testHighDegree[12]=4)],
  ["simple_nonbranch_pole",evalb(testSimplePole[8]
    and testSimplePole[9] and nops(testSimplePole[5])=1)]
]:
adversarialPassed := andmap(record -> record[2],adversarialChecks):

t0 := time():
hermiteRecords := []:
allVerified := true:
allPolesSplit := true:
allBaseRegular := true:
allBasisVerified := true:
processed := 0:
for entryIndex from 1 to nops(epsilonKernels) do
  entryRecords := []:
  for orderIndex from 1 to nops(orders) do
    regulatorOrder := orders[orderIndex]:
    evenKernel := normal(epsilonKernels[entryIndex][orderIndex][1]):
    ellipticKernel := normal(epsilonKernels[entryIndex][orderIndex][2]):
    reduction := hermiteEllipticComplete(ellipticKernel,P4):
    processed := processed+1:
    allVerified := allVerified and reduction[8]:
    allPolesSplit := allPolesSplit and reduction[9]:
    allBaseRegular := allBaseRegular and reduction[10]:
    allBasisVerified := allBasisVerified and reduction[11]:
    entryRecords := [op(entryRecords),[regulatorOrder,evenKernel,
      ellipticKernel,op(reduction)]]:
    printf("ENTRY %d ORDER %d poles=%d solve=%.3f verified=(%a,%a,%a) baseRegular=%a\n",
      entryIndex,regulatorOrder,nops(reduction[5]),reduction[7],
      reduction[8],reduction[9],reduction[11],reduction[10]):
  end do:
  hermiteRecords := [op(hermiteRecords),entryRecords]:
end do:
totalSeconds := time()-t0:
if processed=nops(epsilonKernels)*nops(orders)
    and degree(curveGCD,u)=0 and allVerified and allPolesSplit
    and allBaseRegular and allBasisVerified and adversarialPassed then
  status := "CF303Row25Block15EllipticHermiteCompleteAcceptedV1":
else
  status := "CF303Row25Block15EllipticHermiteCompleteFailedV1":
end if:
printf("ADVERSARIAL %a\n",adversarialChecks):
printf("DONE %.3f status=%s\n",totalSeconds,status):

fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"targets := %a:\n",targets):
fprintf(fd,"orders := %a:\n",orders):
fprintf(fd,"P4 := %a:\n",P4):
fprintf(fd,"curveDiscriminant := %a:\n",curveDiscriminant):
fprintf(fd,"recordSchema := %a:\n",
  "[order,evenKernel,ellipticKernel,primitiveF,remainderH,polynomialPart,{omega0,omegaInf,eta2}Coefficients,poleRecords,factorization,solveSeconds,HermiteVerified,PoleVerified,BaseRegular,BasisVerified,primitivePolynomialDegree]"):
fprintf(fd,"kernelConvention := %a:\n",
  "omega0=du/Y; omegaInf=u du/Y; eta2=(u^2+a3/(2a4)u)du/Y; omega(c)=Y(c)du/((u-c)Y); raw A/(u-c) has coefficient A/Y(c)"):
fprintf(fd,"adversarialChecks := %a:\n",adversarialChecks):
fprintf(fd,"hermiteRecords := %a:\n",hermiteRecords):
fprintf(fd,"totalSeconds := %a:\n",totalSeconds):
fclose(fd):
printf("OUTPUT %s\n",outputFile):
quit:
