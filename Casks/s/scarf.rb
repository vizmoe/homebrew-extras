cask "scarf" do
  arch arm: "ARM64", intel: "Universal"

  version "3.7.1"
  sha256 arm:   "2323fe97905b9bbc33cb8cc38ed9a6fb22182abdb84fa7dbee33ba4123157749",
         intel: "291a298c936ac958b94609a747817dc196383941eba1013ae56465ce86ab29d3"

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
