cask "magpie" do
  arch arm: "arm64", intel: "amd64"

  version "0.1.3240"
  sha256 arm:   "45f1eaecbb58b45d5bec6a365b1e718f38be9b318fa3f9ae66378d8d01eb5915",
         intel: "d3e3907fefb592ffd8023632638bc2d44b40e35eed854b5d9796be2d9d772663"

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
