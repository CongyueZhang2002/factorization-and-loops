restart:
interface(prettyprint=0):
libname := "/home/maxzhang/factorization-and-loops/Addon/Other_Addon/Maple/IntegrableConnections", libname:
with(IntegrableConnections):
with(linalg):

# The source is closed for all k1,k2.  A rational primitive exists only when
# k1=0, since k1*dx/x is logarithmic while k2*dx=d(k2*x).
A := [matrix(1,1,[0]), matrix(1,1,[0])]:
b := [vector(1,[k1/x+k2]), vector(1,[0])]:

printf("integrability=%a\n", TestIntegrabilityConditions(A,[x,y],b)):

try
  Runknown := RationalSolutions(A,[x,y],['param',[eps],'rhs',b]):
  printf("unknown_constants_result=%a\n", Runknown):
catch:
  printf("unknown_constants_error=%a\n", [lastexception]):
end try:

try
  Rparameters := RationalSolutions(A,[x,y],
    ['param',[eps,k1,k2],'rhs',b]):
  printf("declared_parameters_result=%a\n", Rparameters):
catch:
  printf("declared_parameters_error=%a\n", [lastexception]):
end try:

Rfixed := RationalSolutions(A,[x,y],
  ['param',[eps,k2],'rhs',[vector(1,[k2]),vector(1,[0])]]):
printf("fixed_rational_source_result=%a\n", Rfixed):

quit:
