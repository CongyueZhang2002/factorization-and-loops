
import subprocess,time,json,os
from pathlib import Path
root=Path("/home/maxzhang/factorization-and-loops")
scratch=Path("/tmp/feynfacet-stage1-20260906")
paths=["Tests/Transport/t_finite_field_reexpression_speedups.wls"]
results=[]
for test in paths:
 start=time.monotonic()
 with (scratch/(Path(test).stem+"-final.log")).open("w") as log:
  result=subprocess.run(["taskset","-c","0,1,6,7,8,9,18,19","/usr/local/bin/wolframscript","-file",test],cwd=root,stdout=log,stderr=subprocess.STDOUT)
 record={"Test":test,"ExitCode":result.returncode,"Seconds":time.monotonic()-start}
 results.append(record);print(json.dumps(record),flush=True)
 (scratch/"zero-final-test.json").write_text(json.dumps(results,indent=2))
 if result.returncode:raise SystemExit(result.returncode)
directory=root/"ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/DifferentialEquationDataV2/CF259"
env=os.environ.copy()
env.update(FACET_KERNEL_COUNT="1",FACET_MQ_NATIVE_THREADS="8",FACET_FAMILY_BUDGET="600")
out=scratch/"optimized-CF259-final";out.mkdir(exist_ok=True)
start=time.monotonic()
with (scratch/"optimized-CF259-final.log").open("w") as log:
 result=subprocess.run(["taskset","-c","0,1,6,7,8,9,18,19","/usr/bin/time","-v","/usr/local/bin/wolframscript","-file","Scripts/family_epsform_sector.wls","CF259",str(out),str(directory/"FamilyDifferentialSystem.wl"),str(scratch/"CF259-block-decomposition.wl"),str(directory/"CoefficientPresentation.wl"),str(directory/"DiagonalBlockDLogEpsilonForms"),"180","fresh","0"],cwd=root,env=env,stdout=log,stderr=subprocess.STDOUT)
record={"ExitCode":result.returncode,"Seconds":time.monotonic()-start}
(scratch/"optimized-CF259-final-process.json").write_text(json.dumps(record,indent=2))
print(json.dumps(record),flush=True)
