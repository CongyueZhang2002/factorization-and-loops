#!/usr/bin/env python3
"""Run independent SIDIS NNLO comparisons with at most two Wolfram kernels."""
from pathlib import Path
import argparse,concurrent.futures,json,subprocess,time
ROOT=Path(__file__).resolve().parents[2]
def run_project(project,points):
    folder=ROOT/"Projects"/project/"NNLO/q-q/Results/Validation"
    outcomes=[]
    for point in points:
        log=folder/f"NNLOComparisonPoint{point}.log"
        start=time.monotonic()
        with log.open("w") as stream:
            done=subprocess.run(["taskset","-c","0-7","wolframscript","-file",
                str(ROOT/"Scripts/Validation/check_sidis_nnlo.wls"),project,str(point)],
                cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT)
        text=log.read_text()
        passed=done.returncode==0 and "NNLO COMPARISON Passed" in text
        outcomes.append({"point":point,"passed":passed,"seconds":time.monotonic()-start,"log":str(log)})
        print(project,point,"PASS" if passed else "FAIL",flush=True)
        if not passed:break
    report={"project":project,"points":outcomes,"completed":len(outcomes)==len(points),
            "passed":len(outcomes)==len(points) and all(row["passed"] for row in outcomes)}
    (folder/"NNLOComparisonCampaign.json").write_text(json.dumps(report,indent=2))
    return report
if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("projects",nargs="+");parser.add_argument("--points",default="1,2,3,4,5")
    args=parser.parse_args();points=[int(value) for value in args.points.split(",")]
    if not all(point in range(1,6) for point in points):parser.error("point indices must be 1,2,3,4,5")
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        results=list(pool.map(lambda project:run_project(project,points),args.projects))
    raise SystemExit(0 if all(result["passed"] for result in results) else 1)
