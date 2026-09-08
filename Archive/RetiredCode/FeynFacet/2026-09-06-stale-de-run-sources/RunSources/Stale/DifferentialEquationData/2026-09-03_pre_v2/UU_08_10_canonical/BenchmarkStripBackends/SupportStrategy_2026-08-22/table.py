import csv
B="/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/BenchmarkStripBackends/SupportStrategy_2026-08-22/"
rows={}
for s in ["SimplexFirst","SparseFirst"]:
    try:
        for r in csv.DictReader(open(B+s+".tsv"),delimiter="\t"):
            rows.setdefault(r["block"],{})[s]=r
    except FileNotFoundError: pass
print(f"{'block':14} {'dims':7} | {'Simplex s':>9} {'prb':>3} {'supp':>4} {'unk':>5} {'pr':>2} | {'Sparse s':>9} {'prb':>3} {'supp':>4} {'unk':>5} {'pr':>2}")
tot={"SimplexFirst":0.0,"SparseFirst":0.0}; n=0
for b,d in sorted(rows.items(), key=lambda kv: -float((kv[1].get("SimplexFirst") or kv[1].get("SparseFirst"))["seconds"].replace('"',''))):
    def f(s):
        r=d.get(s)
        if not r: return f"{'…':>9} {'':>3} {'':>4} {'':>5} {'':>2}"
        if r["solved"]!="True": return f"{'FAIL '+r['seconds']:>9} {'':>3} {'':>4} {'':>5} {'':>2}"
        return f"{r['seconds']:>9} {r['probes']:>3} {r['support']:>4} {r['unknowns']:>5} {r['primes']:>2}"
    dims=(d.get("SimplexFirst") or d.get("SparseFirst"))["dims"]
    print(f"{b:14} {dims:7} | {f('SimplexFirst')} | {f('SparseFirst')}")
    if all(s in d and d[s]["solved"]=="True" for s in tot):
        n+=1
        for s in tot: tot[s]+=float(d[s]["seconds"])
print(f"both solved: {n} blocks; total seconds Simplex {tot['SimplexFirst']:.0f} vs Sparse {tot['SparseFirst']:.0f}")
