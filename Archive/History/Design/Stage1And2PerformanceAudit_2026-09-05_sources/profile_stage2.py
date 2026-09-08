#!/usr/bin/env python3
"""Profile the finite-solution constructor without changing repository code.

Input is the exact Data/Request/Options association saved as input.wxf by the
family driver. Package loading and reading that input are outside the timing.
"""
import json
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent

def replace_once(text, old, new):
    if text.count(old) != 1:
        raise RuntimeError("Profile marker changed: " + old)
    return text.replace(old, new, 1)

def main():
    if len(sys.argv) != 3:
        raise SystemExit("Expected INPUT.wxf REPORT.json")
    input_file = Path(sys.argv[1]).resolve()
    report_file = Path(sys.argv[2]).resolve()
    if not input_file.is_file():
        raise SystemExit("Input record not found")
    report_file.parent.mkdir(parents=True, exist_ok=True)
    finite = (ROOT / "FeynFacet/Private/Transport/Solutions/FiniteMasterIntegralSolution.wl").read_text()
    finite = replace_once(finite,
        "progress[msg_] := If[TrueQ[verbose],Print[msg]];",
        "progress[msg_] := SpeedAudit`mark[msg];")
    finite = replace_once(finite,
        '  result = <|"DataType" -> "MasterIntegralSolution", "SchemaVersion" -> 3,',
        '  progress["Building the complete result association"];\n'
        '  result = <|"DataType" -> "MasterIntegralSolution", "SchemaVersion" -> 3,')
    finite = replace_once(finite,
        '  If[!FeynFacet`MasterIntegralSolutionQ[result],',
        '  progress["Checking the complete finite expression"];\n'
        '  If[!FeynFacet`MasterIntegralSolutionQ[result],')
    orders = (ROOT / "FeynFacet/Private/Transport/Orders/MasterIntegralExpansionOrders.wl").read_text()
    markers = [
        (' frame=epsOrderPrepareFrame[system,homSeconds,automatic];', 'Order determination: prepare the system'),
        (' pointDefinitions=epsOrderPointIntegralDefinitions[system,r,e];', 'Order determination: select the base point'),
        (' lv=Map[epsOrderValuation[#,e]&,q,{2}];', 'Order determination: basis valuations'),
        (' beta=Table[Min[epsOrderValuation[#[[i,j]],e]& /@ frame["ConnectionMatrices"]],{i,n},{j,n}];', 'Order determination: connection valuations'),
        (' representations=Lookup[r,"MasterIntegralRepresentations",Lookup[system,"MasterIntegralRepresentations",<||>]];', 'Order determination: defining integrals and pole bounds'),
        (' <|"DataType"->"MasterIntegralExpansionOrders",', 'Order determination: assemble the report'),
    ]
    for old, label in markers:
        orders = replace_once(orders, old, ' SpeedAudit`mark["' + label + '"];\n' + old)
    # Explicit package contexts prevent reloading from binding local names to
    # Global symbols created by other packages. The WL template enforces this.
    with tempfile.TemporaryDirectory(prefix="feynfacet-profile-") as directory:
        directory = Path(directory)
        finite_path = directory / "FiniteMasterIntegralSolution.profile.wl"
        order_path = directory / "MasterIntegralExpansionOrders.profile.wl"
        finite_path.write_text(finite)
        order_path.write_text(orders)
        script = (HERE / "profile_stage2.template.wls").read_text()
        replacements = {
            "__REPOSITORY_ROOT__": json.dumps(str(ROOT)),
            "__INPUT_FILE__": json.dumps(str(input_file)),
            "__REPORT_FILE__": json.dumps(str(report_file)),
            "__FINITE_PROFILE__": str(finite_path),
            "__ORDER_PROFILE__": str(order_path),
        }
        for old, new in replacements.items():
            script = script.replace(old, new)
        driver = directory / "profile.wls"
        driver.write_text(script)
        return subprocess.run(
            ["/usr/local/bin/wolframscript", "-file", str(driver)], cwd=ROOT
        ).returncode

if __name__ == "__main__":
    raise SystemExit(main())
