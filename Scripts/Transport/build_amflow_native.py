#!/usr/bin/env python3
"""Build the upstream AMFlow C++ solver in a separate, writable installation.

The source installation is never changed. Dependencies must already exist in
the system or in --dependency-prefix (an extracted development installation).
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import shlex
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--wstp", required=True, type=Path)
    parser.add_argument("--dependency-prefix", type=Path)
    parser.add_argument("--jobs", type=int, default=1, choices=range(1, 9))
    args = parser.parse_args()
    source, destination = args.source.resolve(), args.destination.resolve()
    if source == destination or source in destination.parents:
        parser.error("destination must be outside the upstream source tree")
    if not (args.wstp / "CompilerAdditions/wsprep").is_file():
        parser.error("WSTP Developer Kit not found")
    if (destination / "feynfacet_native_build.json").exists():
        parser.error("use a new destination for a new build; existing workers may still use this runtime")
    solver = destination / "diffeq_solver"
    destination.mkdir(parents=True, exist_ok=True)
    solver.mkdir(exist_ok=True)
    for name in ("AMFlow.m", "README.md", "LICENSE.md", "CHANGELOG.md", "options_summary"):
        if (source / name).is_file():
            shutil.copy2(source / name, destination / name)
    interface = destination / "ibp_interface"
    if not interface.exists():
        interface.symlink_to(source / "ibp_interface", target_is_directory=True)
    for name in ("include", "src", "check"):
        shutil.copytree(source / "diffeq_solver" / name, solver / name, dirs_exist_ok=True)
    for name in ("DESolver.m", "Makefile"):
        shutil.copy2(source / "diffeq_solver" / name, solver / name)
    config = [f"WSLINKDIR={args.wstp.resolve()}"]
    environment = os.environ.copy()
    if args.dependency_prefix:
        prefix = args.dependency_prefix.resolve()
        inc, lib = prefix / "usr/include", prefix / "usr/lib/x86_64-linux-gnu"
        for package in ("MPC", "BOOST"):
            config.append(f"AMFLOW_{package}_INCLUDE={inc}")
        config.append(f"AMFLOW_MPC_LIB={lib}")
        environment["LD_LIBRARY_PATH"] = str(lib) + ":" + environment.get("LD_LIBRARY_PATH", "")
        mpsolve = prefix / "usr/bin/mpsolve"
        library_setup = "export LD_LIBRARY_PATH=" + shlex.quote(str(lib)) + ':${LD_LIBRARY_PATH:-}\n'
    else:
        mpsolve = shutil.which("mpsolve")
        library_setup = ""
    if not mpsolve or not Path(mpsolve).is_file():
        parser.error("MPSolve is required in PATH or --dependency-prefix/usr/bin")
    # MPSolve has its own thread pool; OPENMP=no alone does not constrain it.
    wrapper = destination / "mpsolve"
    wrapper.write_text("#!/bin/sh\n" + library_setup + "exec " +
                       shlex.quote(str(mpsolve)) + ' -j 1 "$@"\n')
    wrapper.chmod(0o755)
    config.append(f"MPSOLVE={wrapper}")
    (solver / "config").write_text("\n".join(config) + "\n")
    if (solver / "link.bin").exists():
        (solver / "link.bin").replace(solver / "link")
    # Serial native arithmetic matches the one-core-per-family scheduler.
    subprocess.run(["make", f"-j{args.jobs}", "OPENMP=no", "link"],
                   cwd=solver, env=environment, check=True)
    if args.dependency_prefix:
        binary = solver / "link"
        native = solver / "link.bin"
        binary.replace(native)
        binary.write_text("#!/bin/sh\nexport LD_LIBRARY_PATH=" +
                          shlex.quote(str(lib)) + ':${LD_LIBRARY_PATH:-}\nexec ' +
                          shlex.quote(str(native)) + ' "$@"\n')
        binary.chmod(0o755)
    metadata = {"SourceDirectory": str(source), "WSTPDeveloperKit": str(args.wstp.resolve()),
                "OpenMP": False, "MPSolveThreads": 1, "BuildJobs": args.jobs,
                "DependencyPrefix": str(args.dependency_prefix.resolve()) if args.dependency_prefix else None}
    (destination / "feynfacet_native_build.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(json.dumps(metadata), flush=True)


if __name__ == "__main__":
    main()
