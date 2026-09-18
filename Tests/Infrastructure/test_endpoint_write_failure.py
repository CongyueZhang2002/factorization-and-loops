"""The real endpoint driver must not complete after its final plan write fails.

Run the actual final emission block with small prepared inputs. Mathematical
preparation has separate tests; this one isolates the last acceptance boundary.
"""
from pathlib import Path
import os
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts"))
from wolfram import run_wolfram

class EndpointWriteFailureTest(unittest.TestCase):
    def test_final_plan_write_is_required(self):
        driver = (ROOT / "Scripts/construct_ordered_endpoint_profiles.wls").read_text()
        start = 'Do[\n sourceCard=parentCards[key];parts=StringSplit[key,"/"];'
        self.assertEqual(driver.count(start), 2)
        emission = driver[driver.rindex(start):]
        marker = "COMPLETED ORDERED ENDPOINT PROFILES"
        self.assertIn(marker, emission)
        fixture = r"""Print["FEYNFACET DRIVER ENTERED"];
root="/unused";
key="Fixture/NNLO/q-q/DoubleReal";
parentCards=<|key-><|"StructureFunctions"->{"F"},"WorkDirectory"->"/unused"|>|>;
coefficient=<|"SourceProcessDefinitions"-><|key-><|"Fixture"->True|>|>|>;
bulkVector=<||>;profiles=<||>;prepared=<|"ProjectionConditions"-><||>|>;rules={};
check[value_,stage_]:=If[!AssociationQ[value],Print["INVALID FIXTURE ",stage];Exit[2]];
FeynFacet`ReadContributionCard[_,_]:=<|"WorkDirectory"->"/unused"|>;
FeynFacet`CreateEndpointIntegrationInput[___]:=<|"Fixture"->"Input"|>;
FeynFacet`CreateContributionIntegrationPlan[___]:=<|"Fixture"->"Plan"|>;
"""
        with tempfile.TemporaryDirectory(prefix="feynfacet-endpoint-write-") as directory:
            work = Path(directory)
            for fail in (False, True):
                with self.subTest(failed_plan_write=fail):
                    write = ('FeynFacet`FamilyArtifactWrite[_,path_]:='
                             + ('If[StringEndsQ[path,"/IntegrationPlan.wl"],$Failed,path];'
                                if fail else 'path;'))
                    script = work / ("failure.wls" if fail else "success.wls")
                    log = script.with_suffix(".log")
                    script.write_text(fixture + write + "\n" + emission)
                    result = run_wolfram(script, [], logfile=log, completion=marker,
                                         cpus=[0], timeout=60)
                    output = log.read_text(errors="replace")
                    self.assertNotIn("INVALID FIXTURE", output)
                    if fail:
                        self.assertEqual(result["ReturnCode"], 1)
                        self.assertFalse(result["Passed"])
                        self.assertIn("Required integration plan write failed", output)
                        self.assertNotIn(marker, output)
                    else:
                        self.assertTrue(result["Passed"], output)

if __name__ == "__main__":
    unittest.main()
