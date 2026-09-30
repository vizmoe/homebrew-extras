# Homebrew-Extras

![Homebrew](https://img.shields.io/badge/-Homebrew-FBB040?labelColor=555555&logoColor=FFFFFF&logo=homebrew) ![CI](https://github.com/vizmoe/homebrew-extras/actions/workflows/tests.yml/badge.svg) ![code-size](https://img.shields.io/github/languages/code-size/vizmoe/homebrew-extras) ![repo-size](https://img.shields.io/github/repo-size/vizmoe/homebrew-extras)

Extras [Homebrew](https://github.com/Homebrew/brew) 🍺 Formulae and Casks Not Included in the Official [Homebrew-Core](https://github.com/Homebrew/homebrew-core) and [Homebrew-Cask](https://github.com/Homebrew/homebrew-cask) Taps

## 🍺 Get Started

```bash
brew tap vizmoe/extras
```

Install go-grip:

```bash
brew install vizmoe/extras/go-grip
```

The formula installs upstream prebuilt binaries for macOS and Linux on arm64 and x86_64; no Go toolchain is required. The Linux x86_64 binary requires glibc 2.34 or newer.

The daily autobump workflow updates casks only. go-grip release updates require updating all four platform checksums manually; check for new releases with `brew livecheck vizmoe/extras/go-grip`.

Install the Magpie macOS app:

```bash
brew install --cask vizmoe/extras/magpie
```

The cask installs the signed upstream desktop app for Apple Silicon and Intel Macs running macOS 12 Monterey or later.

## 🌍 List

### Formulae

| Formula Name | Site | Note |
| :----------: | :--: | :--- |
| `go-grip` | [go-grip](https://github.com/chrishrb/go-grip) | Preview Markdown files locally with GitHub styling |

### Casks

|      Cask Name      |                                 Site                                  |                         Note                          |
| :-----------------: | :-------------------------------------------------------------------: | :---------------------------------------------------: |
| `audirvana-origin`  |                 [Audirvana Origin](https://audirvana.com/)                 |                 Audio playback software                 |
|      `azahar`       |          [Azahar](https://github.com/azahar-emu/azahar)           |                 Nintendo 3DS emulator                 |
|      `baocut`       |                    [BaoCut](https://baocut.app/)                     |      Local-first transcription and subtitle editor      |
|     `clicknow`      |                   [Clicknow](https://clicknow.ai/)                   |        AI translation and explanation with one click        |
|    `clouddrive2`    |             [CloudDrive2](https://www.clouddrive2.com/)              |              Unified cloud storage manager              |
|      `magpie`      |                   [Magpie](https://usemagpie.ai/)                   |          Menu bar model manager for AI coding agents          |
|   `nowledge-mem`    |              [Nowledge Mem](https://mem.nowledge.co/)               |     Local-first context manager for AI conversations     |
|       `scarf`       |           [Scarf](https://github.com/awizemann/scarf)            |         Native companion app for the Hermes AI agent         |
|    `subrenamer`     |         [SubRenamer](https://github.com/qwqcode/SubRenamer)          |      Batch rename subtitle files to match video names      |
