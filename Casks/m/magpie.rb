cask "magpie" do
  arch arm: "arm64", intel: "amd64"

  version "0.1.1279"
  sha256 arm:   "dc851543a00fc5c45168211b10627d99609087c2df8a7dc440d902f3e1e8d3ab",
         intel: "7a62d593d551eaf0304f9a652dfec15a60f68344fff4c199c4a1c33b01c45200"

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
