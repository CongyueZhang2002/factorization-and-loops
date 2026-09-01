interface(prettyprint=0):
kernelopts(numcpus=6):
gaugeFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block25_source_gauge.maple":
solutionFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_depth2_mixed_solution.maple":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_depth2_physical_master5.maple":
read gaugeFile:
read solutionFile:
solutionStatus := status:

Dcurve := 4*p^2-4*p-u^2:
Q := normal(curve/Dcurve^2):
reduceQuadratic := proc(sourceExpression)
  local rationalExpression,numeratorExpression,denominatorExpression,
    reducedNumerator,reducedDenominator,n0,n1,d0,d1,quadraticNorm;
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
    normal((n1*d0-n0*d1)/quadraticNorm)];
end proc:

laurentData := proc(expression)
  local polynomial,orders,reconstructed,order;
  if expression=0 then return [[],table()] end if:
  polynomial := convert(series(expression,eps=0,13),polynom):
  orders := select(order -> coeff(polynomial,eps,order)<>0,[$-6..6]):
  reconstructed := add(coeff(polynomial,eps,order)*eps^order,
    order in orders):
  if normal(expression-reconstructed)<>0 then
    error "source-gauge Laurent window -6..6 was not exact";
  end if:
  return [orders,table([seq(order=normal(coeff(polynomial,eps,order)),
    order in orders)])];
end proc:

gaugeReduced := [seq(reduceQuadratic(sourceGaugeEntries[i]),
  i=1..nops(sourceGaugeEntries))]:
gaugeLaurent := [seq([laurentData(gaugeReduced[i][1]),
  laurentData(gaugeReduced[i][2])],i=1..nops(gaugeReduced))]:
gaugeSupports := [seq([gaugeLaurent[i][1][1],gaugeLaurent[i][2][1]],
  i=1..nops(gaugeLaurent))]:

coefficientAt := proc(entryIndex,order)
  local evenCoefficient,oddCoefficient;
  if member(order,gaugeLaurent[entryIndex][1][1]) then
    evenCoefficient := gaugeLaurent[entryIndex][1][2][order]:
  else evenCoefficient := 0 end if:
  if member(order,gaugeLaurent[entryIndex][2][1]) then
    oddCoefficient := gaugeLaurent[entryIndex][2][2][order]:
  else oddCoefficient := 0 end if:
  # even+rho*odd = even+(odd/Dcurve)Y.
  return [normal(evenCoefficient),normal(oddCoefficient/Dcurve)];
end proc:

pairScale := (scalar,pair) -> [normal(scalar*pair[1]),
  normal(scalar*pair[2])]:
pairAdd := (left,right) -> [normal(left[1]+right[1]),
  normal(left[2]+right[2])]:

# Row-major entries are T11,T12,T21,T22.  Master 5 is the first source row.
t11Order0 := coefficientAt(1,0):
t12Order0 := coefficientAt(2,0):
canonical44 := target44[1][1]:
canonical45 := target45[1][1]:
physicalMaster5Coefficient := pairAdd(
  pairScale(canonical44[1],t11Order0),
  pairScale(canonical45[1],t12Order0)):

acceptanceConditions := [evalb(solutionStatus=
  "CF303DepthTwoMixedSolutionAcceptedV1"),evalb(sourceIDs[1]=5),
  evalb(nops(target44)=1),evalb(nops(target45)=1)]:
status := if andmap(value -> value,acceptanceConditions) then
  "CF303DepthTwoPhysicalMaster5AcceptedV1"
else
  "CF303DepthTwoPhysicalMaster5FailedV1"
end if:

fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"acceptanceConditions := %a:\n",acceptanceConditions):
fprintf(fd,"physicalMaster := %a:\n",sourceIDs[1]):
fprintf(fd,"physicalOrder := %a:\n",-1):
fprintf(fd,"boundaryConstant := %a:\n",C23[0]):
fprintf(fd,"curve := %a:\n",curve):
fprintf(fd,"basePoint := %a:\n",basePoint):
fprintf(fd,"targetWord := %a:\n",targetWord):
fprintf(fd,"gaugeSupports := %a:\n",gaugeSupports):
fprintf(fd,"T11Order0 := %a:\n",t11Order0):
fprintf(fd,"T12Order0 := %a:\n",t12Order0):
fprintf(fd,"canonicalCoefficients := %a:\n",
  [canonical44,canonical45]):
fprintf(fd,"physicalCoefficient := %a:\n",physicalMaster5Coefficient):
fprintf(fd,"coefficientConvention := %a:\n",
  "[r(u),s(u)] means r(u)+s(u)Y(u); multiply by C23[0] and the stored targetWord based at u=1/2"):
fclose(fd):
printf("GAUGE supports=%a T11_0=%a T12_0=%a\n",
  gaugeSupports,t11Order0,t12Order0):
printf("ACCEPTANCE %a prior=%a targets=(%d,%d)\n",
  acceptanceConditions,solutionStatus,nops(target44),nops(target45)):
printf("PHYSICAL master=5 order=-1 coefficient=%a\n",
  physicalMaster5Coefficient):
printf("DONE status=%s output=%s\n",status,outputFile):
quit:
