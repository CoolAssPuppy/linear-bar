# Lessons

- When a requested Recent view refers to activity inside the connected service, do not replace it with local app history. Check the public API first, state any limits, and offer the closest remote meaning before implementation.
- For a polymorphic API model, check fields on the shared interface before adding subtype-specific presentation logic. Every visible row needs a meaningful label and a valid action target.
- A release fallback must preserve the expected package design. Mount and inspect a DMG before upload, including its background, `.DS_Store`, application, and Applications link.
