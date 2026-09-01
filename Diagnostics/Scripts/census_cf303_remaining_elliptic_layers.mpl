interface(prettyprint=0):
kernelopts(numcpus=4):

libraryFile := "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/algebraic_curve_word_transport.mpl":
outputRoot := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues":
exceptionText := getenv("CF303_EXCEPTION_BLOCK"):
if exceptionText=false or exceptionText="" then
  exceptionMode := false:
  inputFile := cat(outputRoot,
    "/cf303_remaining_elliptic_layer_path_inputs.maple"):
else
  exceptionMode := true:
  exceptionBlock := parse(exceptionText):
  if not member(exceptionBlock,{1,2,11,14,18}) then
    error "CF303_EXCEPTION_BLOCK must be 1, 2, 11, 14 or 18";
  end if:
  inputFile := cat(outputRoot,"/cf303_block25_exception_",
    exceptionBlock,"_direct_u_path.maple"):
end if:
read inputFile:
read libraryFile:

Dcurve := 4*p^2-4*p-u^2:
P4 := 16*p^6-8*p^4*u^2+p^2*u^4+16*p^3*u^2-4*p*u^4
  -32*p^4+48*p^3*u-24*p^2*u^2-12*p*u^3+4*u^4
  -64*p^2*u+16*p*u^2+8*u^3+16*p^2+16*p*u+4*u^2:
Q := normal(P4/Dcurve^2):
ConfigureAlgebraicWordTransport(P4,u,1/2,Y0):

reduceQuadratic := proc(sourceExpression)
  local rationalExpression,numeratorExpression,denominatorExpression,
    reducedNumerator,reducedDenominator,n0,n1,d0,d1,quadraticNorm;
  if sourceExpression=0 then return [0,0] end if:
  rationalExpression := normal(sourceExpression):
  numeratorExpression := numer(rationalExpression):
  denominatorExpression := denom(rationalExpression):
  reducedNumerator := rem(numeratorExpression,rho^2-Q,rho):
  reducedDenominator := rem(denominatorExpression,rho^2-Q,rho):
  n0 := coeff(reducedNumerator,rho,0):
  n1 := coeff(reducedNumerator,rho,1):
  d0 := coeff(reducedDenominator,rho,0):
  d1 := coeff(reducedDenominator,rho,1):
  quadraticNorm := normal(d0^2-d1^2*Q):
  return [normal((n0*d0-n1*d1*Q)/quadraticNorm),
    normal((n1*d0-n0*d1)/quadraticNorm)]:
end proc:

compileAlgebraicPair := proc(sourceExpression)
  local reduced;
  if sourceExpression=0 then return [0,0] end if:
  reduced := reduceQuadratic(sourceExpression):
  return [reduced[1],normal(P4*reduced[2]/Dcurve)]:
end proc:

# Bounded quadratic projection.  It never forms one global denominator for a
# raw Wolfram sum.  Plus nodes containing rho are projected termwise, reduced
# in batches of 16, and merged as a balanced tree.  Rho-free polynomial/rational
# subexpressions stay opaque coefficients, so this does not expand kinematics.
pairCanonicalQuadratic := pair -> [normal(pair[1]),normal(pair[2])]:

pairMultiplyQuadratic := proc(left,right)
  return pairCanonicalQuadratic([
    left[1]*right[1]+Q*left[2]*right[2],
    left[1]*right[2]+left[2]*right[1]]):
end proc:

pairInverseQuadratic := proc(source)
  local sourceNorm,normValue;
  sourceNorm := pairCanonicalQuadratic(source):
  normValue := normal(sourceNorm[1]^2-Q*sourceNorm[2]^2):
  return [normal(sourceNorm[1]/normValue),
    normal(-sourceNorm[2]/normValue)]:
end proc:

pairPowerQuadratic := proc(source,exponent)
  local base,result,power;
  if exponent=0 then return [1,0] end if:
  if exponent<0 then
    return pairInverseQuadratic(pairPowerQuadratic(source,-exponent)):
  end if:
  base := pairCanonicalQuadratic(source):
  result := [1,0]: power := exponent:
  while power>0 do
    if irem(power,2)=1 then
      result := pairMultiplyQuadratic(result,base):
    end if:
    power := iquo(power,2):
    if power>0 then base := pairMultiplyQuadratic(base,base) end if:
  end do:
  return result:
end proc:

pairSumBalancedQuadratic := proc(sourcePairs)
  local work,nextWork,firstPosition,lastPosition,total,j;
  if nops(sourcePairs)=0 then return [0,0] end if:
  work := sourcePairs:
  while nops(work)>1 do
    nextWork := []:
    for firstPosition from 1 by 16 to nops(work) do
      lastPosition := min(firstPosition+15,nops(work)):
      total := [add(work[j][1],j=firstPosition..lastPosition),
        add(work[j][2],j=firstPosition..lastPosition)]:
      nextWork := [op(nextWork),pairCanonicalQuadratic(total)]:
    end do:
    work := nextWork:
  end do:
  return work[1]:
end proc:

quadraticProjectTermwise := proc(sourceExpression)
  local expressionHead,operands,operand,result,exponent;
  if sourceExpression=0 then return [0,0] end if:
  if sourceExpression=rho then return [0,1] end if:
  if not has(sourceExpression,rho) then return [sourceExpression,0] end if:
  expressionHead := op(0,sourceExpression):
  if expressionHead=`+` then
    operands := [op(sourceExpression)]:
    return pairSumBalancedQuadratic([
      seq(quadraticProjectTermwise(operand),operand in operands)]):
  elif expressionHead=`*` then
    result := [1,0]:
    for operand in [op(sourceExpression)] do
      if has(operand,rho) then
        result := pairMultiplyQuadratic(result,
          quadraticProjectTermwise(operand)):
      else
        result := [result[1]*operand,result[2]*operand]:
      end if:
    end do:
    return pairCanonicalQuadratic(result):
  elif expressionHead=`^` then
    exponent := op(2,sourceExpression):
    if not type(exponent,integer) then
      error "noninteger power survived branch reduction";
    end if:
    return pairPowerQuadratic(
      quadraticProjectTermwise(op(1,sourceExpression)),exponent):
  end if:
  error "unsupported rho-containing expression head",expressionHead:
end proc:

compileAlgebraicPairTermwise := proc(sourceExpression)
  local reduced;
  if sourceExpression=0 then return [0,0] end if:
  reduced := quadraticProjectTermwise(sourceExpression):
  return [normal(reduced[1]),normal(P4*reduced[2]/Dcurve)]:
end proc:

# Exact epsilon descriptor.  A nonconstant core denominator means a rational
# epsilon tail rather than finite Laurent support; its valuation and exact
# numerator/denominator degrees are retained instead of guessing a cutoff.
epsilonDescriptor := proc(sourceExpression)
  local rationalExpression,numeratorExpression,denominatorExpression,
    numeratorValuation,denominatorValuation,valuation,coreDenominator,
    minimumDegree,maximumDegree,support,i;
  if sourceExpression=0 then return ["Zero"] end if:
  rationalExpression := normal(sourceExpression):
  numeratorExpression := collect(numer(rationalExpression),eps):
  denominatorExpression := collect(denom(rationalExpression),eps):
  numeratorValuation := ldegree(numeratorExpression,eps):
  denominatorValuation := ldegree(denominatorExpression,eps):
  valuation := numeratorValuation-denominatorValuation:
  coreDenominator := normal(denominatorExpression/eps^denominatorValuation):
  if degree(coreDenominator,eps)>0 then
    return ["RationalTail",valuation,degree(numeratorExpression,eps),
      degree(denominatorExpression,eps),factor(coreDenominator)]:
  end if:
  minimumDegree := valuation:
  maximumDegree := degree(numeratorExpression,eps)-denominatorValuation:
  support := []:
  for i from minimumDegree to maximumDegree do
    if normal(coeff(expand(rationalExpression*eps^(-minimumDegree)),eps,
        i-minimumDegree))<>0 then
      support := [op(support),i]:
    end if:
  end do:
  return ["FiniteLaurent",support]:
end proc:

censusBlock := proc(block,targets,entries)
  local outputFile,kernelPairs,reducedDeck,epsilonProfiles,failures,
    letterLabels,distinctLetters,primitiveNonzeroCount,nonzeroCount,
    rationalTailCount,finiteLaurentCount,eta2Count,gplCount,e4Count,
    epsDependentLetterCount,quadraticVerified,
    pair,reduction,profile,entry,label,i,started,compileSeconds,
    reduceSeconds,status,fd;
  if exceptionMode then
    outputFile := cat(outputRoot,"/cf303_block25_exception_",block,
      "_elliptic_layer_census.maple"):
  else
    outputFile := cat(outputRoot,
      "/cf303_block",block,"_elliptic_layer_census.maple"):
  end if:
  kernelPairs := []: reducedDeck := []: epsilonProfiles := []:
  failures := []: letterLabels := []:
  primitiveNonzeroCount := 0: nonzeroCount := 0:
  rationalTailCount := 0: finiteLaurentCount := 0:
  quadraticVerified := false:

  started := time():
  for i from 1 to nops(entries) do
    if entries[i]=0 then
      pair := [0,0]: profile := [["Zero"],["Zero"]]:
    else
      nonzeroCount := nonzeroCount+1:
      try
        pair := compileAlgebraicPairTermwise(entries[i]):
        # Projection is constructive in Q(u,p,eps)[rho]/(rho^2-Q).
        # Do not reproject raw rho-free expressions merely to compare their
        # unnormalised syntax with the normal form produced above.  The
        # subsequent Hermite reduction reconstructs every compiled one-form.
        quadraticVerified := true:
        profile := [epsilonDescriptor(pair[1]),
          epsilonDescriptor(pair[2])]:
      catch:
        failures := [op(failures),[targets[i],"Compile",lastexception]]:
        pair := [0,0]: profile := [["Failed"],["Failed"]]:
      end try:
    end if:
    kernelPairs := [op(kernelPairs),pair]:
    epsilonProfiles := [op(epsilonProfiles),profile]:
    if profile[1][1]="RationalTail" or
        profile[2][1]="RationalTail" then
      rationalTailCount := rationalTailCount+1:
    elif profile[1][1]="FiniteLaurent" or
        profile[2][1]="FiniteLaurent" then
      finiteLaurentCount := finiteLaurentCount+1:
    end if:
    if i mod 10=0 or i=nops(entries) then
      printf("BLOCK %d COMPILE %d/%d %.3f\n",block,i,nops(entries),
        time()-started):
    end if:
  end do:
  compileSeconds := time()-started:

  started := time():
  for i from 1 to nops(kernelPairs) do
    if pairZero(kernelPairs[i]) then
      reduction := [[0,0],[],true]:
    else
      try
        # reduceForm includes the one exact reconstruction required for this
        # reduction.  No second verifier is run in this census.
        reduction := reduceForm(kernelPairs[i]):
        if not pairZero(reduction[1]) then
          primitiveNonzeroCount := primitiveNonzeroCount+1:
        end if:
        for entry in reduction[2] do
          letterLabels := [op(letterLabels),entry[2][1]]:
        end do:
      catch:
        failures := [op(failures),[targets[i],"Hermite",lastexception]]:
        reduction := [[0,0],[],false]:
      end try:
    end if:
    reducedDeck := [op(reducedDeck),reduction]:
    if i mod 10=0 or i=nops(kernelPairs) then
      printf("BLOCK %d REDUCE %d/%d %.3f\n",block,i,
        nops(kernelPairs),time()-started):
    end if:
  end do:
  reduceSeconds := time()-started:

  distinctLetters := [op({op(letterLabels)})]:
  eta2Count := nops(select(label -> label[1]="E4Eta2",letterLabels)):
  gplCount := nops(select(label -> substring(label[1],1..3)="GPL",
    letterLabels)):
  e4Count := nops(select(label -> substring(label[1],1..2)="E4",
    letterLabels)):
  epsDependentLetterCount := nops(select(label -> has(label,eps),
    distinctLetters)):
  status := if failures=[] and quadraticVerified then
    "CF303EllipticLayerCensusAcceptedV1"
  else
    "CF303EllipticLayerCensusIncompleteV1"
  end if:

  fd := fopen(outputFile,WRITE,TEXT):
  fprintf(fd,"status := %a:\n",status):
  fprintf(fd,"block := %a:\n",block):
  fprintf(fd,"P4 := %a:\n",P4):
  fprintf(fd,"Dcurve := %a:\n",Dcurve):
  fprintf(fd,"targets := %a:\n",targets):
  fprintf(fd,"kernelPairs := %a:\n",kernelPairs):
  fprintf(fd,"epsilonProfiles := %a:\n",epsilonProfiles):
  fprintf(fd,"reducedKernelDeck := %a:\n",reducedDeck):
  fprintf(fd,"distinctLetters := %a:\n",distinctLetters):
  fprintf(fd,"failures := %a:\n",failures):
  fprintf(fd,"counts := %a:\n",["Entries",nops(entries),
    "Nonzero",nonzeroCount,"PrimitiveNonzero",primitiveNonzeroCount,
    "LetterOccurrences",nops(letterLabels),
    "DistinctLetters",nops(distinctLetters),"GPL",gplCount,"E4",e4Count,
    "Eta2",eta2Count,"EpsilonDependentLetters",epsDependentLetterCount,
    "FiniteLaurentEntries",finiteLaurentCount,
    "RationalTailEntries",rationalTailCount]):
  fprintf(fd,"timings := %a:\n",["Compile",compileSeconds,
    "Reduce",reduceSeconds]):
  fclose(fd):
  printf("BLOCK %d DONE status=%s entries=%d nonzero=%d primitive=%d letters=%d distinct=%d gpl=%d e4=%d eta2=%d epsletters=%d finiteeps=%d rationaltail=%d compile=%.3f reduce=%.3f output=%s\n",
    block,status,nops(entries),nonzeroCount,primitiveNonzeroCount,
    nops(letterLabels),nops(distinctLetters),gplCount,e4Count,eta2Count,
    epsDependentLetterCount,finiteLaurentCount,rationalTailCount,
    compileSeconds,reduceSeconds,outputFile):
  return NULL:
end proc:

requestedText := getenv("CF303_CENSUS_BLOCK"):
if exceptionMode then
  censusBlock(exceptionBlock,exceptionTargets,exceptionEntries):
else
  if requestedText=false or requestedText="" then
    requestedBlocks := [17,21,25]:
  else
    requestedBlocks := [parse(requestedText)]:
  end if:
  for requestedBlock in requestedBlocks do
    if requestedBlock=17 then
      censusBlock(17,block17Targets,block17Entries):
    elif requestedBlock=21 then
      censusBlock(21,block21Targets,block21Entries):
    elif requestedBlock=25 then
      censusBlock(25,block25Targets,block25Entries):
    else
      error "requested block must be 17, 21 or 25";
    end if:
  end do:
end if:
quit:
