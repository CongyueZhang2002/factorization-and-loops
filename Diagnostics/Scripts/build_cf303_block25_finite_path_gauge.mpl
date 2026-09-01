interface(prettyprint=0):
kernelopts(numcpus=1):

# Scratch-only finite triangular path gauge for the final CF303 block.
#
# With dL=eps*S.L, dF=eps*D.F+B.L and F=G+H.L,
#
#   B'_n = B_n + D.H_(n-1) - H_(n-1).S - dH_n.
#
# The complete incoming artifact already contains one accepted Hermite
# reduction of every B entry.  This script never reconstructs and never
# re-reduces those large forms.  At each epsilon order it Hermite-reduces only
# the new cross form D.Hprev-Hprev.S, adds its primitive/remainder linearly to
# the accepted incoming primitive/remainder, and normalizes H_n to vanish at
# the base point before H_n is used at the next order.

runtimeRoot := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues":
transferFile := cat(runtimeRoot,
  "/cf303_block25_general_elliptic_transfer.maple"):
pathInputFile := cat(runtimeRoot,
  "/cf303_block25_path_dlog_gauge_inputs.maple"):
libraryFile := "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/algebraic_curve_word_transport.mpl":
serializerFile := "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/maple_wolfram_serializer.mpl":
outputMaple := cat(runtimeRoot,
  "/cf303_block25_finite_path_gauge.maple"):
outputWolfram := cat(runtimeRoot,
  "/cf303_block25_finite_path_gauge.wl"):
exceptionBlocksExpected := [1,2,11,14,18]:
exceptionCensusFiles := [seq(cat(runtimeRoot,
  "/cf303_block25_exception_",exceptionBlock,
  "_elliptic_layer_census.maple"),
  exceptionBlock in exceptionBlocksExpected)]:
windowLow := -2:
windowHigh := 4:
startedTotal := time():

for exceptionCensusFile in exceptionCensusFiles do
  if not FileTools:-Exists(exceptionCensusFile) then
    error "all five accepted exception censuses must exist before this solver runs";
  end if:
end do:
if not FileTools:-Exists(transferFile) or
    not FileTools:-Exists(pathInputFile) then
  error "complete transfer and path dlog gauge inputs must exist";
end if:

started := time():
read transferFile:
transferSeconds := time()-started:
transferStatus := status:
transferBlock := block:
transferCurve := P4:
transferRows := rows:
transferColumns := columns:
transferEntryRecords := entryRecords:

if transferStatus<>"CF303Block25GeneralEllipticTransferAcceptedV1"
    or transferBlock<>25 or transferRows<>[44,45]
    or nops(transferEntryRecords)<>90 then
  error "the complete 90-entry accepted block-25 transfer is required";
end if:

started := time():
read pathInputFile:
pathInputSeconds := time()-started:
if sourceDimension<>43 or targetDimension<>2
    or nops(sourceRows)<>sourceDimension
    or nops({op(sourceRows)})<>sourceDimension
    or nops(transferColumns)<>sourceDimension+targetDimension
    or {op(transferColumns)}<>{op(sourceRows),op(transferRows)}
    or normal(curve-transferCurve)<>0 then
  error "path dlog gauge input dimensions, source ordering, or curve mismatch";
end if:
if nops(targetFormRecords)=0 or nops(sourceFormRecords)=0 then
  error "path dlog gauge input has an empty diagonal connection";
end if:

# Restore the marked-sheet functions hidden behind short export symbols.
for markedDefinition in markedPointDefinitions do
  assign(markedDefinition[1]=Yc(markedDefinition[2])):
end do:

read libraryFile:
ConfigureAlgebraicWordTransport(curve,u,basePoint,Y0):

newPairArray := proc(rowCount,columnCount)
  local result,row,column;
  result := Array(1..rowCount,1..columnCount):
  for row from 1 to rowCount do
    for column from 1 to columnCount do result[row,column] := [0,0] end do:
  end do:
  return result:
end proc:

# Cross products are accumulated without intermediate normalization.  The
# shared reducer normalizes the completed 2x43 coordinate once; doing it after
# every sparse matrix product would repeatedly rebuild the same denominators.
accumulateFunctionForm := proc(current,functionPair,formPair,sign)
  global P4;
  return [current[1]+sign*(functionPair[1]*formPair[1]
      +functionPair[2]*formPair[2]),
    current[2]+sign*(functionPair[1]*formPair[2]
      +functionPair[2]*P4*formPair[1])]:
end proc:

normalizeAtBase := proc(functionPair)
  local value;
  value := baseValue(functionPair):
  return pairAdd(functionPair,[-value,0]):
end proc:

laurentWindow := proc(expression)
  global eps,windowLow,windowHigh;
  local polynomial,records,epsilonOrder,coefficient;
  if expression=0 then return [] end if:
  polynomial := convert(series(expression,eps=0,windowHigh+1),polynom):
  records := []:
  for epsilonOrder from windowLow to windowHigh do
    coefficient := normal(coeff(polynomial,eps,epsilonOrder)):
    if coefficient<>0 then
      records := [op(records),[epsilonOrder,coefficient]]:
    end if:
  end do:
  return records:
end proc:

windowCoefficient := proc(records,epsilonOrder)
  local record;
  for record in records do
    if record[1]=epsilonOrder then return record[2] end if:
  end do:
  return 0:
end proc:

profileMinimum := proc(profile)
  if profile[1]="Zero" then return infinity
  elif profile[1]="RationalTail" then return profile[2]
  elif profile[1]="FiniteLaurent" then
    if nops(profile[2])=0 then return infinity else return min(op(profile[2])) end if:
  end if:
  error "unsupported epsilon profile",profile:
end proc:

sourceLocation := table():
for sourcePosition from 1 to sourceDimension do
  sourceLocation[sourceRows[sourcePosition]] := sourcePosition:
end do:
targetLocation := table():
for targetPosition from 1 to targetDimension do
  targetLocation[transferRows[targetPosition]] := targetPosition:
end do:

originalPrimitiveTable := table():
getOriginalPrimitive := proc(epsilonOrder,row,column)
  global originalPrimitiveTable;
  if assigned(originalPrimitiveTable[epsilonOrder,row,column]) then
    return originalPrimitiveTable[epsilonOrder,row,column]
  else
    return [0,0]
  end if:
end proc:

transformedLabels := []:
transformedForms := []:
residueTable := table():

internLetter := proc(descriptor)
  global transformedLabels,transformedForms;
  local label,form,index,residual;
  label := descriptor[1]:
  form := descriptor[2]:
  for index from 1 to nops(transformedLabels) do
    if evalb(transformedLabels[index]=label) then
      residual := pairAdd(transformedForms[index],pairScale(-1,form)):
      if not pairZero(residual) then
        error "one letter label carries two different one-forms",label;
      end if:
      return index:
    end if:
  end do:
  transformedLabels := [op(transformedLabels),label]:
  transformedForms := [op(transformedForms),form]:
  return nops(transformedLabels):
end proc:

addResidue := proc(epsilonOrder,descriptor,row,column,coefficient)
  global residueTable,u;
  local letterIndex,old,updated;
  if coefficient=0 then return NULL end if:
  if has(coefficient,u) then
    error "a Hermite remainder coefficient still depends on the path variable";
  end if:
  letterIndex := internLetter(descriptor):
  if assigned(residueTable[epsilonOrder,letterIndex,row,column]) then
    old := residueTable[epsilonOrder,letterIndex,row,column]
  else
    old := 0
  end if:
  updated := normal(old+coefficient):
  residueTable[epsilonOrder,letterIndex,row,column] := updated:
  return NULL:
end proc:

