# typed: strict
# frozen_string_literal: true

# Setup: brew install-bundler-gems --add-groups=formula_test,livecheck
# Run with: brew ruby test/clouddrive2_livecheck_test.rb
require "cask/cask_loader"
require "livecheck/livecheck"
require "utils/shared_audits"
require "minitest/autorun"

class CloudDrive2LivecheckTest < Minitest::Test
  def setup
    @source = File.read(File.expand_path("../Casks/c/clouddrive2.rb", __dir__))
    @cask = Cask::CaskLoader::FromContentLoader.new(@source).load(config: nil)
    # Official app-v1.1.3-22 metadata publishes macOS build 23 on both CPUs.
    @release = {
      "tag_name"   => "app-v1.1.3-22",
      "draft"      => false,
      "prerelease" => true,
      "assets"     => %w[arm64 x64].map { |arch| { "name" => "CloudDrive2-1.1.3-23-macos-#{arch}.dmg" } },
    }
  end

  def test_download_uses_the_tag_build_and_the_published_asset_build
    source = @source.sub(/version "[^"]+"/, 'version "1.1.3,23,22"')
    cask = Cask::CaskLoader::FromContentLoader.new(source).load(config: nil)

    assert_match %r{/app-v1\.1\.3-22/CloudDrive2-1\.1\.3-23-macos-(?:arm64|x64)\.dmg$}, cask.url.to_s
  end

  def test_detects_published_assets_on_the_existing_prerelease_channel
    assert_equal "1.1.3,23,22", latest_version
  end

  def test_detects_a_replaced_asset_build_without_a_new_tag
    @release["assets"].each { |asset| asset["name"].sub!("-23-", "-24-") }
    assert_equal "1.1.3,24,22", latest_version
  end

  def test_selects_the_newest_app_tag_numerically_and_ignores_server_tags
    @tags = %w[app-v1.1.3-9 v99.0.0 app-v1.1.2-90 app-v1.1.3-22]
    assert_equal "1.1.3,23,22", latest_version
  end

  def test_detects_a_new_version_with_matching_tag_and_asset_builds
    @release["tag_name"] = "app-v1.2.0-30"
    @release["prerelease"] = false
    @release["assets"].each { |asset| asset["name"].sub!("1.1.3-23", "1.2.0-30") }
    assert_equal "1.2.0,30,30", latest_version
  end

  def test_ignores_draft_and_non_app_releases
    @release["draft"] = true
    assert_nil latest_version
    @release["draft"] = false
    @release["tag_name"] = "v9.0.0"
    assert_nil latest_version
  end

  def test_requires_matching_assets_for_both_architectures
    @release["assets"].last["name"].sub!("-23-", "-24-")
    assert_nil latest_version
    @release["assets"].pop
    assert_nil latest_version
  end

  def test_ignores_missing_metadata_and_assets_for_another_app_version
    @release["assets"] = [{ "name" => "SHA256SUMS-macos.txt" }, {}]
    assert_nil latest_version
    @release["assets"] = %w[arm64 x64].map { |arch| { "name" => "CloudDrive2-9.0.0-23-macos-#{arch}.dmg" } }
    assert_nil latest_version
    @release.delete("tag_name")
    assert_nil latest_version
  end

  def test_audits_both_stable_and_prerelease_app_releases
    assert_nil release_audit(prerelease: true)
    assert_nil release_audit(prerelease: false)
  end

  def test_release_channel_still_rejects_drafts
    [true, false].each do |prerelease|
      assert_match(/is a GitHub draft/, release_audit(prerelease:, draft: true))
    end
  end

  def test_release_exception_does_not_allow_other_casks_prereleases
    assert_match(/is a GitHub pre-release/, release_audit(prerelease: true, token: "unrelated"))
    assert_nil release_audit(prerelease: false, token: "unrelated")
  end

  private

  def release_audit(prerelease:, draft: false, token: "clouddrive2")
    # Exercise Homebrew's real release audit and tap exception reader. Only the
    # release HTTP response and the tap's checkout location are substituted.
    tap = Tap.fetch("test/clouddrive-audit")
    root = Pathname.new(File.expand_path("..", __dir__))
    tap.define_singleton_method(:path) { root }
    cask = Cask::CaskLoader::FromContentLoader.new(@source.sub('cask "clouddrive2"', "cask \"#{token}\"")).load(config: nil)
    cask.define_singleton_method(:tap) { tap }
    original_api = GitHub::API.method(:open_rest)
    cached_releases = SharedAudits.instance_variable_get(:@github_release_data)
    SharedAudits.instance_variable_set(:@github_release_data, nil)
    GitHub::API.define_singleton_method(:open_rest) { |_url| { "prerelease" => prerelease, "draft" => draft } }
    SharedAudits.github_release("cloud-fs", "cloud-fs.github.io", "app-v1.1.3-24", cask:)
  ensure
    GitHub::API.define_singleton_method(:open_rest, original_api)
    SharedAudits.instance_variable_set(:@github_release_data, cached_releases)
  end

  def latest_version
    # Replace only Git/HTTP transport; exercise Homebrew's real cask, tag parsing,
    # GitHub release URL construction, asset selection, and version comparison.
    tags = @tags || [@release["tag_name"]].compact
    content = tags.map { |tag| "#{"a" * 40}\trefs/tags/#{tag}" }.join("\n")
    release = @release
    test_case = self
    expected_url = "https://api.github.com/repos/cloud-fs/cloud-fs.github.io/releases/tags/#{release["tag_name"]}"
    response = lambda do |url, **_options|
      test_case.assert_equal expected_url, url
      release
    end
    strategy = Homebrew::Livecheck::Strategy::Git
    original = strategy.method(:ls_remote_tags)
    original_api = GitHub::API.method(:open_rest)
    strategy.define_singleton_method(:ls_remote_tags) { |_url| { content: } }
    GitHub::API.define_singleton_method(:open_rest, response)
    result = Homebrew::Livecheck.latest_version(@cask, json: true)
    refute_equal "error", result&.dig(:status), result&.dig(:messages)&.join("\n")
    result&.dig(:latest)&.to_s
  ensure
    strategy.define_singleton_method(:ls_remote_tags, original)
    GitHub::API.define_singleton_method(:open_rest, original_api)
  end
end
