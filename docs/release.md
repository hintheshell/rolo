# Release

How a build reaches a user. The local development loop is in [development.md](development.md);
the signing identity itself is in [signing.md](signing.md).

## Packaging a DMG locally

```sh
./Scripts/build-dmg.sh            # -> build/Rolo-<version>.dmg (version from project.yml)
./Scripts/build-dmg.sh 0.5.7      # -> build/Rolo-0.5.7.dmg
```

It builds a Release `Rolo.app` signed with `Rolo Self-Signed` and packs it with an
`/Applications` symlink. Official releases are built by CI, below.

## Signing & Gatekeeper

Both local builds and CI releases sign with the same stable `Rolo Self-Signed` identity, not an
Apple Developer ID — so macOS quarantines a directly-downloaded DMG. The Homebrew cask strips that
automatically; direct downloaders run `xattr -dr com.apple.quarantine "…/Rolo.app"` once. Full
details in [signing.md](signing.md).

## How the in-app updater consumes a release

Every release publishes two assets from one build: `Rolo-<version>.dmg`, which people download by
hand and which the cask installs, and `Rolo-<version>.zip`, which the in-app updater installs. The
zip is produced with `ditto -c -k --keepParent --sequesterRsrc` — the only zip that leaves the code
signature verifiable, which matters because the updater refuses any bundle whose leaf certificate does
not match the running app's.

Three things a release must keep true, or the updater skips it:

- **It carries a `.zip` asset.** A DMG-only release is not installable and is not offered.
- **The tag parses as `vMAJOR.MINOR.PATCH` or `vMAJOR.MINOR.PATCH-beta.N`,** and agrees with the
  `prerelease` flag. `v0.9.7-sequoia` deliberately parses as neither, which is what keeps beta
  installs off the macOS 15 build.
- **It is not a draft.**

**The cask must declare `auto_updates true`.** That is Homebrew's flag for an app that manages its own
version, and it is what keeps `brew update && brew upgrade` from fighting an app that updated itself:
brew never reports Rolo outdated, never re-downloads it, and never rolls a self-updated copy back.
Removing that line would reintroduce exactly those three problems. See
[features/updates.md](features/updates.md).

## Continuous integration

`.github/workflows/ci.yml` runs on every PR, on a `macos-26` runner with Xcode 26 (the same selection
step as the release workflow). One job, a merge gate; a new push cancels the in-flight run for the
same ref. Two steps, both of which shell out to a script rather than naming rules or harnesses in the
workflow, so neither can drift:

- **the harnesses** — `./Scripts/run-tests.sh`.
- **lint** — `./Scripts/lint.sh`, with `SWIFTLINT_REPORTER=github-actions-logging` so every violation
  is annotated **inline on the PR diff** instead of being buried in the log. It runs under
  `if: always()`, so a failing harness still surfaces the lint annotations in the same run. Warnings
  annotate only; **lint errors fail the job**, exactly as a local run does.

It does **not** run on pushes to `main`. `pull_request` builds the merge result, so re-running after a
merge would re-test content CI has already seen. A direct push to `main` therefore gets no run at all —
use **Actions → CI → Run workflow** if one ever needs checking.

There is **no `xcodebuild` step**: a Debug build costs minutes on every run and the release workflow
builds before it ships anyway, so CI keeps to the checks that finish in about a minute. The
consequence is that a change compiling nowhere still turns the PR green — **build locally before you
open one**. See [testing.md](testing.md#definition-of-done).

## Releasing

`.github/workflows/release.yml` builds and publishes a DMG from GitHub Actions, no local machine
needed. Run it from the **Actions** tab (`Release` → **Run workflow**) and supply the plain semver,
for example `0.2.0`.

It builds on a `macos-26` runner with Xcode 26 and publishes a GitHub Release tagged
`v<version>` with versioned DMG and ZIP assets (`Rolo-<version>.dmg` and `Rolo-<version>.zip`). On
success it also bumps the cask in the tap.

### Homebrew tap automation

The release job's final step rewrites the `version` and `sha256` of `Casks/rolo.rb` in the
[`homebrew-rolo`](https://github.com/hintheshell/homebrew-rolo) tap and pushes it. The
`HOMEBREW_TAP_DEPLOY_KEY` repo secret is an SSH deploy key with write access to that tap only; it
cannot write any other repository.

## Website

`.github/workflows/website.yml` still builds the inherited Tinycast website, but deployment is manual
until that site is Rolo-branded. Do not publish it as Rolo in its current state.

```sh
cd website && npm install && npm run dev     # local preview
```

The workflow uploads `website/out` — a Next.js export lands there, not in `dist/`. `public/.nojekyll`
must stay: GitHub Pages runs Jekyll, which ignores `_`-prefixed directories, so without it every
asset under `_next/` 404s. See [website/README.md](../website/README.md).
