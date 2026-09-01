# Exact Maple-expression to Wolfram-Language serializer for the algebraic
# transport artifacts.  It walks the expression tree; it never rewrites
# printed syntax, so nested powers and inert marked-sheet functions survive.
with(StringTools):

wlExpr := proc(value)
  local childValues,headString,numeratorValue,denominatorValue;
  if type(value,string) then
    return cat("\"",SubstituteAll(value,"\"","\\\""),"\""):
  elif type(value,integer) then
    return sprintf("%a",value):
  elif type(value,rational) then
    numeratorValue := numer(value):
    denominatorValue := denom(value):
    return cat("(",wlExpr(numeratorValue),")/(",
      wlExpr(denominatorValue),")"):
  elif type(value,list) then
    return cat("{",Join(map(wlExpr,value),", "),"}"):
  elif type(value,`+`) then
    childValues := [op(value)]:
    return cat("(",Join(map(wlExpr,childValues)," + "),")"):
  elif type(value,`*`) then
    childValues := [op(value)]:
    return cat("(",Join(map(wlExpr,childValues)," * "),")"):
  elif type(value,`^`) then
    return cat("(",wlExpr(op(1,value)),")^(",
      wlExpr(op(2,value)),")"):
  elif type(value,function) then
    headString := convert(op(0,value),string):
    childValues := [op(value)]:
    return cat(headString,"[",Join(map(wlExpr,childValues),", "),"]"):
  elif type(value,name) then
    if value=true then return "True"
    elif value=false then return "False"
    else return convert(value,string)
    end if:
  end if:
  error "unsupported Maple expression type in Wolfram exporter",value:
end proc:
