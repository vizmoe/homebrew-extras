cask "clouddrive2" do
  arch arm: "arm64", intel: "x64"

  version "1.0.17,16"
  sha256 arm:   "3e189013368177deb1cfcb09b065f5ab4b07d27bfa0d3c454eb5dce946c009e3",
         intel: "fc0d1dd1ef97cea53ea747fa7a17527700bae8cba009a5848297ab4569aca7ee"

  url "https://github.com/cloud-fs/cloud-fs.github.io/releases/download/app-v#{version.csv.first}-#{version.csv.second}/CloudDrive2-#{version.csv.first}-#{version.csv.second}-macos-#{arch}.dmg"
  name "CloudDrive2"
  desc "Unified cloud storage manager"
  homepage "https://www.clouddrive2.com/"

  livecheck do
    url "https://github.com/cloud-fs/cloud-fs.github.io.git"
    regex(/^app-v?(\d+(?:\.\d+)+)[._-](\d+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map do |tag|
        match = tag.match(regex)
        next if match.blank?

        "#{match[1]},#{match[2]}"
      end
    end
  end

  auto_updates true
  depends_on macos: :ventura

  app "CloudDrive.app"

  uninstall quit: "com.clouddrive2.CloudDrive2"

  zap trash: [
    "~/Library/Application Support/CloudDrive",
    "~/Library/Caches/com.clouddrive2.CloudDrive2",
    "~/Library/HTTPStorages/com.clouddrive2.CloudDrive2",
    "~/Library/Preferences/com.clouddrive2.CloudDrive2.plist",
    "~/Library/Saved Application State/com.clouddrive2.CloudDrive2.savedState",
  ]

  caveats <<~EOS
    Local disk mounting requires macFUSE:
      brew install --cask macfuse
  EOS
end
