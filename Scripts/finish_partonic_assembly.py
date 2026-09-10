#!/usr/bin/env python3
"""Replay the general final assembly from explicit solved bulk/face profiles."""
from pathlib import Path
import argparse,subprocess
ROOT=Path(__file__).resolve().parents[1]
def run(script,sentinel,*arguments):
    source=ROOT/"Scripts"/script
    if not source.is_file():raise SystemExit(f"Missing driver: {source}")
    seen=False
    process=subprocess.Popen(["taskset","-c","0-7","wolframscript","-file",str(source),*arguments],
                             cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    for line in process.stdout:
        print(line,end="",flush=True)
        seen=seen or sentinel in line
    code=process.wait()
    if code or not seen:raise SystemExit(code or f"Completion marker absent: {script}")
if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("endpoint_plan");parser.add_argument("finalization_plan")
    parser.add_argument("--projects",nargs="+",required=True);parser.add_argument("--order",required=True)
    args=parser.parse_args()
    run("assemble_endpoint_profiles.wls","COMPLETED ALL ENDPOINT PROFILE OUTPUTS",str(Path(args.endpoint_plan).resolve()))
    for project in args.projects:run("combine_partonic_contributions.wls","COMPLETED ALL PARTONIC CONTRIBUTION SUMS",project,args.order)
    run("finalize_partonic_results.wls","COMPLETED FINITE PARTONIC RESULTS",str(Path(args.finalization_plan).resolve()))
