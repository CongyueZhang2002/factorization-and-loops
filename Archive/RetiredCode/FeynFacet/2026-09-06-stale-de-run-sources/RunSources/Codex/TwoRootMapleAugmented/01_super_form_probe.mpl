restart:
interface(prettyprint=0):
interface(verboseproc=3):
packageDirectory := "/home/maxzhang/factorization-and-loops/Addon/Other_Addon/Maple/IntegrableConnections":
libname := packageDirectory, libname:
with(IntegrableConnections):

printf("BEGIN_SUPER_FORM\n"):
print(eval(IntegrableConnections:-super_form)):
showstat(IntegrableConnections:-super_form):
printf("END_SUPER_FORM\n"):

quit:
