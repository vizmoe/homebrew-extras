"""Delivery contracts; GitHub HTTP is replaced, orchestration runs unchanged."""

import copy
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, call, patch


SCRIPT = Path(__file__).resolve().parents[1] / ".github/scripts/bump-prs.py"
SPEC = importlib.util.spec_from_file_location("bump_prs", SCRIPT)
delivery = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(delivery)


def setUpModule():
    # Fixture failures must not become real Actions annotations or summary rows.
    quiet = patch.object(delivery, "notice")
    quiet.start()
    unittest.addModuleCleanup(quiet.stop)


BEFORE = 'cask "example" do\n  version "1.0"\n  sha256 "' + "a" * 64 + '"\n  url "https://example.com/#{version}.dmg"\nend\n'
AFTER = BEFORE.replace('"1.0"', '"1.1"').replace("a" * 64, "b" * 64)
PR = {
    "number": 4, "state": "open", "draft": False, "user": {"login": "github-actions[bot]"},
    "head": {"ref": "bump-example-1.1", "sha": "a" * 40, "repo": {"full_name": "owner/homebrew-test"}},
    "base": {"ref": "main", "sha": "b" * 40, "repo": {"full_name": "owner/homebrew-test"}},
    "mergeable": True, "mergeable_state": "clean", "body": "Closes #20",
}
RUN = {
    "id": 100, "event": "workflow_dispatch", "status": "completed", "conclusion": "success",
    "head_sha": PR["head"]["sha"], "head_branch": PR["head"]["ref"],
    "head_repository": {"full_name": "owner/homebrew-test"}, "workflow_id": 10,
    "html_url": "https://github.com/owner/homebrew-test/actions/runs/100",
}


class ReleaseScopeTest(unittest.TestCase):
    def test_version_and_checksums_only(self):
        self.assertTrue(delivery.release_change(BEFORE, AFTER))
        before = BEFORE.replace('sha256 "' + "a" * 64 + '"', 'sha256 arm:   "' + "a" * 64 + '",\n         intel: "' + "c" * 64 + '"')
        after = before.replace('"1.0"', '"1.1"').replace("a" * 64, "b" * 64).replace("c" * 64, "d" * 64)
        self.assertTrue(delivery.release_change(before, after))

    def test_executable_or_metadata_changes_are_rejected(self):
        for changed in [AFTER.replace("example.com", "evil.example"), AFTER + 'system "unexpected"\n',
                        AFTER.replace("b" * 64, "#{system('unexpected')}"),
                        AFTER.replace('"1.1"', '"#{system(1)}"'),
                        AFTER.replace('sha256 "' + "b" * 64 + '"', "sha256 :no_check"),
                        AFTER.replace('"1.1"', '"1.0"')]:
            with self.subTest(changed=changed):
                self.assertFalse(delivery.release_change(BEFORE, changed))


class DeliveryTest(unittest.TestCase):
    def setUp(self):
        self.pr = copy.deepcopy(PR)
        self.run = copy.deepcopy(RUN)
        self.api = Mock(repo="owner/homebrew-test", default_branch="main")
        self.api.workflow.return_value = {"id": 10}
        self.api.runs.return_value = []
        self.api.get_run.return_value = self.run
        self.api.pull.return_value = self.pr
        self.api.pulls.return_value = [self.pr]
        self.api.jobs.return_value = [
            {"name": "test-bot (macos-26)", "conclusion": "success"},
            {"name": "test-bot (ubuntu-latest, ghcr.io/homebrew/brew:main)", "conclusion": "success"},
        ]
        self.api.reviews.return_value = []
        self.api.merge.return_value = {"merged": True}
        self.api.current_checks.return_value = True
        self.api.request.return_value = {"state": "closed"}

    def test_dispatches_ci_for_bot_pr_without_approval(self):
        delivery.dispatch_ci(self.api, self.pr)
        self.api.dispatch.assert_called_once_with("tests.yml", self.pr["head"]["ref"],
                                                  {"pull_request": "4", "head_sha": "a" * 40})

    def test_no_duplicate_dispatch_for_active_same_head(self):
        for status in ["queued", "in_progress", "waiting"]:
            with self.subTest(status=status):
                self.api.dispatch.reset_mock()
                self.api.runs.return_value = [dict(self.run, status=status, conclusion=None)]
                delivery.dispatch_ci(self.api, self.pr)
                self.api.dispatch.assert_not_called()

    def test_expired_pr_run_does_not_block_explicit_dispatch(self):
        self.api.runs.return_value = [dict(self.run, event="pull_request", conclusion="failure")]
        delivery.dispatch_ci(self.api, self.pr)
        self.api.dispatch.assert_called_once()

    def test_successful_current_head_is_merged_with_sha(self):
        self.api.runs.return_value = [self.run]
        with patch.object(delivery, "inspect_pr", return_value="example", create=True):
            self.assertTrue(delivery.merge_run(self.api, 100))
        self.api.merge.assert_called_once_with(4, "a" * 40)

    def test_confirmed_merge_closes_its_single_open_issue(self):
        self.api.runs.return_value = [self.run]
        self.api.request.return_value = {"number": 20, "state": "open"}
        with patch.object(delivery, "inspect_pr", return_value="example"):
            self.assertTrue(delivery.merge_run(self.api, 100))
        self.api.request.assert_any_call("/issues/20", "PATCH", {"state": "closed", "state_reason": "completed"})
        calls = self.api.mock_calls
        self.assertLess(calls.index(call.merge(4, "a" * 40)),
                        calls.index(call.request("/issues/20", "PATCH", {"state": "closed", "state_reason": "completed"})))

    def test_refused_merge_never_closes_an_issue(self):
        self.api.runs.return_value = [self.run]
        self.api.merge.return_value = {"merged": False}
        with patch.object(delivery, "inspect_pr", return_value="example"), \
             self.assertRaisesRegex(ValueError, "refused to merge"):
            delivery.merge_run(self.api, 100)
        self.api.request.assert_not_called()

    def test_failed_incomplete_wrong_workflow_or_foreign_run_never_merges(self):
        for changes in [{"conclusion": "failure"}, {"status": "in_progress"},
                        {"event": "pull_request"}, {"workflow_id": 11},
                        {"head_repository": {"full_name": "attacker/fork"}}]:
            with self.subTest(changes=changes):
                self.api.merge.reset_mock()
                self.api.get_run.return_value = dict(self.run, **changes)
                self.api.runs.return_value = [self.api.get_run.return_value]
                with patch.object(delivery, "inspect_pr", return_value="example", create=True):
                    self.assertFalse(delivery.merge_run(self.api, 100))
                self.api.merge.assert_not_called()

    def test_missing_or_failed_matrix_job_never_merges(self):
        for jobs in [[], [{"name": "test-bot (macos-26)", "conclusion": "success"}],
                     [dict(j, conclusion="skipped") for j in self.api.jobs.return_value]]:
            with self.subTest(jobs=jobs):
                self.api.jobs.return_value = jobs
                self.api.runs.return_value = [self.run]
                with patch.object(delivery, "inspect_pr", return_value="example", create=True):
                    self.assertFalse(delivery.merge_run(self.api, 100))
                self.api.merge.assert_not_called()

    def test_changed_head_blocking_review_and_repository_gate_stop_merge(self):
        cases = [({"head": dict(self.pr["head"], sha="c" * 40)}, []),
                 ({"mergeable_state": "blocked"}, []), ({"draft": True}, []),
                 ({}, [{"user": {"login": "reviewer"}, "state": "CHANGES_REQUESTED"}])]
        for changes, reviews in cases:
            with self.subTest(changes=changes, reviews=reviews):
                self.api.pull.return_value = dict(self.pr, **changes)
                self.api.reviews.return_value = reviews
                self.api.runs.return_value = [self.run]
                with patch.object(delivery, "inspect_pr", return_value="example", create=True):
                    self.assertFalse(delivery.merge_run(self.api, 100))
                self.api.merge.assert_not_called()

    def test_newer_run_supersedes_old_success(self):
        self.api.runs.return_value = [dict(self.run, id=101, status="in_progress", conclusion=None), self.run]
        with patch.object(delivery, "inspect_pr", return_value="example", create=True):
            self.assertFalse(delivery.merge_run(self.api, 100))
        self.api.merge.assert_not_called()

    def test_outdated_ci_definitions_require_refresh(self):
        self.api.current_checks.return_value = False
        self.api.runs.return_value = [self.run]
        with patch.object(delivery, "inspect_pr", return_value="example"):
            self.assertFalse(delivery.merge_run(self.api, 100))
        self.api.merge.assert_not_called()

    def approval_only_suite(self):
        self.pr["mergeable_state"] = "unstable"
        self.run["check_suite_id"] = 100
        native = dict(self.run, id=99, event="pull_request", conclusion="action_required", check_suite_id=99)
        self.api.runs.return_value = [self.run, native]
        self.checks = [dict(job, status="completed") for job in self.api.jobs.return_value]
        self.suites = [
            {"id": 100, "conclusion": "success", "app": {"slug": "github-actions"}},
            {"id": 99, "conclusion": "action_required", "app": {"slug": "github-actions"}},
            {"id": 98, "conclusion": None, "app": {"slug": "vercel"}},
        ]
        self.api.pages.side_effect = lambda path, key: self.checks if key == "check_runs" else self.suites
        self.api.request.return_value = {"statuses": [], "state": "closed"}

    def test_successful_dispatch_replaces_the_duplicate_approval_only_suite(self):
        self.approval_only_suite()
        with patch.object(delivery, "inspect_pr", return_value="example"):
            self.assertTrue(delivery.merge_run(self.api, 100))
        self.api.merge.assert_called_once_with(4, "a" * 40)

    def test_actual_failed_or_running_checks_still_block_the_merge(self):
        for status, conclusion in [("in_progress", None), ("completed", "failure"), ("completed", "skipped")]:
            with self.subTest(status=status, conclusion=conclusion):
                self.approval_only_suite()
                self.checks.append({"name": "another check", "status": status, "conclusion": conclusion})
                with patch.object(delivery, "inspect_pr", return_value="example"):
                    self.assertFalse(delivery.merge_run(self.api, 100))
        self.api.merge.assert_not_called()

    def test_failed_status_or_unknown_failed_suite_still_blocks_the_merge(self):
        self.approval_only_suite()
        self.api.request.return_value = {"statuses": [{"context": "external", "state": "failure"}]}
        with patch.object(delivery, "inspect_pr", return_value="example"):
            self.assertFalse(delivery.merge_run(self.api, 100))
        self.api.request.return_value = {"statuses": []}
        self.suites.append({"id": 101, "conclusion": "failure", "app": {"slug": "github-actions"}})
        with patch.object(delivery, "inspect_pr", return_value="example"):
            self.assertFalse(delivery.merge_run(self.api, 100))
        self.api.merge.assert_not_called()

    def test_only_superseded_dispatches_of_the_same_workflow_can_be_replaced(self):
        self.approval_only_suite()
        self.api.runs.return_value.append(dict(self.run, id=97, conclusion="failure", check_suite_id=97))
        self.suites.append({"id": 97, "conclusion": "failure", "app": {"slug": "github-actions"}})
        with patch.object(delivery, "inspect_pr", return_value="example"):
            self.assertTrue(delivery.merge_run(self.api, 100))
        self.api.merge.assert_called_once_with(4, "a" * 40)

    def test_other_unstable_states_and_blocking_reviews_remain_blocked(self):
        self.approval_only_suite()
        self.api.runs.return_value = [self.run]
        with patch.object(delivery, "inspect_pr", return_value="example"):
            self.assertFalse(delivery.merge_run(self.api, 100))
        self.approval_only_suite()
        self.api.reviews.return_value = [{"user": {"login": "reviewer"}, "state": "CHANGES_REQUESTED"}]
        with patch.object(delivery, "inspect_pr", return_value="example"):
            self.assertFalse(delivery.merge_run(self.api, 100))
        self.api.merge.assert_not_called()

    def test_merge_worker_waits_for_ci_and_uses_all_existing_merge_gates(self):
        queued = dict(self.run, status="in_progress", conclusion=None)
        self.api.runs.side_effect = [[queued], [self.run], [self.run]]
        with patch.object(delivery, "inspect_pr", return_value="example"), patch("time.sleep") as sleep:
            delivery.merge_pending(self.api, attempts=3)
        sleep.assert_called_once()
        self.api.merge.assert_called_once_with(4, "a" * 40)

    def test_merge_worker_reports_failed_ci_without_merging(self):
        self.api.runs.return_value = [dict(self.run, conclusion="failure")]
        with patch.object(delivery, "inspect_pr", return_value="example"), \
             self.assertRaisesRegex(ValueError, "CI failed"):
            delivery.merge_pending(self.api, attempts=2)
        self.api.merge.assert_not_called()

    def test_merge_worker_rejects_changed_heads(self):
        self.api.pull.return_value = dict(self.pr, head=dict(self.pr["head"], sha="c" * 40))
        with patch.object(delivery, "inspect_pr", return_value="example"), \
             self.assertRaisesRegex(ValueError, "head changed"):
            delivery.merge_pending(self.api, attempts=2)
        self.api.merge.assert_not_called()

    def test_merge_worker_times_out_when_ci_is_missing_or_gates_do_not_clear(self):
        for runs in [[], [self.run]]:
            self.api.runs.return_value = runs
            self.api.current_checks.return_value = False
            with self.subTest(runs=runs), patch.object(delivery, "inspect_pr", return_value="example"), \
                 patch("time.sleep"), self.assertRaisesRegex(ValueError, "Timed out"):
                delivery.merge_pending(self.api, attempts=2)
            self.api.merge.assert_not_called()

    def test_merge_worker_continues_healthy_updates_after_a_failed_ci(self):
        healthy = copy.deepcopy(self.pr)
        healthy["number"] = 5
        healthy["head"].update(sha="c" * 40, ref="bump-healthy-1.1")
        healthy_run = dict(self.run, id=101, head_sha="c" * 40, head_branch=healthy["head"]["ref"])
        self.api.pulls.return_value = [self.pr, healthy]
        self.api.pull.side_effect = lambda number: healthy if number == 5 else self.pr
        self.api.runs.side_effect = lambda sha: [healthy_run] if sha == "c" * 40 else [dict(self.run, conclusion="failure")]
        self.api.get_run.return_value = healthy_run
        with patch.object(delivery, "inspect_pr", return_value="example"), \
             self.assertRaisesRegex(ValueError, "CI failed"):
            delivery.merge_pending(self.api, attempts=2)
        self.api.merge.assert_called_once_with(5, "c" * 40)


class ScopeInspectionTest(unittest.TestCase):
    def setUp(self):
        self.api = Mock(repo="owner/homebrew-test", default_branch="main")
        self.pr = copy.deepcopy(PR)
        self.api.pages.return_value = [{"filename": "Casks/e/example.rb", "status": "modified"}]
        self.api.request.return_value = {"tree": [{"path": "Casks/e/example.rb", "mode": "100644"}]}
        self.api.content.side_effect = [BEFORE, AFTER]

    def test_complete_version_only_pr_is_eligible(self):
        self.assertEqual(delivery.inspect_pr(self.api, self.pr), "example")

    def test_foreign_human_draft_wrong_base_and_wrong_branch_are_rejected(self):
        cases = [{"user": {"login": "someone"}}, {"draft": True},
                 {"head": dict(self.pr["head"], repo={"full_name": "other/fork"})},
                 {"head": dict(self.pr["head"], ref="bump-other-1.1")},
                 {"base": dict(self.pr["base"], ref="other")}]
        for changes in cases:
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                delivery.inspect_pr(self.api, dict(self.pr, **changes))

    def test_extra_files_renames_and_executable_mode_are_rejected(self):
        for files in [[], self.api.pages.return_value * 2,
                      [{"filename": ".github/workflows/tests.yml", "status": "modified"}],
                      [{"filename": "Casks/e/example.rb", "status": "renamed"}]]:
            self.api.pages.return_value = files
            with self.subTest(files=files), self.assertRaises(ValueError):
                delivery.inspect_pr(self.api, self.pr)
        self.api.pages.return_value = [{"filename": "Casks/e/example.rb", "status": "modified"}]
        self.api.request.return_value["tree"][0]["mode"] = "100755"
        with self.assertRaises(ValueError):
            delivery.inspect_pr(self.api, self.pr)

    def test_modified_download_origin_is_rejected(self):
        self.api.content.side_effect = [BEFORE, AFTER.replace("example.com", "evil.example")]
        with self.assertRaises(ValueError):
            delivery.inspect_pr(self.api, self.pr)


class ReleaseVerificationTest(unittest.TestCase):
    def setUp(self):
        self.api = Mock()
        self.api.pull.return_value = copy.deepcopy(PR)

    def test_all_architectures_are_downloaded_and_audited(self):
        with patch.object(delivery, "inspect_pr", return_value="example"), \
             patch.object(delivery, "live_versions", return_value={"example": {"current": "1.1", "latest": "1.1"}}), \
             patch.object(delivery, "command", return_value="a" * 40) as command:
            delivery.verify(self.api, 4, "a" * 40, "owner/test")
        command.assert_any_call("brew", "fetch", "--cask", "--arch=all", "--retry", "owner/test/example", capture=False)
        command.assert_any_call("brew", "audit", "--cask", "--online", "owner/test/example", capture=False)

    def test_stale_version_stops_validation(self):
        with patch.object(delivery, "inspect_pr", return_value="example"), \
             patch.object(delivery, "live_versions", return_value={"example": {"current": "1.1", "latest": "1.2"}}), \
             patch.object(delivery, "command", return_value="a" * 40) as command:
            with self.assertRaisesRegex(ValueError, "no longer the latest"):
                delivery.verify(self.api, 4, "a" * 40, "owner/test")
        self.assertEqual(command.call_count, 1)

    def test_dispatched_formula_tests_receive_verified_pr_base(self):
        with patch.object(delivery, "inspect_pr", return_value="example"), \
             patch.object(delivery, "command", return_value="a" * 40), \
             patch.object(delivery.subprocess, "run") as run:
            delivery.formulae(self.api, 4, "a" * 40)
        args, kwargs = run.call_args
        self.assertEqual(args[0], ["brew", "test-bot", "--only-formulae"])
        self.assertEqual(kwargs["env"].get("GITHUB_BASE_REF"), "main")
        self.assertTrue(kwargs["check"])

    def test_changed_pr_head_stops_formula_tests(self):
        with patch.object(delivery, "command", return_value="b" * 40), \
             patch.object(delivery.subprocess, "run") as run:
            with self.assertRaises(ValueError):
                delivery.formulae(self.api, 4, "a" * 40)
        run.assert_not_called()


class RefreshIntegrationTest(unittest.TestCase):
    """Real local Git origin/checkout; only the upstream Homebrew call is replaced."""

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.old_cwd = Path.cwd()
        self.root = Path(self.temp.name)
        self.git("init", "--bare", str(self.root / "origin.git"), cwd=self.root)
        self.repo = self.root / "checkout"
        self.repo.mkdir()
        os.chdir(self.repo)
        self.addCleanup(os.chdir, self.old_cwd)
        self.git("init", "-b", "main")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.invalid")
        # Temporary fixture commits must not depend on the user's signing agent.
        self.git("config", "commit.gpgsign", "false")
        self.path = Path("Casks/e/example.rb")
        self.path.parent.mkdir(parents=True)
        self.path.write_text(BEFORE)
        self.git("add", ".")
        self.git("commit", "-m", "base")
        self.git("remote", "add", "origin", str(self.root / "origin.git"))
        self.git("push", "-u", "origin", "main")
        self.git("switch", "-c", "bump-example-1.1")
        self.path.write_text(AFTER)
        self.git("commit", "-am", "old update")
        self.git("push", "-u", "origin", "bump-example-1.1")
        self.pr = copy.deepcopy(PR)
        self.pr["head"]["sha"] = self.git("rev-parse", "HEAD").strip()
        self.git("switch", "main")
        Path("ci-contract").write_text("new checks\n")
        self.git("add", ".")
        self.git("commit", "-m", "new CI")
        self.git("push", "origin", "main")
        self.start = self.git("rev-parse", "HEAD").strip()
        self.api = Mock(default_branch="main")
        self.api.pull.side_effect = self.visible_pr

    def visible_pr(self, _number):
        pr = copy.deepcopy(self.pr)
        pr["head"]["sha"] = self.git("rev-parse", "origin/bump-example-1.1").strip()
        return pr

    @staticmethod
    def git(*args, cwd=None):
        return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, check=True).stdout

    def test_refresh_keeps_pr_branch_and_restores_checkout(self):
        real_command = delivery.command

        def run(*args, **kwargs):
            if args[0] == "brew":
                self.assertIn("--version=1.2", args)
                self.path.write_text(AFTER.replace('"1.1"', '"1.2"').replace("b" * 64, "c" * 64))
                return ""
            return real_command(*args, **kwargs)

        with patch.object(delivery, "command", side_effect=run):
            delivery.refresh(self.api, self.pr, "example", "1.2", "owner/test")
        self.assertEqual(self.git("rev-parse", "HEAD").strip(), self.start)
        self.assertEqual(self.git("status", "--porcelain"), "")
        refreshed = self.git("show", "origin/bump-example-1.1:Casks/e/example.rb")
        self.assertIn('version "1.2"', refreshed)
        self.assertEqual(self.git("show", "origin/bump-example-1.1:ci-contract"), "new checks\n")
        self.assertTrue(delivery.release_change(BEFORE, refreshed))

    def test_failed_download_does_not_push_or_contaminate_next_update(self):
        real_command = delivery.command

        def run(*args, **kwargs):
            if args[0] == "brew":
                self.path.write_text("incomplete download update\n")
                raise subprocess.CalledProcessError(1, args)
            return real_command(*args, **kwargs)

        with patch.object(delivery, "command", side_effect=run), self.assertRaises(subprocess.CalledProcessError):
            delivery.refresh(self.api, self.pr, "example", "1.2", "owner/test")
        self.assertEqual(self.git("rev-parse", "HEAD").strip(), self.start)
        self.assertEqual(self.git("status", "--porcelain"), "")
        self.assertEqual(self.git("rev-parse", "origin/bump-example-1.1").strip(), self.pr["head"]["sha"])

    def test_refresh_waits_for_the_pushed_head_to_be_visible(self):
        def read(number):
            return self.pr if self.api.pull.call_count == 1 else self.visible_pr(number)

        self.api.pull.side_effect = read
        with patch("time.sleep"):
            result = delivery.refresh(self.api, self.pr, "example", "1.1", "owner/test")
        self.assertEqual(result["head"]["sha"], self.visible_pr(4)["head"]["sha"])
        self.assertEqual(self.api.pull.call_count, 2)
        self.assertEqual(self.git("rev-parse", "HEAD").strip(), self.start)

    def test_refresh_fails_if_the_pushed_head_never_becomes_visible(self):
        self.api.pull.side_effect = None
        self.api.pull.return_value = self.pr
        with patch("time.sleep"), self.assertRaisesRegex(ValueError, "not visible"):
            delivery.refresh(self.api, self.pr, "example", "1.1", "owner/test")
        self.assertLessEqual(self.api.pull.call_count, 10)
        self.assertEqual(self.git("rev-parse", "HEAD").strip(), self.start)

    def test_refresh_rejects_a_concurrent_change_to_the_pr_head(self):
        changed = copy.deepcopy(self.pr)
        changed["head"]["sha"] = "f" * 40
        self.api.pull.side_effect = None
        self.api.pull.return_value = changed
        with patch("time.sleep"), self.assertRaisesRegex(ValueError, "changed after refresh"):
            delivery.refresh(self.api, self.pr, "example", "1.1", "owner/test")
        self.assertEqual(self.git("rev-parse", "HEAD").strip(), self.start)


