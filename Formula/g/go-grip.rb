class GoGrip < Formula
  desc "Preview Markdown files locally with GitHub styling"
  homepage "https://github.com/chrishrb/go-grip"
  url "https://github.com/chrishrb/go-grip/archive/refs/tags/v0.10.0.tar.gz"
  sha256 "15fe41b2c2e6c3d8ace76acb0b53871ec5045f22ab663f4d31ad300cf178cdde"
  license "MIT"
  head "https://github.com/chrishrb/go-grip.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "go" => :build

  def install
    ldflags = "-X github.com/chrishrb/go-grip/cmd.version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/go-grip --version")

    (testpath/"README.md").write("# Preview\n\nHello **Homebrew**!\n")
    port = free_port
    pid = fork do
      exec bin/"go-grip", "--browser=false", "--no-reload", "--host=127.0.0.1", "--port=#{port}", "README.md"
    end

    output = shell_output("curl --silent --show-error --fail --retry 5 --retry-connrefused " \
                          "--retry-delay 1 http://127.0.0.1:#{port}/README.md")
    assert_match "<strong>Homebrew</strong>", output
  ensure
    Process.kill("TERM", pid) if pid
    Process.wait(pid) if pid
  end
end
