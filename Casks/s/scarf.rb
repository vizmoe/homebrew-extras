cask "scarf" do
  arch arm: "ARM64", intel: "Universal"

  version "3.9.1"
  sha256 arm:   "b00a0237a61db74d9d00bc7781d7b616f710bb8c102e9640a30b40915bb8517c",
         intel: "2257dd22013098964cfa9069438c63b22b3f0a8b45b3276d1bcc7e9848bfb79f"

  url "https://github.com/awizemann/scarf/releases/download/v#{version}/Scarf-v#{version}-#{arch}.zip"
  name "Scarf"
  desc "Native companion app for the Hermes AI agent"
  homepage "https://github.com/awizemann/scarf"

  livecheck do
    url "https://awizemann.github.io/scarf/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on macos: :sequoia

  app "scarf.app", target: "Scarf.app"

  uninstall quit: "com.scarf.app"

  zap trash: [
    "~/Library/Application Support/com.scarf",
    "~/Library/Application Support/scarf",
    "~/Library/Caches/com.scarf.app",
    "~/Library/Caches/scarf",
    "~/Library/HTTPStorages/com.scarf.app",
    "~/Library/Preferences/com.scarf.app.plist",
    "~/Library/Saved Application State/com.scarf.app.savedState",
    "~/Library/WebKit/com.scarf.app",
  ]
end
