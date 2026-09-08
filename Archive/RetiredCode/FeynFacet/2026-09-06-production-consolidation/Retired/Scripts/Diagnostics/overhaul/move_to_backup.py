#!/usr/bin/env python3
"""Move the top-level definitions of the given symbols from a Private file into
Private_Backup/<same name> (appending, with a provenance header), leaving the
rest of the file intact.  Statements moved: every top-level statement whose
head is one of the symbols (definitions, Options[sym] = ..., sym = ...).
ClearAll lists are left untouched (a listed name without a definition is
harmless).  Usage: move_to_backup.py <worktree> <Private/<layer>/[<sub>/]File.wl> <evidence text> sym1 sym2 ...
(nested layer paths accepted since round 5, 2026-09-02; the backup keeps the bare file name)
Prints the moved statement count and line count; --dry-run only reports."""
import sys,os,re
W=sys.argv[1]; rel=sys.argv[2]; evidence=sys.argv[3]; syms=[a for a in sys.argv[4:] if not a.startswith("--")]; dry="--dry-run" in sys.argv; keepopts="--keep-options" in sys.argv
src=os.path.join(W,"FeynFacet",rel); dst=os.path.join(W,"FeynFacet","Private_Backup",os.path.basename(rel))
text=open(src,encoding="utf-8",errors="replace").read()
# split into top-level statements on the RAW text (comments/strings respected), keeping the text verbatim
def split_raw(s):
    st=[];start=0;depth=0;i=0;n=len(s);incomment=0
    while i<n:
        if incomment:
            if s.startswith("(*",i): incomment+=1;i+=2;continue
            if s.startswith("*)",i): incomment-=1;i+=2;continue
            i+=1;continue
        if s.startswith("(*",i): incomment=1;i+=2;continue
        c=s[i]
        if c=='"':
            j=i+1
            while j<n and s[j]!='"':
                if s[j]=="\\": j+=1
                j+=1
            i=j+1;continue
        if c in "[({": depth+=1
        elif c in "])}": depth=max(0,depth-1)
        if c==";" and depth==0:
            st.append(s[start:i+1]); start=i+1
        i+=1
    st.append(s[start:])
    return st
stmts=split_raw(text)
def head(stmt):
    body=stmt
    # skip leading comments/whitespace
    while True:
        body=body.lstrip()
        if body.startswith("(*"):
            d=1;i=2
            while i<len(body) and d:
                if body.startswith("(*",i): d+=1;i+=2;continue
                if body.startswith("*)",i): d-=1;i+=2;continue
                i+=1
            body=body[i:]
        else: break
    m=re.match(r'(\$?[A-Za-z][A-Za-z0-9$]*)\s*(\[|:=|=(?!=)|/:)',body)
    if not m: return None
    h=m.group(1)
    if h=="Options":
        if keepopts: return None
        mo=re.match(r'Options\[\s*(\$?[A-Za-z][A-Za-z0-9$]*)\s*\]\s*=',body)
        return mo.group(1) if mo else None
    if h in ("ClearAll","Clear","SetAttributes","If","Scan","Do","Module","With","Block"): return None
    if not re.search(r'(:=|(?<![=!<>])=(?!=)|/:)',body): return None
    return h
moved=[s for s in stmts if head(s) in syms]; kept=[s for s in stmts if head(s) not in syms]
lines=sum(s.count("\n") for s in moved)
print(f"{rel}: moving {len(moved)} statements, ~{lines} lines, for {len(set(head(s) for s in moved))} of {len(syms)} requested symbols")
missing=set(syms)-set(head(s) for s in moved)
if missing: print("  no top-level statement found for:", sorted(missing))
if dry: sys.exit(0)
os.makedirs(os.path.dirname(dst),exist_ok=True)
header=f"\n(* ==== moved from {rel} on 2026-09-02 (overhaul goal 1) ====\n   Evidence: {evidence}\n   Symbols: {', '.join(sorted(set(head(s) for s in moved)))}\n   This file is never loaded by FeynFacet.m. *)\n"
with open(dst,"a",encoding="utf-8") as f: f.write(header+"".join(moved)+"\n")
open(src,"w",encoding="utf-8").write("".join(kept))
print(f"  written {dst}; source rewritten")
