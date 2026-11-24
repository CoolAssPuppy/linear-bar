# Sparkle setup for Linear Bar

Linear Bar uses the [Sparkle 2](https://sparkle-project.org/) framework for auto-updates, exactly like mail-notifier. This document records the one-time setup steps.

## Keys

Sparkle signs every update DMG with an Ed25519 key pair. The public key lives in `Source/Resources/Info.plist` under `SUPublicEDKey`. Existing Linear Bar releases use the same public key as Mail Notifier, and `scripts/build-dmg.sh` signs with the keychain account `com.strategicnerds.MailNotifierApp`. Verify that account is available before release. Creating a new Linear Bar key would make updates fail for existing installs.

The signing key must remain available on every release machine. Verify the signed DMG against the public key in the shipped app before publishing the appcast.

## Feed URL

The app points at a Dub shortlink (`https://coolasspuppy.com/linear-bar-updates`) which redirects to the live R2 URL (`https://pub-9c8d72fe664b4ce18aac0d718b4e0346.r2.dev/apps/linear-bar/appcast.xml`). The shortlink lets us repoint the feed without shipping a new build.

Configure the Dub shortlink once:
1. Sign in to https://dub.co
2. Create a link with slug `linear-bar-updates` pointing to `https://pub-9c8d72fe664b4ce18aac0d718b4e0346.r2.dev/apps/linear-bar/appcast.xml`

## Notarization

The release script uses `NOTARY_APPLE_ID` from the environment and `SPARKLE_APP_SPECIFIC_PASSWORD` from Doppler. Without both, it falls back to a `notarytool` keychain profile named `agent-server`. Create it once:

```bash
xcrun notarytool store-credentials "agent-server" \
  --apple-id <your-apple-id> \
  --team-id 955GSY56UT \
  --password <app-specific-password>
```

App-specific passwords are created at https://appleid.apple.com.

## `sign_update` tool

The DMG build script expects Sparkle's `sign_update` binary at `$HOME/bin/sparkle/sign_update`. It is distributed inside the Sparkle SPM artifact:

```bash
mkdir -p ~/bin/sparkle
cp ~/Library/Developer/Xcode/DerivedData/LinearBar-*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update ~/bin/sparkle/sign_update
chmod +x ~/bin/sparkle/sign_update
```

Or set `SPARKLE_SIGN_UPDATE` to override the path when invoking `./scripts/release.sh`.

## End-to-end release flow

```bash
./scripts/release.sh 2.0.1 "<li>What changed.</li><li>Another thing.</li>"
git add project.yml dist/appcast.xml
git commit -m "Release 2.0.1"
git push
```

The script does everything else: bumps version, archives, notarizes both `.app` and `.dmg`, Sparkle-signs the DMG, uploads both DMG and appcast to R2, and verifies the live URLs respond.
