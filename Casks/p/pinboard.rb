cask "pinboard" do
  arch arm: "arm64", intel: "x86_64"

  version "0.2.0"
  sha256 arm:   "38e3284a69d4f66aa56355226fdd6e6240f954630d714efeaa33a1015dfdcca1",
         intel: "13f19e6cad379d1c0983bbf4df44112821590ad76f9448d1d60e7b4f52eac994"

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
