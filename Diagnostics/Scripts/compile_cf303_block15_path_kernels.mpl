interface(prettyprint=0):
kernelopts(numcpus=6):
inputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_elliptic_layer_path_inputs.maple":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_path_kernels.maple":
read inputFile:

Dcurve := 4*p^2-4*p-u^2:
P4 := 16*p^6-8*p^4*u^2+p^2*u^4+16*p^3*u^2-4*p*u^4
  -32*p^4+48*p^3*u-24*p^2*u^2-12*p*u^3+4*u^4
  -64*p^2*u+16*p*u^2+8*u^3+16*p^2+16*p*u+4*u^2:
Q := normal(P4/Dcurve^2):

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
    normal((n1*d0-n0*d1)/quadraticNorm)];
end proc:

compileEntry := proc(sourceExpression)
  local reduced,evenKernel,oddCoefficient,ellipticKernel;
  if sourceExpression=0 then return [0,0] end if:
  reduced := reduceQuadratic(sourceExpression):
  evenKernel := normal(reduced[1]/eps):
  oddCoefficient := normal(reduced[2]/eps):
  if has(evenKernel,eps) or has(oddCoefficient,eps) then
    error "block-15 path entry is not exactly epsilon-linear";
  end if:
  ellipticKernel := normal(P4*oddCoefficient/Dcurve):
  return [evenKernel,ellipticKernel];
end proc:

t0 := time():
block15KernelPairs := [seq(compileEntry(block15FullEntries[i]),
  i=1..nops(block15FullEntries))]:
compileSeconds := time()-t0:
nonzeroCount := nops(select(pair -> pair[1]<>0 or pair[2]<>0,
  block15KernelPairs)):
evenCount := nops(select(pair -> pair[1]<>0,block15KernelPairs)):
ellipticCount := nops(select(pair -> pair[2]<>0,block15KernelPairs)):
mixedCount := nops(select(pair -> pair[1]<>0 and pair[2]<>0,
  block15KernelPairs)):
status := if nops(block15KernelPairs)=nops(block15FullTargets) then
  "CF303Block15PathKernelsAcceptedV1"
else
  "CF303Block15PathKernelsFailedV1"
end if:

fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"P4 := %a:\n",P4):
fprintf(fd,"Dcurve := %a:\n",Dcurve):
fprintf(fd,"feederBlocks := %a:\n",block15FeederBlocks):
fprintf(fd,"columns := %a:\n",block15FullColumns):
fprintf(fd,"targets := %a:\n",block15FullTargets):
fprintf(fd,"kernelPairs := %a:\n",block15KernelPairs):
fprintf(fd,"counts := %a:\n",
  ["Total",nops(block15KernelPairs),"Nonzero",nonzeroCount,
    "Even",evenCount,"Elliptic",ellipticCount,"Mixed",mixedCount]):
fprintf(fd,"compileSeconds := %a:\n",compileSeconds):
fclose(fd):
printf("COUNTS total=%d nonzero=%d even=%d elliptic=%d mixed=%d\n",
  nops(block15KernelPairs),nonzeroCount,evenCount,ellipticCount,mixedCount):
printf("DONE %.3f status=%s output=%s\n",
  compileSeconds,status,outputFile):
quit:
