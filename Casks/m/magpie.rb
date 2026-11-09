cask "magpie" do
  arch arm: "arm64", intel: "amd64"

  version "0.1.3382"
  sha256 arm:   "d22c500b8176f0fb793a445f3b9d96c39788fc4f9f2aadd49831f0f9e7cd73f7",
         intel: "33b7b0ac02861d5bb00566ea9d96f889d0f7d7018606e6130cb0d7ac7bbbf2ad"

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
