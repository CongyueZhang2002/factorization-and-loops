restart:
interface(prettyprint=0):
interface(verboseproc=3):

packageDirectory := "/home/maxzhang/factorization-and-loops/Addon/Other_Addon/Maple/IntegrableConnections":
packageArchive := cat(packageDirectory, "/IntegrableConnections.mla"):
libname := packageDirectory, libname:

printf("BEGIN_ENVIRONMENT\n"):
printf("kernel_version=%a\n", kernelopts(version)):
printf("package_directory=%s\n", packageDirectory):
printf("package_archive=%s\n", packageArchive):
printf("archive_exists=%a\n", FileTools:-Exists(packageArchive)):
printf("libname=%a\n", libname):
printf("END_ENVIRONMENT\n"):

printf("BEGIN_LOAD\n"):
try
    with(IntegrableConnections):
    printf("load_result=OK\n"):
catch:
    printf("load_result=ERROR\n"):
    printf("load_exception=%a\n", lastexception):
end try:
printf("END_LOAD\n"):

printf("BEGIN_EXPORTS\n"):
try
    packageExports := [exports(IntegrableConnections)]:
    printf("exports_result=OK\n"):
    printf("exports=%a\n", packageExports):
catch:
    printf("exports_result=ERROR\n"):
    printf("exports_exception=%a\n", lastexception):
end try:
printf("END_EXPORTS\n"):

printf("BEGIN_RATIONALSOLUTIONS_DEFINITION\n"):
try
    printf("rationalsolutions_type=%a\n", type(IntegrableConnections:-RationalSolutions, procedure)):
    print(eval(IntegrableConnections:-RationalSolutions)):
    showstat(IntegrableConnections:-RationalSolutions):
catch:
    printf("rationalsolutions_definition_error=%a\n", lastexception):
end try:
printf("END_RATIONALSOLUTIONS_DEFINITION\n"):

printf("BEGIN_MRATSOLDE_DEFINITION\n"):
try
    printf("mratsolde_type=%a\n", type(IntegrableConnections:-Mratsolde, procedure)):
    print(eval(IntegrableConnections:-Mratsolde)):
    showstat(IntegrableConnections:-Mratsolde):
catch:
    printf("mratsolde_definition_error=%a\n", lastexception):
end try:
printf("END_MRATSOLDE_DEFINITION\n"):

printf("BEGIN_HELP_RATIONALSOLUTIONS\n"):
?IntegrableConnections[RationalSolutions]
printf("END_HELP_RATIONALSOLUTIONS\n"):

printf("BEGIN_HELP_INTEGRABLECONNECTIONS\n"):
?IntegrableConnections
printf("END_HELP_INTEGRABLECONNECTIONS\n"):

quit:
