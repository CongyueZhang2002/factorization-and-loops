interface(prettyprint=0):
kernelopts(numcpus=1):

# Scratch-only pilot for the exact Hermite-primitive branch of the CF303
# block-25 transport.  It consumes the accepted direct-u census for the two
# missing block-2 one-forms.  All algebraic-curve reduction and IBP comes from
# algebraic_curve_word_transport.mpl; none of that mathematics is duplicated
# here.

inputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block25_exception_2_elliptic_layer_census.maple":
libraryFile := "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/algebraic_curve_word_transport.mpl":
serializerFile := "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/maple_wolfram_serializer.mpl":
outputMaple := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block25_exception_2_primitive_ibp_pilot.maple":
outputWolfram := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block25_exception_2_primitive_ibp_pilot.wl":

windowLow := -2:
windowHigh := 4:
startedTotal := time():

started := time():
read inputFile:
inputSeconds := time()-started:
if status<>"CF303EllipticLayerCensusAcceptedV1" or block<>2
    or nops(targets)<>2 or nops(reducedKernelDeck)<>2 then
  error "accepted CF303 block-2 exception census was not supplied";
end if:

read libraryFile:
ConfigureAlgebraicWordTransport(P4,u,1/2,Y0):

# Return only the nonzero coefficients in the requested finite Laurent
# window.  Rational epsilon tails remain tails outside this window; the pilot
# deliberately makes no finite-support claim about them.
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

# One census reduction
#   [primitivePair, [[coefficient,[label,formPair]],...], verified]
# becomes a compact exact Laurent deck.  The full formPair is kept internally
# for the IBP demonstration; the serialized window deck needs only the label
# because the standard alphabet fixes its one-form.
compileWindowReduction := proc(target,reduction)
  local primitiveWindows,remainderWindows,term;
  primitiveWindows := [laurentWindow(reduction[1][1]),
    laurentWindow(reduction[1][2])]:
  remainderWindows := []:
  for term in reduction[2] do
    remainderWindows := [op(remainderWindows),
      [term[2],laurentWindow(term[1])]]:
  end do:
  return [target,primitiveWindows,remainderWindows]:
end proc:

reductionAtOrder := proc(compiled,epsilonOrder)
  local primitive,remainder,record,coefficient;
  primitive := [windowCoefficient(compiled[2][1],epsilonOrder),
    windowCoefficient(compiled[2][2],epsilonOrder)]:
  remainder := []:
  for record in compiled[3] do
    coefficient := windowCoefficient(record[2],epsilonOrder):
    if coefficient<>0 then
      remainder := [op(remainder),[coefficient,record[1]]]:
    end if:
  end do:
  return [primitive,remainder,true]:
end proc:

formFromReduction := proc(reduction)
  local result,term;
  result := functionDerivative(reduction[1]):
  for term in reduction[2] do
    result := pairAdd(result,pairScale(term[1],term[2][2])):
  end do:
  return result:
end proc:

remainderForm := proc(reduction)
  local result,term;
  result := [0,0]:
  for term in reduction[2] do
    result := pairAdd(result,pairScale(term[1],term[2][2])):
  end do:
  return result:
end proc:

# The connection-level triangular cleanup uses the unique representative that
# vanishes at the transport base.  Subtracting this scalar changes neither
# component of dH, but it makes U(u0)=Identity and hence preserves the existing
# canonical boundary constants.
normalizePrimitiveAtBase := proc(primitive)
  local value;
  value := baseValue(primitive):
  return pairAdd(primitive,[-value,0]):
end proc:

supportOrders := proc(records)
  local record;
  return [seq(record[1],record in records)]:
end proc:

started := time():
compiledWindowDeck := [seq(compileWindowReduction(targets[i],
  reducedKernelDeck[i]),i=1..nops(targets))]:
windowSeconds := time()-started:

# Compact summaries prove that every primitive and remainder coefficient was
# expanded without serializing the large input forms a second time.
entrySummaries := []:
for i from 1 to nops(compiledWindowDeck) do
  compiled := compiledWindowDeck[i]:
  remainderCounts := [seq([epsilonOrder,
    add(`if`(windowCoefficient(record[2],epsilonOrder)<>0,1,0),
      record in compiled[3])],
    epsilonOrder=windowLow..windowHigh)]:
  entrySummaries := [op(entrySummaries),[
    compiled[1],
    [supportOrders(compiled[2][1]),supportOrders(compiled[2][2])],
    nops(compiled[3]),remainderCounts]]:
end do:

# Select one genuine finite-window slice having both a nonzero primitive and
# a nonzero standard remainder.  This exercises the exact part and the Chen
# append part together.
chosenEntry := 0:
chosenOrder := NULL:
chosenReduction := NULL:
for i from 1 to nops(compiledWindowDeck) while chosenEntry=0 do
  for epsilonOrder from windowLow to windowHigh while chosenEntry=0 do
    candidateReduction := reductionAtOrder(compiledWindowDeck[i],epsilonOrder):
    if not pairZero(candidateReduction[1]) and
        nops(candidateReduction[2])>0 then
      chosenEntry := i:
      chosenOrder := epsilonOrder:
      chosenReduction := candidateReduction:
    end if:
  end do:
end do:
if chosenEntry=0 then
  error "no finite-window slice contains both a primitive and a remainder";
end if:

# Prefer a rational GPL head, then an elliptic head.  Block 2 presently has
# rational heads, but the selection remains valid if a later accepted census
# exposes an elliptic one.
chosenHead := NULL:
for term in chosenReduction[2] while chosenHead=NULL do
  labelFamily := term[2][1][1]:
  if type(labelFamily,string) and StringTools:-Search("GPL",labelFamily)=1 then
    chosenHead := term[2]:
  end if:
end do:
if chosenHead=NULL then
  for term in chosenReduction[2] while chosenHead=NULL do
    labelFamily := term[2][1][1]:
    if type(labelFamily,string) and StringTools:-Search("E4",labelFamily)=1 then
      chosenHead := term[2]:
    end if:
  end do:
end if:
if chosenHead=NULL then chosenHead := chosenReduction[2][1][2] end if:

inputForm := formFromReduction(chosenReduction):

started := time():
emptySolution := integrateReducedFormWord(chosenReduction,[]):
emptySeconds := time()-started:
started := time():
emptyVerification := verifyIntegratedWord(inputForm,[],emptySolution):
emptyVerifySeconds := time()-started:

started := time():
headSolution := integrateReducedFormWord(chosenReduction,[chosenHead]):
headSeconds := time()-started:
started := time():
headVerification := verifyIntegratedWord(inputForm,[chosenHead],headSolution):
headVerifySeconds := time()-started:

# Connection-level pilot at the leading incoming order.  Here H[-3]=0, so
# R[-2]=B[-2] and the transformed connection is simply
#
#   Bprime[-2] = B[-2] - d H[-2] = standard curve-letter remainder.
#
# Later orders add D.H[n-1]-H[n-1].S before the same reduction; no such cross
# term is present in this deliberately minimal block-2 demonstration.
started := time():
gaugeStepOrder := windowLow:
gaugeStepRecords := []:
gaugeStepAccepted := true:
for i from 1 to nops(compiledWindowDeck) do
  gaugeReduction := reductionAtOrder(compiledWindowDeck[i],gaugeStepOrder):
  gaugePrimitive := normalizePrimitiveAtBase(gaugeReduction[1]):
  gaugeInput := formFromReduction(gaugeReduction):
  gaugeRemainder := remainderForm(gaugeReduction):
  gaugeTransformed := pairAdd(gaugeInput,
    pairScale(-1,functionDerivative(gaugePrimitive))):
  gaugeResidual := pairAdd(gaugeTransformed,pairScale(-1,gaugeRemainder)):
  gaugeBaseZero := evalb(normal(baseValue(gaugePrimitive))=0):
  gaugeResidualZero := pairZero(gaugeResidual):
  gaugeStepAccepted := evalb(gaugeStepAccepted and gaugeBaseZero
    and gaugeResidualZero):
  gaugeStepRecords := [op(gaugeStepRecords),[
    targets[i],gaugeStepOrder,gaugePrimitive,
    [seq([term[1],term[2][1]],term in gaugeReduction[2])],
    gaugeBaseZero,gaugeResidualZero]]:
end do:
gaugeStepSeconds := time()-started:

chosenRemainder := [seq([term[1],term[2][1]],
  term in chosenReduction[2])]:
transitionDeck := [
  ["EmptyWord",targets[chosenEntry],chosenOrder,
    chosenReduction[1],chosenRemainder,[],
    labelledSolution(emptySolution),emptyVerification[1]],
  ["OneHead",targets[chosenEntry],chosenOrder,
    chosenReduction[1],chosenRemainder,[chosenHead[1]],
    labelledSolution(headSolution),headVerification[1]]
]:
headScope := "Algebra-valid remainder head; this pilot does not assert source-operator reachability":

accepted := evalb(emptyVerification[1] and headVerification[1]
  and gaugeStepAccepted):
pilotStatus := if accepted then
  "CF303Block25Exception2PrimitiveIBPPilotAcceptedV1"
else
  "CF303Block25Exception2PrimitiveIBPPilotFailedV1"
end if:
timings := [
  ["InputMilliseconds",round(1000*inputSeconds)],
  ["LaurentWindowMilliseconds",round(1000*windowSeconds)],
  ["EmptyIntegrateMilliseconds",round(1000*emptySeconds)],
  ["EmptyVerifyMilliseconds",round(1000*emptyVerifySeconds)],
  ["OneHeadIntegrateMilliseconds",round(1000*headSeconds)],
  ["OneHeadVerifyMilliseconds",round(1000*headVerifySeconds)],
  ["LeadingGaugeStepMilliseconds",round(1000*gaugeStepSeconds)],
  ["TotalBeforeSerializationMilliseconds",
    round(1000*(time()-startedTotal))]
]:

started := time():
fd := fopen(outputMaple,WRITE,TEXT):
fprintf(fd,"status := %a:\n",pilotStatus):
fprintf(fd,"sourceStatus := %a:\n",status):
fprintf(fd,"block := 2:\n"):
fprintf(fd,"window := %a:\n",[windowLow,windowHigh]):
fprintf(fd,"curve := %a:\n",P4):
fprintf(fd,"basePoint := 1/2:\n"):
fprintf(fd,"entrySummaries := %a:\n",entrySummaries):
fprintf(fd,"transitionDeck := %a:\n",transitionDeck):
fprintf(fd,"headScope := %a:\n",headScope):
fprintf(fd,"leadingGaugeStep := %a:\n",gaugeStepRecords):
fprintf(fd,"leadingGaugeFormula := %a:\n",
  "F25=G25+H.L; Bprime[-2]=B[-2]-dH[-2] because H[-3]=0; every H[-2](u0)=0"):
fprintf(fd,"timings := %a:\n",timings):
fprintf(fd,"statement := %a:\n",
  "Every primitive and remainder coefficient was Laurent-expanded on -2..4; the deck stores one exact empty-word and one exact nontrivial-head IBP transition, each differentiated back with the shared curve library"):
fclose(fd):

read serializerFile:
wolframText := cat(
  "<|\n",
  "  \"Status\" -> ",wlExpr(pilotStatus),",\n",
  "  \"SourceStatus\" -> ",wlExpr(status),",\n",
  "  \"Block\" -> 2,\n",
  "  \"Window\" -> ",wlExpr([windowLow,windowHigh]),",\n",
  "  \"Curve\" -> ",wlExpr(P4),",\n",
  "  \"BasePoint\" -> 1/2,\n",
  "  \"EntrySummaries\" -> ",wlExpr(entrySummaries),",\n",
  "  \"TransitionDeck\" -> ",wlExpr(transitionDeck),",\n",
  "  \"HeadScope\" -> ",wlExpr(headScope),",\n",
  "  \"LeadingGaugeStep\" -> ",wlExpr(gaugeStepRecords),",\n",
  "  \"LeadingGaugeFormula\" -> \"F25=G25+H.L; Bprime[-2]=B[-2]-dH[-2] because H[-3]=0; every H[-2](u0)=0\",\n",
  "  \"Timings\" -> ",wlExpr(timings),",\n",
  "  \"Statement\" -> \"Every primitive and remainder coefficient was Laurent-expanded on -2..4; the deck stores one exact empty-word and one exact nontrivial-head IBP transition, each differentiated back with the shared curve library\"\n",
  "|>\n"):
fd := fopen(outputWolfram,WRITE,TEXT):
fprintf(fd,"%s",wolframText):
fclose(fd):
serializationSeconds := time()-started:

printf("CF303 EXCEPTION2 PRIMITIVE IBP status=%s window=%a target=%a order=%d head=%a empty_terms=%d head_terms=%d gauge_records=%d exact=%a expand=%.3f empty=%.3f head=%.3f gauge=%.3f serialize=%.3f\n",
  pilotStatus,[windowLow,windowHigh],targets[chosenEntry],chosenOrder,
  chosenHead[1],nops(emptySolution),nops(headSolution),
  nops(gaugeStepRecords),accepted,
  windowSeconds,emptySeconds,headSeconds,gaugeStepSeconds,
  serializationSeconds):
printf("OUTPUT_MAPLE %s\nOUTPUT_WOLFRAM %s\n",outputMaple,outputWolfram):
quit:
