# frozen_string_literal: true

source "https://rubygems.org"

# Fastlane for iOS/macOS automation
gem "fastlane", "~> 2.219"

# Ruby 3.4+ compatibility - these gems were removed from stdlib
# Without these, you'll get "cannot load such file" errors
gem "abbrev"  # Removed from stdlib in Ruby 3.4
gem "ostruct" # Will be removed in Ruby 3.5

# Environment variable management (critical for Fastlane)
# Fastlane does NOT automatically load .env files - dotenv is required
gem "dotenv"
