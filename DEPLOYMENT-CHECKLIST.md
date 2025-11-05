# LinearBar - Deployment Readiness Checklist

## ✅ Pre-Deployment Setup (One-Time)

### Environment Configuration
- [x] Ruby 3.4.7 installed
- [x] Bundler installed (`gem install bundler`)
- [x] Xcode 26.1 installed with Command Line Tools
- [x] Gemfile created with Ruby 3.4+ compatibility gems
- [x] Dependencies installed (`bundle install --path vendor/bundle`)
- [x] .env file created with credentials
- [x] .env.default committed to git as template
- [x] .gitignore updated to exclude secrets

### Fastlane Setup
- [x] fastlane/ directory created
- [x] Appfile configured with Apple ID and Team ID
- [x] Fastfile created with all lanes
- [x] App Store Connect API key (.p8) copied from meeting-notifier
- [x] Environment variables configured
- [x] Pre-flight checks passing (`bundle exec fastlane prep`)

### Code Signing
- [x] Xcode automatic signing enabled
- [x] Apple Development certificate installed
- [x] Apple Distribution certificate installed
- [ ] Mac Installer Distribution certificate (**NEEDED FOR APP STORE ONLY, NOT TESTFLIGHT**)

### Scripts & Documentation
- [x] deploy.sh created and executable
- [x] quick-test.sh created and executable
- [x] CHANGELOG.md created
- [x] DEPLOY-STEPS.md created (comprehensive guide)
- [x] DEPLOYMENT-SUMMARY.md created (quick reference)
- [x] app-store-text.md created (App Store listing)

### Validation Tests
- [x] `bundle exec fastlane lanes` lists all lanes
- [x] `bundle exec fastlane prep` passes pre-flight checks
- [x] Info.plist read/write working
- [x] Version reading working (plutil)
- [x] Xcode build succeeds
- [x] deploy.sh script working

---

## 🚀 Ready for TestFlight Beta

### You Can Deploy RIGHT NOW!

Everything needed for TestFlight is ready:

```bash
cd /Users/prashant/Developer/linear-bar
./deploy.sh
# Select option 1 for TestFlight
```

**What Will Happen:**
1. ✅ Pre-flight checks run
2. ✅ Build number increments automatically (1 → 2)
3. ✅ App builds with signing
4. ✅ Uploads to App Store Connect
5. ⏱️  Build processes on Apple's servers (10-15 min)
6. ✅ Available in TestFlight for testing

**Timeline:**
- Script execution: ~5 minutes
- Apple processing: ~10-15 minutes
- **Total:** ~15-20 minutes

---

## 📋 Before First TestFlight Deployment

### App Store Connect Setup
- [ ] App created in App Store Connect
- [ ] Bundle ID `com.strategicnerds.LinearBar` registered
- [ ] TestFlight internal testers added (optional)
- [ ] Export compliance info filled out (if applicable)

### Local Preparation
- [ ] All code committed to git
- [ ] Version set to 1.0 (build 1) - **ALREADY SET ✅**
- [ ] Release notes prepared for TestFlight

### Run Pre-Flight Check

```bash
bundle exec fastlane prep
```

Should show:
- ✅ Environment variables: OK
- ✅ API key file: OK
- ✅ Apple Distribution certificate: OK
- ⚠️  Mac Installer Distribution certificate not found (EXPECTED - not needed for TestFlight)
- ✅ Current version: 1.0 (build 1)
- ✅ All pre-flight checks passed!

---

## 📱 TestFlight Deployment Steps

### Step 1: Run Deployment

```bash
cd /Users/prashant/Developer/linear-bar
./deploy.sh
```

Select option 1 (TestFlight)

Or directly:
```bash
bundle exec fastlane beta
```

### Step 2: Monitor Progress

The script will:
- Show pre-flight check results
- Build the app
- Upload to App Store Connect (completes in seconds!)
- Display success message

**Expected Output:**
```
🚀 Build uploaded to TestFlight!
Build will be available for testing in 10-15 minutes
Check status at: https://appstoreconnect.apple.com
```

### Step 3: Verify in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Go to TestFlight tab
4. Wait for build to finish processing (~10-15 min)
5. Add build to internal testing group (if not automatic)

### Step 4: Test on Device

1. Download TestFlight app from Mac App Store
2. Open TestFlight
3. Find LinearBar
4. Click "Install"
5. Test all functionality

---

## 🏪 App Store Production Release

### Prerequisites
- [ ] TestFlight testing completed
- [ ] All critical bugs fixed
- [ ] **Mac Installer Distribution certificate installed** (**REQUIRED!**)
- [ ] App Store screenshots prepared
- [ ] App Store description finalized
- [ ] Privacy policy URL ready
- [ ] Support URL ready

### Create Mac Installer Distribution Certificate

**This is REQUIRED for App Store, but NOT for TestFlight**

1. Go to [Apple Developer Portal → Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click "+" button
3. Select "Mac Installer Distribution"
4. Create CSR:
   - Open Keychain Access
   - Certificate Assistant → Request a Certificate from a Certificate Authority
   - Your email: prashant_sridharan@hotmail.com
   - Common Name: Mac Installer Distribution
   - Save to disk
5. Upload CSR to Apple Developer Portal
6. Download certificate (.cer file)
7. Double-click to install in Keychain
8. Verify:
   ```bash
   security find-identity -v -p codesigning | grep "Mac Installer"
   ```

### Deployment Steps

1. **Bump version (if needed)**
   ```bash
   bundle exec fastlane bump_patch   # 1.0.0 → 1.0.1
   # or
   bundle exec fastlane bump_minor   # 1.0.0 → 1.1.0
   # or
   bundle exec fastlane bump_major   # 1.0.0 → 2.0.0
   ```

2. **Commit version change**
   ```bash
   git add LinearBar/Resources/Info.plist
   git commit -m "Bump version to 1.0.0"
   git push && git push --tags
   ```

3. **Deploy to App Store**
   ```bash
   ./deploy.sh
   # Select option 2 (App Store)
   ```

4. **Fill in App Store Connect**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Select your app
   - Click "Prepare for Submission"
   - Fill in:
     - Version number
     - What's New (copy from CHANGELOG.md)
     - Keywords (from app-store-text.md)
     - Description (from app-store-text.md)
     - Screenshots
     - Support URL
     - Privacy Policy URL

5. **Submit for Review**
   - Click "Submit for Review"
   - Answer export compliance questions
   - Wait for Apple review (typically 1-3 days)

---

## 🔄 Regular Deployment Workflow

### For New TestFlight Builds

```bash
cd /Users/prashant/Developer/linear-bar

# Make your code changes

# Commit changes
git add .
git commit -m "Fix bug in favorites view"

# Deploy to TestFlight
./deploy.sh
# Select option 1

# Build number auto-increments (e.g., 1 → 2)
```

### For New App Store Versions

```bash
# Bump version
bundle exec fastlane bump_patch   # or bump_minor, bump_major

# Commit version bump
git push && git push --tags

# Deploy
./deploy.sh
# Select option 2

# Complete submission in App Store Connect
```

---

## 📊 Status Dashboard

### Current Configuration

| Item | Value |
|------|-------|
| Version | 1.0 |
| Build | 1 |
| Bundle ID | com.strategicnerds.LinearBar |
| Team ID | 955GSY56UT |
| Apple ID | prashant_sridharan@hotmail.com |
| Platform | macOS 13.0+ |
| API Key ID | LX39DTG7L3 |
| Issuer ID | 69a6de75-1a97-47e3-e053-5b8c7c11a4d1 |

### Readiness Status

| Category | Status |
|----------|--------|
| **TestFlight** | ✅ **READY NOW** |
| **App Store** | ⚠️  **NEED Mac Installer Cert** |
| Environment | ✅ Configured |
| Code Signing | ✅ Automatic |
| API Key | ✅ Installed |
| Scripts | ✅ Working |
| Documentation | ✅ Complete |

---

## 🆘 Quick Troubleshooting

### Build Fails

1. Run pre-flight check:
   ```bash
   bundle exec fastlane prep
   ```

2. Check certificates:
   ```bash
   security find-identity -v -p codesigning
   ```

3. Clean and rebuild in Xcode:
   - Product → Clean Build Folder (⌘⇧K)
   - Product → Build (⌘B)

### Upload Fails

1. Verify API key file exists:
   ```bash
   ls -lh fastlane/app_store_connect_api_key.p8
   ```

2. Check environment variables:
   ```bash
   cat .env | grep APP_STORE_CONNECT
   ```

3. Verify API key is valid in App Store Connect

### "Mac Installer Distribution certificate not found"

- **For TestFlight:** Ignore this warning - not needed
- **For App Store:** Create the certificate (see steps above)

### Script Hangs

- Check internet connection
- Verify not waiting for 2FA (should use API key)
- Kill and restart: Ctrl+C, then run again

---

## 📚 Documentation Index

- **DEPLOYMENT-SUMMARY.md** - Quick start and overview (this file's sibling)
- **DEPLOY-STEPS.md** - Comprehensive guide with troubleshooting
- **DEPLOYMENT-CHECKLIST.md** - This file - step-by-step checklist
- **CHANGELOG.md** - Version history
- **app-store-text.md** - App Store listing copy
- **.env.default** - Environment template

---

## ✅ Final Verification

Before your first deployment, verify:

```bash
# 1. Check all files exist
ls -1 Gemfile fastlane/Appfile fastlane/Fastfile .env fastlane/app_store_connect_api_key.p8 deploy.sh

# 2. Run pre-flight checks
bundle exec fastlane prep

# 3. Test build (without signing)
xcodebuild -project LinearBar.xcodeproj -scheme LinearBar clean build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# 4. List available lanes
bundle exec fastlane lanes
```

If all pass: **YOU'RE READY TO DEPLOY!** 🚀

---

## 🎯 Your First Deployment

Ready to deploy? Just run:

```bash
cd /Users/prashant/Developer/linear-bar
./deploy.sh
```

Select option 1 for TestFlight, and follow the prompts!

**The script handles everything:**
- ✅ Pre-flight checks
- ✅ Build number increment
- ✅ Code signing
- ✅ App archiving
- ✅ Upload to TestFlight
- ✅ Success confirmation

**Time required:** ~5 minutes
**Difficulty:** Press 1, press Enter, done!

---

**Happy Deploying! 🚀**
