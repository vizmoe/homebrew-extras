#!/usr/bin/env python3
"""Deliver automated cask updates after current-head CI succeeds.

The privileged commands run from the default branch. PR code only runs in the
read-only test workflow. GitHub's merge endpoint still enforces repository rules.
"""

import argparse
import base64
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from urllib.parse import urlencode


EXPECTED_JOBS = {"test-bot (macos-26)", "test-bot (ubuntu-latest, ghcr.io/homebrew/brew:main)"}
VALUE = re.compile(r'(?m)^([ \t]*(version|sha256(?:[ \t]+(?:arm|intel):)?|(?:arm|intel):)[ \t]+)"([^"\n]+)"(,?)$')
CASK_PATH = re.compile(r"Casks/[a-z0-9]/([a-z0-9][a-z0-9+@.-]*)\.rb")


def command(*args, capture=True):
    return subprocess.run(args, text=True, check=True, capture_output=capture).stdout


def notice(message, warning=False):
    print(message, flush=True)
    if warning:
        escaped = message.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
        print(f"::warning title=Cask delivery needs attention::{escaped}", flush=True)
    if summary := os.environ.get("GITHUB_STEP_SUMMARY"):
        with Path(summary).open("a", encoding="utf-8") as output:
            output.write(f"- {message}\n")


class GitHub:
    def __init__(self, repo):
        self.repo = repo
        self.default_branch = self.request("")["default_branch"]

    def request(self, path, method="GET", data=None):
        args = ["gh", "api", f"repos/{self.repo}{path}", "--method", method]
        if data is not None:
            args += ["--input", "-"]
        result = subprocess.run(args, input=json.dumps(data) if data is not None else None,
                                text=True, capture_output=True, check=True)
        return json.loads(result.stdout) if result.stdout.strip() else None

    def pages(self, path, key=None):
        entries = []
        for page in range(1, 101):
            data = self.request(f"{path}{'&' if '?' in path else '?'}per_page=100&page={page}")
            batch = data[key] if key else data
            entries.extend(batch)
            if len(batch) < 100:
                return entries
        raise ValueError("GitHub pagination limit reached")

    def pull(self, number):
        return self.request(f"/pulls/{number}")

    def pulls(self):
        return self.pages("/pulls?state=open")

    def workflow(self):
        return self.request("/actions/workflows/tests.yml")

    def runs(self, sha):
        return self.pages("/actions/workflows/tests.yml/runs?" + urlencode({"head_sha": sha}), "workflow_runs")

    def get_run(self, run_id):
        return self.request(f"/actions/runs/{run_id}")

    def jobs(self, run_id):
        return self.pages(f"/actions/runs/{run_id}/jobs", "jobs")

    def reviews(self, number):
        return self.pages(f"/pulls/{number}/reviews")

    def dispatch(self, workflow, branch, inputs):
        return self.request(f"/actions/workflows/{workflow}/dispatches", "POST", {"ref": branch, "inputs": inputs})

    def merge(self, number, sha):
        return self.request(f"/pulls/{number}/merge", "PUT", {"sha": sha, "merge_method": "squash"})

    def content(self, path, sha):
        data = self.request(f"/contents/{path}?" + urlencode({"ref": sha}))
        if data["type"] != "file" or data["encoding"] != "base64":
            raise ValueError(f"Not a regular text file: {path}")
        return base64.b64decode(data["content"]).decode("utf-8")

    def current_checks(self, sha):
        def entries(ref):
            tree = self.request(f"/git/trees/{ref}?recursive=1")
            if tree.get("truncated"):
                raise ValueError("Incomplete repository tree")
            return {e["path"]: (e["sha"], e["mode"]) for e in tree["tree"]
                    if e["type"] == "blob" and e["path"].startswith((".github/", "test/"))}
        return entries(sha) == entries(self.default_branch)


def release_change(before, after):
    def mask(text):
        versions = []
        checksums = []

        def replace(match):
            prefix, field, value, comma = match.groups()
            if field == "version":
                if not re.fullmatch(r"[0-9][0-9A-Za-z.,_+-]*", value):
                    raise ValueError("Invalid literal version")
                versions.append(value)
            else:
                if not re.fullmatch(r"[a-f0-9]{64}", value):
                    raise ValueError("A literal SHA-256 is required")
                checksums.append(value)
            return f'{prefix}"RELEASE_VALUE"{comma}'

        normalized = VALUE.sub(replace, text)
        if len(versions) != 1 or not checksums:
            raise ValueError("Expected one version and at least one checksum")
        return normalized, versions[0]

    try:
        old, old_version = mask(before)
        new, new_version = mask(after)
        return old == new and old_version != new_version
    except ValueError:
        return False


