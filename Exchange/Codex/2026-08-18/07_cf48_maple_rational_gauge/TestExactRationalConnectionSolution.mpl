restart:
libname := "/home/maxzhang/FACET/Addon/Other_Addon/Maple/IntegrableConnections", libname:
with(IntegrableConnections):
with(linalg):
read "ExactRationalConnectionSolution.mpl":

A1 := matrix(1,1,[1/(2*x)]):
A2 := matrix(1,1,[1/(2*y)]):
b1 := vector(1,[1/2]):
b2 := vector(1,[-x/(2*y)]):

result := ExactRationalConnectionSolution(
    [A1,A2], [x,y], [b1,b2], []):

if result = FAIL then
    error "the synthetic exact connection was not solved"
end if:

V := vector(result["SolutionList"]):
printf("SYNTHETIC_SOLUTION=%a\n", convert(V,list)):
printf("SYNTHETIC_RESIDUALS=%a\n", result["Residuals"]):
quit:
