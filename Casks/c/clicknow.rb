cask "clicknow" do
  version "1.21"
  sha256 "f63b3c87131468aab41dddf9507fe257413bfb5c8590547da7c9f219e42c5143"

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
