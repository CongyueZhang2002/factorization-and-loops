#!/usr/bin/env python3
"""Strict FORM-to-Wolfram reference translation, isolated from production."""
from pathlib import Path
import argparse,json,re

SCALARS={"NC","NF","x","z","LMUR","LMUF","LMUA","pi","zeta3",
         "poly2","sqrtxz1","sqrtxz2","sqrtxz3","rln2",
         "r1","r2","t1","t2","u1","u2","u3","u4"}
FUNCTIONS={"ln":"Log","Li2":"PolyLog[2,#]","Li3":"PolyLog[3,#]",
           "ArcTan":"ArcTan","InvTanInt":"InverseTangentIntegral",
           "Dd":"Dd","Dn":"Dn","T":"ReferenceRegion"}

def translate(body):
    if re.search(r"[^A-Za-z0-9_+*/^(),\[\].\s-]",body):
        raise ValueError("Unsupported FORM characters")
    words=set(re.findall(r"[A-Za-z_]\w*",body))
    if words-SCALARS-FUNCTIONS.keys():
        raise ValueError(f"Unsupported FORM identifiers: {words-SCALARS-FUNCTIONS.keys()}")
    tokens=re.findall(r"[A-Za-z_]\w*|\d+(?:\.\d*)?|[^\s]",body)
    out=[];stack=[];i=0
    while i<len(tokens):
        token=tokens[i]
        if token in FUNCTIONS:
            if i+1>=len(tokens) or tokens[i+1]!="(":
                raise ValueError("Expected function arguments")
            target=FUNCTIONS[token]
            out.append({"Li2":"PolyLog[2,","Li3":"PolyLog[3,"}.get(token,target+"["))
            stack.append("]");i+=2;continue
        if token in ("(","["):out.append("(");stack.append(")")
        elif token in (")","]"):
            if not stack:raise ValueError("Unbalanced FORM expression")
            out.append(stack.pop())
        else:out.append({"pi":"Pi","zeta3":"Zeta[3]"}.get(token,token))
        i+=1
    if stack:raise ValueError("Unbalanced FORM expression")
    return "".join(out)

def read_reference(path,order=1):
    text=Path(path).read_text()
    result={}
    for name,body in re.findall(r"\bid\s+((?:D?C)"+str(order)+r"\w+)\s*=\s*(.*?);",text,re.S):
        result[name]=translate(body)
    if not result:raise ValueError(f"No order-{order} reference coefficients found")
    return "<|"+",\n".join(json.dumps(k)+"->"+v for k,v in result.items())+"|>\n"

def read_nlo(path):return read_reference(path,1)

if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("input");parser.add_argument("output")
    parser.add_argument("--order",type=int,choices=(1,2),default=1);args=parser.parse_args()
    target=Path(args.output);target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(read_reference(args.input,args.order))
