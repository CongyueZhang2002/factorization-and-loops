interface(prettyprint=0):
kernelopts(numcpus=6):
inputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_row25_block15_elliptic_hermite_complete.maple":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_depth2_mixed_solution.maple":
read inputFile:

u0 := 1/2:
basisShift := normal(coeff(P4,u,3)/(2*coeff(P4,u,4))):

# A marked point has one sheet choice for the entire word calculation.
# Keep that value as the inert symbol Yc(c), with Yc(c)^2=P4(c), rather than
# repeatedly expanding principal square roots.  Coefficient and kernel then
# carry inverse factors that cancel exactly, while the branch is fixed once
# in the output contract.
markedY := proc(pole)
  option remember;
  return Yc(pole);
end proc:

pairNormal := pair -> [normal(pair[1]),normal(pair[2])]:
pairScale := (scalar,pair) -> [normal(scalar*pair[1]),
  normal(scalar*pair[2])]:
pairAdd := (left,right) -> [normal(left[1]+right[1]),
  normal(left[2]+right[2])]:
pairZero := pair -> evalb(normal(pair[1])=0 and normal(pair[2])=0):

# Multiply the algebraic function f+F*Y by the differential
# e du+R du/Y, returning another differential pair.
functionTimesForm := proc(functionPair,formPair)
  return [normal(functionPair[1]*formPair[1]
      +functionPair[2]*formPair[2]),
    normal(functionPair[1]*formPair[2]
      +functionPair[2]*P4*formPair[1])];
end proc:

functionDerivative := proc(functionPair)
  return [normal(diff(functionPair[1],u)),
    normal(P4*diff(functionPair[2],u)
      +diff(P4,u)*functionPair[2]/2)];
end proc:

baseValue := functionPair -> normal(subs(u=u0,functionPair[1])
  +subs(u=u0,functionPair[2])*Y0):

rationalReduce := proc(sourceKernel)
  local denPoly,repeated,squarefree,degreeRepeated,degreeSquarefree,
    sourcePolynomialPart,sourcePolynomialDegree,primitivePolynomialDegree,
    aVariables,bVariables,fVariables,variables,aPoly,bPoly,fPoly,
    primitive,remainder,equationNumerator,equations,solution,
    primitiveReduced,remainderReduced,residual,factorization,poleRecords,
    factorRecord,factorPolynomial,factorDegree,denominatorTotal,otherFactor,
    gcdValue,bezoutS,bezoutT,partialNumerator,pole,coefficient,
    reconstruction,a,b,f,i;
  if sourceKernel=0 then return [0,[],true] end if:
  denPoly := primpart(denom(sourceKernel),u):
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
  primitivePolynomialDegree := sourcePolynomialDegree+1:

  if degreeRepeated>0 then
    aVariables := [seq(a[i],i=0..degreeRepeated-1)]:
    aPoly := add(aVariables[i+1]*u^i,i=0..degreeRepeated-1):
  else
    aVariables := []: aPoly := 0:
  end if:
  if degreeSquarefree>0 then
    bVariables := [seq(b[i],i=0..degreeSquarefree-1)]:
    bPoly := add(bVariables[i+1]*u^i,i=0..degreeSquarefree-1):
  else
    bVariables := []: bPoly := 0:
  end if:
  if primitivePolynomialDegree>=1 then
    fVariables := [seq(f[i],i=1..primitivePolynomialDegree)]:
    fPoly := add(fVariables[i]*u^i,i=1..primitivePolynomialDegree):
  else
    fVariables := []: fPoly := 0:
  end if:
  variables := [op(aVariables),op(bVariables),op(fVariables)]:
  primitive := aPoly/repeated+fPoly:
  remainder := bPoly/squarefree:
  equationNumerator := numer(normal(
    sourceKernel-diff(primitive,u)-remainder)):
  equations := {seq(coeff(equationNumerator,u,i)=0,
    i=0..degree(equationNumerator,u))}:
  solution := solve(equations,{op(variables)}):
  if solution=NULL or nops(solution)<>nops(variables) then
    error "rational Hermite system did not have one solution";
  end if:
  primitiveReduced := normal(subs(solution,primitive)):
  remainderReduced := normal(subs(solution,remainder)):
  residual := normal(sourceKernel-diff(primitiveReduced,u)
    -remainderReduced):
  factorization := factors(denom(remainderReduced)):
  poleRecords := []:
  reconstruction := 0:
  denominatorTotal := denom(remainderReduced):
  for factorRecord in factorization[2] do
    factorPolynomial := sort(primpart(factorRecord[1],u),u):
    factorDegree := degree(factorPolynomial,u):
    if factorDegree=0 then next end if:
    if factorRecord[2]<>1 or factorDegree>2 then
      error "rational remainder is not split into simple degree<=2 poles";
    end if:
    otherFactor := normal(denominatorTotal/factorPolynomial):
    gcdValue := gcdex(otherFactor,factorPolynomial,u,'bezoutS','bezoutT'):
    partialNumerator := rem(normal(numer(remainderReduced)
      *bezoutS/gcdValue),factorPolynomial,u):
    reconstruction := reconstruction+partialNumerator/factorPolynomial:
    if factorDegree=1 then
      pole := expand(normal(-coeff(factorPolynomial,u,0)
        /coeff(factorPolynomial,u,1))):
      coefficient := normal(partialNumerator
        /coeff(factorPolynomial,u,1)):
      poleRecords := [op(poleRecords),[coefficient,
        [["GPLPole",pole],[1/(u-pole),0]]]]:
    else
      if coeff(partialNumerator,u,0)<>0 then
        poleRecords := [op(poleRecords),[coeff(partialNumerator,u,0),
          [["GPLQuadratic0",factorPolynomial],
            [1/factorPolynomial,0]]]]:
      end if:
      if coeff(partialNumerator,u,1)<>0 then
        poleRecords := [op(poleRecords),[coeff(partialNumerator,u,1),
          [["GPLQuadratic1",factorPolynomial],
            [u/factorPolynomial,0]]]]:
      end if:
    end if:
  end do:
  return [primitiveReduced,poleRecords,
    evalb(residual=0 and normal(remainderReduced-reconstruction)=0)];
end proc:

ellipticReduce := proc(sourceKernel)
  local denPoly,branchGCD,repeated,squarefree,degreeRepeated,
    degreeSquarefree,sourcePolynomialPart,sourcePolynomialDegree,
    primitivePolynomialDegree,aVariables,bVariables,fVariables,variables,
    aPoly,bPoly,fPoly,primitive,remainder,equationNumerator,equations,
    solution,primitiveReduced,remainderReduced,residual,properNumerator,
    properDenominator,polynomialPart,properRemainder,basisCoefficients,
    factorization,poleRecords,factorRecord,factorPolynomial,factorDegree,
    denominatorTotal,otherFactor,gcdValue,bezoutS,bezoutT,
    partialNumerator,pole,rawCoefficient,ySquare,yValue,coefficient,
    reconstruction,a,b,f,c0,c1,c2,i;
  if sourceKernel=0 then return [0,[],true] end if:
  denPoly := primpart(denom(sourceKernel),u):
  branchGCD := gcd(denPoly,P4):
  if degree(branchGCD,u)>0 then
    error "branch-point pole requires a separate reduction rule";
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
    aVariables := []: aPoly := 0:
  end if:
  if degreeSquarefree>0 then
    bVariables := [seq(b[i],i=0..degreeSquarefree-1)]:
    bPoly := add(bVariables[i+1]*u^i,i=0..degreeSquarefree-1):
  else
    bVariables := []: bPoly := 0:
  end if:
  if primitivePolynomialDegree>=0 then
    fVariables := [seq(f[i],i=0..primitivePolynomialDegree)]:
    fPoly := add(fVariables[i+1]*u^i,i=0..primitivePolynomialDegree):
  else
    fVariables := []: fPoly := 0:
  end if:
  variables := [op(aVariables),op(bVariables),op(fVariables),c0,c1,c2]:
  primitive := aPoly/repeated+fPoly:
  remainder := bPoly/squarefree+c0+c1*u+c2*u^2:
  equationNumerator := numer(normal(sourceKernel-
    (P4*diff(primitive,u)+diff(P4,u)*primitive/2)-remainder)):
  equations := {seq(coeff(equationNumerator,u,i)=0,
    i=0..degree(equationNumerator,u))}:
  solution := solve(equations,{op(variables)}):
  if solution=NULL or nops(solution)<>nops(variables) then
    error "elliptic Hermite system did not have one solution";
  end if:
  primitiveReduced := normal(subs(solution,primitive)):
  remainderReduced := normal(subs(solution,remainder)):
  residual := normal(sourceKernel-(P4*diff(primitiveReduced,u)
    +diff(P4,u)*primitiveReduced/2)-remainderReduced):
  properNumerator := numer(remainderReduced):
  properDenominator := denom(remainderReduced):
  polynomialPart := quo(properNumerator,properDenominator,u):
  properRemainder := normal(remainderReduced-polynomialPart):
  basisCoefficients := [coeff(polynomialPart,u,0),
    normal(coeff(polynomialPart,u,1)
      -basisShift*coeff(polynomialPart,u,2)),
    coeff(polynomialPart,u,2)]:
  poleRecords := []:
  if basisCoefficients[1]<>0 then
    poleRecords := [op(poleRecords),[basisCoefficients[1],
      [["E4Omega0"],[0,1]]]]:
  end if:
  if basisCoefficients[2]<>0 then
    poleRecords := [op(poleRecords),[basisCoefficients[2],
      [["E4OmegaInf"],[0,u]]]]:
  end if:
  if basisCoefficients[3]<>0 then
    poleRecords := [op(poleRecords),[basisCoefficients[3],
      [["E4Eta2"],[0,u^2+basisShift*u]]]]:
  end if:
  reconstruction := polynomialPart:
  factorization := factors(denom(properRemainder)):
  denominatorTotal := denom(properRemainder):
  for factorRecord in factorization[2] do
    factorPolynomial := sort(primpart(factorRecord[1],u),u):
    factorDegree := degree(factorPolynomial,u):
    if factorDegree=0 then next end if:
    if factorRecord[2]<>1 or factorDegree>2 then
      error "elliptic remainder is not split into simple degree<=2 poles";
    end if:
    otherFactor := normal(denominatorTotal/factorPolynomial):
    gcdValue := gcdex(otherFactor,factorPolynomial,u,'bezoutS','bezoutT'):
    partialNumerator := rem(normal(numer(properRemainder)
      *bezoutS/gcdValue),factorPolynomial,u):
    reconstruction := reconstruction+partialNumerator/factorPolynomial:
    if factorDegree=1 then
      pole := expand(normal(-coeff(factorPolynomial,u,0)
        /coeff(factorPolynomial,u,1))):
      rawCoefficient := normal(partialNumerator
        /coeff(factorPolynomial,u,1)):
      ySquare := normal(subs(u=pole,P4)):
      yValue := markedY(pole):
      coefficient := normal(rawCoefficient/yValue):
      poleRecords := [op(poleRecords),[coefficient,
        [["E4Pole",pole],[0,yValue/(u-pole)]]]]:
    else
      if coeff(partialNumerator,u,0)<>0 then
        poleRecords := [op(poleRecords),[coeff(partialNumerator,u,0),
          [["E4Quadratic0",factorPolynomial],
            [0,1/factorPolynomial]]]]:
      end if:
      if coeff(partialNumerator,u,1)<>0 then
        poleRecords := [op(poleRecords),[coeff(partialNumerator,u,1),
          [["E4Quadratic1",factorPolynomial],
            [0,u/factorPolynomial]]]]:
      end if:
    end if:
  end do:
  return [primitiveReduced,poleRecords,
    evalb(residual=0 and normal(remainderReduced-reconstruction)=0)];
end proc:

reduceForm := proc(formPair)
  local rational,elliptic,terms,primitive,reconstructed,entry,
    standardResidual,standardVerified;
  rational := rationalReduce(formPair[1]):
  elliptic := ellipticReduce(formPair[2]):
  if not (rational[3] and elliptic[3]) then
    error "one-form reduction failed its exact residual";
  end if:
  terms := [op(rational[2]),op(elliptic[2])]:
  primitive := [rational[1],elliptic[1]]:
  reconstructed := functionDerivative(primitive):
  for entry in terms do
    reconstructed := pairAdd(reconstructed,
      pairScale(entry[1],entry[2][2])):
  end do:
  standardResidual := pairAdd(reconstructed,pairScale(-1,formPair)):
  standardVerified := pairZero(standardResidual):
  if not standardVerified then
    printf("STANDARD_REDUCTION_FAILED zero=(%a,%a) hasYc=(%a,%a) sample=%a\n",
      evalb(standardResidual[1]=0),evalb(standardResidual[2]=0),
      has(reconstructed[1],Yc),has(reconstructed[2],Yc),
      evalf(subs(p=4/11,u=5/7,standardResidual))):
  end if:
  return [primitive,terms,standardVerified];
end proc:

wordLabels := proc(word)
  local i;
  return [seq(word[i][1],i=1..nops(word))];
end proc:

addSolutionTerm := proc(current,coefficientPair,word)
  local result,normalizedPair,labels,found,j,newPair;
  result := current:
  normalizedPair := pairNormal(coefficientPair):
  if pairZero(normalizedPair) then return result end if:
  labels := wordLabels(word):
  found := false:
  for j from 1 to nops(result) do
    if evalb(wordLabels(result[j][2])=labels) then
      newPair := pairAdd(result[j][1],normalizedPair):
      result[j] := [newPair,result[j][2]]:
      found := true:
      break:
    end if:
  end do:
  if not found then result := [op(result),[normalizedPair,word]] end if:
  return select(term -> not pairZero(term[1]),result):
end proc:

integrateFormWord := proc(formPair,word)
  local reduction,primitive,remainder,result,entry,head,tail,product,
    recursive,j;
  reduction := reduceForm(formPair):
  primitive := reduction[1]:
  remainder := reduction[2]:
  result := []:
  if nops(word)=0 then
    result := addSolutionTerm(result,primitive,[]):
    result := addSolutionTerm(result,[-baseValue(primitive),0],[]):
    for entry in remainder do
      result := addSolutionTerm(result,[entry[1],0],[entry[2]]):
    end do:
    return result:
  end if:

  result := addSolutionTerm(result,primitive,word):
  for entry in remainder do
    result := addSolutionTerm(result,[entry[1],0],
      [entry[2],op(word)]):
  end do:
  head := word[1]:
  if nops(word)=1 then tail := [] else tail := [op(2..nops(word),word)] end if:
  product := functionTimesForm(primitive,head[2]):
  recursive := integrateFormWord(product,tail):
  for j from 1 to nops(recursive) do
    result := addSolutionTerm(result,pairScale(-1,recursive[j][1]),
      recursive[j][2]):
  end do:
  return result:
end proc:

differentiateSolution := proc(solution)
  local result,term,word,head,tail,product;
  result := []:
  for term in solution do
    word := term[2]:
    result := addSolutionTerm(result,functionDerivative(term[1]),word):
    if nops(word)>0 then
      head := word[1]:
      if nops(word)=1 then tail := []
      else tail := [op(2..nops(word),word)] end if:
      product := functionTimesForm(term[1],head[2]):
      result := addSolutionTerm(result,product,tail):
    end if:
  end do:
  return result:
end proc:

integralResidual := proc(formPair,inputWord,solution)
  local residual,term;
  residual := differentiateSolution(solution):
  residual := addSolutionTerm(residual,pairScale(-1,formPair),inputWord):
  return residual:
end proc:

labelledSolution := proc(solution)
  local i;
  return [seq([solution[i][1],wordLabels(solution[i][2])],
    i=1..nops(solution))];
end proc:

# The accepted outer order -2 kernels are records 1 and 3 for rows 44,45.
outer44 := [hermiteRecords[1][2][2],hermiteRecords[1][2][3]]:
outer45 := [hermiteRecords[3][2][2],hermiteRecords[3][2][3]]:
c := expand(normal(2*p*(1-p))):
innerGPLLetter := [["GPLPole",c],[1/(u-c),0]]:
inputWord := [innerGPLLetter]:

t0 := time():
# The selected inner dlog residue is -1.
solution44 := integrateFormWord(pairScale(-1,outer44),inputWord):
seconds44 := time()-t0:
t1 := time():
solution45 := integrateFormWord(pairScale(-1,outer45),inputWord):
seconds45 := time()-t1:
residual44 := integralResidual(pairScale(-1,outer44),inputWord,solution44):
residual45 := integralResidual(pairScale(-1,outer45),inputWord,solution45):
verified44 := evalb(nops(residual44)=0):
verified45 := evalb(nops(residual45)=0):
labelled44 := labelledSolution(solution44):
labelled45 := labelledSolution(solution45):
targetLabel := [["E4Pole",c],
  ["GPLPole",c]]:
target44 := select(term -> evalb(term[2]=targetLabel),labelled44):
target45 := select(term -> evalb(term[2]=targetLabel),labelled45):
status := if verified44 and verified45 and nops(target44)=1
    and nops(target45)=1 then
  "CF303DepthTwoMixedSolutionAcceptedV1"
else
  "CF303DepthTwoMixedSolutionFailedV1"
end if:

fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"curve := %a:\n",P4):
fprintf(fd,"basePoint := %a:\n",u0):
fprintf(fd,"coefficientConvention := %a:\n",
  "[r(u),s(u)] denotes r(u)+s(u)Y(u); Y0 denotes the chosen Y(1/2) sheet"):
fprintf(fd,"wordConvention := %a:\n",
  "GPLPole(c)=du/(u-c); E4Pole(c,Yc)=Yc du/((u-c)Y); E4Omega0=du/Y; E4OmegaInf=u du/Y; E4Eta2=(u^2+a3/(2a4)u)du/Y"):
fprintf(fd,"inputWord := %a:\n",wordLabels(inputWord)):
fprintf(fd,"row44Solution := %a:\n",labelled44):
fprintf(fd,"row45Solution := %a:\n",labelled45):
fprintf(fd,"targetWord := %a:\n",targetLabel):
fprintf(fd,"target44 := %a:\n",target44):
fprintf(fd,"target45 := %a:\n",target45):
fprintf(fd,"termCounts := %a:\n",[nops(labelled44),nops(labelled45)]):
fprintf(fd,"seconds := %a:\n",[seconds44,seconds45]):
fprintf(fd,"verified := %a:\n",[verified44,verified45]):
fprintf(fd,"residualSummary := %a:\n",[
  [seq(wordLabels(residual44[i][2]),i=1..nops(residual44))],
  [seq(wordLabels(residual45[i][2]),i=1..nops(residual45))]]):
fclose(fd):
printf("ROW44 terms=%d seconds=%.3f verified=%a target=%a\n",
  nops(labelled44),seconds44,verified44,target44):
printf("ROW45 terms=%d seconds=%.3f verified=%a target=%a\n",
  nops(labelled45),seconds45,verified45,target45):
printf("RESIDUAL_COUNTS row44=%d row45=%d\n",
  nops(residual44),nops(residual45)):
printf("RESIDUAL_LABELS row44=%a row45=%a\n",
  [seq(wordLabels(residual44[i][2]),i=1..nops(residual44))],
  [seq(wordLabels(residual45[i][2]),i=1..nops(residual45))]):
printf("DONE status=%s output=%s\n",status,outputFile):
quit:
