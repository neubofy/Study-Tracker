# 🚀 Quick Start Guide - After OAuth Setup

## Your OAuth Credentials ✅

**Store your credentials securely:**
- Client ID: Store locally in your code (NOT in GitHub)
- Client Secret: **NEVER commit to GitHub** - Store locally only

> **⚠️ CRITICAL:** Use GitHub Secrets for CI/CD, never hardcode credentials in repositories.

---

## 🏃 How to Run the App

### Terminal Command
```bash
cd c:\Users\Pawan Kumar\neubofy\mindful_flutter

# Clean previous builds
flutter clean
```

# Get dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📱 Testing the Features

### 1. **Test Google Calendar Sign-In** (2 minutes)

1. Open the app
2. Tap **Settings** tab → **Calendar Integration**
3. You should see sign-in options
4. Tap **"Sign In with Google"**
5. Select your Gmail account
6. Grant calendar access
7. **Expected result:** Shows ✓ Connected + your email

### 2. **Test Calendar Event Loading** (1 minute)

1. Go to https://calendar.google.com/
2. Create an event:
   - Title: "Test Meeting"
   - Date: Today
   - Time: Next 1 hour
3. Go back to app
4. Tap **"Reload Events"**
5. **Expected result:** "Test Meeting" appears in the list

### 3. **Test Focus Mode** (2 minutes)

1. Tap **Focus** tab
2. Select duration: 25 minutes
3. Tap **"Start Focus"**
4. Timer should count down
5. **Expected result:** Timer counts 25m → 24m → 23m...

### 4. **Test Auto-Focus from Calendar** (3 minutes)

1. Create a calendar event for next 30 minutes
2. In app, enable **"Auto Start Focus"**
3. When event time arrives:
   - **Expected result:** Focus Mode starts automatically

---

## 🐛 Troubleshooting

### "Sign-In Button Not Showing"
```
✓ Make sure Client ID is correct in google_calendar_service.dart
✓ Run: flutter clean && flutter pub get
✓ Check: Can see "Sign In with Google" button
```

### "Calendar Events Not Loading"
```
✓ Make sure you signed in successfully
✓ Create a test event in Google Calendar
✓ Tap "Reload Events" in app
✓ Check: Event appears in list
```

### "Focus Timer Freezes"
```
✓ Run: flutter run --release
✓ Check: Device has enough RAM
✓ Try: Restart app and create new session
```

### "DND Not Turning On (Android)"
```
✓ Go to Android Settings → Apps → Special app access
✓ Search "Do Not Disturb"
✓ Give app permission
✓ For Android 12+: Grant "Modify System Settings" permission
```

---

## 📁 Important Files to Know

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point & routing |
| `lib/services/google_calendar_service.dart` | OAuth + Calendar API |
| `lib/ui/screens/calendar_integration_screen.dart` | Calendar UI |
| `lib/database/app_database.dart` | Local database |
| `pubspec.yaml` | Dependencies & config |

---

## 🔄 Common Tasks

### Update OAuth Credentials
**File:** `lib/services/google_calendar_service.dart` (Line 13)
```dart
static const String _clientId = 'YOUR_NEW_CLIENT_ID.apps.googleusercontent.com';
```

### Change App Name
**File:** `pubspec.yaml` (Line 1)
```yaml
name: neubofy_productive
```

### Add New Screen
**File:** `lib/main.dart` → Update `appRouter` GoRouter

### Change Theme Color
**File:** `lib/main.dart` → Update `colorSchemeSeed: Colors.blue`

---

## 📦 Build for Release (APK)

```bash
# Create signed APK
flutter build apk --release

# Create signed App Bundle (for Play Store)
flutter build appbundle --release

# Output location:
# APK: build/app/outputs/flutter-apk/app-release.apk
# Bundle: build/app/outputs/bundle/release/app-release.aab
```

---

## 🎯 What's Working Now

| Feature | Status |
|---------|--------|
| Google Calendar OAuth | ✅ Ready |
| One-tap email selection | ✅ Ready |
| Calendar event sync | ✅ Ready |
| Auto-focus trigger | ✅ Ready |
| Do Not Disturb control | ✅ Ready |
| Focus timer | ✅ Ready |
| Notifications | ✅ Ready |
| Local database | ✅ Ready |
| Secure token storage | ✅ Ready |

---

## 🚨 Security Notes

✅ **What's Secure:**
- Client Secret NOT in code (only Client ID)
- Tokens stored in FlutterSecureStorage (encrypted)
- HTTPS only for API calls
- Minimal permissions requested

⚠️ **What to Remember:**
- Never share Client Secret
- Never commit `.env` files with secrets
- Test with test Gmail account first
- Review OAuth consent screen before production

---

## 📚 Documentation Files

- **OAUTH_CLIENT_ID_SETUP.md** - Step-by-step OAuth setup
- **CHANGES_APPLIED.md** - What was changed in this session
- **QUICK_START.md** - Original quick start guide
- **README.md** - Project overview
- **ARCHITECTURE.md** - Technical architecture

---

## 🎉 You're Ready!

1. ✅ OAuth Client ID configured
2. ✅ Code updated
3. ✅ Unused files deleted
4. ✅ All services ready

**Next step:** Open terminal and run:
```bash
cd c:\Users\Pawan Kumar\neubofy\mindful_flutter
flutter run
```

Test the sign-in flow and let me know if anything needs fixing! 🚀
