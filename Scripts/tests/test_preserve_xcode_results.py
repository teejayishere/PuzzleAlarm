import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location("preserver", Path(__file__).parents[1] / "preserve_xcode_results.py")
preserver = importlib.util.module_from_spec(spec)
spec.loader.exec_module(preserver)


class PreservationTests(unittest.TestCase):
    def test_final_objects_and_logs_are_frozen_without_live_staging(self):
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            result = root / "Shell.xcresult"
            (result / "Data").mkdir(parents=True)
            (result / "Data" / "data.object").write_bytes(b"retained attachment")
            (result / "Staging").mkdir()
            (result / "Staging" / "moving.tracev3").write_bytes(b"live diagnostics")
            log = root / "tests.log"; log.write_text("test failure must remain visible")
            output = root / "frozen"
            self.assertTrue(preserver.preserve(result, [log], output))
            # Later source changes cannot affect the files given to upload-artifact.
            (result / "Data" / "data.object").write_bytes(b"changed")
            (result / "Staging" / "moving.tracev3").unlink()
            log.write_text("changed")
            with zipfile.ZipFile(output / "xcresult.zip") as archive:
                self.assertEqual(archive.namelist(), ["Shell.xcresult/Data/data.object"])
                self.assertEqual(archive.read(archive.namelist()[0]), b"retained attachment")
            self.assertEqual((output / "tests.log").read_text(), "test failure must remain visible")
            manifest = json.loads((output / "manifest.json").read_text())
            self.assertEqual(manifest["errors"], [])
            self.assertEqual(len(manifest["excluded"]), 1)

    def test_missing_evidence_is_reported_and_cannot_pass(self):
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            self.assertFalse(preserver.preserve(root / "missing.xcresult", [root / "missing.log"], root / "frozen"))
            manifest = json.loads((root / "frozen" / "manifest.json").read_text())
            self.assertEqual(len(manifest["errors"]), 2)
            self.assertTrue((root / "frozen" / "xcresult.zip").exists())


if __name__ == "__main__":
    unittest.main()
