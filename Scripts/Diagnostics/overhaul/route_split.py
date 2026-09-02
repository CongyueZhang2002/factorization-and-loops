#!/usr/bin/env python3
"""For each candidate stale route (root symbol), list the symbols that are reachable
from the route root but from NO other live root (public API, scripts, string sites),
with their defining file and statement line counts."""
import re,os,json,collections,sys
ROOT="/home/maxzhang/factorization-and-loops"; PRIV=ROOT+"/FeynFacet/Private"
IDENT=re.compile(r'\$?[A-Za-z][A-Za-z0-9$]*'); STR=re.compile(r'"(?:[^"\\]|\\.)*"')
def strip(s, keep_strings=False):
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
            out.append(s[i:j+1] if keep_strings else '""'); i=j+1;continue
        out.append(s[i]);i+=1
    return "".join(out)
def statements(code):
    st=[];buf=[];depth=0
    for c in code:
        if c in "[({": depth+=1
        elif c in "])}": depth=max(0,depth-1)
        buf.append(c)
        if c==";" and depth==0: st.append("".join(buf));buf=[]
    if buf: st.append("".join(buf))
    return st
def private_files():
    """every module under Private/ (any depth: Private/<layer>/[<sub>/]<File>.wl, round 5 2026-09-02), as paths relative to Private/"""
    out=[]
    for dp,_,fs in os.walk(PRIV):
        for fn in fs:
            if fn.endswith(".wl") and fn!="LoadOrder.wl": out.append(os.path.relpath(os.path.join(dp,fn),PRIV))
    return sorted(out)
graph=collections.defaultdict(set); deffile={}; deflines=collections.Counter()
for f in private_files():
    if not f.endswith(".wl"): continue
    code=strip(open(os.path.join(PRIV,f),encoding="utf-8",errors="replace").read())
    for s in statements(code):
        m=re.match(r'\s*(\$?[A-Za-z][A-Za-z0-9$]*)\s*(\[|:=|=(?!=)|/:)',s)
        if m and re.search(r'(:=|(?<![=!<>])=(?!=)|/:)',s) and m.group(1) not in ("Clear","ClearAll","Options","If","SetAttributes","Module","With","Block","Do","Scan"):
            h=m.group(1); deffile.setdefault(h,f); graph[h]|=set(IDENT.findall(s)); deflines[h]+=s.count("\n")+1
        mo=re.match(r'\s*Options\[\s*(\$?[A-Za-z][A-Za-z0-9$]*)\s*\]\s*=',s)
        if mo: deffile.setdefault(mo.group(1),f); graph[mo.group(1)]|=set(IDENT.findall(s)); deflines[mo.group(1)]+=s.count("\n")+1
symbols=set(deffile)
usage=set(re.findall(r'^([A-Za-z][A-Za-z0-9]*)::usage',open(ROOT+"/FeynFacet/FeynFacet.m").read(),re.M))
roots=set(u for u in usage if u in symbols)
mtext=strip(open(ROOT+"/FeynFacet/FeynFacet.m").read()); roots|={t for t in IDENT.findall(mtext) if t in symbols}
for d in ("Scripts","Addon/Load"):
    for dp,_,fs in os.walk(os.path.join(ROOT,d)):
        if any(x in dp for x in ("Diagnostics","HardClasses","/Libra")): continue   # diagnostics are not production contracts
        for fn in fs:
            if fn.endswith((".wl",".wls",".sh")):
                t=open(os.path.join(dp,fn),errors="replace").read()
                roots|=set(IDENT.findall(t))&symbols
for f in private_files():
    if f.endswith(".wl"):
        src=strip(open(os.path.join(PRIV,f),encoding="utf-8",errors="replace").read(),keep_strings=True)
        roots|=set(IDENT.findall(" ".join(STR.findall(src))))&symbols
def reach(rs,cut=set()):
    seen=set(x for x in rs if x not in cut); st=list(seen)
    while st:
        x=st.pop()
        for y in graph.get(x,()):
            if y in symbols and y not in seen and y not in cut: seen.add(y); st.append(y)
    return seen
routes={"SolveEpsFormStrip (CANONICA/Maple strip ladder)":{"SolveEpsFormStrip"},
        "TransportFamily (Libra path-ordered transport engines)":{"TransportFamily"},
        "CanonicalizeClasses (CANONICA class ladder)":{"CanonicalizeClasses"},
        "LibraFamilyEpsForm (whole-family Libra route)":{"LibraFamilyEpsForm"},
        "transportChartMapleCanonicalGauge (Maple canonical gauge mode)":{"transportChartMapleCanonicalGauge"},
        "TransportPathArtifactRun (CF303 exception seam entry)":{"TransportPathArtifactRun"}}
full=reach(roots)
print("live symbols from all roots:",len(full))
out={}
for name,rs in routes.items():
    without=reach(roots-rs, cut=rs)
    only=reach(rs)-without
    byfile=collections.Counter(deffile[x] for x in only)
    lines=sum(deflines[x] for x in only)
    print(f"\n### {name}: {len(only)} symbols reachable only through this route, ~{lines} statement lines")
    for f,c in byfile.most_common(): print(f"   {f}: {c} symbols, ~{sum(deflines[x] for x in only if deffile[x]==f)} lines")
    out[name]=sorted(only)
json.dump(out,open(os.path.dirname(os.path.abspath(__file__))+"/route_only_symbols.json","w"),indent=1)
