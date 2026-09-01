# Reusable algebraic-curve word-integration library.
#
# ConfigureAlgebraicWordTransport binds a quartic model Y(variable)^2=curve,
# a base point, and the chosen base-point sheet value.  Nonsingularity and
# branch-point avoidance are mathematical preconditions supplied by the caller.
# Quadratic letters remain root-free and marked simple poles use the inert
# Yc(c) convention so one sheet choice is retained throughout a word.
ConfigureAlgebraicWordTransport := proc(curveInput,variableInput,
    basePointInput,baseYInput)
  global P4,u,u0,Y0,basisShift;
  P4 := curveInput:
  u := variableInput:
  u0 := basePointInput:
  Y0 := baseYInput:
  if degree(P4,u)<>4 or coeff(P4,u,4)=0 then
    error "curve must be quartic in its configured variable";
  end if:
  basisShift := normal(coeff(P4,u,3)/(2*coeff(P4,u,4))):
  return NULL:
end proc:

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
    if factorRecord[2]<>1 then
      error "rational remainder still has a repeated finite factor";
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
      for i from 0 to factorDegree-1 do
        if coeff(partialNumerator,u,i)<>0 then
          poleRecords := [op(poleRecords),[
            coeff(partialNumerator,u,i),
            [["GPLFactor",factorPolynomial,i],
              [u^i/factorPolynomial,0]]]]:
        end if:
      end do:
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
    partialNumerator,pole,rawCoefficient,yValue,coefficient,
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
    if factorRecord[2]<>1 then
      error "elliptic remainder still has a repeated finite factor";
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
      yValue := markedY(pole):
      coefficient := normal(rawCoefficient/yValue):
      poleRecords := [op(poleRecords),[coefficient,
        [["E4Pole",pole],[0,yValue/(u-pole)]]]]:
    else
      for i from 0 to factorDegree-1 do
        if coeff(partialNumerator,u,i)<>0 then
          poleRecords := [op(poleRecords),[
            coeff(partialNumerator,u,i),
            [["E4Factor",factorPolynomial,i],
              [0,u^i/factorPolynomial]]]]:
        end if:
      end do:
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
    error "standard one-form reconstruction failed";
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
  local residual;
  residual := differentiateSolution(solution):
  residual := addSolutionTerm(residual,pairScale(-1,formPair),inputWord):
  return residual:
end proc:

# Exact derivative verification in the configured algebraic function field.
verifyIntegratedWord := proc(formPair,inputWord,solution)
  local residual;
  residual := integralResidual(formPair,inputWord,solution):
  return [evalb(nops(residual)=0),residual]:
end proc:

labelledSolution := proc(solution)
  local i;
  return [seq([solution[i][1],wordLabels(solution[i][2])],
    i=1..nops(solution))];
end proc:
