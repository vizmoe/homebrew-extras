cask "magpie" do
  arch arm: "arm64", intel: "amd64"

  version "0.1.1370"
  sha256 arm:   "c9734762c99fbddf3bc05ca31019a004a3f59311ef56a9bcfe92f4fb4dc9b3f5",
         intel: "303ad78470d4fc2dced405bbd46b65506e2dc8f4aa154511cc13dd91142276e9"

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
