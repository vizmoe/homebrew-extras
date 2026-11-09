class GoGrip < Formula
  desc "Preview Markdown files locally with GitHub styling"
  homepage "https://github.com/chrishrb/go-grip"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/chrishrb/go-grip/releases/download/v0.11.0/go-grip-v0.11.0-darwin-arm64.tar.gz"
      sha256 "120d61d9487edc21bd460fa7fa9f4679b2387157e6f005a605cdde9613d5e188"
    end

    on_intel do
      url "https://github.com/chrishrb/go-grip/releases/download/v0.11.0/go-grip-v0.11.0-darwin-amd64.tar.gz"
      sha256 "1d2444e6027c046b462705eb624da45efd2b3914011a31623fb2c4a4e2f3f635"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chrishrb/go-grip/releases/download/v0.11.0/go-grip-v0.11.0-linux-arm64.tar.gz"
      sha256 "d3d4379891a64b9562c3d878b47718eadafee0768c5522def3c72eea9f21ffb0"
    end

    on_intel do
      url "https://github.com/chrishrb/go-grip/releases/download/v0.11.0/go-grip-v0.11.0-linux-amd64.tar.gz"
      sha256 "2e02783d537e078066e2bc45b2ab78521d4148f21a2c71021cf5eed1166111dc"
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