class IssueCloseoutTest(unittest.TestCase):
    def setUp(self):
        self.api = Mock(repo="owner/homebrew-test", default_branch="main")
        self.pr = dict(copy.deepcopy(PR), state="closed", merged=True, merged_at="2026-10-17T09:53:37Z")
        self.issue = {"number": 20, "state": "open"}
        self.api.pulls.return_value = []
        self.api.pull.return_value = self.pr
        self.api.request.return_value = self.issue
        self.api.pages.side_effect = lambda path: [self.issue] if path.startswith("/issues?") else [self.pr]

    def prepare(self):
        with patch.object(delivery, "live_versions", return_value={}):
            delivery.prepare(self.api, "owner/test")

    def test_next_updater_recovers_an_issue_left_open_after_a_merge(self):
        self.prepare()
        self.api.request.assert_any_call("/issues/20", "PATCH", {"state": "closed", "state_reason": "completed"})

    def test_closed_issues_are_not_written_again(self):
        self.api.request.return_value = {"number": 20, "state": "closed"}
        self.prepare()
        self.api.request.assert_called_once_with("/issues/20")

    def test_unmerged_foreign_human_or_ambiguous_prs_do_not_close_issues(self):
        cases = [{"merged": False}, {"state": "open"}, {"merged_at": None},
                 {"user": {"login": "someone"}}, {"draft": True},
                 {"head": dict(self.pr["head"], repo={"full_name": "other/fork"})},
                 {"base": dict(self.pr["base"], ref="other")},
                 {"body": "Closes #20\nCloses #21"}, {"body": "Refs #20"}]
        for changes in cases:
            with self.subTest(changes=changes):
                original = self.pr
                self.pr = dict(original, **changes)
                self.api.pull.return_value = self.pr
                self.api.request.reset_mock()
                self.prepare()
                self.api.request.assert_not_called()
                self.pr = original

    def test_issue_close_failure_is_reported_and_retried_on_next_run(self):
        self.api.request.side_effect = [self.issue, subprocess.CalledProcessError(1, "gh")]
        with self.assertRaises(subprocess.CalledProcessError):
            self.prepare()
        self.api.request.side_effect = None
        self.prepare()
        self.api.request.assert_any_call("/issues/20", "PATCH", {"state": "closed", "state_reason": "completed"})

    def test_pull_request_references_are_not_closed_as_issues(self):
        self.issue["pull_request"] = {"url": "https://example.invalid/pr/20"}
        self.prepare()
        self.api.request.assert_not_called()


class ReconciliationTest(unittest.TestCase):
    def test_one_invalid_pr_does_not_stop_healthy_updates(self):
        api = Mock(repo="owner/homebrew-test", default_branch="main")
        first, second = copy.deepcopy(PR), copy.deepcopy(PR)
        second["number"] = 5
        api.pulls.return_value = [first, second]
        api.pull.side_effect = [first, second]
        refreshed = copy.deepcopy(second)
        refreshed["head"]["sha"] = "d" * 40
        with patch.object(delivery, "live_versions", return_value={"example": {"latest": "1.2"}}), \
             patch.object(delivery, "inspect_pr", side_effect=[ValueError("extra file"), "example", "example"]), \
             patch.object(delivery, "ensure_issue") as issue, \
             patch.object(delivery, "refresh", return_value=refreshed) as refresh, \
             patch.object(delivery, "dispatch_ci") as dispatch:
            with self.assertRaisesRegex(ValueError, "1 cask delivery failure"):
                delivery.reconcile(api, "owner/test")
        issue.assert_called_once_with(api, "example", "1.2", second)
        refresh.assert_called_once_with(api, second, "example", "1.2", "owner/test")
        dispatch.assert_called_once_with(api, refreshed)
        api.dispatch.assert_called_once_with("automerge.yml", "main", {})


if __name__ == "__main__":
    unittest.main()
