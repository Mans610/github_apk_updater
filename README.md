# github_apk_updater

Auto-update your Flutter Android app via GitHub Releases — no server, no third-party service.

### ✨ Next-Level Features Added in v1.0.8+:
- **Streamlined Browser Download**: When users tap update, it opens their browser to download and install the new APK smoothly.
- **"Skip This Version" Feature**: Allows your users to hide the dialog until you release the next version.
- **Smart Semantic Versioning**: Bulletproof version parsing (`pub_semver`) knows `1.22.0` is seamlessly newer than `1.9.0`.
- **Fully Customizable UI**: Redesigned default UI that matches your app's primary theme color, or supply your own entirely custom Widget via the new `dialogBuilder`.

---

## How It Works

```
You push code to GitHub
  → GitHub Actions builds APK automatically
  → Uploads APK to GitHub Releases (free)
  → Updates version.json

User opens your app
  → App checks version.json silently
  → If new version exists → shows update dialog
  → User taps Update Now → downloads & installs
```

---

## ⚠️ Required: Copy Workflow File (Do This First)

**Every project using this package needs a GitHub Actions workflow file.**
Without this file, GitHub will NOT build your APK automatically.

**Step 1 — Create this folder in your project root:**
```
your_project/
└── .github/
    └── workflows/
        └── build_apk.yml   ← create this file
```

**Step 2 — Paste this into `build_apk.yml`:**

```yaml
name: Build & Release APK

on:
  push:
    branches:
      - main

permissions:
  contents: write

jobs:
  build:
    name: Build APK
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Cache Debug Keystore for Stable Signatures
        uses: actions/cache@v4
        with:
          path: ~/.android/debug.keystore
          key: debug-keystore

      - name: Get Flutter packages
        run: flutter pub get

      - name: Build APK
        run: flutter build apk --release

      - name: Get version from pubspec
        id: get_version
        run: |
          VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//' | tr -d ' ')
          echo "VERSION=$VERSION" >> $GITHUB_OUTPUT

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v${{ steps.get_version.outputs.VERSION }}
          name: v${{ steps.get_version.outputs.VERSION }}
          files: build/app/outputs/flutter-apk/app-release.apk
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Update version.json
        run: |
          VERSION=${{ steps.get_version.outputs.VERSION }}
          REPO="${{ github.repository }}"
          APK_URL="https://github.com/$REPO/releases/download/v$VERSION/app-release.apk"
          printf '{\n  "latest_version": "%s",\n  "apk_url": "%s",\n  "force_update": false,\n  "release_notes": "New update available!"\n}\n' "$VERSION" "$APK_URL" > version.json

      - name: Commit version.json
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add version.json
          git diff --staged --quiet || git commit -m "chore: bump version.json to v${{ steps.get_version.outputs.VERSION }}"
          git push
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Step 3 — Add `version.json` to your project root:**

```json
{
  "latest_version": "1.0.0",
  "apk_url": "https://github.com/USERNAME/REPO/releases/download/v1.0.0/app-release.apk",
  "force_update": false,
  "release_notes": "Initial release."
}
```

---

## Install Package

```yaml
dependencies:
  github_apk_updater: ^1.0.0
```

---

## 🔒 Android Permissions (Required)

To allow the app to check for updates on GitHub, you **must** add this permission to your `android/app/src/main/AndroidManifest.xml` (inside the `<manifest>` tag, right above `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## Add to Your App

```dart
import 'package:github_apk_updater/github_apk_updater.dart';

final updater = GithubApkUpdater(
  config: UpdaterConfig(
    githubUsername: 'your_username',  // ← your GitHub username
    githubRepo: 'your_repo',          // ← your GitHub repo name
  ),
);

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    updater.check(context);
  });
}
```

---

## Every Push Routine

```bash
# 1. Bump version in pubspec.yaml
#    example: 1.0.0+1 → 1.0.1+2

# 2. Add and Commit!
git add .
git commit -m "chore: bump version for update"

# 3. Pull latest changes (if any)
git pull --rebase

# 4. Push to trigger GitHub Actions
git push origin main
```

---

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `githubUsername` | required | Your GitHub username |
| `githubRepo` | required | Your repository name |
| `branch` | `main` | Branch with version.json |
| `dialogTitle` | `Update Available` | Dialog title |
| `updateButtonText` | `Update Now` | Update button label |
| `laterButtonText` | `Later` | Dismiss button label |
| `skipButtonText` | `Skip This Version` | Button label for skipping an update |
| `allowSkip` | `false` | Shows a "Skip" button. Saves version locally to never show dialog for this version again. |
| `dialogBuilder` | `null` | Provide a completely custom Widget (e.g. BottomSheet) to display. |

---

## Force Update

Set `force_update: true` in `version.json` — users cannot skip the update.

---

## Fully Custom UI

Don't like the default popup? You can pass your own completely custom widgets using the `dialogBuilder` in your config!

```dart
final updater = GithubApkUpdater(
  config: UpdaterConfig(
    githubUsername: 'your_username',
    githubRepo: 'your_repo',
    // Supply your own Widget! 
    dialogBuilder: (BuildContext context, UpdateInfo info) {
      return AlertDialog(
        title: Text('Huge Update! v${info.latestVersion}'),
        content: Text(info.releaseNotes),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(context), 
             child: const Text('Cancel'),
          ),
          ElevatedButton(
             // Use our package's built-in URL string to download it yourself, 
             // or open it however you prefer!
             onPressed: () => launchUrl(Uri.parse(info.apkUrl)), 
             child: const Text('Get it now!'),
          ),
        ],
      );
    },
  ),
);
```

Or just fetch the raw data yourself:

```dart
final info = await GithubApkUpdater(config: config).getUpdateInfo();
if (info != null && info.hasUpdate) {
  print(info.latestVersion);
  print(info.apkUrl);
  print(info.releaseNotes);
}
```
