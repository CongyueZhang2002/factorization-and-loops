#!/usr/bin/env python3
"""Evaluate the unmodified INCNLO 1.4 reference for channel J0=1.

Only used for validation. Production FeynFacet never imports these results.
The compiled reference is temporary; only the small comparison data survives.
"""
import argparse,json,subprocess,tempfile
from pathlib import Path
from fractions import Fraction

def main():
    parser=argparse.ArgumentParser();parser.add_argument("project",type=Path);parser.add_argument("output",type=Path);args=parser.parse_args()
    source=args.project/"References/INCNLO/inc1_4/hadlib/src"
    wrapper=Path(__file__).with_name("hard_function_probe.f90")
    points=[
      ["2/5","3/7","1","1","1","1","5"],
      ["3/4","2/3","2","3","5","7","4"],
      ["1/5","4/5","3","2","1","4","3"],
      ["5/6","1/4","5","7","3","2","6"],
      ["2/3","9/10","7","2","11","3","5"],
      ["1/3","1/7","11","13","2","5","4"],
      ["4/7","3/5","2","1/2","3/2","5/2","5"],
      ["7/9","5/8","3/2","7/3","2/5","11/7","6"]]
    stdin="".join(" ".join(format(float(Fraction(x)),".17g") for x in row)+"\n" for row in points)
    with tempfile.TemporaryDirectory(prefix="feynfacet-incnlo-") as tmp:
        binary=Path(tmp)/"reference"
        command=["gfortran","-O1","-std=legacy","-ffixed-line-length-none","-ffunction-sections","-fdata-sections","-fallow-argument-mismatch",
          "-I"+str(source),str(source/"hadlib.f"),str(source/"cdel.f"),str(wrapper),"-Wl,--gc-sections","-o",str(binary)]
        subprocess.run(command,check=True,capture_output=True,text=True)
        result=subprocess.run([str(binary)],input=stdin,check=True,capture_output=True,text=True)
    values=[[float(x) for x in line.split()] for line in result.stdout.splitlines() if line.strip()]
    if len(values)!=len(points) or any(len(row)!=4 for row in values):raise RuntimeError("Reference output coverage incomplete")
    record={"Source":"INCNLO 1.4, unmodified hadlib.f and cdel.f","SourceURL":"https://lapth.cnrs.fr/PHOX_FAMILY/readme_inc.html",
      "Channel":"J0=1: q_j q_k -> observed q_j, distinct flavors","Scheme":"JMAR=0, AL=1, CQ=0: original MSbar conversion included",
      "InputVariables":["v","w","s","muF2","muD2","muR2","nf"],"OutputCoefficients":["Delta","Plus0","Plus1","Regular"],
      "PhysicalMultiplier":"alpha_s^3/(8 CA^2 pi s^2)","Points":points,"Values":values}
    args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(json.dumps(record,indent=2)+"\n")
    print("INCNLO_REFERENCE_POINTS",len(values))
if __name__=="__main__":main()
