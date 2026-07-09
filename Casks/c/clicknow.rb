cask "clicknow" do
  version "1.19.13"
  sha256 "d63c7e5152a4780258fd3d222fda61d6794ee183fbcdce9639ffca76d06ce752"

  url "https://github.com/laike9m/Clicknow/releases/download/#{version}/Clicknow-#{version}.dmg",
      verified: "github.com/laike9m/Clicknow/"
  name "Clicknow"
  desc "AI translation and explanation with one click"
  homepage "https://clicknow.ai/"

  livecheck do
    url :url
    strategy :github_latest
  end

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
