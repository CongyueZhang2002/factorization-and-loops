import os,re,glob,sys
S="/tmp/claude-1000/-home-maxzhang/ecf0b429-302d-4fa5-85cc-249574ef5ba1/scratchpad"
def pool(dirpath, prefixes=("run_","fresh_")):
    t={}
    for sub in ("done","failed"):
        for f in glob.glob(f"{dirpath}/{sub}/*.status"):
            name=os.path.basename(f)[:-7]
            pre=None
            for p in prefixes+("fix1_","fix2_","fix3_","fix4_"):
                if name.startswith(p): pre=p; name=name[len(p):]; break
            if not name.startswith("t_"): continue
            txt=open(f,errors="replace").read()
            m=re.search(r'"Status" -> "([A-Z0-9]+)"',txt); w=re.search(r'"Wall" -> ([0-9.]+)',txt)
            st=(m.group(1) if m else "?", float(w.group(1)) if w else None, pre)
            # a fix1_ rerun supersedes the batch result
            if name in t and (t[name][2] or "").startswith("fix") and not pre.startswith("fix"): continue
            if name in t and (t[name][2] or "").startswith("fix") and pre.startswith("fix") and pre < t[name][2]: continue
            t[name]=st
    return t
base=pool(S+"/kernelpool_base"); over=pool(S+"/kernelpool_overhaul")
print(f"pooled: baseline {len(base)} results, overhaul {len(over)} results")
reg=[];fix=[]
for n in sorted(over):
    b=base.get(n,("-",None,None))[0]; o=over[n][0]
    if b!=o:
        print(f"{n:50s} {b:8s} {o:8s} {('(rerun '+over[n][2]+')') if (over[n][2] or '').startswith('fix') else ''}")
        if b=="OK" and o!="OK": reg.append(n)
        if b!="OK" and o=="OK": fix.append(n)
print("pooled regressions:",len(reg)); print("pooled fixes:",fix)
if "--lines" in sys.argv:
    for n in reg:
        f=f"{S}/kernelpool_overhaul/logs/run_{n}.log"
        if not os.path.exists(f): continue
        lines=[l.strip()[:150] for l in open(f,errors="replace") if re.search(r'^"?FAIL|noopen|BackendSourceUnavailable|::[a-z]+:',l) and "General::stop" not in l]
        print(f"--- {n}: "+" | ".join(lines[:3]))
