cask "nowledge-mem" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.10.110"
  sha256 arm:   "e4109f6ed5258a0965616c05b13cdec7aafb215eb772039fa840bd4609cb3605",
         intel: "82f65fd096e4fde21e57c08c882aff7f0d1e89793a9713804526873bb4058fba"

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
