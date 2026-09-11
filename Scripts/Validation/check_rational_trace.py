"""Compare two rational traces at supplied finite-field points.

This pinned Ratracer evaluator produced inconsistent results with small moduli.
Require prime moduli in the checked 63-bit range. Other finite-field backends
have their own modulus requirements.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
import time

from sympy import isprime

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from wolfram import atomic_json, select_cpus

ROOT = Path(__file__).resolve().parents[2]


def validate_request(request):
    samples = request["Samples"]
    mapping = request["OutputNameMap"]
    if (not samples or not isinstance(mapping, dict) or not mapping
            or len(set(mapping.values())) != len(mapping)):
        raise ValueError("Nonempty samples and a one-to-one output map are required.")
    for point in samples:
        prime, values = point["Prime"], point["Values"]
        if type(prime) is not int or not (1 << 62) < prime < (1 << 63) or not isprime(prime):
            raise ValueError("This Ratracer check requires a prime modulus between 2^62 and 2^63.")
        if not isinstance(values, dict) or not values or any(
                not isinstance(name, str) or not name or type(value) is not int
                for name, value in values.items()):
            raise ValueError("Each sample must assign integers to named trace variables.")
    for key in ("OriginalTrace", "AlternativeTrace"):
        if not Path(request[key]).is_file():
            raise ValueError(f"Missing {key}.")


def read_values(path):
    text = path.read_text()
    matches = list(re.finditer(r"(?m)^(.+) =\n\s+([0-9]+);\s*", text))
    if (not matches or matches[0].start() != 0 or matches[-1].end() != len(text)
            or any(a.end() != b.start() for a, b in zip(matches, matches[1:]))):
        raise ValueError("Invalid or partial native evaluation output.")
    values = {m[1]: int(m[2]) for m in matches}
    if len(values) != len(matches):
        raise ValueError("Duplicate native evaluation output.")
    return values


def compare(request, directory):
    validate_request(request)
    directory = Path(directory).resolve()
    directory.mkdir(parents=True, exist_ok=True)
    executable = request.get("Executable", str(ROOT / "Addon/Other_Addon/Ratracer/bin/ratracer"))
    cpu = select_cpus(request.get("CpuSet", [0]))
    atomic_json(directory / "Report.json", {"Status": "Running", "Passed": False})
    timings, results = {}, {}
    for name, key in (("Original", "OriginalTrace"), ("Alternative", "AlternativeTrace")):
        input_names_file = directory / f"{name}Inputs.txt"
        args = ["taskset", "-c", ",".join(map(str, cpu)), executable, "load-trace", request[key],
                "list-inputs", "--to=" + str(input_names_file)]
        paths = []
        for index, point in enumerate(request["Samples"]):
            path = directory / f"{name}_{index}.txt"
            paths.append(path)
            args += ["evaluate-modular", "--modulus=" + str(point["Prime"])]
            for variable, value in point["Values"].items():
                args += ["--set", variable, str(value)]
            args += ["--to=" + str(path)]
        atomic_json(directory / f"{name}Command.json", args)
        started = time.monotonic()
        with (directory / f"{name}.log").open("w") as log:
            subprocess.run(args, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                           check=True, timeout=request.get("TimeoutSeconds", 120))
        timings[name] = time.monotonic() - started
        input_rows = [line.split(" ", 1) for line in input_names_file.read_text().splitlines()]
        if any(len(row) != 2 or row[0] != str(index) for index, row in enumerate(input_rows)):
            raise ValueError("Invalid native input inventory.")
        input_names = {row[1] for row in input_rows}
        if any(not input_names.issubset(point["Values"]) for point in request["Samples"]):
            raise ValueError("A trace input variable was not assigned.")
        results[name] = [read_values(path) for path in paths]
    checks = []
    for index, (a, b) in enumerate(zip(results["Original"], results["Alternative"])):
        for source, target in request["OutputNameMap"].items():
            if source not in a or target not in b:
                raise ValueError("A requested output is absent.")
            checks.append({"Sample": index, "Original": source, "Alternative": target,
                           "Equal": a[source] == b[target]})
    report = {"Status": "Complete", "Passed": all(row["Equal"] for row in checks), "Comparisons": len(checks),
              "Seconds": timings, "Checks": checks,
              "Method": "Probabilistic identity validation by exact modular evaluations."}
    atomic_json(directory / "Report.json", report)
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("request")
    parser.add_argument("output")
    args = parser.parse_args()
    request = json.loads(Path(args.request).read_text())
    report = compare(request, args.output)
    print(f"RATIONAL TRACE CHECK {report['Comparisons']} comparisons, passed={report['Passed']}")
    raise SystemExit(0 if report["Passed"] else 1)
