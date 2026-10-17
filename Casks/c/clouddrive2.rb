cask "clouddrive2" do
  arch arm: "arm64", intel: "x64"

  version "1.1.3,23,22"
  sha256 arm:   "acc0a9a23118e406f340de33e9d83ba3153445175fe9bb1bcc30bb9f96fb008a",
         intel: "c13e10f1c2066dfa22d4cc27b9e93afff4ae6e2523e59adea8ad76dd28e69402"

  # Upstream's macOS asset build can differ from the release tag's build.
  url "https://github.com/cloud-fs/cloud-fs.github.io/releases/download/app-v#{version.csv.first}-#{version.csv.third}/CloudDrive2-#{version.csv.first}-#{version.csv.second}-macos-#{arch}.dmg"
  name "CloudDrive2"
  desc "Unified cloud storage manager"
  homepage "https://www.clouddrive2.com/"

  livecheck do
    url "https://github.com/cloud-fs/cloud-fs.github.io.git"
    regex(/^app-v?(\d+(?:\.\d+)+)-(\d+)$/i)
    strategy :git do |tags, regex|
      # App releases are buried behind server releases in the paginated API.
      tag = tags.filter_map { |value| value.match(regex) }
                .max_by { |match| [Version.new(match[1]), match[2].to_i] }
      next if tag.blank?

      # This app channel has always included upstream's GitHub prereleases.
      release = GitHub.get_release("cloud-fs", "cloud-fs.github.io", tag[0])
      next if release["draft"] || release["tag_name"] != tag[0]

      builds = release.fetch("assets", []).filter_map do |asset|
        match = asset["name"]&.match(/^CloudDrive2-(\d+(?:\.\d+)+)-(\d+)-macos-(arm64|x64)\.dmg$/i)
        next if match.blank? || match[1] != tag[1]

        [match[2], match[3]]
      end.group_by(&:first)

      builds.filter_map do |build, assets|
        next if assets.map(&:last).uniq.sort != %w[arm64 x64]

        "#{tag[1]},#{build},#{tag[2]}"
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
