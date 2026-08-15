#!/usr/bin/env python3
"""Extract the cut/propagator definitions of the families involved in the
PID 1/6/7 realization transfers from the Kira family configs (which live in
a gitignored agent workspace) into a version-controlled Wolfram record."""
import re, sys, os

# Repository-relative: this script lives at
#   <root>/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/BoundaryPeriods/Scripts/
ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                    *([os.pardir] * 5)))
SRC = os.path.join(ROOT, "Codex", "ppHX_NNLO_DoubleReal", "Kira",
                   "UU_08_10_canonical", "families")
FAMS = ["CF1", "CF124", "CF300", "CF299", "CF21", "CF226", "CF23",
        "CF248", "CF253", "CF53", "CF57", "CF91", "CF97"]

def parse_momentum(expr):
    """'-ka - kb + kc + ke' -> {'ka':-1,'kb':-1,'kc':1,'ke':1}"""
    expr = expr.strip().replace(" ", "")
    if not expr.startswith(("+", "-")):
        expr = "+" + expr
    out = {}
    for sign, name in re.findall(r"([+-])([A-Za-z]\w*)", expr):
        out[name] = out.get(name, 0) + (1 if sign == "+" else -1)
    return out

def parse_family(fam):
    path = os.path.join(SRC, fam, "config", "integralfamilies.yaml")
    text = open(path).read()
    loop = re.search(r"loop_momenta:\s*\[([^\]]*)\]", text).group(1)
    loop = [s.strip() for s in loop.split(",") if s.strip()]
    cuts = re.search(r"cut_propagators:\s*\[([^\]]*)\]", text).group(1)
    cuts = [int(s) for s in cuts.split(",") if s.strip()]
    props = []
    body = text[text.index("propagators:"):]
    for line in body.splitlines()[1:]:
        ls = line.strip()
        if not ls.startswith("-"):
            continue
        m = re.match(r'-\s*\[\s*"([^"]*)"\s*,\s*([^\]]*)\]', ls)
        if m:
            props.append(("sq", parse_momentum(m.group(1)), m.group(2).strip()))
            continue
        m = re.match(r'-\s*\{\s*bilinear:\s*\[\s*\[\s*"([^"]*)"\s*,\s*"([^"]*)"\s*\]\s*,\s*([^\]]*)\]\s*\}', ls)
        if m:
            props.append(("bilinear",
                          (parse_momentum(m.group(1)), parse_momentum(m.group(2))),
                          m.group(3).strip()))
            continue
        raise SystemExit("unparsed propagator line in %s: %r" % (fam, ls))
    return loop, cuts, props

def wl_mom(d):
    return "<|" + ", ".join('"%s" -> %d' % (k, v) for k, v in sorted(d.items())) + "|>"

def main():
    out = ['(* Cut and propagator definitions for the families involved in the',
           '   PID 1 / 6 / 7 realization transfers.  Extracted verbatim from',
           '   Kira integralfamilies.yaml by Scripts/extract_families.py so that',
           '   the transfer test does not depend on a gitignored workspace.',
           '   Momenta are recorded as coefficient associations over the basis',
           '   {ka, kb, kc, ke, kf}. *)', '<|']
    entries = []
    for fam in FAMS:
        loop, cuts, props = parse_family(fam)
        plist = []
        for kind, data, mass in props:
            if kind == "sq":
                plist.append('<|"Type" -> "Square", "Momentum" -> %s, "Mass" -> %s|>'
                             % (wl_mom(data), mass))
            else:
                plist.append('<|"Type" -> "Bilinear", "Momenta" -> {%s, %s}, "Mass" -> %s|>'
                             % (wl_mom(data[0]), wl_mom(data[1]), mass))
        entries.append('  "%s" -> <|\n    "LoopMomenta" -> {%s},\n    "CutPropagators" -> {%s},\n    "Propagators" -> {\n      %s}|>'
                       % (fam, ", ".join(loop), ", ".join(map(str, cuts)),
                          ",\n      ".join(plist)))
    out.append(",\n".join(entries))
    out.append("|>")
    sys.stdout.write("\n".join(out) + "\n")

main()
