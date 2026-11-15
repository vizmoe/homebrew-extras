cask "mygo-music" do
  arch arm: "arm64", intel: "amd64"

  version "0.1.25"
  sha256 arm:   "589373d58a6b2a9c2dcdcb2ca7ecfc0b5ca43d029174e73240eed491e94a211d",
         intel: "3e52759de81d4890e30be2c13593dcde15a678d891b98761a833341706b4febd"

  url "https://github.com/egoist/mygo-music/releases/download/v#{version}/mygo-music-#{version}-#{arch}.dmg"
  name "MyGo Music"
  desc "Native music player extensible with plugins"
  homepage "https://music.egoist.dev/"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :ventura

  app "MyGo Music.app"

  uninstall quit: "dev.egoist.music"

  zap trash: [
    "~/Library/Application Support/MyGo Music",
    "~/Library/Caches/dev.egoist.music",
    "~/Library/Caches/MyGo Music",
    "~/Library/HTTPStorages/dev.egoist.music",
    "~/Library/Logs/MyGo Music",
    "~/Library/Preferences/dev.egoist.music.plist",
    "~/Library/Saved Application State/dev.egoist.music.savedState",
    "~/Library/WebKit/dev.egoist.music",
  ]
end
