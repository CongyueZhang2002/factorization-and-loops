restart:
interface(prettyprint=0):
interface(verboseproc=3):
packageDirectory := "/home/maxzhang/factorization-and-loops/Addon/Other_Addon/Maple/IntegrableConnections":
libname := packageDirectory, libname:
with(IntegrableConnections):

printf("BEGIN_DIRECT_RATSOL\n"):
print(eval(IntegrableConnections:-direct_ratsol)):
showstat(IntegrableConnections:-direct_ratsol):
printf("END_DIRECT_RATSOL\n"):

printf("BEGIN_MRATSOLDE\n"):
print(eval(IntegrableConnections:-Mratsolde)):
showstat(IntegrableConnections:-Mratsolde):
printf("END_MRATSOLDE\n"):

quit:
