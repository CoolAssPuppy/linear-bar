# Using Doppler for Secrets Management

LinearBar supports loading OAuth credentials from Doppler for secure secrets management.

## Setup

### 1. Install Doppler CLI

```bash
# macOS
brew install dopplerhq/cli/doppler

# Or download from https://docs.doppler.com/docs/install-cli
```

### 2. Login to Doppler

```bash
doppler login
```

### 3. Create Doppler Project

```bash
# Create a new project
doppler projects create linearbar

# Set up the project in this directory
cd /Users/prashant/Developer/linear-bar
doppler setup
```

When prompted:
- **Project**: linearbar
- **Config**: dev (for development)

### 4. Add Your Secrets to Doppler

```bash
# Add Linear OAuth credentials
doppler secrets set LINEAR_CLIENT_ID="lin_oauth_xxxxx"
doppler secrets set LINEAR_CLIENT_SECRET="your_secret_here"
```

### 5. Run Xcode with Doppler

There are two ways to use Doppler with Xcode:

#### Option A: Run Xcode via Doppler (Recommended for Development)

```bash
# Run Xcode with Doppler environment variables injected
doppler run -- open LinearBar.xcodeproj
```

This automatically injects the secrets as environment variables.

#### Option B: Configure Xcode Scheme (Permanent)

1. In Xcode, click on the scheme dropdown (next to LinearBar) → Edit Scheme
2. Select **Run** → **Arguments** tab
3. Under **Environment Variables**, add:
   - `LINEAR_CLIENT_ID`: Use Doppler's value
   - `LINEAR_CLIENT_SECRET`: Use Doppler's value
4. Or better yet, add a **Pre-action** script to load from Doppler:

```bash
# In Edit Scheme → Build → Pre-actions → New Run Script Action
export $(doppler secrets download --no-file --format env)
```

## How It Works

The app checks for environment variables first:
1. If `LINEAR_CLIENT_ID` and `LINEAR_CLIENT_SECRET` are in environment → uses those
2. Otherwise → falls back to hardcoded values in `LinearAuthSecrets.swift`

This means:
- **With Doppler**: Secrets are never in code, always from Doppler
- **Without Doppler**: You can still hardcode them in `LinearAuthSecrets.swift` for quick local dev

## For Team Development

Each team member should:
1. Install Doppler CLI
2. Run `doppler login`
3. Run `doppler setup` in the project directory
4. They automatically get access to secrets (based on your Doppler permissions)

No need to share secrets via Slack/email! 🎉

## For CI/CD

In your CI environment:

```bash
# Authenticate with Doppler service token
doppler configure set token $DOPPLER_TOKEN --scope /path/to/project

# Run build with secrets
doppler run -- xcodebuild -project LinearBar.xcodeproj ...
```

## Quick Commands

```bash
# View current secrets
doppler secrets

# Download secrets to .env file (gitignored)
doppler secrets download --no-file --format env > .env

# Run any command with secrets
doppler run -- <your-command>
```

## Security Notes

- ✅ Secrets never stored in git
- ✅ Encrypted at rest in Doppler
- ✅ Audit logs of who accessed what
- ✅ Easy rotation (just update in Doppler)
- ✅ Works across team without sharing credentials

## Alternative: Simple Local Development

If you just want to develop locally without Doppler:

1. Open `LinearBar/Services/LinearAuthSecrets.swift`
2. Replace `YOUR_LINEAR_CLIENT_ID` with your actual ID
3. Replace `YOUR_LINEAR_CLIENT_SECRET` with your actual secret
4. This file is gitignored, so it's safe

---

**Recommendation**: Use Doppler for team projects or production. For solo development, the local file approach works great too!
