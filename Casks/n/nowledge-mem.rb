cask "nowledge-mem" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.10.125"
  sha256 arm:   "90f954d07209b17e486f2477530fbbc650ec0c46441c58fd08b83b5c2c6ac37a",
         intel: "cf20f78a13f58efadfc2d2bd6bc33aaefa27aa35b2f9ae7a124bbbc5a71a0bab"

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
