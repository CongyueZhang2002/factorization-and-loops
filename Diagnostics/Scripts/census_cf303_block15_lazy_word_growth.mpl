interface(prettyprint=0):
kernelopts(numcpus=6):
inputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_lazy_chen_operator.maple":
outputFile := "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_lazy_word_growth.maple":
read inputFile:

# Count reachable words without enumerating them.  Each 3x3 Boolean support
# relation is one of only 2^9 states; dynamic programming over those states
# gives a rigorous structural upper bound even when the word alphabet is
# large.
relationKey := proc(relation)
  local ordered;
  ordered := sort([op(relation)]):
  return convert(ordered,string):
end proc:

composeRelations := proc(left,right)
  local result,leftPair,rightPair;
  result := {}:
  for leftPair in left do
    for rightPair in right do
      if leftPair[2]=rightPair[1] then
        result := result union {[leftPair[1],rightPair[2]]}:
      end if:
    end do:
  end do:
  return result:
end proc:

letterRelations := []:
for letterIndex from 1 to nops(letters) do
  rel := {}:
  for record in diagonalResidueRecords do
    if record[1]=letterIndex then
      rel := rel union
        {[record[2],record[3]-diagonalColumnPositions[1]+1]}:
    end if:
  end do:
  letterRelations := [op(letterRelations),rel]:
end do:

identityRelation := {[1,1],[2,2],[3,3]}:
states := table():
states[relationKey(identityRelation)] := [identityRelation,1]:
weightRecords := []:
for weight from 0 to 5 do
  totalWords := add(states[key][2],key in [indices(states,'nolist')]):
  pairCounts := [seq(seq([row,column,add(
    `if`(member([row,column],states[key][1]),states[key][2],0),
    key in [indices(states,'nolist')])],column=1..3),row=1..3)]:
  weightRecords := [op(weightRecords),[weight,totalWords,
    nops([indices(states,'nolist')]),pairCounts]]:
  if weight=5 then break end if:
  nextStates := table():
  for key in [indices(states,'nolist')] do
    for letterIndex from 1 to nops(letterRelations) do
      nextRelation := composeRelations(letterRelations[letterIndex],
        states[key][1]):
      if nops(nextRelation)=0 then next end if:
      nextKey := relationKey(nextRelation):
      if assigned(nextStates[nextKey]) then
        nextStates[nextKey][2] := nextStates[nextKey][2]+states[key][2]:
      else
        nextStates[nextKey] := [nextRelation,states[key][2]]:
      end if:
    end do:
  end do:
  states := copy(nextStates):
end do:

fd := fopen(outputFile,WRITE,TEXT):
fprintf(fd,"status := %a:\n","CF303Block15LazyWordGrowthAcceptedV1"):
fprintf(fd,"letterCount := %a:\n",nops(letters)):
fprintf(fd,"letterRelations := %a:\n",letterRelations):
fprintf(fd,"weightRecords := %a:\n",weightRecords):
fprintf(fd,"interpretation := %a:\n",
  "Structural nonzero-word upper bounds for the 3x3 homogeneous block; algebraic cancellation can only lower them"):
fclose(fd):
for record in weightRecords do
  printf("WEIGHT %d words=%d relation_states=%d\n",
    record[1],record[2],record[3]):
end do:
printf("DONE output=%s\n",outputFile):
quit:
