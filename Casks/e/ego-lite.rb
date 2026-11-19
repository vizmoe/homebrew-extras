cask "ego-lite" do
  arch arm: "arm64", intel: "x64"

  version :latest
  sha256 :no_check

  url "https://cdn.ego.app/setup/macos/#{arch}/egolite.dmg"
  name "ego lite"
  desc "Browser for AI agents to run web automation"
  homepage "https://lite.ego.app/"

  depends_on macos: :ventura

  app "ego lite.app"

  uninstall quit: "com.citrolabs.ego.lite"

  zap trash: [
    "~/.ego-browser",
    "~/Library/Application Support/ego lite",
    "~/Library/Caches/com.citrolabs.ego.lite",
    "~/Library/Caches/ego lite",
    "~/Library/EgoSoftwareUpdate/Actives/com.citrolabs.ego.lite",
    "~/Library/HTTPStorages/com.citrolabs.ego.lite",
    "~/Library/Logs/ego lite",
    "~/Library/Preferences/com.citrolabs.ego.lite.plist",
    "~/Library/Saved Application State/com.citrolabs.ego.lite.savedState",
    "~/Library/WebKit/com.citrolabs.ego.lite",
  ]
end
