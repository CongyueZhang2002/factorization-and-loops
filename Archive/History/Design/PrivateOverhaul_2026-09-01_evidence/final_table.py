import re,os,glob,sys
S="/tmp/claude-1000/-home-maxzhang/ecf0b429-302d-4fa5-85cc-249574ef5ba1/scratchpad"
def driver_rows(log):
    rows={}
    for l in open(log,errors="replace"):
        m=re.match(r'(t_\w+)\s+(OK|EXIT\d+|SCREEN)\s+([0-9.]+)\s*(.*)',l)
        if not m: continue
        n,st,w,note=m.groups()
        if "confirmation" in note or "standalone-only" in note: rows.setdefault(n,{})["standalone"]=(st,float(w))
        else: rows.setdefault(n,{})["pooled"]=(st,float(w))
    return rows
def queue_rows(log):
    rows={}
    for l in open(log,errors="replace"):
        m=re.match(r'=== JOB (\S+) end (\S+) exit=(\d+) tally: (.*)',l.strip())
        if not m: continue
        label,end,code,tally=m.groups()
        if not re.search(r't_\w+',label): continue
        name=re.search(r'(t_\w+?)(_rerun)?$',label).group(1)
        jl=f"{S}/bench/seatqueue_{label}.log"; txt=open(jl,errors="replace").read() if os.path.exists(jl) else ""
        trues=len(re.findall(r'-> True',txt)); falses=len(re.findall(r'-> False',txt))
        checks=re.search(r'(\d+)/(\d+) checks passed',txt)
    passed=code=="0" and (re.search(r'\b0 failed\b',tally) or re.search(r'\b0 FAIL\b',tally) or (trues>0 and falses==0) or (checks and checks.group(1)==checks.group(2)))
        if passed: v="OK"
        elif "ALLOWANCE EXPIRED" in txt: v="CAPPED"
        elif code=="0": v="OK?"
        else: v=f"EXIT{code}"
        rows[name]=(v,label,end[11:19])   # latest run wins (later lines overwrite)
    return rows
base=driver_rows(S+"/bench/baseline_tests.log"); over=driver_rows(S+"/bench/overhaul_tests.log"); conf=queue_rows(S+"/bench/seatqueue_confirm.log")
def verdict(d,standalone=None):
    if standalone: return standalone[0]
    if "standalone" in d: return d["standalone"][0]
    if "pooled" in d: return d["pooled"][0] if d["pooled"][0]!="SCREEN" else "SCREEN(unconfirmed)"
    return "-"
names=sorted(set(base)|set(over)|set(conf))
print("| test | baseline (pooled / standalone) | overhaul pooled | overhaul standalone (latest run) | verdict |"); print("|---|---|---|---|---|")
summary={"same":0,"fixed":0,"regressed":0,"new":0,"red-both":0,"pending":0}
for n in names:
    b=base.get(n,{}); o=over.get(n,{}); c=conf.get(n)
    bv=verdict(b); ov=verdict(o,c)
    bcell=" / ".join(f"{b[k][0]}" for k in ("pooled","standalone") if k in b) or "-"
    ocell=o.get("pooled",("-",0))[0]; ccell=f"{c[0]} ({c[1].split('_')[0]} {c[2]})" if c else "-"
    if bv=="-" and ov=="-": cls="pending"
    elif bv=="-": cls="new" if ov=="OK" else ("pending" if "SCREEN" in ov else "new-red")
    elif ov=="-" or ov.startswith("SCREEN") or bv.startswith("SCREEN"): cls="pending"
    elif bv=="OK" and ov=="OK": cls="same"
    elif bv=="OK" and ov!="OK": cls="regressed"
    elif bv!="OK" and ov=="OK": cls="fixed"
    else: cls="red-both"
    summary[cls]=summary.get(cls,0)+1
    if "--all" in sys.argv or cls not in ("same",):
        print(f"| {n} | {bcell} | {ocell} | {ccell} | {cls} |")
print(); print("summary:", ", ".join(f"{k} {v}" for k,v in summary.items() if v))
