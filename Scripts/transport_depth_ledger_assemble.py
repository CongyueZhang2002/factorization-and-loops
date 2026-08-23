#!/usr/bin/env python3
# Assemble the per-family records written by Scripts/transport_depth_ledger.wls into
#   Results/UU_08_10_canonical/TransportDepthLedger.wl  (machine-readable)
#   Results/UU_08_10_canonical/TransportDepthLedger.md  (human-readable)
# Usage: run from a directory holding the per-family records in ./ledger/ .
# Pure Python on purpose: it needs no Wolfram seat, which is why it exists.
import re, glob, os, datetime, collections
R="/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical"
IN="ledger"

def unwrap(s):
    s=s.strip()
    if s.startswith("(*"):
        i=s.find("*)"); s=s[i+2:].strip()
    return s

def value(txt, key, start=0):
    """balanced-expression value of \"key\" -> ... inside txt"""
    m=re.search(r'"%s" ->\s*'%re.escape(key), txt[start:])
    if not m: return None
    i=start+m.end()
    depth=0; j=i; instr=False; esc=False
    while j < len(txt):
        c=txt[j]
        if instr:
            if esc: esc=False
            elif c=='\\': esc=True
            elif c=='"': instr=False
        else:
            if c=='"': instr=True
            elif c in '{[(': depth+=1
            elif c in '}])':
                if depth==0: break
                depth-=1
            elif c=='|' and txt[j:j+2]=='|>':
                if depth==0: break
                depth-=1; j+=1
            elif c=='<' and txt[j:j+2]=='<|':
                depth+=1; j+=1
            elif c==',' and depth==0: break
        j+=1
    return re.sub(r'\s+',' ',txt[i:j].strip())

def sub(txt, key):
    m=re.search(r'"%s" ->\s*'%re.escape(key), txt)
    if not m: return ""
    return txt[m.end():]

files=sorted(glob.glob(IN+"/*.wl"))
recs=[]
for f in files:
    t=unwrap(open(f).read())
    fam=value(t,"Family")
    if fam is None: continue
    recs.append((fam.strip('"'), t))
print("records:", len(recs))

# valuations
vtxt=open(os.path.join(R,"MasterCoefficientValuations.wl")).read()
entries=re.findall(r'<\|"Index" -> (\d+), "Family" -> "(\w+)", "Indices" -> \{([-\d, ]+)\}, "Valuation" -> ([^,]+), "Route" -> "(\w+)", "Bytes" -> ([^|]+)\|>', vtxt)
print("valuation entries:", len(entries))
hist=collections.Counter()
for e in entries:
    v=e[3].strip()
    hist[int(v) if re.match(r'^-?\d+$',v) else None]+=1
deep=[e for e in entries if re.match(r'^-?\d+$',e[3].strip()) and int(e[3])<=-2]
zeros=[e for e in entries if not re.match(r'^-?\d+$',e[3].strip())]

# ---------------- .wl -------------------------------------------------
created=datetime.datetime.now().replace(microsecond=0).isoformat()
famtxt=",\n  ".join(t for _,t in recs)
wl = f'''(* Transport depth ledger: per-master demands from the MEASURED eps-Laurent
   valuation of every canonical master's coefficient column in the NNLO UU hard
   function, and the per-block transport depth under both depth rules.
   Generated {created} by Scripts/transport_depth_ledger.wls +
   Scripts/master_coefficient_valuations.py.  NOTHING was transported: every
   family was entered through TransportFamily / TransportFamilyInChart with
   "MaxWeight" -> 0, which returns the assembly and the depth arithmetic and
   stops before the backend.  Human-readable companion: TransportDepthLedger.md *)
<|"Format" -> "FeynFacet-TransportDepthLedger", "FormatVersion" -> 1,
 "Created" -> "{created}",
 "Inputs" -> <|
   "Valuations" -> "Results/UU_08_10_canonical/MasterCoefficientValuations.wl",
   "ValuationSource" -> "Codex/ppHX_NNLO_DoubleReal/CoefficientSimplification/UU_08_10_canonical/Reconstruction_2026_08_13/{{rec_rest.txt, series_000001.txt, series_000002.txt}}",
   "DifferentialEquations" -> "Results/UU_08_10_canonical/DifferentialEquations/nnlo_de_CF*.wl",
   "BlockClasses" -> "Results/UU_08_10_canonical/BlockClasses/block_class_assign.wl",
   "ClassForms" -> "Results/UU_08_10_canonical/ClassForms/class*.wl"|>,
 "Conventions" -> <|
   "Demand" -> "N_a = 0 - valuation_a + 1: the hard function is wanted through eps^0 and one extra order of safety is carried.  DemandNoSafety = -valuation_a is tabulated beside it.",
   "Eq11" -> "N_i = max over masters a in block i and eps-orders t with T_ai^[t] != 0 of (N_a - t), on the family's ASSEMBLED T (in the chart for the chart families).",
   "Subsectors" -> "A family DE row that is not one of that family's OWN canonical masters carries NO direct demand: it is a canonical master of another family, is solved there, and is needed inside this family only as a source for this family's masters.  Its demand here therefore comes only from the coupling back-propagation.",
   "ClampedRule" -> "wmax = jmax + D, D = longest path under the edge cost max(0, 1 - ord): a proved upper bound, the module default.",
   "ExactRule" -> "wmax = max_i W_i(N_i) from the per-block recursion (GPT-Pro Eq. 4) with the FULL Laurent support of every coupling (masterTransportExactDepth, option \\"DepthRule\\" -> \\"Exact\\")."|>,
 "Valuations" -> Get[FileNameJoin[{{DirectoryName[$InputFileName], "MasterCoefficientValuations.wl"}}]],
 "Families" -> {{
  {famtxt}}}|>
'''
tmp=os.path.join(R,"TransportDepthLedger.wl.tmp")
open(tmp,"w").write(wl); os.replace(tmp, os.path.join(R,"TransportDepthLedger.wl"))
print("wrote TransportDepthLedger.wl", len(wl), "chars")

# ---------------- .md -------------------------------------------------
def g(t,k): 
    v=value(t,k); return v if v is not None else "-"
def ge(t,k,outer="ExactDepthEq11"):
    s=sub(t,outer)
    v=value(s,k) if s else None
    return v if v is not None else "-"

rows=[]
for fam,t in recs:
    st=g(t,"Status").strip('"')
    full='"ExactDepthEq11"' in t
    rows.append(dict(fam=fam,t=t,status=st,full=full,
        dim=g(t,"Dim"), frame=g(t,"Frame").strip('"'), secs=g(t,"Seconds"),
        clamp=g(t,"ClampedWeight"),
        exM=(ge(t,"WMax","ExactDepthModuleDemands") if full else "-"),
        dem=g(t,"BlockDemandEq11"),
        exE=(ge(t,"WMax") if full else "-"), clE=(ge(t,"ClampedMax") if full else "-"),
        mixed=(ge(t,"MixedEdges") if full else "-")))
full=[r for r in rows if r["full"]]
diff=[r for r in full if r["exE"]!=r["clE"]]
mixedfams=[r for r in full if r["mixed"] not in ("-","{}")]

def detail(r):
    t=r["t"]; s=sub(t,"ExactDepthEq11")
    supp=value(s,"Support") or ""
    trunc=value(s,"SupportTruncated") or ""
    pairs=re.findall(r'\{(\d+), (\d+)\} -> (\{[^}]*\})', supp)
    tr=dict(((a,b),c) for a,b,c in re.findall(r'\{(\d+), (\d+)\} -> (True|False)', trunc))
    ms=re.findall(r'<\|"GLI" -> gli\["(\w+)", \{([-\d, ]+)\}\], "Valuation" -> ([^,]+), "Route" -> "(\w+)", "Demand" -> ([^,]+), "DemandNoSafety" -> ([^,]+), "Row" -> \{(\d+)\}\|>', re.sub(r'\s+',' ',t))
    out=[f"### {r['fam']}  ({r['frame']} frame, entry status `{r['status']}`, {r['secs']} s)\n"]
    out.append(f"- dimension {g(t,'Dim')}, block dims {g(t,'BlockDims')}, classes {g(t,'BlockClasses')}")
    out.append(f"- block rows: {g(t,'Blocks')}")
    out.append(f"- kmin per block {g(t,'KMinPerBlock')}, lowest carried order {ge(t,'Lowest')}")
    out.append("\n  | master | valuation | route | N (+1) | N (no +1) |\n  |---|---|---|---|---|")
    for m in ms:
        out.append(f"  | `gli[\"{m[0]}\", {{{m[1]}}}]` | {m[2]} | {m[3]} | {m[4]} | {m[5]} |")
    out.append("")
    out.append(f"- per-block demand N_i (Eq. 11, with +1): {g(t,'BlockDemandEq11')}")
    out.append(f"- per-block demand N_i (Eq. 11, no +1):  {g(t,'BlockDemandEq11NoSafety')}")
    out.append(f"- module's own per-block need (all blocks at kmaxF): {value(sub(t,'Budget'),'Need') or '-'}")
    out.append(f"- Bellman potentials pi_i: {ge(t,'Potentials')}")
    out.append(f"- exact W_i(N_i), Eq. 11 demands: {ge(t,'W')}  -> **max {ge(t,'WMax')}**")
    out.append(f"- clamped per block, same demands: {ge(t,'ClampedPerBlock')}  -> **max {ge(t,'ClampedMax')}**")
    out.append(f"- exact max_i W_i, module's own demands: {ge(t,'WMax','ExactDepthModuleDemands')}")
    out.append(f"- the module's CURRENT requested weight (clamped jmax + D): {g(t,'ClampedWeight')}")
    out.append(f"- deficit edges (ord <= 0): {ge(t,'DeficitEdges')}")
    out.append(f"- slack edges (ord >= 2): {ge(t,'SlackEdges')}")
    out.append(f"- **MIXED edges** (deficit AND slack in the same coupling block -- where the two rules differ): {ge(t,'MixedEdges')}")
    out.append(f"- Laurent support cap used: {ge(t,'Cap')}\n")
    out.append("  full Laurent support of every coupling block (block i depends on block j):\n")
    out.append("  | edge (i,j) | eps-orders present | truncated at cap |\n  |---|---|---|")
    for a,b,c in pairs:
        out.append(f"  | ({a},{b}) | {c} | {tr.get((a,b),'-')} |")
    out.append("")
    return "\n".join(out)

prio=[r for r in rows if r["fam"] in ("CF258","CF230") and r["full"]]
others=sorted([r for r in rows if r["fam"] not in ("CF258","CF230")], key=lambda r:(not r["full"], r["fam"]))

md=[]
md.append("# Transport depth ledger (per-master demands, per-block depth)\n")
md.append(f"Generated {created} by `Scripts/master_coefficient_valuations.py` (valuations) and "
          "`Scripts/transport_depth_ledger.wls` (per-family depth). Machine-readable companion: "
          "`TransportDepthLedger.wl`; per-master table: `MasterCoefficientValuations.wl`.\n")
md.append("**Nothing here was transported.** Every family is entered through the existing "
          "`TransportFamily` / `TransportFamilyInChart` with `\"MaxWeight\" -> 0`, which returns "
          "the assembly and the depth arithmetic and stops before the backend.\n")
md.append("## What is measured and what is assumed\n")
md.append("""MEASURED
- the eps-Laurent valuation of every canonical master's coefficient column in the hard
  function (345 exact rational columns + 2 eps^5 series columns, 2026-08-13 production
  reconstruction). Each rational column's valuation is pinned by a SANDWICH: a rigorous
  structural lower bound on ord_eps meets a rigorous evaluation upper bound obtained by
  substituting exact field elements for CA, CF, x, y in F_p, p = 2^61-1, with eps kept
  SYMBOLIC. Where the two meet the valuation is exact, with no probabilistic step. All
  343 non-zero rational columns closed at three independent random points.
- the per-block kmin, the coupling DAG, the FULL Laurent support of every coupling
  block, and both depth rules, computed on each family's own assembled connection.

ASSUMPTION / CONVENTION (stated, not measured)
- `N_a = 0 - valuation_a + 1`: the hard function is wanted through eps^0 and one extra
  order of safety is carried. The number without the +1 is tabulated everywhere.
- a family DE row that is not one of that family's OWN canonical masters carries no
  direct demand: it is a canonical master of another family and is solved there; inside
  this family it is only a source, so its depth comes from the coupling back-propagation.
- the couplings are dlog with constant Laurent-in-eps residues. The whole weight grading
  rests on this. It is part of the assembly certificate for the DIAGONAL blocks and is
  NOT separately re-certified for the off-diagonal couplings here (flagged by both
  2026-08-16 reviews).
- an overall eps-free normalization common to all columns does not shift the demands; a
  prefactor with nonzero eps valuation would shift them all uniformly.
""")
md.append("## Master coefficient valuations (all 347)\n")
md.append("| valuation | masters | demand N = -val + 1 |\n|---|---|---|")
for k in sorted([x for x in hist if x is not None]):
    md.append(f"| {k} | {hist[k]} | {-k+1} |")
md.append(f"| (identically zero column) | {hist[None]} | none |\n")
md.append(f"The deepest column is eps^-4 (exactly one master), so the deepest demand anywhere in "
          f"the hard function is eps^5. {hist.get(0,0)} of 347 columns start at eps^0 (demand eps^1) "
          f"and {hist.get(-1,0)} at eps^-1 (demand eps^2); only {sum(hist[k] for k in hist if k is not None and k<=-2)} "
          "columns are deeper than eps^-1. The earlier planning estimate \"every master through "
          "roughly eps^4\" is superseded.\n")
md.append("Masters with a column valuation <= -2:\n")
md.append("| master | valuation | route | N | N (no +1) |\n|---|---|---|---|---|")
for e in sorted(deep, key=lambda e:int(e[3])):
    md.append(f"| `GLI[{e[1]}, {{{e[2]}}}]` | {e[3].strip()} | {e[4]} | {-int(e[3])+1} | {-int(e[3])} |")
md.append("")
md.append("Identically zero coefficient columns (no demand at all): " +
          ", ".join(f"`GLI[{e[1]}, {{{e[2]}}}]`" for e in zeros) + "\n")
md.append("## The chart families in detail\n")
for r in prio: md.append(detail(r))
md.append("## All families with a full depth record\n")
md.append(f"{len(full)} of 91 families carry a full per-block depth record. `clamped` is the weight "
          "the module requests today (jmax + D on its own uniform demands). `exact(mod)` is the exact "
          "recursion on those same demands. The last comparison is the like-for-like one: both rules "
          "on the MEASURED Eq. (11) demands.\n")
md.append("| family | dim | frame | blocks-demand N_i (Eq. 11) | clamped | exact(mod) | exact(Eq.11) | clamped(Eq.11) | mixed edges | s |")
md.append("|---|---|---|---|---|---|---|---|---|---|")
for r in sorted(full, key=lambda r:r["fam"]):
    nm = "0" if r["mixed"]=="{}" else str(len(re.findall(r'\{\d+, \d+\}', r["mixed"])))
    md.append(f"| {r['fam']} | {r['dim']} | {r['frame']} | {r['dem']} | {r['clamp']} | {r['exM']} | "
              f"**{r['exE']}** | {r['clE']} | {nm} | {r['secs']} |")
md.append("")
md.append(f"**The exact rule is strictly below the clamped rule on the same demands in "
          f"{len(diff)} of {len(full)} families** ({', '.join(sorted(r['fam'] for r in diff))}), "
          "normally by one weight -- which at 6-14 letters is roughly a factor 10 in word count. "
          f"A coupling block carrying BOTH a deficit order and a slack order (a MIXED edge) occurs in "
          f"{len(mixedfams)} of {len(full)} families. This corrects the 2026-08-16 night reading "
          "\"no coupling of order >= 2 (no slack)\", which was taken from the MINIMUM eps-order per "
          "coupling block rather than from its full Laurent support.\n")
notfull=[r for r in rows if not r["full"]]
md.append("## Families with no per-block record, and why\n")
md.append("The per-master half of this ledger covers all 347 masters in all 91 families. The "
          "per-block half needs the family ASSEMBLY, and that is where families are lost: the plain "
          "(v,w) entry point correctly REFUSES a class whose certified form lives in a chart "
          "(`ClassFormNotEpsForm`, `ClassFormTwoVariableChartNeedsChartTransport`) -- using such a "
          "form in the (v,w) frame would differentiate it with respect to symbols it does not "
          "contain. The chart route (v = xy, w = (1-x)(1-y)) recovers many of them; the rest carry a "
          "conic class that does not pull back to THIS chart (`ClassFormChartNotPullable`).\n")
md.append("| family | status |\n|---|---|")
for r in sorted(notfull, key=lambda r:r["fam"]):
    md.append(f"| {r['fam']} | `{r['status']}` |")
md.append("")
out="\n".join(md)
tmp=os.path.join(R,"TransportDepthLedger.md.tmp")
open(tmp,"w").write(out); os.replace(tmp, os.path.join(R,"TransportDepthLedger.md"))
print("wrote TransportDepthLedger.md", len(out), "chars;", len(full), "full records,", len(diff), "where exact<clamped,", len(mixedfams), "with mixed edges")
