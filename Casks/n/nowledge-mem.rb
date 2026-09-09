cask "nowledge-mem" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.10.80"
  sha256 arm:   "78f3481415fbcb76371594d6492480d6078bd141d4fc32ce88a9de09eea1e93c",
         intel: "8e0713cb171396f6ee6deccad63cc663218f336788d02a9fdba7a359e554b8aa"

  url "https://download-mem.nowledge.co/app/#{version}/#{arch}-apple-darwin.dmg"
  name "Nowledge Mem"
  desc "Local-first context manager for AI conversations"
  homepage "https://mem.nowledge.co/"

  livecheck do
    url "https://mem.nowledge.co/changelog"
    regex(/Latest release.*?font-mono[^>]*>v?(\d+(?:\.\d+)+)/im)
  end

  auto_updates true
  depends_on macos: :monterey

  app "Nowledge Mem.app"

  uninstall quit: "co.nowledge.mem.desktop"

  zap trash: [
    "~/Library/Application Support/co.nowledge.mem.desktop",
    "~/Library/Application Support/Nowledge Mem",
    "~/Library/Caches/co.nowledge.mem.desktop",
    "~/Library/HTTPStorages/co.nowledge.mem.desktop",
    "~/Library/Logs/Nowledge Mem",
    "~/Library/Preferences/co.nowledge.mem.desktop.plist",
    "~/Library/Saved Application State/co.nowledge.mem.desktop.savedState",
    "~/Library/WebKit/co.nowledge.mem.desktop",
  ]
end
