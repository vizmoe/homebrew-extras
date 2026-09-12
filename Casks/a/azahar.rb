cask "azahar" do
  arch arm: "arm64", intel: "x86_64"

  version "2126.1.1"
  sha256 arm:   "473214a0d4493839b411c1754f5aa51e83a2b3f9c215225f855b6346914bc485",
         intel: "bc01eb4bc20f3671bdddfe3905000f719841add093a99aef98249e6e66822abb"

  url "https://github.com/azahar-emu/azahar/releases/download/#{version}/azahar-macos-#{arch}-#{version}.zip"
  name "Azahar"
  desc "Nintendo 3DS emulator"
  homepage "https://github.com/azahar-emu/azahar"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  app "azahar-macos-#{arch}-#{version}/Azahar.app", target: "Azahar.app"

  zap trash: [
    "~/Library/Application Support/Azahar",
    "~/Library/Preferences/org.azahar-emu.azahar.plist",
    "~/Library/Saved Application State/org.azahar-emu.azahar.savedState",
  ]

  caveats <<~EOS
    Azahar is signed ad-hoc and is not accepted by Gatekeeper.
  EOS
end
