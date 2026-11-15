cask "pinboard" do
  arch arm: "arm64", intel: "x86_64"

  version "0.3.1"
  sha256 arm:   "94a4500ba76b7d93f7d364098256211f4a9cbd9f76fa85c4736e274d221b3b27",
         intel: "2594a8d42186cb9257f36800219cd92a2183efbedb0698605d3d5877e95aca66"

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