def candidate(api, pr):
    return (pr["state"] == "open" and not pr["draft"]
            and pr["user"]["login"] == "github-actions[bot]"
            and pr["base"]["ref"] == api.default_branch
            and pr["base"]["repo"]["full_name"] == api.repo
            and (pr["head"].get("repo") or {}).get("full_name") == api.repo
            and pr["head"]["ref"].startswith("bump-"))


def inspect_pr(api, pr):
    if not candidate(api, pr):
        raise ValueError("Not an eligible same-repository bot update")
    files = api.pages(f'/pulls/{pr["number"]}/files')
    if len(files) != 1 or files[0]["status"] != "modified":
        raise ValueError("Expected exactly one modified cask")
    path = files[0]["filename"]
    match = CASK_PATH.fullmatch(path)
    if not match or not pr["head"]["ref"].startswith(f"bump-{match[1]}-"):
        raise ValueError("Cask path and bump branch do not match")
    for sha in [pr["base"]["sha"], pr["head"]["sha"]]:
        tree = api.request(f"/git/trees/{sha}?recursive=1")
        if tree.get("truncated") or not any(e["path"] == path and e["mode"] == "100644" for e in tree["tree"]):
            raise ValueError("Cask must remain a regular non-executable file")
    if not release_change(api.content(path, pr["base"]["sha"]), api.content(path, pr["head"]["sha"])):
        raise ValueError("Update changes more than the literal version and SHA-256 values")
    return match[1]


def dispatch_ci(api, pr):
    runs = [r for r in api.runs(pr["head"]["sha"]) if r["event"] == "workflow_dispatch"]
    if runs and runs[0]["status"] != "completed":
        notice(f'PR #{pr["number"]}: CI already {runs[0]["status"]} for {pr["head"]["sha"]}.')
        return False
    if runs and runs[0]["conclusion"] == "success":
        return merge_run(api, runs[0]["id"])
    api.dispatch("tests.yml", pr["head"]["ref"], {"pull_request": str(pr["number"]), "head_sha": pr["head"]["sha"]})
    notice(f'PR #{pr["number"]}: dispatched CI for {pr["head"]["sha"]}.')
    return True


def merge_run(api, run_id):
    run = api.get_run(run_id)
    if (run["event"] != "workflow_dispatch" or run["status"] != "completed" or run["conclusion"] != "success"
            or run["workflow_id"] != api.workflow()["id"]
            or (run.get("head_repository") or {}).get("full_name") != api.repo):
        return False
    latest = [r for r in api.runs(run["head_sha"]) if r["event"] == "workflow_dispatch"]
    if not latest or latest[0]["id"] != run_id:
        return False
    jobs = api.jobs(run_id)
    if {j["name"] for j in jobs} != EXPECTED_JOBS or any(j["conclusion"] != "success" for j in jobs):
        return False
    matches = [p for p in api.pulls() if p["head"]["ref"] == run["head_branch"]]
    if len(matches) != 1:
        return False
    pr = api.pull(matches[0]["number"])
    if (not candidate(api, pr) or pr["head"]["sha"] != run["head_sha"]
            or pr["mergeable"] is not True or pr["mergeable_state"] != "clean"):
        notice(f'PR #{pr["number"]}: head changed or merge/review/check gates are not clear; retained for the next run.', True)
        return False
    inspect_pr(api, pr)
    # Historical PRs must include the current checks, not an older, weaker CI.
    if not api.current_checks(pr["head"]["sha"]):
        notice(f'PR #{pr["number"]}: CI definitions are out of date; updater must refresh the branch.', True)
        return False
    decisions = {}
    for review in api.reviews(pr["number"]):
        if review["state"] != "COMMENTED":
            decisions[review["user"]["login"]] = review["state"]
    if "CHANGES_REQUESTED" in decisions.values():
        notice(f'PR #{pr["number"]}: unresolved change request; not merged.', True)
        return False
    if not api.merge(pr["number"], run["head_sha"]).get("merged"):
        raise ValueError(f'GitHub refused to merge PR #{pr["number"]}')
    notice(f'Merged PR #{pr["number"]} at verified head {run["head_sha"]}; CI: {run["html_url"]}.')
    return True


