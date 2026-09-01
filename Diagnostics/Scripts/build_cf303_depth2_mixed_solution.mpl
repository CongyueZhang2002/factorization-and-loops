interface(prettyprint=0):
kernelopts(numcpus=6):
inputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_row25_block15_elliptic_hermite_complete.maple":
libraryFile := "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/algebraic_curve_word_transport.mpl":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_depth2_mixed_solution.maple":
read inputFile:
read libraryFile:
ConfigureAlgebraicWordTransport(P4,u,1/2,Y0):

# CF303 row block 25 <- block 15: accepted outer order -2 records and inner
# dlog residue.  Everything below this point is family-specific data wiring.
outer44 := [hermiteRecords[1][2][2],hermiteRecords[1][2][3]]:
outer45 := [hermiteRecords[3][2][2],hermiteRecords[3][2][3]]:
c := expand(normal(2*p*(1-p))):
innerGPLLetter := [["GPLPole",c],[1/(u-c),0]]:
inputWord := [innerGPLLetter]:

t0 := time():
solution44 := integrateFormWord(pairScale(-1,outer44),inputWord):
seconds44 := time()-t0:
t1 := time():
solution45 := integrateFormWord(pairScale(-1,outer45),inputWord):
seconds45 := time()-t1:
verification44 := verifyIntegratedWord(
  pairScale(-1,outer44),inputWord,solution44):
verification45 := verifyIntegratedWord(
  pairScale(-1,outer45),inputWord,solution45):
verified44 := verification44[1]:
verified45 := verification45[1]:
residual44 := verification44[2]:
residual45 := verification45[2]:
labelled44 := labelledSolution(solution44):
labelled45 := labelledSolution(solution45):
targetLabel := [["E4Pole",c],["GPLPole",c]]:
target44 := select(term -> evalb(term[2]=targetLabel),labelled44):
target45 := select(term -> evalb(term[2]=targetLabel),labelled45):
status := if verified44 and verified45 and nops(target44)=1
    and nops(target45)=1 then
  "CF303DepthTwoMixedSolutionAcceptedV1"
else
  "CF303DepthTwoMixedSolutionFailedV1"
end if:

fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n",status):
fprintf(fd,"curve := %a:\n",P4):
fprintf(fd,"basePoint := %a:\n",u0):
fprintf(fd,"coefficientConvention := %a:\n",
  "[r(u),s(u)] denotes r(u)+s(u)Y(u); Y0 denotes the chosen Y(1/2) sheet"):
fprintf(fd,"wordConvention := %a:\n",
  "GPLPole(c)=du/(u-c); E4Pole(c,Yc)=Yc du/((u-c)Y); E4Omega0=du/Y; E4OmegaInf=u du/Y; E4Eta2=(u^2+a3/(2a4)u)du/Y"):
fprintf(fd,"inputWord := %a:\n",wordLabels(inputWord)):
fprintf(fd,"row44Solution := %a:\n",labelled44):
fprintf(fd,"row45Solution := %a:\n",labelled45):
fprintf(fd,"targetWord := %a:\n",targetLabel):
fprintf(fd,"target44 := %a:\n",target44):
fprintf(fd,"target45 := %a:\n",target45):
fprintf(fd,"termCounts := %a:\n",[nops(labelled44),nops(labelled45)]):
fprintf(fd,"seconds := %a:\n",[seconds44,seconds45]):
fprintf(fd,"verified := %a:\n",[verified44,verified45]):
fprintf(fd,"residualSummary := %a:\n",[
  [seq(wordLabels(residual44[i][2]),i=1..nops(residual44))],
  [seq(wordLabels(residual45[i][2]),i=1..nops(residual45))]]):
fclose(fd):
printf("ROW44 terms=%d seconds=%.3f verified=%a target=%a\n",
  nops(labelled44),seconds44,verified44,target44):
printf("ROW45 terms=%d seconds=%.3f verified=%a target=%a\n",
  nops(labelled45),seconds45,verified45,target45):
printf("RESIDUAL_COUNTS row44=%d row45=%d\n",
  nops(residual44),nops(residual45)):
printf("RESIDUAL_LABELS row44=%a row45=%a\n",
  [seq(wordLabels(residual44[i][2]),i=1..nops(residual44))],
  [seq(wordLabels(residual45[i][2]),i=1..nops(residual45))]):
printf("DONE status=%s output=%s\n",status,outputFile):
quit:
