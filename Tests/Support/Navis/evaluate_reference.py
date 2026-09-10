#!/usr/bin/env python3
"""Direct unmodified Navis UU/LL finite coefficients, used only for validation."""
import argparse
from fractions import Fraction
import json
import math
from pathlib import Path
import subprocess
import tempfile
import time

POINTS = [
    ["2/5","3/7","1","1","1","1","5","3"],
    ["3/4","2/3","2","3","5","7","4","3"],
    ["1/5","4/5","3","2","1","4","3","3"],
    ["5/6","1/4","5","7","3","2","6","3"],
    ["2/3","9/10","7","2","11","3","5","3"],
    ["1/3","1/7","11","13","2","5","4","3"],
    ["4/7","3/5","2","1/2","3/2","5/2","5","3"],
    ["7/9","5/8","3/2","7/3","2/5","11/7","6","3"],
    ["2/5","3/7","1","1","1","1","5","5"],
    ["3/4","2/3","2","3","5","7","4","5"],
]
CHANNELS = {1:"qqprime observed incoming quark",5:"annihilation observed distinct-flavor quark",
            13:"qg observed quark",14:"qg observed gluon"}

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("references",type=Path)
    parser.add_argument("output",type=Path)
    args=parser.parse_args()
    source=args.references.resolve()/"Navis"
    provenance=json.loads((source/"Source.json").read_text())
    template=Path(__file__).with_name("hard_function_probe.rs").read_text()
    template=template.replace("__POL_SOURCE__",str(source/"navis-pol/src/mes.rs"))
    template=template.replace("__UU_SOURCE__",str(source/"navis-unpol/src/mes.rs"))
    if '"' in str(source) or "\\" in str(source):
        raise ValueError("Reference path must be a plain Unix path")
    rows=[(j,point) for j in CHANNELS for point in POINTS]
    stdin="".join(str(j)+" "+" ".join(format(float(Fraction(x)),".17g") for x in p)+"\n" for j,p in rows)
    t0=time.monotonic()
    with tempfile.TemporaryDirectory(prefix="feynfacet-navis-") as tmp:
        wrapper=Path(tmp)/"probe.rs";wrapper.write_text(template)
        binary=Path(tmp)/"probe"
        compiler=subprocess.run(["rustc","--version"],check=True,capture_output=True,text=True).stdout.strip()
        subprocess.run(["rustc","--edition=2021","-C","opt-level=1",str(wrapper),"-o",str(binary)],
                       check=True,capture_output=True,text=True)
        result=subprocess.run([str(binary)],input=stdin,check=True,capture_output=True,text=True)
    values=[[float(x) for x in line.split()] for line in result.stdout.splitlines()]
    if len(values)!=len(rows) or any(len(v)!=8 or not all(map(math.isfinite,v)) for v in values):
        raise RuntimeError("Reference output coverage incomplete")
    record={"Source":provenance,"Compiler":compiler,"SecondsIncludingCompilation":time.monotonic()-t0,
            "InputVariables":["v","w","s","muF2","muD2","muR2","nf","CA"],"Points":POINTS,
            "OutputCoefficients":["Delta","Plus0","Plus1","Regular"],
            "PhysicalMultiplier":"alpha_s^3/(8 CC pi s^2)",
            "NormalizationSource":"navis-core/constants.rs prefactors; navis-pol/integrand.rs dplus; same invariant-density conversion as INCNLO",
            "Schemes":{"UU":"MSbar","LL":"helicity-preserving MSbar; validated independently against qqprime and annihilation controls"},
            "Channels":{str(j):{"Description":label,"UU":values[i*len(POINTS):(i+1)*len(POINTS)],
                                "LL":[]} for i,(j,label) in enumerate(CHANNELS.items())}}
    for ch in record["Channels"].values():
        both=ch["UU"];ch["UU"]=[v[:4] for v in both];ch["LL"]=[v[4:] for v in both]
    args.output.parent.mkdir(parents=True,exist_ok=True)
    tmp=args.output.with_suffix(".json.tmp");tmp.write_text(json.dumps(record,indent=2)+"\n");tmp.replace(args.output)
    print("NAVIS_REFERENCE_POINTS",len(rows),"COEFFICIENTS",8*len(rows))
if __name__=="__main__": main()
