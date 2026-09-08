restart:
interface(prettyprint=0):

generatedInput := "/home/maxzhang/factorization-and-loops/Codex/TwoRootMapleAugmented/05_cf254_augmented_yx.mpl":
inputDescriptor := fopen(generatedInput, READ):
for lineNumber from 1 to 9 do
    inputLine := readline(inputDescriptor):
    if lineNumber >= 2 then
        parse(inputLine, statement):
    end if:
end do:
fclose(inputDescriptor):

infolevel[IntegrableConnections] := 5:
infolevel[IntegrableConnections:-direct_ratsol] := 5:
infolevel[IntegrableConnections:-Mpolsolde] := 5:

printf("probe=Mratsolde(A1,y)\n"):
printf("dimension=%d\n", rowdim(A1)):
printf("variable=%a\n", variables[1]):
probeStart := time[real]():
probeResult := Mratsolde(A1, variables[1]):
probeSeconds := time[real]() - probeStart:
printf("probe_status=RETURNED\n"):
printf("probe_seconds=%.6f\n", probeSeconds):
printf("probe_result=%a\n", eval(probeResult)):

quit:
