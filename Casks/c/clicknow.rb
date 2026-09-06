cask "clicknow" do
  version "1.20.1"
  sha256 "5852bbd79a5486bc66d29ef59742c59e11c01c005396d00156c5f8783cf88844"

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

  zap trash: [
    "~/Library/Application Support/Clicknow",
    "~/Library/Caches/app.xylect",
    "~/Library/HTTPStorages/app.xylect",
    "~/Library/Preferences/app.xylect.plist",
    "~/Library/Saved Application State/app.xylect.savedState",
  ]
end
