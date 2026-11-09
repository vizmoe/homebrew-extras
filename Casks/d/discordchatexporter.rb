cask "discordchatexporter" do
  arch arm: "arm64", intel: "x64"

  version "2.48"
  sha256 arm:   "c489f531c157740d05ce88d78c63532c2e4c4e4e30deb83ac690f8bcbd32ba53",
         intel: "9aaa2bf86cb3e200beac26bc04274a49e9486df3d8b9c617e3e5ef0933c4d841"

  url "https://github.com/Tyrrrz/DiscordChatExporter/releases/download/#{version}/DiscordChatExporter.osx-#{arch}.zip"
  name "DiscordChatExporter"
  desc "Saves Discord chat logs to a file"
  homepage "https://github.com/Tyrrrz/DiscordChatExporter"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :monterey

  app "DiscordChatExporter.app"

  uninstall quit: "me.tyrrrz.discordchatexporter"

  zap trash: [
    "~/Library/Preferences/me.tyrrrz.discordchatexporter.plist",
    "~/Library/Saved Application State/me.tyrrrz.discordchatexporter.savedState",
  ]

  caveats <<~EOS
    DiscordChatExporter is signed ad-hoc and is not accepted by Gatekeeper.
  EOS
end
