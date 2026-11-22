cask "clicknow" do
  version "1.22.3"
  sha256 "fc4ae4b12c2f1d7505f30e02d38b0b178826d6eb017529a72344612cb03e3da8"

  url "https://github.com/laike9m/Clicknow/releases/download/#{version}/Clicknow-#{version}.dmg"
  name "Clicknow"
  desc "AI translation and explanation with one click"
  homepage "https://clicknow.ai/"

  livecheck do
    url "https://laike9m.github.io/Clicknow/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on macos: :sonoma

  app "Clicknow.app"

  uninstall quit: "app.xylect"

  zap trash: [
    "~/Library/Application Support/Clicknow",
    "~/Library/Caches/app.xylect",
    "~/Library/HTTPStorages/app.xylect",
    "~/Library/Preferences/app.xylect.plist",
    "~/Library/Saved Application State/app.xylect.savedState",
  ]
end
