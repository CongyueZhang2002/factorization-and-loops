"""Recheck the stored before/after CF259 assemblies without solving a DE."""
from pathlib import Path
import gzip,json,os,shutil,subprocess,tempfile
source=Path(__file__).resolve().parent
with tempfile.TemporaryDirectory(prefix="facet-stage1-validation-") as directory:
    directory=Path(directory)
    for filename in ["CF259-before-assembled-connection.wxf","CF259-after-assembly.wxf"]:
        with gzip.open(source/(filename+".gz"),"rb") as inp,(directory/filename).open("wb") as out:
            shutil.copyfileobj(inp,out)
    env=os.environ.copy()
    env["FACET_VERIFICATION_INPUT_DIR"]=str(directory)
    result=subprocess.run(["taskset","-c","0,1,6,7,8,9,18,19","/usr/local/bin/wolframscript",
        "-file",str(source/"verify-assembly.wls")],env=env)
    report=directory/"assembly-validation.json"
    if report.exists():print(report.read_text())
    raise SystemExit(result.returncode)
