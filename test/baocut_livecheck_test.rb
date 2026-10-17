# typed: strict
# frozen_string_literal: true

# Setup: brew install-bundler-gems --add-groups=formula_test,livecheck
# Run with: brew ruby test/baocut_livecheck_test.rb
require "cask/cask_loader"
require "livecheck/livecheck"
require "minitest/autorun"

class BaoCutLivecheckTest < Minitest::Test
  FEED_URL = "https://github.com/JimLiu/baocut/releases/latest/download/appcast-aarch64-apple-darwin.json"

  def setup
    source = File.read(File.expand_path("../Casks/b/baocut.rb", __dir__))
    @cask = Cask::CaskLoader::FromContentLoader.new(source).load(config: nil)
    # Relevant fields from the official 3.8.0 build 77 macOS appcast.
    @appcast = { "schema" => 1, "target" => "aarch64-apple-darwin", "version" => "3.8.0", "build" => 77 }
  end

  def test_detects_the_published_macos_release
    assert_equal "3.8.0,77", latest_version
  end

  def test_detects_a_new_version_without_changing_the_feed_url
    @appcast["version"] = "3.9.0"
    @appcast["build"] = 80

    assert_equal "3.9.0,80", latest_version
  end

  def test_preserves_build_only_updates
    @appcast["build"] = 78

    assert_equal "3.8.0,78", latest_version
  end

  def test_accepts_a_string_build_number
    @appcast["build"] = "77"

    assert_equal "3.8.0,77", latest_version
  end

  def test_rejects_incomplete_releases
    missing_values = [nil, ""]
    %w[version build].each do |field|
      original = @appcast.fetch(field)
      missing_values.each do |missing|
        @appcast[field] = missing
        assert_nil latest_version, "must not offer an update with #{field}=#{missing.inspect}"
      end
      @appcast[field] = original
    end
  end

  private

  def latest_version
    # Stub only HTTP: exercise Homebrew's real cask, strategy selection and JSON
    # parsing. The retired baocut.app endpoint must still reproduce its 404.
    content = JSON.generate(@appcast)
    response = lambda do |url, **_options|
      if url == FEED_URL
        { content: }
      else
        { messages: ["HTTP 404: #{url}"] }
      end
    end

    strategy = Homebrew::Livecheck::Strategy
    original = strategy.method(:page_content)
    strategy.define_singleton_method(:page_content, response)
    result = Homebrew::Livecheck.latest_version(@cask, json: true)
    refute_equal "error", result&.dig(:status), result&.dig(:messages)&.join("\n")
    result&.dig(:latest)&.to_s
  ensure
    strategy.define_singleton_method(:page_content, original)
  end
end
