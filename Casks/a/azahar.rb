cask "azahar" do
  arch arm: "arm64", intel: "x86_64"

  version "2126.1"
  sha256 arm:   "d0e261f53a61ea005ef62e30db4a3ead935d8f1a0ec1d1809d03c05949dc0914",
         intel: "e47f5dc5457da4951d70328e189564695a4e9cd3e15f75f8e70e78b5939ac5cb"

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
