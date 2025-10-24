# Code Signing & Notarization Setup

**Required for App Store and direct distribution on macOS**

---

## Overview

macOS requires all distributed apps to be:
1. **Code Signed** - Cryptographically signed with a Developer ID
2. **Notarized** - Approved by Apple's notarization service
3. **Sandboxed** - Running with limited system access (for App Store)

---

## Prerequisites

### 1. Apple Developer Account
- **Required**: Paid Apple Developer Program membership ($99/year)
- Sign up at: https://developer.apple.com/programs/

### 2. Developer Certificates
You need two certificates:
- **Apple Development Certificate** - For development/testing
- **Apple Distribution Certificate** - For App Store submission

---

## Step 1: Create Certificates

### Using Xcode (Recommended)

1. Open Xcode
2. Go to **Xcode → Settings** (Cmd+,)
3. Select **Accounts** tab
4. Click **+** to add your Apple ID
5. Select your account → **Manage Certificates**
6. Click **+** → **Apple Development**
7. Click **+** → **Apple Distribution** (for App Store)

### Using Developer Portal (Manual)

1. Go to: https://developer.apple.com/account/resources/certificates
2. Click **+** to create new certificate
3. Choose **Apple Development** or **Apple Distribution**
4. Follow CSR (Certificate Signing Request) instructions
5. Download and install certificate

---

## Step 2: Create App ID

1. Go to: https://developer.apple.com/account/resources/identifiers
2. Click **+** to register new identifier
3. Select **App IDs** → **Continue**
4. Select **App** → **Continue**
5. Enter:
   - Description: `Local File Converter`
   - Bundle ID: `com.localfileconverter.app` (must match Info.plist)
6. Capabilities:
   - ✅ **Network Extensions** (for video downloads)
   - ✅ **User Selected Files** (for file access)
7. Click **Continue** → **Register**

---

## Step 3: Create Provisioning Profile

### For Development
1. Go to: https://developer.apple.com/account/resources/profiles
2. Click **+** → **macOS App Development**
3. Select App ID: `com.localfileconverter.app`
4. Select your development certificate
5. Select your Mac (if testing on specific device)
6. Name: `LocalFileConverter Development`
7. Download and double-click to install

### For App Store Distribution
1. Click **+** → **App Store**
2. Select App ID: `com.localfileconverter.app`
3. Select your distribution certificate
4. Name: `LocalFileConverter App Store`
5. Download and double-click to install

---

## Step 4: Configure Xcode Project

### Open Project in Xcode

Since this is a Swift Package Manager project, you need to:

```bash
# Open Package.swift in Xcode
cd /path/to/LocalFileConverter
open Package.swift
```

Or create an Xcode project:

```bash
# Generate Xcode project (older method)
swift package generate-xcodeproj
open LocalFileConverter.xcodeproj
```

### Configure Signing

1. Select project in navigator
2. Select **LocalFileConverter** target
3. Go to **Signing & Capabilities** tab

**For Development:**
- ✅ Automatically manage signing
- Team: [Your Team Name]
- Signing Certificate: **Apple Development**

**For Release:**
- ✅ Automatically manage signing
- Team: [Your Team Name]
- Signing Certificate: **Apple Distribution**

### Add Entitlements

1. In **Signing & Capabilities** tab
2. Click **+ Capability**
3. Add **App Sandbox**
4. Configure sandbox:
   - ✅ User Selected Files (Read/Write)
   - ✅ Network (Outgoing Connections)

5. The `LocalFileConverter.entitlements` file is already created

### Link Entitlements File

1. Select target → **Build Settings**
2. Search for "entitlements"
3. Set **Code Signing Entitlements** to:
   ```
   LocalFileConverter.entitlements
   ```

---

## Step 5: Build & Sign

### Development Build

```bash
# Build with signing
xcodebuild -scheme LocalFileConverter \
  -configuration Debug \
  CODE_SIGN_IDENTITY="Apple Development" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID"
```

### Release Build

```bash
# Build for release
xcodebuild -scheme LocalFileConverter \
  -configuration Release \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID" \
  archive -archivePath LocalFileConverter.xcarchive
```

### Verify Signing

```bash
# Check code signature
codesign -dvvv /path/to/LocalFileConverter.app

# Verify entitlements
codesign -d --entitlements - /path/to/LocalFileConverter.app

# Check if hardened runtime enabled
codesign -dvv /path/to/LocalFileConverter.app | grep runtime
```

---

## Step 6: Notarization

### Create App-Specific Password

1. Go to: https://appleid.apple.com/
2. Sign in with Apple ID
3. **Security** → **App-Specific Passwords**
4. Click **+** to generate
5. Name: `LocalFileConverter Notarization`
6. Save the password (you'll need it)

### Store Credentials in Keychain

```bash
# Store notarization credentials
xcrun notarytool store-credentials "LocalFileConverter-Profile" \
  --apple-id "your-email@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "your-app-specific-password"
```

### Create Archive

```bash
# Export app as archive
xcodebuild -exportArchive \
  -archivePath LocalFileConverter.xcarchive \
  -exportPath ./export \
  -exportOptionsPlist ExportOptions.plist
```

**Create ExportOptions.plist:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

### Create DMG (for direct distribution)

```bash
# Create distributable DMG
hdiutil create -volname "LocalFileConverter" \
  -srcfolder export/LocalFileConverter.app \
  -ov -format UDZO \
  LocalFileConverter.dmg
```

### Submit for Notarization

```bash
# Submit DMG for notarization
xcrun notarytool submit LocalFileConverter.dmg \
  --keychain-profile "LocalFileConverter-Profile" \
  --wait
```

This will output a submission ID. Check status:

```bash
# Check notarization status
xcrun notarytool info <submission-id> \
  --keychain-profile "LocalFileConverter-Profile"

# Get log if it failed
xcrun notarytool log <submission-id> \
  --keychain-profile "LocalFileConverter-Profile"
```

### Staple Notarization Ticket

Once notarization succeeds:

```bash
# Staple the notarization ticket to the app
xcrun stapler staple LocalFileConverter.dmg

# Verify stapling
xcrun stapler validate LocalFileConverter.dmg

# Check Gatekeeper approval
spctl -a -vvv -t install LocalFileConverter.dmg
```

---

## Step 7: App Store Submission

### Using Xcode

1. **Product** → **Archive**
2. Wait for archive to complete
3. Click **Distribute App**
4. Select **App Store Connect**
5. Select **Upload**
6. Choose signing: **Automatically manage signing**
7. Review content and click **Upload**

### Using Transporter App

1. Download **Transporter** from Mac App Store
2. Drag `.pkg` file into Transporter
3. Click **Deliver**

### Using Command Line

```bash
# Upload to App Store Connect
xcrun altool --upload-app \
  --type macos \
  --file LocalFileConverter.pkg \
  --username "your-email@example.com" \
  --password "your-app-specific-password"
```

---

## Important Notes

### ⚠️ Homebrew Tool Dependencies

**CRITICAL ISSUE**: The app currently depends on Homebrew-installed tools (ffmpeg, imagemagick, pandoc, 7z, yt-dlp).

**This will NOT work in the App Store** because:
- Apps can't execute arbitrary external binaries
- Sandbox prevents access to `/usr/local/bin` or `/opt/homebrew/bin`

**Solutions:**

#### Option 1: Bundle Tools (Recommended for App Store)
```bash
# Bundle required tools with app
mkdir -p LocalFileConverter.app/Contents/Resources/bin
cp /opt/homebrew/bin/ffmpeg LocalFileConverter.app/Contents/Resources/bin/
cp /opt/homebrew/bin/magick LocalFileConverter.app/Contents/Resources/bin/
# ... repeat for all tools
```

Update code to use bundled tools:
```swift
let bundlePath = Bundle.main.resourcePath! + "/bin"
let ffmpegPath = bundlePath + "/ffmpeg"
```

#### Option 2: XPC Service Helper
Create a privileged helper tool with proper entitlements

#### Option 3: Mac App Store Distribution Only (Not Direct)
Require users to install Homebrew tools separately (not ideal)

### 📋 Checklist Before Submission

- [ ] All icon sizes created and added
- [ ] Code signed with Distribution certificate
- [ ] Notarization successful
- [ ] Privacy policy URL (if collecting data)
- [ ] App Store screenshots (1280x800, 1440x900, 2880x1800)
- [ ] App description and keywords
- [ ] Support URL
- [ ] Bundle tools or add XPC helper
- [ ] Test on clean macOS installation
- [ ] Verify sandbox permissions work

---

## Troubleshooting

### "No signing certificate found"
- Go to Xcode → Settings → Accounts → Download Manual Profiles

### "Provisioning profile doesn't match"
- Check Bundle ID in Info.plist matches App ID
- Regenerate provisioning profile

### "Notarization failed - invalid signature"
- Ensure hardened runtime enabled
- Check entitlements are correct
- Verify all binaries are signed (including bundled tools)

### "App sandbox violation"
- Check entitlements file
- Ensure file access is user-initiated
- Review Console.app for violation logs

---

## Resources

- **Code Signing Guide**: https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/
- **Notarizing Guide**: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution
- **App Store Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **App Sandbox Guide**: https://developer.apple.com/documentation/security/app_sandbox

---

## Quick Reference Commands

```bash
# Check Team ID
xcrun security find-identity -v -p codesigning

# List keychains
security list-keychains

# Verify code signature
codesign --verify --deep --strict --verbose=2 LocalFileConverter.app

# Check if app is notarized
spctl -a -vv LocalFileConverter.app

# Display app entitlements
codesign -d --entitlements :- LocalFileConverter.app
```

---

**Next Steps:** Complete icon creation, bundle required tools, then follow steps above for code signing and notarization.