def live_versions(tap):
    entries = json.loads(command("brew", "livecheck", "--json", "--autobump", f"--tap={tap}"))
    if not isinstance(entries, list) or not entries:
        raise ValueError("Missing livecheck results")
    return {e["cask"]: e["version"] for e in entries if isinstance(e, dict) and e.get("cask")
            and not e.get("status") and isinstance(e.get("version"), dict)
            and isinstance(e["version"].get("latest"), str) and e["version"]["latest"].strip()}


def merge_pending(api, attempts=120):
    pending = {}
    failures = []

    def failed(message):
        notice(message, True)
        failures.append(message)

    for pr in api.pulls():
        if not candidate(api, pr):
            continue
        try:
            inspect_pr(api, pr)
            pending[pr["number"]] = pr["head"]["sha"]
        except (ValueError, subprocess.CalledProcessError) as error:
            failed(f'PR #{pr["number"]}: {error}')

    for attempt in range(attempts):
        for number, sha in list(pending.items()):
            try:
                pr = api.pull(number)
                if pr["state"] != "open":
                    del pending[number]
                    continue
                if pr["head"]["sha"] != sha:
                    raise ValueError("PR head changed while waiting; updater must restart verification")
                runs = [r for r in api.runs(sha) if r["event"] == "workflow_dispatch"]
                if not runs or runs[0]["status"] != "completed":
                    continue
                if runs[0]["conclusion"] != "success":
                    raise ValueError(f'CI failed: {runs[0]["html_url"]}')
                if merge_run(api, runs[0]["id"]):
                    del pending[number]
            except (ValueError, subprocess.CalledProcessError) as error:
                failed(f"PR #{number}: {error}")
                del pending[number]
        if not pending:
            break
        if attempt < attempts - 1:
            time.sleep(15)

    for number, sha in pending.items():
        failed(f"PR #{number}: Timed out waiting for CI/merge gates at {sha}; rerun the updater")
    if failures:
        raise ValueError("; ".join(failures))


def ensure_issue(api, name, version, pr=None):
    body = (pr.get("body") or "") if pr else ""
    closing = re.findall(r"(?im)^Closes #(\d+)\s*$", body)
    if len(closing) == 1:
        return int(closing[0])
    if closing:
        raise ValueError("Expected exactly one primary leaf issue")
    marker = f"<!-- cask-update:{name} -->"
    matches = [i for i in api.pages("/issues?state=open") if "pull_request" not in i and marker in (i.get("body") or "")]
    if len(matches) > 1:
        raise ValueError(f"Multiple update issues for {name}")
    issue = matches[0] if matches else api.request("/issues", "POST", {
        "title": f"Update {name} to {version}",
        "body": f"{marker}\n\nUpdate only the {name} cask to the latest stable release. Verify livecheck, all architecture downloads/checksums, and macOS/Linux CI before merging its single-package PR. Preserve existing installation behavior; compatibility changes require manual review.",
    })
    if pr:
        api.request(f'/pulls/{pr["number"]}', "PATCH", {"body": body + f'\n\nCloses #{issue["number"]}\n'})
    return issue["number"]


def prepare(api, tap):
    pulls = api.pulls()
    for name, version in live_versions(tap).items():
        if version.get("outdated"):
            matches = [p for p in pulls if candidate(api, p) and p["head"]["ref"].startswith(f"bump-{name}-")]
            ensure_issue(api, name, version["latest"], matches[0] if len(matches) == 1 else None)


def refresh(api, pr, name, latest, tap):
    start = command("git", "rev-parse", "HEAD").strip()
    branch = pr["head"]["ref"]
    try:
        command("git", "fetch", "origin", api.default_branch, branch)
        command("git", "checkout", "--detach", f"origin/{branch}")
        if command("git", "rev-parse", "HEAD").strip() != pr["head"]["sha"]:
            raise ValueError("PR changed before refresh")
        command("git", "merge", "--no-edit", f"origin/{api.default_branch}", capture=False)
        path = next(Path("Casks").glob(f"*/{name}.rb"))
        current = re.search(r'^  version "([^"]+)"$', path.read_text(), re.M)[1]
        if current != latest:
            command("brew", "bump-cask-pr", "--write-only", f"--version={latest}", f"{tap}/{name}", capture=False)
            changed = command("git", "diff", "--name-only").splitlines()
            if changed != [str(path)]:
                raise ValueError("Refresh modified unexpected files")
            command("git", "add", "--", str(path))
            command("git", "commit", "-m", f"{name} {latest}")
        if not release_change(command("git", "show", f"origin/{api.default_branch}:{path}"), path.read_text()):
            raise ValueError("Refreshed cask is not a version/checksum-only update")
        head = command("git", "rev-parse", "HEAD").strip()
        if head != pr["head"]["sha"]:
            command("git", "push", "origin", f"HEAD:refs/heads/{branch}", capture=False)
        api.request(f'/pulls/{pr["number"]}', "PATCH", {"title": f"{name} {latest}"})
        # GitHub can briefly return the old PR head after accepting the push.
        for attempt in range(10):
            updated = api.pull(pr["number"])
            if updated["head"]["sha"] == head:
                return updated
            if updated["head"]["sha"] != pr["head"]["sha"]:
                raise ValueError("PR changed after refresh; refusing to dispatch CI")
            if attempt < 9:
                time.sleep(3)
        raise ValueError(f"Pushed PR head {head} is not visible; rerun the updater")
    finally:
        # Only a dedicated Actions checkout may run refresh. Do not reset user work.
        command("git", "reset", "--hard", start)
        command("git", "checkout", "--detach", start)


def reconcile(api, tap):
    versions = live_versions(tap)
    failures = []
    pending_updates = False
    for listed in api.pulls():
        if not candidate(api, listed):
            continue
        pending_updates = True
        try:
            pr = api.pull(listed["number"])
            name = inspect_pr(api, pr)
            latest = versions.get(name, {}).get("latest")
            if not latest:
                raise ValueError(f"Unable to determine latest {name} version")
            if versions[name].get("newer_than_upstream"):
                raise ValueError(f"Refusing to downgrade {name}: tap is newer than upstream")
            ensure_issue(api, name, latest, pr)
            pr = refresh(api, pr, name, latest, tap)
            inspect_pr(api, pr)
            dispatch_ci(api, pr)
        except (ValueError, subprocess.CalledProcessError) as error:
            message = f'PR #{listed["number"]}: {error}'
            notice(message, True)
            failures.append(message)
    # Token-triggered runs may not emit workflow_run. Explicit dispatch does.
    if pending_updates:
        api.dispatch("automerge.yml", api.default_branch, {})
        notice("Started the default-branch merge worker to wait for current-head CI.")
    if failures:
        raise ValueError(f"{len(failures)} cask delivery failure(s)")


def verify(api, number, sha, tap):
    pr = api.pull(number)
    if pr["head"]["sha"] != sha or command("git", "rev-parse", "HEAD").strip() != sha:
        raise ValueError("Requested PR head changed")
    name = inspect_pr(api, pr)
    version = live_versions(tap).get(name, {})
    if not version.get("latest") or version.get("current") != version["latest"]:
        raise ValueError(f"{name} is no longer the latest stable release")
    command("brew", "fetch", "--cask", "--arch=all", "--retry", f"{tap}/{name}", capture=False)
    command("brew", "audit", "--cask", "--online", f"{tap}/{name}", capture=False)


def formulae(api, number, sha):
    pr = api.pull(number)
    if pr["head"]["sha"] != sha or command("git", "rev-parse", "HEAD").strip() != sha:
        raise ValueError("Requested PR head changed")
    inspect_pr(api, pr)
    # Homebrew detects a PR's diff through GITHUB_BASE_REF, which dispatch lacks.
    env = dict(os.environ, GITHUB_BASE_REF=pr["base"]["ref"])
    subprocess.run(["brew", "test-bot", "--only-formulae"], env=env, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=["prepare", "reconcile", "merge", "merge-pending", "verify", "formulae"])
    parser.add_argument("--tap", default=os.environ.get("TAP_NAME"))
    parser.add_argument("--pr", type=int)
    parser.add_argument("--sha")
    parser.add_argument("--run-id", type=int)
    args = parser.parse_args()
    api = GitHub(os.environ["GITHUB_REPOSITORY"])
    if args.operation == "merge":
        merge_run(api, args.run_id)
    elif args.operation == "merge-pending":
        merge_pending(api)
    elif args.operation == "verify":
        verify(api, args.pr, args.sha, args.tap)
    elif args.operation == "formulae":
        formulae(api, args.pr, args.sha)
    elif args.operation == "prepare":
        prepare(api, args.tap)
    else:
        if os.environ.get("GITHUB_ACTIONS") != "true" or command("git", "status", "--porcelain").strip():
            raise ValueError("Refreshing PRs requires a clean, dedicated Actions checkout")
        reconcile(api, args.tap)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, subprocess.CalledProcessError) as error:
        notice(str(error), warning=True)
        sys.exit(1)
