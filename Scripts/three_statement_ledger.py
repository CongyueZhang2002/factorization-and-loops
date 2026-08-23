#!/usr/bin/env python3
"""Three-statement ledger over Masters/ (2026-08-18 convention, Codex):
   per family: (i) transported map known, (ii) endpoint modes matched,
   (iii) boundary periods evaluated.  Reads .status lines + record text
   markers only (no kernel).  Usage: three_statement_ledger.py <MastersDir>"""
import sys, os, re, glob
d = sys.argv[1]
rows = []
for st in sorted(glob.glob(os.path.join(d, "CF*.status"))):
    fam = os.path.basename(st)[:-7]
    line = open(st).read().strip()
    transported = " Transported " in line
    route = "ObservableOnly" if "observable-only" in line else ("Route2/1" if transported else "-")
    rec = os.path.join(d, fam + ".wl")
    modes = "-"; periods = "-"
    if os.path.exists(rec):
        head = open(rec, errors="ignore").read(200000)
        m = re.search(r'"EndpointModesMatched" -> ([^,|]*)', head)
        p = re.search(r'"BoundaryPeriodsEvaluated" -> ([A-Za-z]*)', head)
        modes = (m.group(1).strip()[:40] if m else "not tracked")
        periods = (p.group(1) if p else "not tracked")
    rows.append((fam, "yes" if transported else "no", route, modes, periods, line[:70]))
n = len(rows); t = sum(r[1]=="yes" for r in rows)
print(f"families with status: {n}   transported map known: {t}")
print(f"{'family':7} {'map':4} {'route':14} {'endpoint modes':42} {'periods':12} status")
for r in rows:
    print(f"{r[0]:7} {r[1]:4} {r[2]:14} {r[3]:42} {r[4]:12} {r[5]}")