# Compile the accepted incoming reductions only by Laurent coefficient
# extraction.  No B entry is reconstructed and reduceForm is never called on
# it.  Target/source positions are resolved through the authoritative
# sourceRows ordering rather than inferred from temporary matrix positions.
started := time():
incomingRecordsUsed := 0:
for entryRecord in transferEntryRecords do
  target := entryRecord[1]:
  if member(target[2],{op(transferRows)}) then next end if:
  if not assigned(targetLocation[target[1]]) or
      not assigned(sourceLocation[target[2]]) then
    error "incoming transfer target is absent from sourceRows",target;
  end if:
  row := targetLocation[target[1]]:
  column := sourceLocation[target[2]]:
  if min(profileMinimum(entryRecord[2][1]),
      profileMinimum(entryRecord[2][2]))<windowLow then
    error "incoming transfer valuation lies below the finite window",target;
  end if:
  primitiveWindows := [laurentWindow(entryRecord[3][1]),
    laurentWindow(entryRecord[3][2])]:
  for epsilonOrder from windowLow to windowHigh do
    primitiveCoefficient := [
      windowCoefficient(primitiveWindows[1],epsilonOrder),
      windowCoefficient(primitiveWindows[2],epsilonOrder)]:
    if not pairZero(primitiveCoefficient) then
      originalPrimitiveTable[epsilonOrder,row,column] := pairAdd(
        getOriginalPrimitive(epsilonOrder,row,column),primitiveCoefficient):
    end if:
  end do:
  for term in entryRecord[4] do
    if has(term[2],eps) then
      error "an accepted incoming letter depends on epsilon",target,term[2][1];
    end if:
    coefficientWindow := laurentWindow(term[1]):
    for coefficientRecord in coefficientWindow do
      addResidue(coefficientRecord[1],term[2],row,column,
        coefficientRecord[2]):
    end do:
  end do:
  incomingRecordsUsed := incomingRecordsUsed+1:
end do:
incomingCompileSeconds := time()-started:
if incomingRecordsUsed<>2*sourceDimension then
  error "the complete transfer does not contain exactly 2x43 incoming records";
end if:

# The diagonal input is an epsilon-independent one-form matrix.  Refuse a
# malformed record before it enters the finite recursion.
for formRecord in [op(sourceFormRecords),op(targetFormRecords)] do
  if has(formRecord[3],eps) then
    error "a path diagonal one-form depends on epsilon",
      [formRecord[1],formRecord[2]];
  end if:
end do:

HPrevious := newPairArray(targetDimension,sourceDimension):
HByOrder := []:
crossReductionRecords := []:
crossFailures := []:
baseFailures := []:
orderTimings := []:

for epsilonOrder from windowLow to windowHigh do
  startedOrder := time():
  crossMatrix := newPairArray(targetDimension,sourceDimension):

  # D.HPrevious, using only nonzero target-diagonal records.
  for formRecord in targetFormRecords do
    row := formRecord[1]:
    middle := formRecord[2]:
    formPair := formRecord[3]:
    if row<1 or row>targetDimension or middle<1 or
        middle>targetDimension then
      error "target diagonal record index out of range",
        [formRecord[1],formRecord[2]];
    end if:
    for column from 1 to sourceDimension do
      if not pairZero(HPrevious[middle,column]) then
        crossMatrix[row,column] := accumulateFunctionForm(
          crossMatrix[row,column],HPrevious[middle,column],formPair,1):
      end if:
    end do:
  end do:

  # -HPrevious.S, using only nonzero source-diagonal records.
  for formRecord in sourceFormRecords do
    middle := formRecord[1]:
    column := formRecord[2]:
    formPair := formRecord[3]:
    if middle<1 or middle>sourceDimension or column<1 or
        column>sourceDimension then
      error "source diagonal record index out of range",
        [formRecord[1],formRecord[2]];
    end if:
    for row from 1 to targetDimension do
      if not pairZero(HPrevious[row,middle]) then
        crossMatrix[row,column] := accumulateFunctionForm(
          crossMatrix[row,column],HPrevious[row,middle],formPair,-1):
      end if:
    end do:
  end do:

  HCurrent := newPairArray(targetDimension,sourceDimension):
  crossNonzero := 0:
  crossPrimitiveNonzero := 0:
  crossLetterTerms := 0:
  for row from 1 to targetDimension do
    for column from 1 to sourceDimension do
      crossPrimitive := [0,0]:
      crossTerms := []:
      crossVerified := true:
      crossFailureReason := NULL:
      crossForm := pairNormal(crossMatrix[row,column]):
      if not pairZero(crossForm) then
        crossNonzero := crossNonzero+1:
        try
          crossReduction := reduceForm(crossForm):
          crossPrimitive := crossReduction[1]:
          crossTerms := crossReduction[2]:
          crossVerified := crossReduction[3]:
        catch:
          crossVerified := false:
          crossFailureReason := sprintf("%a",lastexception):
        end try:
        if not crossVerified then
          if crossFailureReason=NULL then
            crossFailureReason := "cross Hermite residual was not exact":
          end if:
          crossFailures := [op(crossFailures),[
            epsilonOrder,transferRows[row],sourceRows[column],
            crossFailureReason]]:
        end if:
      end if:
      if not pairZero(crossPrimitive) then
        crossPrimitiveNonzero := crossPrimitiveNonzero+1:
      end if:
      crossLetterTerms := crossLetterTerms+nops(crossTerms):
      for term in crossTerms do
        addResidue(epsilonOrder,term[2],row,column,term[1]):
      end do:

      totalPrimitive := pairAdd(
        getOriginalPrimitive(epsilonOrder,row,column),crossPrimitive):
      HCurrent[row,column] := normalizeAtBase(totalPrimitive):
      if normal(baseValue(HCurrent[row,column]))<>0 then
        baseFailures := [op(baseFailures),[
          epsilonOrder,transferRows[row],sourceRows[column]]]:
      end if:
    end do:
  end do:

  sparseHRecords := []:
  for row from 1 to targetDimension do
    for column from 1 to sourceDimension do
      if not pairZero(HCurrent[row,column]) then
        sparseHRecords := [op(sparseHRecords),[
          transferRows[row],sourceRows[column],HCurrent[row,column]]]:
      end if:
    end do:
  end do:
  HByOrder := [op(HByOrder),[epsilonOrder,sparseHRecords]]:
  crossReductionRecords := [op(crossReductionRecords),[
    epsilonOrder,crossNonzero,crossPrimitiveNonzero,crossLetterTerms]]:
  orderTimings := [op(orderTimings),[
    epsilonOrder,round(1000*(time()-startedOrder))]]:
  HPrevious := HCurrent:
end do:

# Compress residue coordinates without losing the authoritative original row
# labels.  A record is {epsilonOrder,letterID,{{targetRow,sourceRow,c},...}}.
transformedResidueRecords := []:
for epsilonOrder from windowLow to windowHigh do
  for letterIndex from 1 to nops(transformedLabels) do
    coordinateRecords := []:
    for row from 1 to targetDimension do
      for column from 1 to sourceDimension do
        if assigned(residueTable[epsilonOrder,letterIndex,row,column]) then
          coefficient := normal(
            residueTable[epsilonOrder,letterIndex,row,column]):
          if coefficient<>0 then
            coordinateRecords := [op(coordinateRecords),[
              transferRows[row],sourceRows[column],coefficient]]:
          end if:
        end if:
      end do:
    end do:
    if nops(coordinateRecords)>0 then
      transformedResidueRecords := [op(transformedResidueRecords),[
        epsilonOrder,letterIndex,coordinateRecords]]:
    end if:
  end do:
end do:

letterRecords := [seq([transformedLabels[letterIndex],
  transformedForms[letterIndex]],
  letterIndex=1..nops(transformedLabels))]:
accepted := evalb(nops(crossFailures)=0 and nops(baseFailures)=0):
finalStatus := if accepted then
  "CF303Block25FinitePathGaugeAcceptedV1"
else
  "CF303Block25FinitePathGaugeFailedV1"
end if:
timings := [
  ["TransferReadMilliseconds",round(1000*transferSeconds)],
  ["PathInputReadMilliseconds",round(1000*pathInputSeconds)],
  ["AcceptedIncomingCompileMilliseconds",
    round(1000*incomingCompileSeconds)],
  ["PerOrderMilliseconds",orderTimings],
  ["TotalBeforeSerializationMilliseconds",
    round(1000*(time()-startedTotal))]
]:

started := time():
fd := fopen(outputMaple,WRITE,TEXT):
fprintf(fd,"status := %a:\n",finalStatus):
fprintf(fd,"family := \"CF303\":\n"):
fprintf(fd,"block := 25:\n"):
fprintf(fd,"curve := %a:\n",curve):
fprintf(fd,"variable := %a:\n",u):
fprintf(fd,"basePoint := %a:\n",basePoint):
fprintf(fd,"window := %a:\n",[windowLow,windowHigh]):
fprintf(fd,"sourceRows := %a:\n",sourceRows):
fprintf(fd,"targetRows := %a:\n",transferRows):
fprintf(fd,"HByOrder := %a:\n",HByOrder):
fprintf(fd,"letterRecords := %a:\n",letterRecords):
fprintf(fd,"transformedResidueRecords := %a:\n",
  transformedResidueRecords):
fprintf(fd,"crossReductionRecords := %a:\n",crossReductionRecords):
fprintf(fd,"crossFailures := %a:\n",crossFailures):
fprintf(fd,"baseFailures := %a:\n",baseFailures):
fprintf(fd,"timings := %a:\n",timings):
fprintf(fd,"formula := %a:\n",
  "F25=G25+H.L; Bprime_n=B_n+D.H_(n-1)-H_(n-1).S-dH_n; H_n(basePoint)=0"):
fprintf(fd,"acceptance := %a:\n",
  "Each original B reduction is reused from the complete accepted transfer; only each cross form is Hermite-reduced, using reduceForm's existing exact residual, and every H_n is base-normalized"):
fclose(fd):

read serializerFile:
wolframText := cat(
  "<|\n",
  "  \"Status\" -> ",wlExpr(finalStatus),",\n",
  "  \"Family\" -> \"CF303\",\n",
  "  \"Block\" -> 25,\n",
  "  \"Curve\" -> ",wlExpr(curve),",\n",
  "  \"Variable\" -> ",wlExpr(u),",\n",
  "  \"BasePoint\" -> ",wlExpr(basePoint),",\n",
  "  \"Window\" -> ",wlExpr([windowLow,windowHigh]),",\n",
  "  \"SourceRows\" -> ",wlExpr(sourceRows),",\n",
  "  \"TargetRows\" -> ",wlExpr(transferRows),",\n",
  "  \"HByOrder\" -> ",wlExpr(HByOrder),",\n",
  "  \"LetterRecords\" -> ",wlExpr(letterRecords),",\n",
  "  \"TransformedResidueRecords\" -> ",
    wlExpr(transformedResidueRecords),",\n",
  "  \"CrossReductionRecords\" -> ",
    wlExpr(crossReductionRecords),",\n",
  "  \"CrossFailures\" -> ",wlExpr(crossFailures),",\n",
  "  \"BaseFailures\" -> ",wlExpr(baseFailures),",\n",
  "  \"Timings\" -> ",wlExpr(timings),",\n",
  "  \"Formula\" -> \"F25=G25+H.L; Bprime_n=B_n+D.H_(n-1)-H_(n-1).S-dH_n; H_n(basePoint)=0\",\n",
  "  \"Acceptance\" -> \"Each original B reduction is reused from the complete accepted transfer; only each cross form is Hermite-reduced, using reduceForm's existing exact residual, and every H_n is base-normalized\"\n",
  "|>\n"):
fd := fopen(outputWolfram,WRITE,TEXT):
fprintf(fd,"%s",wolframText):
fclose(fd):
serializationSeconds := time()-started:

printf("CF303 BLOCK25 FINITE PATH GAUGE status=%s Horders=%d letters=%d residues=%d cross_failures=%d base_failures=%d compile=%.3f total=%.3f serialize=%.3f\n",
  finalStatus,nops(HByOrder),nops(letterRecords),
  nops(transformedResidueRecords),nops(crossFailures),
  nops(baseFailures),incomingCompileSeconds,time()-startedTotal,
  serializationSeconds):
printf("OUTPUT_MAPLE %s\nOUTPUT_WOLFRAM %s\n",outputMaple,outputWolfram):
quit:
