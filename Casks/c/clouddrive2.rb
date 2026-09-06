cask "clouddrive2" do
  arch arm: "arm64", intel: "x64"

  version "1.0.17,14"
  sha256 arm:   "dd01ab6b3b19b8f939b42a3044dba33b9e11f74e8bd580cc529f77e26c621b08",
         intel: "b93f8fadb6dfc023710ad9013b948067e1c16d7500b175b5c24135111f71b3aa"

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
