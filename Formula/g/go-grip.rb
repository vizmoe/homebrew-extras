class GoGrip < Formula
  desc "Preview Markdown files locally with GitHub styling"
  homepage "https://github.com/chrishrb/go-grip"
  license "MIT"
  revision 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/chrishrb/go-grip/releases/download/v0.10.0/go-grip-v0.10.0-darwin-arm64.tar.gz"
      sha256 "006c11f55b11798a98e54101cf0e2a7f4174719aef7e9ff80578a909cc458cdc"
    end

    on_intel do
      url "https://github.com/chrishrb/go-grip/releases/download/v0.10.0/go-grip-v0.10.0-darwin-amd64.tar.gz"
      sha256 "835d512fe8c40e54c3059bacc210e32a81a5cc9f51494641bff7d6846c4352d4"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chrishrb/go-grip/releases/download/v0.10.0/go-grip-v0.10.0-linux-arm64.tar.gz"
      sha256 "14e516e1dd885973efa85b7f25548b654db77ca1b924155bd0e0ab6bc22a923b"
    end

    on_intel do
      url "https://github.com/chrishrb/go-grip/releases/download/v0.10.0/go-grip-v0.10.0-linux-amd64.tar.gz"
      sha256 "8065eec0230e7258a15dcce6c9c920bdd555a6d3ed4a2eddc74ca61f67ce9ef8"
    end
  end

  def install
    bin.install "go-grip"
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
