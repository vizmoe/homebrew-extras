"""Exercise the workflow reporter CLI; only the brew executable is replaced."""

import contextlib
import io
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / ".github/scripts/check-livecheck.py"
HEALTHY = {
    "cask": "baocut",
    "version": {"current": "3.8.0,77", "latest": "3.8.0,77", "outdated": False},
}
ERROR = {
    "cask": "baocut",
    "status": "error",
    "messages": ["curl: (22) The requested URL returned error: 404"],
    "meta": {"livecheck_defined": True},
}


class LivecheckReportTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.summary = self.directory / "summary.md"
        self.arguments = self.directory / "arguments.txt"
        brew = self.directory / "brew"
        brew.write_text(
            '#!/bin/sh\n'
            'printf "%s\\n" "$@" > "$FAKE_BREW_ARGUMENTS"\n'
            'printf "%s" "$FAKE_BREW_STDOUT"\n'
            'printf "%s" "$FAKE_BREW_STDERR" >&2\n'
            'exit "$FAKE_BREW_EXIT"\n',
            encoding="utf-8",
        )
        brew.chmod(0o755)

    def run_report(self, payload, *, returncode=0, stderr="", raw=False, summary_path=None):
        summary_path = summary_path or self.summary
        if summary_path.is_file():
            summary_path.unlink()
        env = dict(os.environ)
        env.update(
            PATH=f"{self.directory}{os.pathsep}{env['PATH']}",
            GITHUB_STEP_SUMMARY=str(summary_path),
            FAKE_BREW_ARGUMENTS=str(self.arguments),
            FAKE_BREW_STDOUT=payload if raw else json.dumps(payload),
            FAKE_BREW_STDERR=stderr,
            FAKE_BREW_EXIT=str(returncode),
        )
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "vizmoe/extras"],
            env=env,
            capture_output=True,
            text=True,
            check=False,
            timeout=10,
        )
        summary = summary_path.read_text() if summary_path.is_file() else ""
        return result, summary

    def test_zero_exit_with_historical_404_is_a_visible_failure(self):
        result, summary = self.run_report([ERROR])
        self.assertEqual(result.returncode, 1)
        self.assertIn("::warning", result.stdout)
        self.assertIn("baocut", result.stdout)
        self.assertIn("404", result.stdout)
        self.assertIn("Failed", summary)
        self.assertIn("404", summary)

    def test_checks_formulae_and_casks_without_failing_for_updates(self):
        formula = {
            "formula": "go-grip",
            "version": {"current": "0.10.0", "latest": "0.11.0", "outdated": True},
        }
        result, summary = self.run_report([HEALTHY, formula])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("::warning", result.stdout)
        self.assertIn("baocut", summary)
        self.assertIn("go-grip", summary)
        self.assertIn("0.11.0", summary)
        self.assertIn("Update available", summary)
        self.assertEqual(
            self.arguments.read_text().splitlines(),
            ["livecheck", "--json", "--autobump", "--tap=vizmoe/extras"],
        )

    def test_reports_healthy_packages_alongside_all_errors(self):
        another_error = {"formula": "broken", "status": "error", "messages": ["No versions"]}
        result, summary = self.run_report([HEALTHY, another_error, ERROR])
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.count("::warning"), 2)
        self.assertIn("3.8.0,77", summary)
        self.assertIn("broken", summary)
        self.assertIn("No versions", summary)

    def test_missing_latest_version_fails_even_without_an_error_status(self):
        for version in (None, {}, {"latest": None}, {"latest": ""}, {"latest": "  "}):
            with self.subTest(version=version):
                result, summary = self.run_report([{"cask": "empty", "version": version}])
                self.assertEqual(result.returncode, 1)
                self.assertIn("empty", result.stdout)
                self.assertIn("latest version", summary)

    def test_intentional_skips_are_visible_without_false_alarms(self):
        statuses = ("skipped", "deprecated", "disabled", "versioned", "latest", "unversioned")
        payload = [
            {"cask": status, "status": status, "messages": ["Intentional skip"]}
            for status in statuses
        ]
        result, summary = self.run_report(payload)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("::warning", result.stdout)
        for status in statuses:
            self.assertIn(status, summary)
        self.assertIn("Intentional skip", summary)

    def test_invalid_or_empty_reports_fail_explicitly(self):
        for payload in ("", "not json", "null", "{}", "[]", '["bad entry"]', '[{}]'):
            with self.subTest(payload=payload):
                result, summary = self.run_report(payload, raw=True)
                self.assertEqual(result.returncode, 1)
                self.assertIn("::warning", result.stdout)
                self.assertIn("Failed", summary)

    def test_command_failure_is_not_hidden_by_valid_json(self):
        result, summary = self.run_report([HEALTHY], returncode=2, stderr="GitHub API unavailable")
        self.assertEqual(result.returncode, 1)
        self.assertIn("exit status 2", summary)
        self.assertIn("GitHub API unavailable", summary)
        self.assertIn("baocut", summary)

    def test_unknown_or_malformed_statuses_fail_explicitly(self):
        for status in ("unexpected", ["error"], {"error": True}):
            with self.subTest(status=status):
                result, summary = self.run_report([{"cask": "broken", "status": status}])
                self.assertEqual(result.returncode, 1)
                self.assertIn("::warning", result.stdout)
                self.assertIn("broken", summary)

    def test_a_tap_version_newer_than_upstream_is_reported_accurately(self):
        entry = {
            "cask": "ahead",
            "version": {"current": "2.0", "latest": "1.0", "newer_than_upstream": True},
        }
        result, summary = self.run_report([entry])
        self.assertEqual(result.returncode, 0)
        self.assertIn("Tap newer than upstream", summary)

    def test_unwritable_summary_is_an_explicit_failure(self):
        result, _ = self.run_report([HEALTHY], summary_path=self.directory)
        self.assertEqual(result.returncode, 1)
        self.assertIn("Unable to write job summary", result.stdout)

    def test_missing_brew_and_timeouts_produce_annotations(self):
        reporter = runpy.run_path(str(SCRIPT))
        for error in (FileNotFoundError("brew not found"), subprocess.TimeoutExpired("brew", 600)):
            with self.subTest(error=error):
                output = io.StringIO()
                with (
                    mock.patch("subprocess.run", side_effect=error),
                    mock.patch.dict(os.environ, {"GITHUB_STEP_SUMMARY": str(self.summary)}),
                    contextlib.redirect_stdout(output),
                ):
                    result = reporter["main"](["vizmoe/extras"])
                self.assertEqual(result, 1)
                self.assertIn("::warning", output.getvalue())
                self.assertIn("Unable to run brew livecheck", self.summary.read_text())

    def test_diagnostics_cannot_inject_workflow_commands_or_table_rows(self):
        error = {
            "cask": "broken",
            "status": "error",
            "messages": ["50% failed\r\n::error::injected | <tag>"],
        }
        result, summary = self.run_report([error])
        self.assertEqual(result.returncode, 1)
        self.assertIn("50%25 failed%0D%0A::error::injected", result.stdout)
        self.assertNotIn("\n::error::injected", result.stdout)
        self.assertIn("\\| &lt;tag&gt;", summary)
        self.assertNotIn("<tag>", summary)


if __name__ == "__main__":
    unittest.main()
