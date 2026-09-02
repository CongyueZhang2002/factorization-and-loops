import re,os,sys,glob
S="/tmp/claude-1000/-home-maxzhang/ecf0b429-302d-4fa5-85cc-249574ef5ba1/scratchpad"
log=sys.argv[1] if len(sys.argv)>1 else S+"/bench/seatqueue_confirm.log"
rows=[]
for l in open(log,errors="replace"):
    m=re.match(r'=== JOB (\S+) end (\S+) exit=(\d+) tally: (.*)',l.strip())
    if not m: continue
    label,end,code,tally=m.groups()
    name=label.replace("confirm_","").replace("_rerun","")
    jl=f"{S}/bench/seatqueue_{label}.log"
    txt=open(jl,errors="replace").read() if os.path.exists(jl) else ""
    falses=len(re.findall(r'-> False',txt)); trues=len(re.findall(r'-> True',txt))
    refused="not activated or is experiencing a license" in txt[-3000:]
    killed="ALLOWANCE EXPIRED" in txt
    checks=re.search(r'(\d+)/(\d+) checks passed',txt)
    passed=code=="0" and (re.search(r'\b0 failed\b',tally) or re.search(r'\b0 FAIL\b',tally) or (trues>0 and falses==0) or (checks and checks.group(1)==checks.group(2)))
    if passed: verdict="OK"
    elif killed: verdict="CAPPED"
    elif refused and code!="0": verdict="REFUSED"
    elif code=="0" and "NO-TALLY" in tally: verdict="VOID"
    elif code=="0": verdict="OK?"
    else: verdict=f"EXIT{code}"
    t=tally.replace("NO-TALLY (void: the job produced no result marker)", f"{trues} True / {falses} False booleans" if trues+falses else "no tally")
    rows.append((name,verdict,t.strip()[:70]))
print("| test | standalone verdict | tally |"); print("|---|---|---|")
for n,v,t in rows: print(f"| {n} | {v} | {t} |")
print(f"\n{len(rows)} jobs: "+", ".join(f"{v} {sum(1 for r in rows if r[1]==v)}" for v in sorted(set(r[1] for r in rows))))
