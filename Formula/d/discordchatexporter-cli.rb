class DiscordchatexporterCli < Formula
  desc "Saves Discord chat logs to a file"
  homepage "https://github.com/Tyrrrz/DiscordChatExporter"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/Tyrrrz/DiscordChatExporter/releases/download/2.48/DiscordChatExporter.Cli.osx-arm64.zip"
      sha256 "623f9d2dce568e17a46b8fbd366a18dca49803d386216f4ba24507d2c000fee9"
    end

    on_intel do
      url "https://github.com/Tyrrrz/DiscordChatExporter/releases/download/2.48/DiscordChatExporter.Cli.osx-x64.zip"
      sha256 "91b4eae3525df85d084969004f3a287edad4eeaafd664e4869b26bb8422e2e88"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/Tyrrrz/DiscordChatExporter/releases/download/2.48/DiscordChatExporter.Cli.linux-arm64.zip"
      sha256 "02a47fc8e0192fd509fbb082aadd9322035b18feae96849699fefc424a1e3379"
    end

    on_intel do
      url "https://github.com/Tyrrrz/DiscordChatExporter/releases/download/2.48/DiscordChatExporter.Cli.linux-x64.zip"
      sha256 "3e253e28ec7ea034b2201443fa84571142945299296541ecbe196ffceef8bc3c"
    end
  end

  def install
    rm(Dir[
      "createdump",
      "DiscordChatExporter.Core.pdb",
      "libcoreclrtraceptprovider.so",
      "libmscordaccore.dylib",
      "libmscordaccore.so",
      "libmscordbi.dylib",
      "libmscordbi.so",
    ])
    libexec.install Dir["*"]
    chmod 0755, libexec/"DiscordChatExporter.Cli"

    if OS.mac?
      bin.install_symlink libexec/"DiscordChatExporter.Cli" => "discordchatexporter-cli"
    else
      (bin/"discordchatexporter-cli").write_env_script(
        libexec/"DiscordChatExporter.Cli",
        DOTNET_SYSTEM_GLOBALIZATION_INVARIANT: "${DOTNET_SYSTEM_GLOBALIZATION_INVARIANT:-1}",
      )
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/discordchatexporter-cli --version")
    assert_match "Get the list of channels in a server.",
                 shell_output("#{bin}/discordchatexporter-cli channels --help")
  end
end
