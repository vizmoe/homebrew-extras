cask "nowledge-mem" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.10.119"
  sha256 arm:   "cc527adf37914aa047437c9aadbcaed3d89afe64797be250d4aae60de062503f",
         intel: "00f84accebcb3b6ad78c719c47d04c858c5d93727c84bc368ecded727a2397f4"

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
