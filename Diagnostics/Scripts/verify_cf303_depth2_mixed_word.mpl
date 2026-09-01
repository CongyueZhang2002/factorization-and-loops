interface(prettyprint=0):
kernelopts(numcpus=6):
pathInputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_elliptic_layer_path_inputs.maple":
hermiteFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_row25_block15_elliptic_hermite_complete.maple":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_depth2_mixed_word.maple":

read pathInputFile:
Dcurve := 4*p^2-4*p-u^2:
P4 := 16*p^6-8*p^4*u^2+p^2*u^4+16*p^3*u^2-4*p*u^4
  -32*p^4+48*p^3*u-24*p^2*u^2-12*p*u^3+4*u^4
  -64*p^2*u+16*p*u^2+8*u^3+16*p^2+16*p*u+4*u^2:
Q := normal(P4/Dcurve^2):

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

# Rows 23 and 24 are positions 1 and 4 in the row-major 3x3 block-15 deck.
innerReduced := reduceQuadratic(block15Entries[1]+block15Entries[4]):
innerKernel := normal(innerReduced[1]/eps):
innerOdd := normal(innerReduced[2]/eps):
c := 2*p*(1-p):
innerExpected := normal(3*diff(Dcurve,u)/Dcurve-diff(P4,u)/P4
  -1/(u-c)):
innerDifference := normal(innerKernel-innerExpected):
innerVerified := evalb(innerDifference=0 and not has(innerKernel,eps)
  and not has(innerOdd,eps)):

read hermiteFile:
outerRecords := hermiteRecords:
# orders={-3,-2,...,6}; order -2 is record position 2.
record44a := outerRecords[1][2]:
record44b := outerRecords[2][2]:
record45a := outerRecords[3][2]:
record45b := outerRecords[4][2]:
outerPairsIdentical := evalb(
  normal(record44a[3]-record44b[3])=0 and
  normal(record45a[3]-record45b[3])=0):

poleRecordAt := proc(record,poleValue)
  local candidates;
  candidates := select(item -> normal(item[2]-poleValue)=0,record[8]):
  if nops(candidates)<>1 then
    error "expected exactly one marked-pole record";
  end if:
  return candidates[1];
end proc:
pole44 := poleRecordAt(record44a,c):
pole45 := poleRecordAt(record45a,c):
raw44 := normal(pole44[3]):
raw45 := normal(pole45[3]):
ySquareAtC := normal(subs(u=c,P4)):
expected44 := normal(12*(p^2-p-1)*p^4/(p-2)):
expected45 := normal(8*(p^2-p-1)*p^4/(p-2)):
expectedYSquare := normal(16*p^2*(p-2)^2*(p-1)^2
  *(p^2-p-1)^2):
outerVerified := evalb(outerPairsIdentical
  and normal(raw44-expected44)=0
  and normal(raw45-expected45)=0
  and normal(ySquareAtC-expectedYSquare)=0):

# The inner residue at u=c is -1.  The raw outer convention is
# du/((u-c)Y); normalized eMPL uses Y(c)du/((u-c)Y).
rawDepthTwoCoefficients := [-raw44,-raw45]:
normalizedDepthTwoCoefficients := [
  normal(-raw44/sqrt(ySquareAtC)),
  normal(-raw45/sqrt(ySquareAtC))]:
u0 := 1/2:
affineGPLLetter := normal((c-u0)/(uTarget-u0)):
status := if innerVerified and outerVerified then
  "CF303DepthTwoMixedWordAcceptedV1"
else
  "CF303DepthTwoMixedWordFailedV1"
end if:

fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"curve := %a:\n",P4):
fprintf(fd,"basePoint := %a:\n",u0):
fprintf(fd,"markedPoint := %a:\n",c):
fprintf(fd,"markedPointYSquare := %a:\n",ySquareAtC):
fprintf(fd,"innerKernel := %a:\n",innerKernel):
fprintf(fd,"innerOdd := %a:\n",innerOdd):
fprintf(fd,"innerExpectedDifference := %a:\n",innerDifference):
fprintf(fd,"innerProjection := %a:\n",
  "the displayed mixed word uses the -dlog(u-c) term of the even component; the same inner entry also has independent elliptic letters"):
fprintf(fd,"innerDecomposition := %a:\n",
  [3,diff(Dcurve,u)/Dcurve,-1,diff(P4,u)/P4,-1,1/(u-c)]):
fprintf(fd,"affineGPLLetter := %a:\n",affineGPLLetter):
fprintf(fd,"mixedWord := %a:\n",
  [["E4Pole",c,sqrt(ySquareAtC)],["GPLPole",c]]):
fprintf(fd,"rawDepthTwoCoefficients := %a:\n",rawDepthTwoCoefficients):
fprintf(fd,"normalizedDepthTwoCoefficients := %a:\n",
  normalizedDepthTwoCoefficients):
fprintf(fd,"checks := %a:\n",[["Inner",innerVerified],
  ["Outer",outerVerified],["OuterPairsIdentical",outerPairsIdentical]]):
fclose(fd):
printf("INNER verified=%a odd=%a difference=%a kernel=%a\n",
  innerVerified,innerOdd,innerDifference,innerKernel):
printf("OUTER verified=%a raw=(%a,%a) Yc2=%a\n",
  outerVerified,raw44,raw45,ySquareAtC):
printf("WORD raw_coefficients=%a normalized=%a\n",
  rawDepthTwoCoefficients,normalizedDepthTwoCoefficients):
printf("DONE status=%s output=%s\n",status,outputFile):
quit:
