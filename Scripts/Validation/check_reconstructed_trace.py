"""Check every saved rational/Laurent output against its source trace."""
import argparse
import json
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_rational_trace import compare
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from wolfram import atomic_json, select_cpus

ROOT = Path(__file__).resolve().parents[2]


def split_record(record, directory):
    """Parse complete native blocks, retaining the exact expression text."""
    names, files, seen = [], [], set()
    with Path(record).open() as stream:
        for header in stream:
            if not header.strip():
                continue
            if header.startswith("(* FeynFacet-ReconstructionDone "):
                if not header.rstrip().endswith("*)") or stream.read().strip():
                    raise ValueError("Invalid reconstruction completion marker.")
                break
            if not header.rstrip().endswith(" ="):
                raise ValueError("Invalid reconstruction output header.")
            name = header.rstrip()[:-2]
            if not name or name in seen:
                raise ValueError("Duplicate or empty reconstruction output.")
            path = directory / f"Output_{len(names):06d}.expr"
            with path.open("w") as output:
                for line in stream:
                    if line.rstrip().endswith(";"):
                        output.write(line.rstrip()[:-1])
                        break
                    output.write(line)
                else:
                    raise ValueError("Unterminated reconstruction expression.")
            seen.add(name)
            names.append(name)
            files.append(path)
        else:
            raise ValueError("Reconstruction completion marker is missing.")
    if not names:
        raise ValueError("No reconstructed outputs.")
    return names, files


def check(request, output):
    output = Path(output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    executable = request.get("Executable", str(ROOT / "Addon/Other_Addon/Ratracer/bin/ratracer"))
    cpus = select_cpus(request.get("CpuSet", [0]))
    expected = [line.split(" ", 1)[1] for line in Path(request["SourceOutputList"]).read_text().splitlines()]
    with TemporaryDirectory(prefix="expressions-", dir=output) as temporary:
        names, files = split_record(request["RecordFile"], Path(temporary))
        if set(names) != set(expected) or len(names) != len(expected):
            raise ValueError("Reconstruction does not cover the complete source output list.")
        trace = output / "Reconstructed.trace.gz"
        command = ["taskset", "-c", ",".join(map(str, cpus)), executable]
        for path in files:
            command += ["trace-expression", str(path)]
        command += ["optimize", "finalize", "save-trace", str(trace)]
        with (output / "TraceConstruction.log").open("w") as log:
            subprocess.run(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                           check=True, timeout=request.get("TimeoutSeconds", 300))
        comparison = {**request, "AlternativeTrace": str(trace),
                      "OutputNameMap": dict(zip(names, map(str, files)))}
        atomic_json(output / "Request.json", comparison)
        return compare(comparison, output / "Comparison")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("request")
    parser.add_argument("output")
    args = parser.parse_args()
    report = check(json.loads(Path(args.request).read_text()), args.output)
    print(f"RECONSTRUCTED TRACE CHECK {report['Comparisons']} comparisons, passed={report['Passed']}")
    raise SystemExit(0 if report["Passed"] else 1)
