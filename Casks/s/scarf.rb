cask "scarf" do
  arch arm: "ARM64", intel: "Universal"

  version "2.17.0"
  sha256 arm:   "6f01f80a07f1febdd5161a98c56d2b6f23f4cc5f27befaa6dbb0e5c578ebb57a",
         intel: "c327606c2dfc14657a2b61b90db65fede1dedd51245bd72ec73be012a507e74e"

  url "https://github.com/awizemann/scarf/releases/download/v#{version}/Scarf-v#{version}-#{arch}.zip"
  name "Scarf"
  desc "Native companion app for the Hermes AI agent"
  homepage "https://github.com/awizemann/scarf"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :sonoma

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
