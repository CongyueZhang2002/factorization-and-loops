restart:
interface(prettyprint=0):
interface(verboseproc=3):
packageDirectory := "/home/maxzhang/factorization-and-loops/Addon/Other_Addon/Maple/IntegrableConnections":
libname := packageDirectory, libname:
with(IntegrableConnections):

printf("BEGIN_GOOD_FORM\n"):
print(eval(IntegrableConnections:-good_form)):
showstat(IntegrableConnections:-good_form):
printf("END_GOOD_FORM\n"):

printf("BEGIN_MPOLSOLDE\n"):
print(eval(IntegrableConnections:-Mpolsolde)):
showstat(IntegrableConnections:-Mpolsolde):
printf("END_MPOLSOLDE\n"):

quit:
