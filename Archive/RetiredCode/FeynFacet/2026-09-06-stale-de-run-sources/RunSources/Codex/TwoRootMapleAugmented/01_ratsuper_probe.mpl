restart:
interface(prettyprint=0):
interface(verboseproc=3):
packageDirectory := "/home/maxzhang/factorization-and-loops/Addon/Other_Addon/Maple/IntegrableConnections":
libname := packageDirectory, libname:
with(IntegrableConnections):

printf("BEGIN_RATSUPER\n"):
print(eval(IntegrableConnections:-ratsuper)):
showstat(IntegrableConnections:-ratsuper):
printf("END_RATSUPER\n"):

quit:
