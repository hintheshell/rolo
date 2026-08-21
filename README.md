# Rolo

A tiny, fully native macOS launcher, maintained as a personal fork of
[Tinycast](https://github.com/abue-ammar/tinycast).

<p align="center">
  <a href="LICENSE">
    <img alt="License: AGPL-3.0"
         src="https://img.shields.io/badge/License-AGPL--3.0-3DA639?style=flat"></a>
</p>

<p align="center">
  <img src="docs/screenshot.png" alt="Rolo command palette" width="720">
</p>

Around **3 MB on disk** and **under 100 MB of RAM** — no Electron, no telemetry, no background
CPU churn. Just SwiftUI + AppKit with zero dependencies. It's fast because there's nothing to it.

It also **runs Raycast extensions** — the real ones, rendered as native SwiftUI. No Node.js, no
browser: JavaScriptCore ships with macOS, so that costs no extra binary size.

## Features

- **App launcher** — fuzzy-search and launch anything, pin favorites, see what's running, quit an app
  or every app at once.
- **Custom commands** — run named shell commands through fuzzy search or their own global hotkeys.
- **Calculator** — do math, unit, live currency and crypto conversions inline, right in the palette.
- **Clipboard history** — text and images, searchable, pasted back into the app you were using.
- **Snippets** — reusable Markdown templates with dynamic placeholders, arguments, nested references
  and optional keyword expansion.
- **Global hotkey** — one shortcut summons the palette from anywhere.
- **Per-app hotkeys** — bind a key to an app; press it to toggle (focus/hide).
- **Raycast extensions** — run the ones you already have natively, rendered as SwiftUI.

## Differences from Tinycast

Rolo stays close to upstream and currently adds:

- **Localized app search** — find apps by localized or Finder-renamed names, including Mandarin
  pinyin.
- **Command-number shortcuts** — hold **⌘** to reveal **1–9**, then press **⌘1–⌘9** to open a
  Launcher result or paste a Clipboard result.
- **A separate release** — installs as `Rolo.app` with its own bundle ID and Homebrew cask,
  targets macOS 26+, and can run alongside Tinycast.

## Install

```sh
brew install --cask hintheshell/rolo/rolo
```

Rolo targets macOS 26 or later. It installs as `Rolo.app` with bundle ID `com.hintheshell.rolo`, so
it can coexist with Tinycast while you migrate and verify your data.

Rolo is self-signed. Installing via Homebrew clears the macOS quarantine flag for you
automatically on every install and update, so there's nothing to run. (If you download the DMG
directly from Releases instead, clear it once: `xattr -dr com.apple.quarantine
"/Applications/Rolo.app"`.)

## Permissions

**Accessibility** — needed when Rolo pastes or expands text into another app, and the only
permission snippet keyword expansion needs. You're prompted when you first use a feature that needs
it; grant access in **System Settings → Privacy & Security → Accessibility**. Snippets ship
disabled, and keystrokes are matched locally, never stored and never sent anywhere.

## Using it

1. Open **Settings → General** and record a global shortcut to summon Rolo.
2. Press it anywhere → the palette floats in. Type to filter, **↵** to launch.
3. **Tab** switches between Apps and Clipboard; **↑/↓** move, **Esc** dismisses. Hold **⌘** in
   Clipboard to reveal **1–9**, then press **⌘1–⌘9** to paste that entry directly.
4. **Settings → Shortcuts** — search an app or custom command and record a global shortcut.
5. **Settings → Snippets** — enable the feature, then create templates with expansion keywords.

## Building from source

See **[docs/development.md](docs/development.md)** for the toolchain, build, packaging, release and
website workflows. **[docs/](docs/README.md)** indexes everything else — architecture, engineering
standards, the design system and one document per feature.

## Upstream and contributing

Rolo preserves Tinycast's architecture and development standards so upstream changes remain practical
to merge. Read **[CONTRIBUTING.md](CONTRIBUTING.md)** before changing code. Changes intended for the
original project should follow [Tinycast's contribution process](https://github.com/abue-ammar/tinycast/blob/main/CONTRIBUTING.md).

Rolo's own changes are documented in this repository and remain available under the same license.

## License

[AGPL-3.0](LICENSE)
