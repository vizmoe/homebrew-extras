cask "baocut" do
  version "3.16.4,92"
  sha256 "7520f279e3112a2b7807b88b3c76918d8e19ef9fb86e32e4dfbb6067b64d250e"

  url "https://github.com/JimLiu/baocut/releases/download/baocut-v#{version.csv.first}-build.#{version.csv.second}/BaoCut-#{version.csv.first}-build.#{version.csv.second}-aarch64-apple-darwin.dmg"
  name "BaoCut"
  desc "Local-first transcription and subtitle editor"
  homepage "https://baocut.com/"

  livecheck do
    url "https://github.com/JimLiu/baocut/releases/latest/download/appcast-aarch64-apple-darwin.json"
    strategy :json do |json|
      version = json["version"]
      build = json["build"]
      next if version.blank? || build.blank?

      "#{version},#{build}"
    end
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "BaoCut.app"

  uninstall quit: "com.baocut.app"

  zap trash: [
    "~/Library/Application Support/BaoCut",
    "~/Library/Caches/com.baocut.app",
    "~/Library/Caches/com.jimliu.baocut",
    "~/Library/HTTPStorages/com.baocut.app",
    "~/Library/HTTPStorages/com.jimliu.baocut",
    "~/Library/Logs/BaoCut",
    "~/Library/Preferences/com.baocut.app.plist",
    "~/Library/Preferences/com.jimliu.baocut.plist",
    "~/Library/Saved Application State/com.baocut.app.savedState",
    "~/Library/Saved Application State/com.jimliu.baocut.savedState",
  ]
end
