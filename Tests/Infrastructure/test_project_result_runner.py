"""Channel scheduling and cancellation without starting a Wolfram kernel."""
from pathlib import Path
from contextlib import redirect_stdout, redirect_stderr
from io import StringIO
import json
import signal
import sys
import tempfile
import threading
import unittest
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/"Scripts"))
import run_project_results as runner

class ProjectResultRunner(unittest.TestCase):
    def cards(self, root, count):
        out=[]
        for i in range(count):
            card=root/"Projects"/"Example"/"Results"/"NLO"/f"channel{i}"/"Result_Card.wl"
            card.parent.mkdir(parents=True);card.write_text("<||>")
            out.append(card)
        return out

    def invoke(self, root, cards, function, mode="all"):
        args=["run_project_results",*map(str,cards),"--mode",mode,"--report",str(root/"Report.json")]
        with patch.object(runner,"ROOT",root),patch.object(runner,"select_cpus",return_value=list(range(8))),\
             patch.object(runner,"run_wolfram",side_effect=function),patch.object(sys,"argv",args),\
             redirect_stdout(StringIO()),redirect_stderr(StringIO()):
            return runner.main()

    def test_single_channel_gets_all_cpus_and_distinct_wall_timing(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);cards=self.cards(root,1)
            def run(script,args,**kw):
                self.assertEqual(kw["cpus"],list(range(8)))
                (cards[0].parent/"Timing.json").write_text(json.dumps({"Seconds":7.2,"Status":"Completed"}))
                return {"Passed":True,"Seconds":9.1,"ReturnCode":0,"Log":str(kw["logfile"])}
            self.assertEqual(self.invoke(root,cards,run),0)
            timing=json.loads((cards[0].parent/"Timing.json").read_text())
            self.assertEqual((timing["WolframSeconds"],timing["WallSeconds"]),(7.2,9.1))

    def test_simultaneous_channels_have_disjoint_cpu_allocations(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);cards=self.cards(root,2);barrier=threading.Barrier(2)
            allocations=[]
            def run(script,args,**kw):
                allocations.append(set(kw["cpus"]));barrier.wait(timeout=5)
                return {"Passed":True,"Seconds":1.0,"ReturnCode":0,"Log":str(kw["logfile"])}
            self.assertEqual(self.invoke(root,cards,run,mode="plan"),0)
            self.assertFalse(allocations[0]&allocations[1])
            self.assertEqual(allocations[0]|allocations[1],set(range(8)))

    def test_duplicate_cards_are_rejected_before_launch(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);card=self.cards(root,1)[0]
            with self.assertRaises(SystemExit) as error:
                self.invoke(root,[card,card],lambda *a,**k:self.fail("kernel launched"))
            self.assertEqual(error.exception.code,2)

    def test_cancellation_stops_queued_jobs_without_overwriting_old_logs(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);cards=self.cards(root,6);calls=[];previous=signal.getsignal(signal.SIGTERM)
            for card in cards:
                old=card.parent/"Validation/Regeneration.log";old.parent.mkdir();old.write_text("old accepted log")
            def run(script,args,**kw):
                calls.append(args[0])
                # Invoke the installed main-thread handler as a user termination would.
                signal.getsignal(signal.SIGTERM)(signal.SIGTERM,None)
                self.assertTrue(kw["cancel"].is_set())
                return {"Passed":False,"Seconds":1.0,"ReturnCode":130,"Log":str(kw["logfile"])}
            self.assertEqual(self.invoke(root,cards,run),130)
            self.assertLessEqual(len(calls),2)
            self.assertIs(signal.getsignal(signal.SIGTERM),previous)
            report=json.loads((root/"Report.json").read_text())
            self.assertTrue(report["Cancelled"]);self.assertEqual(report["Finished"],6)
            for card in cards:
                self.assertEqual((card.parent/"Validation/Regeneration.log").read_text(),"old accepted log")
if __name__=="__main__":unittest.main()
