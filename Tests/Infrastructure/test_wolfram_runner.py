"""Failure cases of the common driver lifecycle, without starting Wolfram."""
from pathlib import Path
import os
import signal
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts"))
import wolfram


class WolframRunnerTests(unittest.TestCase):
    def test_completion_requires_current_entry_exit_and_marker(self):
        self.assertFalse(wolfram.completed(0, "COMPLETED OLD OUTPUT", "COMPLETED "))
        self.assertFalse(wolfram.completed(0, wolfram.ENTRY_MARKER, "COMPLETED "))
        self.assertFalse(wolfram.completed(1, wolfram.ENTRY_MARKER + "\nCOMPLETED X", "COMPLETED "))
        self.assertFalse(wolfram.completed(0, wolfram.ENTRY_MARKER + "\ntext COMPLETED X", "COMPLETED "))
        self.assertTrue(wolfram.completed(0, wolfram.ENTRY_MARKER + "\nCOMPLETED X", "COMPLETED "))

    def test_post_entry_license_failure_is_not_retried(self):
        failure = "No valid password found.\nConnection closed by WolframKernel."
        self.assertTrue(wolfram.startup_failure(255, failure))
        self.assertFalse(wolfram.startup_failure(255, wolfram.ENTRY_MARKER + "\n" + failure))

    def test_nonzero_cpu_allocation_is_respected(self):
        with patch.object(os, "sched_getaffinity", return_value={8, 9, 10}):
            self.assertEqual(wolfram.select_cpus(), [8, 9, 10])
            with self.assertRaises(ValueError):
                wolfram.select_cpus([0])
            with self.assertRaises(ValueError):
                wolfram.select_cpus([8, 8])

    def test_stale_log_cannot_supply_a_completion_marker(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            script = folder / "driver.wls"
            script.write_text("placeholder")
            logfile = folder / "driver.log"
            logfile.write_text(wolfram.ENTRY_MARKER + "\nCOMPLETED OLD OUTPUT\n")
            popen = subprocess.Popen

            def child(command, **kwargs):
                return popen([sys.executable, "-c", "print('FEYNFACET DRIVER ENTERED')"], **kwargs)

            with patch.object(wolfram.subprocess, "Popen", side_effect=child):
                result = wolfram.run_wolfram(script, [], logfile=logfile, completion="COMPLETED ")
            self.assertFalse(result["Passed"])
            self.assertNotIn("COMPLETED OLD OUTPUT", logfile.read_text())

    def test_assigned_cpu_ids_and_counts_reach_the_kernel_environment(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            script = folder / "driver.wls"
            script.write_text("placeholder")
            cpus = sorted(os.sched_getaffinity(0))[:4:2]
            seen = {}
            popen = subprocess.Popen

            def child(command, **kwargs):
                seen.update(kwargs["env"])
                self.assertEqual(command[:3], ["taskset", "-c", ",".join(map(str, cpus))])
                return popen([sys.executable, "-c",
                              "print('FEYNFACET DRIVER ENTERED'); print('COMPLETED TEST')"], **kwargs)

            with patch.object(wolfram.subprocess, "Popen", side_effect=child):
                result = wolfram.run_wolfram(script, [], logfile=folder / "run.log",
                                            completion="COMPLETED ", cpus=cpus)
            self.assertTrue(result["Passed"])
            self.assertEqual(seen["FACET_CPU_LIST"], ",".join(map(str, cpus)))
            self.assertEqual(seen["FACET_CPU_COUNT"], str(len(cpus)))
            self.assertEqual(seen["FACET_KERNEL_COUNT"], str(len(cpus)))

    def test_worker_is_stopped_after_launcher_has_exited(self):
        with tempfile.TemporaryDirectory() as directory:
            pidfile = Path(directory) / "worker.pid"
            launcher = subprocess.Popen([sys.executable, "-c",
                "import subprocess,sys; from pathlib import Path; "
                "p=subprocess.Popen([sys.executable,'-c','import time; time.sleep(60)']); "
                "Path(sys.argv[1]).write_text(str(p.pid))", str(pidfile)], start_new_session=True)
            launcher.wait(timeout=5)
            pid = int(pidfile.read_text())
            try:
                wolfram.stop_process_group(launcher, grace=0.2)
                status = Path(f"/proc/{pid}/stat")
                self.assertTrue(not status.exists() or status.read_text().split()[2] == "Z")
            finally:
                try:
                    os.kill(pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass


if __name__ == "__main__":
    unittest.main()
