# GitHub Actions Setup Guide

## Overview
This project uses GitHub Actions to automatically build and publish APKs on every push to the main branch. The workflow handles:

- ✅ Flutter dependency installation
- ✅ APK compilation in release mode
- ✅ Artifact storage for 30 days
- ✅ Automatic GitHub Release creation
- ✅ APK publication for download

## Automatic Builds

### Triggers
The workflow runs automatically on:
- **Push to `main` branch** → Creates GitHub Release with APK
- **Push to `develop` branch** → Builds APK (artifacts only, no release)
- **Pull Requests** → Builds APK (artifacts only, no release)
- **Manual trigger** → Run from Actions tab on GitHub

### APK Output
| Event | Artifact | Release |
|-------|----------|---------|
| Push to main | ✅ Yes | ✅ Yes |
| Push to develop | ✅ Yes | ❌ No |
| Pull request | ✅ Yes | ❌ No |

## Signing for Play Store

The current workflow produces **unsigned APKs**. To create signed APKs for Google Play Store:

### Step 1: Generate Signing Key (One-time)
```bash
keytool -genkey -v -keystore ~/neubofy-productive-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias neubofy-productive
```

### Step 2: Encode Key to Base64
```bash
base64 ~/neubofy-productive-key.jks | tr -d '\n'
```

### Step 3: Add GitHub Secrets
In your GitHub repository settings:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Create these secrets:
   - `KEYSTORE_BASE64`: Base64-encoded JKS file (from Step 2)
   - `KEYSTORE_PASSWORD`: Your keystore password
   - `KEY_ALIAS`: `neubofy-productive`
   - `KEY_PASSWORD`: Your key password

### Step 4: Update Workflow
Add to `.github/workflows/build-apk.yml` before the build step:

```yaml
- name: Decode keystore
  run: |
    echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > ~/keystore.jks
    echo "${{ secrets.KEYSTORE_PASSWORD }}" > ~/key.properties
    echo "${{ secrets.KEY_ALIAS }}" >> ~/key.properties
    echo "${{ secrets.KEY_PASSWORD }}" >> ~/key.properties

- name: Build signed APK
  run: |
    flutter build apk --release \
      --dart-define=KEYSTORE_PATH=~/keystore.jks \
      --dart-define=KEYSTORE_PASSWORD=${{ secrets.KEYSTORE_PASSWORD }} \
      --dart-define=KEY_ALIAS=${{ secrets.KEY_ALIAS }} \
      --dart-define=KEY_PASSWORD=${{ secrets.KEY_PASSWORD }}
```

## Accessing Built APKs

### Option 1: From GitHub Releases (Main Branch Only)
1. Go to your repository's **Releases** page
2. Latest release has `neubofy-productive-release.apk`
3. Download and install on Android device

### Option 2: From Actions Artifacts (All Branches)
1. Go to **Actions** tab
2. Click on the latest workflow run
3. Scroll down to **Artifacts**
4. Download `apk-release.zip`
5. Extract and install APK

### Option 3: Manual Download
```bash
# Download latest APK from main branch
gh release download --repo yourusername/neubofy \
  --pattern "*.apk" --dir ./downloads
```

## CI/CD Pipeline Features

### Automatic PR Comments
When you open a pull request:
- Workflow runs automatically
- Builds APK
- Comments on PR with link to artifacts

### Automatic Releases
On push to `main`:
- APK is built
- GitHub Release is created
- Release tagged as `v-build-{BUILD_ID}`
- APK attached to release
- Ready for distribution

## Troubleshooting

### Build Fails: Java Version
**Error**: `java.lang.UnsupportedClassVersionError`
**Solution**: Update Java to 17+ in workflow:
```yaml
- uses: actions/setup-java@v3
  with:
    java-version: '17'  # Must be 17+
```

### Build Fails: Flutter Not Found
**Solution**: Ensure Flutter setup step is before build:
```yaml
- uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.13.0'
    cache: true  # Speeds up subsequent builds
```

### APK Not in Artifacts
**Solution**: Check workflow log for build errors. APK location is:
```
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/apk/release/app-release.apk
```

### Need to Skip CI
Add `[skip ci]` or `[ci skip]` to commit message:
```bash
git commit -m "Minor docs fix [skip ci]"
```

## Next Steps

1. **Set up signing keys** for Play Store releases
2. **Configure branch protection** to require CI to pass
3. **Link Play Store account** for automated releases
4. **Create changelog** from git commits in releases

## References
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Guide](https://flutter.dev/docs/deployment/cd)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
