cask "subrenamer" do
  arch arm: "arm64", intel: "amd64"

  version "2.4.0"
  sha256 arm:   "8876349f691ad149ed03f4adb9bacebbda9695671e984c9474b0887063c7cb72",
         intel: "1a05ce5a952e23bf536b2a054ee310d03243f2d48924a1edc1300ae78a64564f"

  url "https://github.com/qwqcode/SubRenamer/releases/download/v#{version}/SubRenamer_macos_#{arch}.zip"
  name "SubRenamer"
  desc "Batch rename subtitle files to match video names"
  homepage "https://github.com/qwqcode/SubRenamer"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "SubRenamer.app"

  zap trash: [
    "~/Library/Application Support/SubRenamer",
    "~/Library/Preferences/com.qwqcode.subrenamer.plist",
    "~/Library/Saved Application State/com.qwqcode.subrenamer.savedState",
  ]
end
