# LinearBar - Deployment Guide

Complete guide for deploying LinearBar to TestFlight and the Mac App Store.

## Table of Contents

- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [One-Time Setup](#one-time-setup)
- [Regular Deployment Workflow](#regular-deployment-workflow)
- [Troubleshooting](#troubleshooting)
- [What Was Automated](#what-was-automated)
- [Maintenance](#maintenance)

---

## Project Structure

LinearBar is a **standalone macOS project** (not a monorepo).

```
/Users/prashant/Developer/linear-bar/        ← PROJECT_ROOT
├── LinearBar.xcodeproj/                     ← Xcode project
├── LinearBar/                               ← Source code
│   ├── App/
│   ├── Models/
│   ├── Views/
│   ├── Services/
│   ├── Extensions/
│   └── Resources/
├── fastlane/                                ← Fastlane automation
│   ├── Appfile                              ← Apple ID & Team configuration
│   ├── Fastfile                             ← Deployment lanes
│   └── app_store_connect_api_key.p8         ← API key (YOU MUST CREATE THIS)
├── Gemfile                                  ← Ruby dependencies
├── .env                                     ← Your secrets (YOU MUST CREATE THIS)
├── .env.default                             ← Environment template (committed)
├── deploy.sh                                ← Interactive deployment script
├── quick-test.sh                            ← Quick test runner
├── CHANGELOG.md                             ← Version history
└── DEPLOY-STEPS.md                          ← This file

**Important:** All deployment commands work from PROJECT_ROOT
```

---

## Prerequisites

### Required

- ✅ macOS 13.0 or later
- ✅ Xcode 15.0+ with Command Line Tools installed
- ✅ Ruby 3.0+ (you have 3.4.7)
- ✅ Bundler (`gem install bundler` if not installed)
- ✅ Git repository initialized
- ✅ Apple Developer account with **Admin** or **App Manager** access
- ✅ App registered in App Store Connect
- ✅ Bundle identifier `com.strategicnerds.LinearBar` registered in Apple Developer Portal

### Code Signing Certificates

Your current status:

| Certificate | Status | Required For |
|-------------|--------|-------------|
| Apple Development | ✅ Installed | Local development |
| Apple Distribution | ✅ Installed | App Store submission |
| **Mac Installer Distribution** | ⚠️  **MISSING** | **Mac App Store (CRITICAL!)** |

**CRITICAL:** You are **MISSING** the "Mac Installer Distribution" certificate!

macOS App Store requires **TWO** certificates:
1. **Apple Distribution** - Signs the .app bundle ✅ You have this
2. **Mac Installer Distribution** - Signs the .pkg installer ❌ **YOU NEED THIS**

### How to Create Mac Installer Distribution Certificate

1. Go to [Apple Developer Portal → Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click "+" to create new certificate
3. Select "Mac Installer Distribution"
4. Create and upload CSR:
   ```bash
   # Open Keychain Access
   # → Keychain Access menu → Certificate Assistant → Request a Certificate from a Certificate Authority
   # Fill in: Your email, "Mac Installer Distribution", Save to disk
   ```
5. Download the certificate file (.cer)
6. Double-click to install in Keychain
7. Verify installation:
   ```bash
   security find-identity -v -p codesigning | grep "Mac Installer Distribution"
   ```

**Without this certificate, `deploy.sh` will FAIL when building for App Store!**

---

## One-Time Setup

Follow these steps exactly **once** before your first deployment.

### Step 1: Create App Store Connect API Key

Using an API key is **strongly recommended** - it eliminates 2FA prompts and makes automation reliable.

1. Go to [App Store Connect → Users and Access → Keys](https://appstoreconnect.apple.com/access/api)
2. Click "+" to generate a new key
3. Name it: "LinearBar Fastlane"
4. Role: **App Manager** or **Admin**
5. Click "Generate"
6. **IMPORTANT:** Download the `.p8` file immediately (only available once!)
7. Save the file as:
   ```bash
   /Users/prashant/Developer/linear-bar/fastlane/app_store_connect_api_key.p8
   ```
8. **Copy these values** (you'll need them next):
   - **Key ID** (e.g., ABC123DEF4)
   - **Issuer ID** (e.g., abcd1234-ef56-78gh-90ij-klmnopqrstuv)

### Step 2: Configure Environment Variables

1. Create your `.env` file from the template:
   ```bash
   cd /Users/prashant/Developer/linear-bar
   cp .env.default .env
   ```

2. Edit `.env` with your actual values:
   ```bash
   # Open in your preferred editor
   nano .env
   # or
   code .env
   ```

3. Fill in these values:
   ```bash
   # Already filled in (from your Apple Developer account):
   FASTLANE_USER=prashant_sridharan@hotmail.com
   FASTLANE_TEAM_ID=955GSY56UT
   FASTLANE_ITC_TEAM_ID=955GSY56UT

   # Fill in from Step 1 above:
   APP_STORE_CONNECT_API_KEY_ID=your_key_id_here
   APP_STORE_CONNECT_API_ISSUER_ID=your_issuer_id_here

   # Leave this as-is:
   APP_STORE_CONNECT_API_KEY_PATH=fastlane/app_store_connect_api_key.p8
   FASTLANE_SKIP_2FA_UPGRADE=true
   ```

4. **CRITICAL:** Never commit `.env` to git (it's already in .gitignore)

### Step 3: Enable Xcode Automatic Code Signing

1. Open project in Xcode:
   ```bash
   open LinearBar.xcodeproj
   ```

2. Select the **LinearBar** target

3. Go to **Signing & Capabilities** tab

4. Check **"Automatically manage signing"**

5. Select your team: **Prashant Sridharan (955GSY56UT)**

6. Xcode will automatically:
   - Create provisioning profiles
   - Handle certificate selection
   - Manage entitlements

7. Build once in Xcode to verify signing works:
   - Product → Build (⌘B)
   - Should succeed with no signing errors

### Step 4: Install Ruby Dependencies

```bash
cd /Users/prashant/Developer/linear-bar
bundle install
```

This creates:
- `Gemfile.lock` - Locks gem versions
- `vendor/bundle/` - Local gem installation

**Why these specific gems?**
- `fastlane` - Deployment automation
- `abbrev` - Ruby 3.4+ removed this from stdlib
- `ostruct` - Ruby 3.4+ will remove this in 3.5
- `dotenv` - Required for loading .env files (Fastlane doesn't auto-load them!)

### Step 5: Verify Setup

Run pre-flight checks to ensure everything is configured:

```bash
cd /Users/prashant/Developer/linear-bar
bundle exec fastlane prep
```

This validates:
- ✅ Environment variables are set
- ✅ API key file exists
- ✅ Code signing certificates are installed
- ⚠️  Mac Installer Distribution certificate (will warn if missing)
- ✅ Git status
- ✅ Current version/build numbers

**If all checks pass (except Mac Installer warning), you're ready to deploy! 🚀**

---

## Regular Deployment Workflow

### Deploy to TestFlight (Beta Testing)

**Option 1: Interactive Script (Recommended)**

```bash
cd /Users/prashant/Developer/linear-bar
./deploy.sh
# Select option 1 for TestFlight
```

**Option 2: Direct Command**

```bash
cd /Users/prashant/Developer/linear-bar
bundle exec fastlane beta
```

**What happens:**
1. Runs pre-flight checks
2. Increments build number automatically
3. Builds signed .pkg for Mac App Store
4. Uploads to App Store Connect
5. Build appears in TestFlight within 10-15 minutes

**No waiting!** The script uses `skip_waiting_for_build_processing: true` to complete in seconds instead of 5-30 minutes.

### Deploy to Production (App Store)

**Option 1: Interactive Script (Recommended)**

```bash
cd /Users/prashant/Developer/linear-bar
./deploy.sh
# Select option 2 for App Store
```

**Option 2: Direct Command**

```bash
cd /Users/prashant/Developer/linear-bar
bundle exec fastlane release
```

**What happens:**
1. Safety confirmation prompt
2. Checks git status (warns if uncommitted changes)
3. Runs pre-flight checks
4. Increments build number
5. Builds signed .pkg
6. Uploads to App Store Connect
7. Ready for submission (manual step)

**After upload, you must:**
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Click on the new version
4. Fill in:
   - What's New (release notes)
   - Keywords (if first release)
   - Description (if first release)
   - Screenshots (if first release)
5. Click "Submit for Review"

### Version Management

**Bump Patch Version (1.0.0 → 1.0.1)**

For bug fixes and minor changes:

```bash
bundle exec fastlane bump_patch
```

**Bump Minor Version (1.0.0 → 1.1.0)**

For new features:

```bash
bundle exec fastlane bump_minor
```

**Bump Major Version (1.0.0 → 2.0.0)**

For breaking changes:

```bash
bundle exec fastlane bump_major
```

**All bump commands:**
- Update `CFBundleShortVersionString` in Info.plist
- Commit the change to git
- Create a git tag (e.g., `v1.0.1`)

**Don't forget to push tags:**
```bash
git push && git push --tags
```

### Run Tests

```bash
# Full test suite with coverage
bundle exec fastlane test

# Or use the quick script
./quick-test.sh
```

---

## Troubleshooting

### Error: "cannot load such file -- abbrev"

**Cause:** Ruby 3.4+ removed `abbrev` and `ostruct` from default gems.

**Solution:**
```bash
# Ensure your Gemfile has these lines:
gem "abbrev"
gem "ostruct"

# Then reinstall:
bundle install
```

### Error: "Could not find .env file" or Environment Variables Not Loading

**Cause:** Either `.env` doesn't exist, or Fastfile isn't loading dotenv correctly.

**Solution:**
```bash
# 1. Create .env file
cp .env.default .env

# 2. Fill in your values
nano .env

# 3. Verify Fastfile has this at the TOP (before default_platform):
# require 'dotenv'
# env_file = File.expand_path('../.env', __dir__)
# Dotenv.load(env_file) if File.exist?(env_file)
```

### Error: "No signing certificate 'Mac Installer Distribution' found"

**Cause:** Missing required certificate for Mac App Store.

**Solution:** See [Code Signing Certificates](#code-signing-certificates) section above to create this certificate.

### Error: "No profiles for 'com.strategicnerds.LinearBar' were found"

**Cause:** Automatic signing couldn't create provisioning profile.

**Solution:**
1. Verify Xcode has "Automatically manage signing" enabled
2. Ensure bundle identifier matches Apple Developer Portal
3. Check that `-allowProvisioningUpdates` flag is in Fastfile xcargs (it is)
4. Try building once in Xcode (Product → Build) to trigger profile creation

### Error: "Apple Generic Versioning is not enabled"

**Cause:** Using agvtool-based actions (`increment_build_number`, `increment_version_number`).

**This should NOT happen** - our Fastfile uses `plutil` commands, not agvtool.

**If you see this:**
1. Check your Fastfile for any `increment_*` actions
2. Replace with direct `plutil` commands (see examples in Fastfile)

### Error: Fastlane Hangs After Upload

**Cause:** Waiting for Apple's build processing (5-30 minutes).

**This should NOT happen** - our Fastfile uses `skip_waiting_for_build_processing: true`.

**If it happens:**
1. Kill the process (Ctrl+C)
2. Verify Fastfile has `skip_waiting_for_build_processing: true` in upload_to_testflight
3. Build will still process on Apple's servers
4. Check App Store Connect in 10-15 minutes

### Error: "Could not find Xcode project" or "No such file or directory"

**Cause:** Running Fastlane from wrong directory.

**Solution:** Always run from PROJECT_ROOT:
```bash
cd /Users/prashant/Developer/linear-bar
bundle exec fastlane <lane_name>
```

### Error: Build Succeeds But App Crashes on Launch

**Cause:** Usually an entitlements or sandboxing issue.

**Solution:**
1. Check LinearBar.entitlements for required capabilities
2. Verify App Sandbox is enabled
3. Check Console.app for crash logs
4. Ensure all required entitlements are in App Store Connect

### Git Status Errors

**"You have uncommitted changes"**

For TestFlight, this is just a warning. For production releases, commit first:

```bash
git add .
git commit -m "Prepare for v1.0.1 release"
```

### Certificate Expiration Warnings

Check certificate expiration:

```bash
security find-identity -v -p codesigning
```

Certificates expire after 1 year. Renew them:
1. Go to Apple Developer Portal → Certificates
2. Revoke expiring certificate
3. Create new one (same type)
4. Download and install

---

## What Was Automated

Time savings: **~30-45 minutes per deployment → ~5 minutes** ⚡

### Fully Automated ✅

- **Build number incrementation** - Automatic on every build
- **Version number bumping** - Semantic versioning (patch/minor/major)
- **Code signing** - Automatic via Xcode (no manual cert management)
- **Provisioning profiles** - Auto-created and managed
- **App archiving** - Full .pkg build for Mac App Store
- **TestFlight upload** - Direct to App Store Connect
- **App Store upload** - Ready for review submission
- **Git tagging** - Version tags created automatically
- **Changelog management** - Keep a Changelog format
- **Pre-flight checks** - Validates environment before deployment

### Manual Steps (Intentionally) ⚠️

1. **Create App Store Connect API key** (one-time)
2. **Create Mac Installer Distribution certificate** (one-time, required for macOS)
3. **Fill in .env file** (one-time)
4. **Submit for App Store review** (safety - you control timing)
5. **Fill in "What's New"** (required by Apple per release)
6. **Add screenshots** (one-time, if not using deliver)
7. **Push git tags** (safety - you control when)

---

## Maintenance

### Update Fastlane

```bash
cd /Users/prashant/Developer/linear-bar
bundle update fastlane
```

### Update All Gems

```bash
bundle update
```

### Renew Code Signing Certificates

**Apple Distribution** - Expires annually:

1. Check expiration: `security find-identity -v -p codesigning`
2. If expiring soon:
   - Go to Apple Developer Portal → Certificates
   - Revoke old certificate
   - Create new "Apple Distribution" certificate
   - Download and double-click to install

**Mac Installer Distribution** - Expires annually:

1. Follow same process as Apple Distribution
2. Select "Mac Installer Distribution" instead
3. This is CRITICAL for Mac App Store - don't let it expire!

**Automatic signing will use new certs automatically** - no Fastlane changes needed.

### Rotate App Store Connect API Key

If compromised or expiring:

1. Generate new key in App Store Connect
2. Download new .p8 file
3. Replace `fastlane/app_store_connect_api_key.p8`
4. Update `.env` with new Key ID and Issuer ID
5. Revoke old key in App Store Connect

### Update App Store Metadata

To update description, keywords, screenshots without a new build:

```bash
bundle exec fastlane metadata
```

Or manually in App Store Connect → My Apps → LinearBar → App Store tab.

---

## Quick Reference

### Most Common Commands

```bash
# From anywhere in project:
cd /Users/prashant/Developer/linear-bar

# Interactive deployment menu
./deploy.sh

# Deploy to TestFlight
./deploy.sh beta
# or
bundle exec fastlane beta

# Deploy to App Store
./deploy.sh release
# or
bundle exec fastlane release

# Bump version
bundle exec fastlane bump_patch   # 1.0.0 → 1.0.1
bundle exec fastlane bump_minor   # 1.0.0 → 1.1.0
bundle exec fastlane bump_major   # 1.0.0 → 2.0.0

# Run tests
./quick-test.sh
# or
bundle exec fastlane test

# Pre-flight checks
bundle exec fastlane prep

# Update dependencies
bundle update
```

### File Locations

```
PROJECT_ROOT: /Users/prashant/Developer/linear-bar

Configuration:
  - .env                                     (your secrets)
  - .env.default                             (template)
  - Gemfile                                  (Ruby dependencies)
  - fastlane/Appfile                         (Apple ID config)
  - fastlane/Fastfile                        (lanes)
  - fastlane/app_store_connect_api_key.p8    (API key)

Scripts:
  - deploy.sh                                (interactive menu)
  - quick-test.sh                            (quick tests)

Info:
  - CHANGELOG.md                             (version history)
  - DEPLOY-STEPS.md                          (this file)
  - app-store-text.md                        (App Store listing)

Build Output:
  - fastlane/builds/*.pkg                    (built packages)

Xcode:
  - LinearBar.xcodeproj                      (project file)
  - LinearBar/Resources/Info.plist           (version/build numbers)
```

---

## Support

- **Issues:** Check [Troubleshooting](#troubleshooting) section
- **Fastlane Docs:** https://docs.fastlane.tools/
- **Apple Developer:** https://developer.apple.com/support/
- **App Store Connect:** https://appstoreconnect.apple.com/

---

**Happy Deploying! 🚀**

Remember: The first deployment is always the hardest. After setup, it's just `./deploy.sh` and you're done!
