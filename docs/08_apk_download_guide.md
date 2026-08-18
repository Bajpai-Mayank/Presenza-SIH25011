# 8. APK Generation & GitHub Release Guide

This guide explains how to generate the Android APK so other users can download and install the app directly from your GitHub repository.

---

## 1. Prerequisites (Firebase Configuration)

Before building the APK, the project requires the Firebase configuration files:
1. `lib/firebase_options.dart`
2. `android/app/google-services.json`

Generate these by running:
```powershell
flutterfire configure
```

---

## 2. Option A: Build APK Locally

Run the following command in your terminal from the project root:

```powershell
flutter build apk --release
```

### Output Location:
The generated APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

You can rename this file to `Presenza.apk` and share it directly or upload it to your GitHub Releases.

---

## 3. Option B: Distribute APK via GitHub Releases (Recommended)

To allow anyone on GitHub to download the APK easily:

1. Open your repository on GitHub: [https://github.com/Bajpai-Mayank/Presenza](https://github.com/Bajpai-Mayank/Presenza)
2. Go to **Releases** (on the right sidebar) -> Click **Create a new release** (or **Draft a new release**).
3. Set a tag version (e.g., `v1.0.0`) and release title (e.g., `Presenza v1.0.0`).
4. Drag and drop the `app-release.apk` into the **Attach binaries** section.
5. Click **Publish release**.

Anyone visiting your repository can now download `Presenza.apk` under the **Assets** section of the Release page!

---

## 4. How to Download & Install on Any Android Phone (End-User Steps)

Share this link with your users: **https://github.com/Bajpai-Mayank/Presenza/releases**

### Steps for the Phone User:
1. **Open the link** in any mobile browser (Chrome, Samsung Internet, etc.):  
   👉 `https://github.com/Bajpai-Mayank/Presenza/releases`
2. Look for the **Latest Release** at the top.
3. Tap on the **Assets** dropdown (if collapsed).
4. Tap on **`app-release.apk`** (or `Presenza.apk`) to download it.
5. Once downloaded, tap **Open** (or find it in your phone's **Downloads** folder / Notification bar).
6. When prompted by Android:
   - Tap **Settings** ➔ Toggle ON **"Allow from this source"** (to permit installing apps downloaded from your browser).
   - Tap **Back** and click **Install**.
7. Once installed, tap **Open** to launch Presenza! 🎉

---

## 5. Option C: Automatic Cloud Build via GitHub Actions

A GitHub Actions workflow has been added at `.github/workflows/build_apk.yml`.

Whenever you push changes or trigger the workflow:
1. GitHub Cloud servers automatically build the APK.
2. The APK will be available in the **Actions** tab as a downloadable artifact.
3. If you push a tag (e.g. `v1.0.0`), it will automatically publish the APK to GitHub Releases.

