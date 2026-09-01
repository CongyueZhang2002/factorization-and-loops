interface(prettyprint=0):
inputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block25_exception_2_elliptic_layer_census.maple":
q := 2305843009213691819:
pImage := 4*modp(1/11,q) mod q:
epsilonImage := 11:
uImages := [7*modp(1/5,q) mod q,9*modp(1/7,q) mod q,13*modp(1/11,q) mod q]:
read inputFile:

valueMod := proc(expression,uImage)
  local specialized;
  specialized := eval(expression,{p=pImage,eps=epsilonImage,u=uImage}):
  return modp(specialized,q):
end proc:

for i from 1 to 2 do
  printf("ROW %d\n",i):
  printf("FORCING %a\n",[seq(valueMod(kernelPairs[i][1],pointImage),pointImage in uImages)]):
  printf("PRIMITIVE %a\n",[seq(valueMod(reducedKernelDeck[i][1][1],pointImage),pointImage in uImages)]):
  printf("REMAINDER %a\n",[seq(valueMod(kernelPairs[i][1]-diff(reducedKernelDeck[i][1][1],u),pointImage),pointImage in uImages)]):
end do:
quit:
