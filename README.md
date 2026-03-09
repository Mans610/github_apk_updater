# github_apk_updater

Auto-update your Flutter Android app via GitHub Releases.

**Zero cost. Zero third-party services. Zero server. Fully self-owned.**

---

## How It Works

```
You: git push
        → GitHub Actions builds APK automatically
        → Uploads APK to GitHub Releases (free)
        → Updates version.json on your repo

User opens app:
        → App fetches version.json silently
        → If newer version → shows update dialog
        → User taps "Update Now" → downloads & installs
```

---

## Setup (4 steps only)

### Step 1 — Add to pubspec.yaml

```yaml
dependencies:
  github_apk_updater: ^1.0.0
```

### Step 2 — Add version.json to your project root

Create a file called `version.json` in your project root:

```json
{
  "latest_version": "1.0.0",
  "apk_url": "https://github.com/YOUR_USERNAME/YOUR_REPO/releases/download/v1.0.0/app-release.apk",
  "force_update": false,
  "release_notes": "Initial release."
}
```

### Step 3 — Copy the GitHub Actions workflow

Copy `github-workflow-template.yml` from this package into your project:

```
your_project/
└── .github/
    └── workflows/
        └── build_apk.yml   ← paste the template here
```

### Step 4 — Add updater to your app

```dart
import 'package:github_apk_updater/github_apk_updater.dart';

// Create config once (put this somewhere global or in your controller)
final updater = GithubApkUpdater(
  config: UpdaterConfig(
    githubUsername: 'YOUR_USERNAME',   // ← your GitHub username
    githubRepo: 'YOUR_REPO',           // ← your GitHub repo name
  ),
);

// Call in your home screen initState
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    updater.check(context);
  });
}
```

**That's it. Done.**

---

## Configuration Options

```dart
UpdaterConfig(
  githubUsername: 'Mans610',          // required
  githubRepo: 'supperclubApp',        // required

  branch: 'main',                     // optional, default: 'main'
  dialogTitle: 'Update Available',    // optional
  updateButtonText: 'Update Now',     // optional
  laterButtonText: 'Later',           // optional
)
```

---

## Force Update

To force ALL users to update (cannot skip):

Edit `version.json` on GitHub and set:
```json
"force_update": true
```

Users will see the dialog with no "Later" button.

---

## Advanced — Custom UI

If you don't want the built-in dialog:

```dart
final info = await updater.getUpdateInfo();
if (info != null && info.hasUpdate) {
  // show your own dialog using info.latestVersion, info.apkUrl etc.
}
```

---

## Push Routine

Every time you want to release an update:

```bash
# 1. Bump version in pubspec.yaml
#    e.g. version: 1.0.0+1  →  version: 1.0.1+2

# 2. Push
git pull --rebase && git add . && git commit -m "your message" && git push origin main
```

GitHub Actions handles everything else. APK is built and users get notified automatically.

---

## Cost

| Item | Cost |
|------|------|
| GitHub repo + Actions | Free |
| APK storage (GitHub Releases) | Free |
| version.json hosting | Free |
| **Total** | **$0** |

---

## Android Permission Required

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
```

Users also need to enable **"Install from unknown sources"** once in Android settings. This is normal for apps distributed outside the Play Store.
