"""Concurrent source-owned result updates must not overwrite each other."""
from pathlib import Path
import select
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / "Scripts/raw_result_lock.py"

class RawResultLockTests(unittest.TestCase):
    def helper(self, path):
        process = subprocess.Popen([sys.executable, str(SCRIPT), str(path)],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.addCleanup(self.close_process, process)
        return process

    @staticmethod
    def close_process(process):
        if process.poll() is None:
            process.kill()
        process.wait(timeout=5)
        for stream in (process.stdin, process.stdout, process.stderr):
            stream.close()

    def test_mutual_exclusion_and_release(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "Results.lock"
            first = self.helper(path)
            self.assertEqual(first.stdout.readline().strip(), "LOCKED")
            second = self.helper(path)
            self.assertEqual(select.select([second.stdout], [], [], 0.15)[0], [])
            first.stdin.write("\n")
            first.stdin.flush()
            first.wait(timeout=5)
            self.assertEqual(second.stdout.readline().strip(), "LOCKED")

    def test_process_death_releases_lock(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "Results.lock"
            first = self.helper(path)
            self.assertEqual(first.stdout.readline().strip(), "LOCKED")
            first.kill()
            first.wait(timeout=5)
            second = self.helper(path)
            self.assertEqual(second.stdout.readline().strip(), "LOCKED")

if __name__ == "__main__":
    unittest.main()
