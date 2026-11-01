cask "pinboard" do
  arch arm: "arm64", intel: "x86_64"

  version "0.1.1"
  sha256 arm:   "d93a6c91d6ce0ec03cbcde543d02d2027b18f8ce6399dbed9ad4a4d00731ff02",
         intel: "5a063220a70107c0c2189fe7a89f8ec4f02311465158e23d97fd4f0e00154316"

  url "https://github.com/vizmoe/pinboard/releases/download/v#{version}/Pinboard-#{version}-macos-#{arch}.dmg"
  name "Pinboard"
  desc "Pin clipboard text and images in floating windows"
  homepage "https://github.com/vizmoe/pinboard"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  app "Pinboard.app"

  uninstall quit: "com.shiro.pinboard"

  zap trash: [
    "~/Library/Application Support/Pinboard",
    "~/Library/Preferences/com.shiro.pinboard.plist",
    "~/Library/Saved Application State/com.shiro.pinboard.savedState",
  ]
end
