cask "clicknow" do
  version "1.20"
  sha256 "3aeee4c20a6cd83e7a32cd9f01e0c5c072c51ef04a0dc60b9d31603a31efaa89"

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
