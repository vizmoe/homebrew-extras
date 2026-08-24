cask "azahar" do
  arch arm: "arm64", intel: "x86_64"

  version "2126.0"
  sha256 arm:   "3483afef5a0e6579abe7c9f0954f306a6665f5291bfde09ee2402a6ca53b5267",
         intel: "26029710a9187349c4832fb35d423ed01989776969f4fcf20a22413d2b794a70"

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
