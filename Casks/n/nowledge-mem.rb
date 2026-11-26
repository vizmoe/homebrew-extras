cask "nowledge-mem" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.10.124"
  sha256 arm:   "4bb5c3ec0e396d832f055d86d19f945469bc2204186253cbe207a805a1b57833",
         intel: "d8c9093fc597505cf664f780ce11fb0cdd4172defaab53bf396a13009e514ec6"

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
