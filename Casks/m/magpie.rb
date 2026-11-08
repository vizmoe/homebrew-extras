cask "magpie" do
  arch arm: "arm64", intel: "amd64"

  version "0.1.3320"
  sha256 arm:   "3cf09d3c9e5275d2dfdbeafa863e440f2316cf152629556e7c1482abdad46241",
         intel: "a89c8f07417f8711e631b63e9840b8cec808d8fc69f6f1ac260a0ecba522ce9b"

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
