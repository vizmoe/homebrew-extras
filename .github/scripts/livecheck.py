"""Bounded retries for read-only Homebrew version queries."""

import json
import re
import subprocess
import sys
import time


TRANSIENT = re.compile(
    r"curl: \((?:5|6|7|18|28|35|52|55|56)\)"
    r"|(?:returned error:|HTTP(?:/\S+)?(?: error| status)?)\s*(?:408|429|500|502|503|504)\b",
    re.IGNORECASE,
)


def transient_failure(result):
    messages = []
    if result.stdout.strip():
        try:
            entries = json.loads(result.stdout)
        except ValueError:
            return False
        if not isinstance(entries, list) or not entries:
            return False
        for entry in entries:
            if not isinstance(entry, dict):
                return False
            if entry.get("status") == "error":
                details = entry.get("messages", [])
                if not isinstance(details, list) or not details:
                    return False
                messages.extend(str(message) for message in details)
    if result.returncode and result.stderr.strip():
        messages.append(result.stderr.strip())
    return bool(messages) and all(TRANSIENT.search(message) for message in messages)


def run_livecheck(tap):
    delays = (2, 5)
    for attempt in range(len(delays) + 1):
        try:
            result = subprocess.run(
                ["brew", "livecheck", "--json", "--autobump", f"--tap={tap}"],
                capture_output=True,
                encoding="utf-8",
                errors="replace",
                check=False,
                timeout=180,
            )
        except subprocess.TimeoutExpired:
            if attempt == len(delays):
                raise
        else:
            if attempt == len(delays) or not transient_failure(result):
                return result
        print(f"Retrying read-only brew livecheck after a transient failure ({attempt + 1}/{len(delays)}).", file=sys.stderr)
        time.sleep(delays[attempt])
