#!/usr/bin/env python3
"""Call-graph reachability over FeynFacet/Private.
Roots: public symbols (FeynFacet.m ::usage) defined in Private; Private symbols
referenced from Scripts/ (code tokens); string-constructed names.  Reports per
symbol whether it is reachable from public API, from scripts, referenced by
tests, or dead."""
import re, os, json, collections, sys
ROOT="/home/maxzhang/factorization-and-loops"; PRIV=os.path.join(ROOT,"FeynFacet","Private")
IDENT=re.compile(r'\$?[A-Za-z][A-Za-z0-9$]*')
STR=re.compile(r'"(?:[^"\\]|\\.)*"')
def strip_comments(s):
    """one pass: remove (* nested *) comments and replace string literals by "" (strings may contain comment markers)"""
    out=[];i=0;d=0;n=len(s)
    while i<n:
        if d:
            if s.startswith("(*",i): d+=1;i+=2;continue
            if s.startswith("*)",i): d-=1;i+=2;continue
            i+=1;continue
        if s.startswith("(*",i): d+=1;i+=2;continue
        if s[i]=='"':
            j=i+1
            while j<n and s[j]!='"':
                if s[j]=="\\": j+=1
                j+=1
            out.append('""'); i=j+1;continue
        out.append(s[i]);i+=1
    return "".join(out)

def strip_comments_only(s):
    out=[];i=0;d=0;n=len(s)
    while i<n:
        if d:
            if s.startswith("(*",i): d+=1;i+=2;continue
            if s.startswith("*)",i): d-=1;i+=2;continue
            i+=1;continue
        if s.startswith("(*",i): d+=1;i+=2;continue
        if s[i]=='"':
            j=i+1
            while j<n and s[j]!='"':
                if s[j]=="\\": j+=1
                j+=1
            out.append(s[i:j+1]); i=j+1;continue
        out.append(s[i]);i+=1
    return "".join(out)

def statements(code):
    """split into top-level statements on ';' at depth 0 or a newline followed by an identifier at column 0 (after a blank line)."""
    st=[];buf=[];depth=0;i=0;n=len(code)
    while i<n:
        c=code[i]
        if c in "[({": depth+=1
        elif c in "])}": depth=max(0,depth-1)
        buf.append(c)
        if c==";" and depth==0:
            st.append("".join(buf));buf=[]
        elif c=="\n" and depth==0:
            # lookahead: blank line then identifier at col 0 -> new statement
            j=i+1
            if j<n and code[j]=="\n":
                k=j+1
                while k<n and code[k]=="\n": k+=1
                if k<n and (code[k].isalpha() or code[k]=="$"):
                    st.append("".join(buf));buf=[]
        i+=1
    if buf: st.append("".join(buf))
    return [s for s in st if s.strip()]
files=sorted(f for f in os.listdir(PRIV) if f.endswith(".wl"))
defs=collections.defaultdict(set); body_refs=collections.defaultdict(set); defline={}
code_by_file={}
for f in files:
    src=open(os.path.join(PRIV,f),encoding="utf-8",errors="replace").read()
    code=STR.sub('""',strip_comments(src)); code_by_file[f]=code
    pos=0
    for s in statements(code):
        m=re.match(r'\s*(\$?[A-Za-z][A-Za-z0-9$]*)\s*(\[|:=|=(?!=)|/:|\^:=|\^=)',s)
        line=code[:code.find(s,pos)].count("\n")+1 if code.find(s,pos)>=0 else 0
        pos=max(pos,code.find(s,pos))
        if not m: continue
        head=m.group(1)
        if head in ("If","Do","Module","Block","With","Scan","Map","Table","While","For","Which","Switch","SetAttributes","Protect","Unprotect","Needs","Get","Quiet","Check","Catch","Throw","Attributes","SyntaxInformation","Format","MakeBoxes","Print","Clear","ClearAll","Off","On","Begin","End","BeginPackage","EndPackage","Options"):
            if head=="Options":
                mo=re.match(r'\s*Options\[\s*(\$?[A-Za-z][A-Za-z0-9$]*)\s*\]\s*=',s)
                if mo: defs[mo.group(1)].add(f); body_refs[mo.group(1)].update(IDENT.findall(s)); 
            if head in ("Clear","ClearAll"):
                for nm in IDENT.findall(s):
                    if nm not in ("Clear","ClearAll"): defs[nm].add(f)
            continue
        # only treat as definition if an assignment operator appears at depth 0 in the statement
        if not re.search(r'(:=|(?<![=!<>])=(?!=)|/:|\^:=)',s): continue
        defs[head].add(f); defline.setdefault(head,(f,line))
        body_refs[head].update(IDENT.findall(s))
symbols=set(defs)
graph={h:{r for r in refs if r in symbols and r!=h} for h,refs in body_refs.items()}
# public roots
usage=set(re.findall(r'^([A-Za-z][A-Za-z0-9]*)::usage',open(os.path.join(ROOT,"FeynFacet","FeynFacet.m")).read(),re.M))
public_roots={u for u in usage if u in symbols}
# also symbols defined in FeynFacet.m itself that reference private symbols
mtext=STR.sub('""',strip_comments(open(os.path.join(ROOT,"FeynFacet","FeynFacet.m")).read()))
m_refs={t for t in IDENT.findall(mtext) if t in symbols}
# script roots and test refs and string hits
script_roots=set(); test_refs=set(); string_hits=collections.defaultdict(set)
for d in ("Scripts","Tests","Addon/Load"):
    for dp,_,fs in os.walk(os.path.join(ROOT,d)):
        for fn in fs:
            if not fn.endswith((".wl",".wls",".m",".sh",".py")): continue
            p=os.path.relpath(os.path.join(dp,fn),ROOT)
            t=open(os.path.join(dp,fn),encoding="utf-8",errors="replace").read()
            nc=strip_comments_only(t) if fn.endswith((".wl",".wls",".m")) else t
            toks=set(IDENT.findall(STR.sub('""',nc)))
            stoks=set(IDENT.findall(" ".join(STR.findall(nc))))
            hit=(toks|stoks)&symbols
            if d=="Tests": test_refs|=hit
            else: script_roots|=hit
            for h in stoks&symbols: string_hits[h].add(p)
# string-constructed within Private/FeynFacet.m
priv_string_hits=collections.defaultdict(set)
for f in files:
    src=strip_comments_only(open(os.path.join(PRIV,f),encoding="utf-8",errors="replace").read())
    for h in set(IDENT.findall(" ".join(STR.findall(src))))&symbols: priv_string_hits[h].add(f)
for h in set(IDENT.findall(" ".join(STR.findall(strip_comments_only(open(os.path.join(ROOT,"FeynFacet","FeynFacet.m")).read())))))&symbols: priv_string_hits[h].add("FeynFacet.m")
def reach(roots):
    seen=set(roots); stack=list(roots)
    while stack:
        x=stack.pop()
        for y in graph.get(x,()):
            if y not in seen: seen.add(y); stack.append(y)
    return seen
R_public=reach(public_roots|m_refs)
R_scripts=reach(script_roots)
R_strings=reach(set(priv_string_hits)|set(string_hits))
R_tests=reach(test_refs)
live=R_public|R_scripts|R_strings
rows=[]
for s in sorted(symbols):
    rows.append({"symbol":s,"files":sorted(defs[s]),"line":defline.get(s,(None,None))[1],
      "public":s in public_roots,"reachPublic":s in R_public,"reachScripts":s in R_scripts,"reachStrings":s in R_strings,
      "reachTests":s in R_tests,"testRef":s in test_refs,"stringHits":sorted(set(string_hits.get(s,()))|set(priv_string_hits.get(s,()))),
      "status":("live" if s in live else ("test-only" if s in R_tests else "dead"))})
json.dump(rows,open(os.path.join(os.path.dirname(os.path.abspath(__file__)),"reachability.json"),"w"),indent=1)
per=collections.defaultdict(collections.Counter)
for r in rows:
    for f in r["files"]: per[f][r["status"]]+=1
print(f"{'file':38s} {'live':>5s} {'test-only':>9s} {'dead':>5s}")
for f in files: print(f"{f:38s} {per[f]['live']:5d} {per[f]['test-only']:9d} {per[f]['dead']:5d}")
tot=collections.Counter(r["status"] for r in rows); print("TOTAL",dict(tot))
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)),"dead_and_testonly.txt"),"w") as fo:
    for st in ("dead","test-only"):
        fo.write(f"### {st}\n")
        for r in rows:
            if r["status"]==st: fo.write(f"{r['files'][0]:38s} L{str(r['line']):6s} {r['symbol']}\n")
