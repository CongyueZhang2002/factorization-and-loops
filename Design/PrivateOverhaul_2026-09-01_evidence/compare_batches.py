#!/usr/bin/env python3
"""Compare the baseline and overhaul test-batch driver tables.
Rows: 'test  STATUS  wall (...)'.  A SCREEN row is superseded by the later
standalone confirmation row of the same test."""
import re,sys
S="/tmp/claude-1000/-home-maxzhang/ecf0b429-302d-4fa5-85cc-249574ef5ba1/scratchpad"
def table(path):
    t={}
    for line in open(path,errors="replace"):
        m=re.match(r'^(t_[a-z0-9_]+)\s+(OK|EXIT\d+|SCREEN|CANCELLED|KERNELLOST|NEVERSTARTED|FAILED|ABORTED)\s+(\S+)(.*)$',line)
        if not m: continue
        name,st,wall,rest=m.groups()
        if st=="SCREEN" and name in t: continue
        if st=="SCREEN": t[name]=("SCREEN",wall,rest.strip()); continue
        t[name]=(st,wall,rest.strip())
    return t
base=table(S+"/bench/baseline_tests.log"); over=table(S+"/bench/overhaul_tests.log")
names=sorted(set(base)|set(over))
print(f"{'test':50s} {'baseline':10s} {'overhaul':10s} note")
worse=[];better=[];newtests=[];gone=[]
for n in names:
    b=base.get(n,("-","",""))[0]; o=over.get(n,("-","",""))[0]
    note=""
    if n not in base: newtests.append(n); note="new in overhaul"
    elif n not in over: gone.append(n); note="not in overhaul batch"
    elif b=="OK" and o not in ("OK","SCREEN"): worse.append(n); note="REGRESSION?"
    elif b!="OK" and o=="OK": better.append(n); note="fixed"
    if note or b!=o: print(f"{n:50s} {b:10s} {o:10s} {note}")
print("\nsummary: baseline OK", sum(1 for v in base.values() if v[0]=="OK"), "of", len(base), "| overhaul OK", sum(1 for v in over.values() if v[0]=="OK"), "of", len(over))
print("regressions:", worse); print("fixed:", better); print("new:", newtests); print("missing:", gone)
