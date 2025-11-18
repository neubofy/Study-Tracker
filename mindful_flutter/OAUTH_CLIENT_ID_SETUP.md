# 🔐 OAuth Client ID Setup - Step by Step

## 🎯 What You Need to Do RIGHT NOW

Follow these exact steps to get your OAuth Client ID:

---

## Step 1: Go to Google Cloud Console

**Open this URL in your browser:**
```
https://console.cloud.google.com/
```

**You should see this screen:**
- Blue Google Cloud logo (top left)
- "Select a Project" button (top center)
- "Console" text

---

## Step 2: Create a New Project

**Click:** "Select a Project" button (top center)

**You'll see a popup, click:** "+ NEW PROJECT"

**Fill in:**
```
Project name: Neubofy Productive
Location: (leave default)
```

**Click:** "CREATE"

⏳ Wait 2-3 minutes for project to be created

---

## Step 3: Enable Google Calendar API

**In the search bar (top):** Type "Calendar API"

**Click:** "Google Calendar API" from results

**Click:** "ENABLE" button (blue button on right)

⏳ Wait 1 minute for API to be enabled

---

## Step 4: Enable Google Sign-In API

**In search bar:** Type "Google Sign-In API"

**Click:** "Google Sign-In API" from results

**Click:** "ENABLE" button

⏳ Wait 30 seconds

---

## Step 5: Create OAuth Consent Screen

**On left sidebar:** Click "OAuth consent screen"

**Select:** "External" (for personal use)

**Click:** "CREATE"

**Fill form:**
```
App name: Neubofy Productive
User support email: your-email@gmail.com
Developer contact: your-email@gmail.com
```

**Click:** "SAVE AND CONTINUE"

**Click:** "ADD OR REMOVE SCOPES"

**Search and add these 3 scopes:**
1. `calendar.readonly` ✓
2. `calendar.events.readonly` ✓  
3. `userinfo.email` ✓

**Click:** "UPDATE"

**Click:** "SAVE AND CONTINUE"

**Click:** "BACK TO DASHBOARD"

---

## Step 6: Create OAuth 2.0 Client ID (Web Application)

**On left sidebar:** Click "Credentials"

**Click:** "+ CREATE CREDENTIALS" button

**Select:** "OAuth 2.0 Client ID"

**Select application type:** "Web application"

**Fill in:**
```
Name: Neubofy Web Client
```

**Add authorized redirect URIs:**

Click: "Add URI" and add these 4:
```
1. http://localhost:8080/
2. http://localhost:7777/
3. com.neubofy.mindful://oauth
4. urn:ietf:wg:oauth:2.0:oob
```

**Click:** "CREATE"

**You'll see a popup with your credentials!** 👇

---

## Step 7: Copy Your Client ID

**In the popup, you'll see:**

```
Client ID: YOUR_CLIENT_ID.apps.googleusercontent.com
Client Secret: NEVER_SHARE_THIS_IN_PUBLIC_REPOS
```

⚠️ **IMPORTANT:** Never commit Client Secret to GitHub or public repositories.

Example:
```
123456789-abcdefghijklmnop.apps.googleusercontent.com
```

---

## Step 8: Update Your Flutter Code

**File:** `lib/services/google_calendar_service.dart`

**Find line 13:**
```dart
static const String _clientId = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
```

**Replace with your actual Client ID:**
```dart
static const String _clientId = '123456789-abcdefghijklmnop.apps.googleusercontent.com';
```

**Save the file**

---

## Step 9: Test It

**Open Terminal/PowerShell:**

```bash
cd c:\Users\Pawan Kumar\neubofy\mindful_flutter

flutter clean
flutter pub get
flutter run
```

**In the app:**
1. Go to Settings tab
2. Tap "Calendar Integration"
3. Should NOT show errors
4. Tap "Sign In"
5. Should ask to sign in with Google

✅ **If this works, you're done!**

---

## 🆘 Troubleshooting

### "Invalid Client ID"
- Copy the ENTIRE Client ID (including `.apps.googleusercontent.com`)
- Make sure there are no extra spaces
- Check spelling carefully

### "Redirect URI Mismatch"
- Go back to Google Cloud Console
- Credentials → OAuth 2.0 Client ID
- Make sure these 4 URIs are added:
  - http://localhost:8080/
  - http://localhost:7777/
  - com.neubofy.mindful://oauth
  - urn:ietf:wg:oauth:2.0:oob

### "Calendar API not enabled"
- Go to Google Cloud Console
- Search "Google Calendar API"
- Click "Enable"
- Wait 1 minute

### "No sign-in button appears"
- Make sure `_clientId` is set (not 'YOUR_CLIENT_ID')
- Run `flutter clean`
- Run `flutter run` again

---

## ✅ Verification Checklist

Mark each as complete:

```
☐ Opened Google Cloud Console
☐ Created new project "Neubofy Productive"
☐ Enabled Google Calendar API
☐ Enabled Google Sign-In API
☐ Created OAuth Consent Screen
☐ Added 3 scopes to consent screen
☐ Created OAuth 2.0 Client ID (Web)
☐ Added 4 redirect URIs
☐ Copied Client ID
☐ Updated Flutter code with Client ID
☐ Ran: flutter clean
☐ Ran: flutter pub get
☐ Ran: flutter run
☐ App shows no errors
☐ Can tap "Sign In" button
```

If all ✅: **You're ready to test!** 🎉

---

## 📱 Testing After Setup

### Quick Test (2 minutes)

1. **Run app:**
   ```bash
   flutter run
   ```

2. **In app:**
   - Go to Settings tab
   - Tap "Calendar Integration"
   - Tap "Sign In" button
   - Should see Google sign-in screen
   - Sign in with your Gmail

3. **Expected result:**
   - Shows "✓ Connected"
   - Shows your email
   - Shows "Last synced: just now"

✅ **If you see this, OAuth setup is complete!**

---

## 🔄 Next Steps After Setup

1. **Create test calendar event:**
   - Open https://calendar.google.com/
   - Create event for next 30 minutes
   - Title: "Test Focus"

2. **Check if app shows the event:**
   - Go back to app
   - Scroll down to "Calendar Events"
   - Should see "Test Focus" listed

3. **Test auto-focus (BONUS):**
   - Make event start time = NOW
   - End time = 30 min from now
   - Toggle "Auto Focus" ON
   - Watch if Focus Mode starts automatically

✅ **If all these work, you're production-ready!**

---

## 📞 Quick Reference

| Step | What to Do | Where | Result |
|------|-----------|-------|--------|
| 1 | Go to Cloud Console | https://console.cloud.google.com | Access console |
| 2 | Create project | Project selector → New | Project created |
| 3 | Enable Calendar API | Search → Enable | API ready |
| 4 | Enable Sign-In API | Search → Enable | API ready |
| 5 | OAuth Consent Screen | Sidebar | Consent configured |
| 6 | Create Client ID | Credentials → Create | Client ID ready |
| 7 | Copy Client ID | Credentials screen | Have credentials |
| 8 | Update code | google_calendar_service.dart | Code updated |
| 9 | Run app | `flutter run` | App running |

---

**You're all set! Start from Step 1 and follow each step exactly.** 🚀

If you get stuck on any step, tell me the exact error and I'll help! ✅
