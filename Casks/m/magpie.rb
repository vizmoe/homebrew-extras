cask "magpie" do
  arch arm: "arm64", intel: "amd64"

  version "0.1.2188"
  sha256 arm:   "e669717553f2bbda77a7fdaa8980a1ece4ce6de61bb4775a4922f8f535969713",
         intel: "2b5df1d3da5a090634ed57dcc3789e90023d1fb9676bdeda7ac8114b5b17b94e"

  url "https://github.com/yetone/magpie-releases/releases/download/v#{version}/magpie-darwin-#{arch}.zip"
  name "magpie"
  desc "Menu bar model manager for AI coding agents"
  homepage "https://usemagpie.ai/"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :monterey

  app "magpie.app"

  uninstall launchctl: "com.yetone.magpie",
            quit:      "com.yetone.magpie"

  zap trash: [
    "~/.config/magpie",
    "~/Library/Caches/com.yetone.magpie",
    "~/Library/HTTPStorages/com.yetone.magpie",
    "~/Library/Preferences/com.yetone.magpie.plist",
    "~/Library/Saved Application State/com.yetone.magpie.savedState",
    "~/Library/WebKit/com.yetone.magpie",
  ]
end
