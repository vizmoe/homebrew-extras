cask "scarf" do
  arch arm: "ARM64", intel: "Universal"

  version "2.20.0"
  sha256 arm:   "ef9c785c84c4f8c2ac4a642b8844883288cbe41669bb4b39c7b986109ad7ab2b",
         intel: "cc83956437e6c3398c5f6fa43307f79181d58f098eec9a4d3a563ecc131dba0a"

  url "https://github.com/awizemann/scarf/releases/download/v#{version}/Scarf-v#{version}-#{arch}.zip"
  name "Scarf"
  desc "Native companion app for the Hermes AI agent"
  homepage "https://github.com/awizemann/scarf"

  livecheck do
    url :url
    strategy :github_latest
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
