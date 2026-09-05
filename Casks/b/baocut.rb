cask "baocut" do
  version "1.1.4,51"
  sha256 "5bf6e683d1ffdf14e2f2f519085c62b62cd6ec40fc6df97479af1f5f853d7738"

  url "https://baocut.app/downloads/BaoCut-#{version.csv.first}-build.#{version.csv.second}-arm64.dmg"
  name "BaoCut"
  desc "Local-first transcription and subtitle editor"
  homepage "https://baocut.app/"

  livecheck do
    url "https://baocut.app/appcast.json"
    strategy :json do |json|
      version = json["version"]
      build = json["build"]
      next if version.blank? || build.blank?

      "#{version},#{build}"
    end
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "BaoCut.app"

  uninstall quit: "com.jimliu.baocut"

  zap trash: [
    "~/Library/Application Support/BaoCut",
    "~/Library/Caches/com.jimliu.baocut",
    "~/Library/HTTPStorages/com.jimliu.baocut",
    "~/Library/Logs/BaoCut",
    "~/Library/Preferences/com.jimliu.baocut.plist",
    "~/Library/Saved Application State/com.jimliu.baocut.savedState",
  ]
end
