cask "scarf" do
  arch arm: "ARM64", intel: "Universal"

  version "3.8.0"
  sha256 arm:   "acc250e718994d1179c28a930f37b35dd20dbde3688a087ad8940560acb8a7f2",
         intel: "f613bbdfa8ce6a9ab09a7b94da6ebc02654fa594655a0c5694e3d193e384c3d3"

  url "https://github.com/awizemann/scarf/releases/download/v#{version}/Scarf-v#{version}-#{arch}.zip"
  name "Scarf"
  desc "Native companion app for the Hermes AI agent"
  homepage "https://github.com/awizemann/scarf"

  livecheck do
    url "https://awizemann.github.io/scarf/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on macos: :sequoia

  app "scarf.app", target: "Scarf.app"

  uninstall quit: "com.scarf.app"

  zap trash: [
    "~/Library/Application Support/com.scarf",
    "~/Library/Application Support/scarf",
    "~/Library/Caches/com.scarf.app",
    "~/Library/Caches/scarf",
    "~/Library/HTTPStorages/com.scarf.app",
    "~/Library/Preferences/com.scarf.app.plist",
    "~/Library/Saved Application State/com.scarf.app.savedState",
    "~/Library/WebKit/com.scarf.app",
  ]
end
