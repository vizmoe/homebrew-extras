#!/usr/bin/env python3
"""Report upstream version checks and fail on errors hidden by brew's exit code."""

import argparse
import html
import json
import os
from pathlib import Path
import subprocess
import sys


SKIP_STATUSES = {"skipped", "deprecated", "disabled", "versioned", "latest", "unversioned"}


def annotation(message):
    escaped = message.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print(f"::warning title=Upstream version check failed::{escaped}")


def table_cell(value):
    text = html.escape(str(value), quote=False).replace("|", "\\|")
    return text.replace("\r\n", "\n").replace("\r", "\n").replace("\n", "<br>")


def report(stdout, command_error=""):
    rows = []
    failures = []

    def fail(package, reason, current="—"):
        failures.append(f"{package}: {reason}")
        rows.append((package, current, "—", f"Failed: {reason}"))

    try:
        entries = json.loads(stdout)
        if not isinstance(entries, list) or not entries:
            raise ValueError("expected a nonempty list of package results")
    except ValueError as error:
        entries = []
        command_error = "; ".join(filter(None, [command_error, f"Invalid livecheck output: {error}"]))

    if command_error:
        fail("brew livecheck", command_error)

    for index, entry in enumerate(entries, start=1):
        package = None
        if isinstance(entry, dict):
            package = entry.get("cask") or entry.get("formula")
        if not isinstance(package, str) or not package.strip():
            fail(f"Result {index}", "Invalid package result: missing formula/cask name")
            continue

        status = entry.get("status")
        messages = entry.get("messages", [])
        reason = "; ".join(map(str, messages)) if isinstance(messages, list) else str(messages or "")
        version = entry.get("version")
        version = version if isinstance(version, dict) else {}
        current = version.get("current") or "—"
        latest = version.get("latest")

        if isinstance(status, str) and status in SKIP_STATUSES:
            rows.append((package, current, "—", f"Skipped ({status}): {reason}"))
        elif status == "error":
            fail(package, reason or "Unable to determine latest version", current)
        elif status:
            fail(package, reason or f"Unexpected livecheck status: {status}", current)
        elif not isinstance(latest, str) or not latest.strip():
            fail(package, "Unable to determine latest version", current)
        else:
            if version.get("outdated"):
                result = "Update available"
            elif version.get("newer_than_upstream"):
                result = "Tap newer than upstream"
            else:
                result = "Up to date"
            rows.append((package, current, latest, result))

    for message in failures:
        annotation(message)

    summary = "## Upstream version checks\n\n| Package | Current | Latest | Result |\n| --- | --- | --- | --- |\n"
    summary += "\n".join("| " + " | ".join(map(table_cell, row)) + " |" for row in rows)
    summary += f"\n\n{len(failures)} failure(s).\n"
    print(summary)
    if summary_path := os.environ.get("GITHUB_STEP_SUMMARY"):
        try:
            with Path(summary_path).open("a", encoding="utf-8") as output:
                output.write(summary)
        except OSError as error:
            annotation(f"Unable to write job summary: {error}")
            return 1
    return int(bool(failures))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tap", help="Homebrew tap, such as vizmoe/extras")
    args = parser.parse_args(argv)
    try:
        result = subprocess.run(
            ["brew", "livecheck", "--json", "--autobump", f"--tap={args.tap}"],
            capture_output=True,
            encoding="utf-8",
            errors="replace",
            check=False,
            timeout=600,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        return report("", f"Unable to run brew livecheck: {error}")

    command_error = ""
    if result.returncode:
        command_error = f"brew livecheck exit status {result.returncode}: {result.stderr.strip()}"
    return report(result.stdout, command_error)


if __name__ == "__main__":
    sys.exit(main())
