# 9. Vercel Deployment Guide for Presenza Web

This guide explains how to deploy the Presenza Flutter Web application to Vercel in just a few clicks.

---

## 1. Project Configuration Added

The following files have been configured for Vercel:

| File | Purpose |
|---|---|
| `vercel.json` | Configures output directory (`build/web`), SPA route rewrites, and security headers |
| `build.sh` | Automated script that installs Flutter and builds `flutter build web --release` |
| `package.json` | Sets `"build": "bash build.sh"` so Vercel triggers the build automatically |

---

## 2. Step-by-Step Deployment Instructions

### Step 1: Sign in to Vercel
Go to **[vercel.com](https://vercel.com)** and sign in with your GitHub account.

### Step 2: Import Your Repository
1. Click **Add New...** ➔ **Project**.
2. Find and select **`Presenza`** from your GitHub repositories.
3. Click **Import**.

### Step 3: Configure Project Settings on Vercel
On the configuration screen:
- **Framework Preset**: Select **Other**
- **Root Directory**: `./` (leave default)
- **Build Command**: `bash build.sh` (or `npm run build`)
- **Output Directory**: `build/web`
- **Install Command**: Leave blank / default

### Step 4: Click Deploy
Click **Deploy**!

Vercel will clone the repo, install Flutter, compile the web bundle, and host your live website with a free `.vercel.app` domain and SSL certificate! 🎉

---

## 3. Live Features on Vercel Web
- Fully responsive web UI matching the gradient design.
- Firebase Authentication (Email/Password login & signup).
- Firebase Realtime Database live sync.
- Clean URL routing (`/login`, `/signup`, `/home`).
