# Maddy AI Studio

A starter Flutter Android app with a black-and-gold UI for:
- Text-to-image generation
- Image-to-image editing using a selected gallery photo
- Sharing/saving the generated image

## Important
- The app currently calls the Gemini Developer API directly from the device. This is suitable only for private testing.
- Do NOT distribute this APK or publish it with your API key in the app. A production app needs a secure backend that keeps the API key on the server, user authentication, quotas, abuse protection, and privacy disclosures.
- Image generation models may not have a free tier. Check current pricing and availability before enabling billing.
- This is a starter app, not a finished commercial product. The generated image is shared through Android's share sheet; a dedicated gallery-save feature can be added later.

## Build APK from a phone using GitHub Actions
1. Create a GitHub account and a new **public** repository named `maddy-ai-studio` (public repositories get GitHub-hosted Actions minutes under GitHub's current policies; check your account limits).
2. Upload the contents of this ZIP to the repository, keeping the folder structure:
   - `app/lib/main.dart`
   - `app/pubspec.yaml`
   - `.github/workflows/build-apk.yml`
3. Open the repository's **Actions** tab.
4. Choose **Build Maddy AI Studio APK** and tap **Run workflow**.
5. Wait for the workflow to finish successfully.
6. Open that workflow run, scroll to **Artifacts**, and download `Maddy-AI-Studio-APK`.
7. Extract the ZIP and install `app-release.apk` on your Android phone. You may need to allow installs from your browser/files app.

## API key
For private testing, create a Gemini API key in Google AI Studio and paste it into the app's API key field. Do not share it. Image generation model availability, region eligibility, quotas, and pricing can change. The starter currently uses `gemini-3.1-flash-image`.
