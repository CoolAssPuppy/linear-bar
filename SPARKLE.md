# Sparkle setup for Linear Bar

Linear Bar uses the [Sparkle 2](https://sparkle-project.org/) framework for auto-updates, exactly like mail-notifier. This document records the one-time setup steps.

## Keys

Sparkle signs every update DMG with an Ed25519 key pair. The public key lives in `Source/Resources/Info.plist` under `SUPublicEDKey`. The private key lives in macOS Keychain under the account name `com.strategicnerds.LinearBarApp`, and is backed up to Doppler.

**Generating the keys (run once):**

```bash
# Locate Sparkle's generate_keys after an Xcode build has resolved packages:
~/Library/Developer/Xcode/DerivedData/LinearBar-*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys --account com.strategicnerds.LinearBarApp
```

This stores the private key in Keychain and prints the public key. Paste that public key into `Source/Resources/Info.plist` as the value of `SUPublicEDKey`.

**Back up the private key to Doppler:**

```bash
~/Library/Developer/Xcode/DerivedData/LinearBar-*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys --account com.strategicnerds.LinearBarApp -p > /tmp/sparkle_private.pem
doppler secrets set SPARKLE_PRIVATE_KEY_LINEARBAR --project agent-server --config prd < /tmp/sparkle_private.pem
rm -P /tmp/sparkle_private.pem
```

**Restoring on a new machine:**

```bash
doppler secrets get SPARKLE_PRIVATE_KEY_LINEARBAR --project agent-server --config prd --plain > /tmp/sparkle_private.pem
~/Library/Developer/Xcode/DerivedData/LinearBar-*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys --account com.strategicnerds.LinearBarApp -f /tmp/sparkle_private.pem
rm -P /tmp/sparkle_private.pem
```

**Losing the private key permanently strands every installed copy.** Sparkle does not support key rotation. Do not lose it.

## Feed URL

The app points at a Dub shortlink (`https://coolasspuppy.com/linear-bar-updates`) which redirects to the live R2 URL (`https://downloads.strategicnerds.com/apps/linear-bar/appcast.xml`). The shortlink lets us repoint the feed without shipping a new build.

Configure the Dub shortlink once:
1. Sign in to https://dub.co
2. Create a link with slug `linear-bar-updates` pointing to `https://downloads.strategicnerds.com/apps/linear-bar/appcast.xml`

## Notarization

The release script assumes a `notarytool` keychain profile named `agent-server`. Create it once:

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
