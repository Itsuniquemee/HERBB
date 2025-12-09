# Firebase Phone Authentication Setup Guide

## Overview
This guide will help you enable Phone Authentication in your Firebase project for the Herbal Trace app.

## Prerequisites
- Firebase project already created (herbal-trace)
- Firebase Auth already enabled
- Android SHA-1 and SHA-256 certificates configured

## Steps to Enable Phone Authentication

### 1. Enable Phone Authentication in Firebase Console

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: herbal-trace
3. **Navigate to Authentication**:
   - Click on "Authentication" in the left sidebar
   - Click on "Sign-in method" tab
4. **Enable Phone Provider**:
   - Scroll down and find "Phone" in the list of providers
   - Click on "Phone"
   - Toggle the "Enable" switch to ON
   - Click "Save"

### 2. Configure Phone Authentication Settings

#### A. For Testing (Optional - Development Only)
If you want to test with specific phone numbers without sending real SMS:

1. In the "Phone" provider settings, scroll to "Phone numbers for testing"
2. Click "Add phone number"
3. Add test phone numbers with their verification codes:
   - Example: +919876543210 → 123456
   - You can add multiple test numbers
4. Click "Save"

**Note**: Test phone numbers will bypass SMS sending and always accept the configured OTP code.

#### B. Android Configuration (Required)

1. **Enable SafetyNet**:
   - Phone authentication uses reCAPTCHA for verification
   - Firebase automatically uses SafetyNet on Android
   - No additional setup needed for basic functionality

2. **Add SHA-1 and SHA-256 Fingerprints**:
   - These should already be configured from your initial Firebase setup
   - If not, run these commands in your project directory:
   
   ```powershell
   # Debug keystore (for development)
   cd C:\Users\<YourUsername>\.android
   keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Release keystore (for production)
   keytool -list -v -keystore <path-to-your-release-keystore> -alias <your-key-alias>
   ```
   
   - Copy the SHA-1 and SHA-256 fingerprints
   - Go to Firebase Console → Project Settings → Your Android App
   - Add both fingerprints

3. **Download Updated google-services.json**:
   - After adding fingerprints, download the updated `google-services.json`
   - Replace the file in: `android/app/google-services.json`

### 3. Configure Android App for Phone Auth

#### Update AndroidManifest.xml

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
    <!-- Phone Auth Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECEIVE_SMS" />
    <uses-permission android:name="android.permission.READ_SMS" />
    
    <application ...>
        ...
    </application>
</manifest>
```

**Note**: The app will request SMS permissions at runtime when needed.

### 4. Quota and Billing

#### Free Tier Limits
- **10,000 verifications per month** - Free
- After that: $0.01 per verification (India pricing)

#### SMS Quota
- Firebase Phone Authentication uses Cloud Functions behind the scenes
- SMS quota is generous for development
- For production, monitor usage in Firebase Console → Authentication → Usage

#### Enable Billing (If needed)
1. Go to Firebase Console → Settings (gear icon) → Usage and billing
2. Click "Details & settings"
3. Upgrade to Blaze (Pay as you go) plan if needed
4. Set budget alerts to avoid unexpected charges

### 5. Regional SMS Providers (Optional - For Production)

For Indian phone numbers, Firebase uses Twilio by default. For better delivery rates in India:

1. **Consider using regional SMS providers**:
   - Firebase supports custom SMS providers via Cloud Functions
   - Popular Indian providers: MSG91, Twilio (with Indian numbers), AWS SNS

2. **Set up custom SMS handler** (Advanced):
   - Create a Cloud Function to handle SMS sending
   - Use Firebase Admin SDK to verify custom tokens
   - This gives you more control over SMS delivery and cost

### 6. Security Rules

Update Firestore security rules to handle phone-authenticated users:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Allow users to read/write their own data
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Phone auth users might not have email
      allow create: if request.auth != null;
    }
  }
}
```

### 7. Testing Phone Authentication

#### Test Flow:
1. **Run the app**: `flutter run -d <device-id>`
2. **Go to Signup**: Select role → Choose "Phone & OTP"
3. **Enter phone number**: Use your real Indian number (+91XXXXXXXXXX)
4. **Verify SMS**: Check your phone for OTP SMS
5. **Enter OTP**: Input the 6-digit code
6. **Complete signup**: Fill remaining details

#### For Testing Without Real SMS:
1. Add your number as a test number in Firebase Console (step 2A above)
2. Use the configured test OTP instead of waiting for SMS
3. This is useful for rapid testing without SMS costs

### 8. Production Checklist

Before going live:

- [ ] Remove all test phone numbers from Firebase Console
- [ ] Add production SHA-1/SHA-256 fingerprints
- [ ] Enable billing if expecting >10,000 verifications/month
- [ ] Set up budget alerts in Firebase Console
- [ ] Test with real phone numbers across different carriers
- [ ] Implement rate limiting to prevent abuse
- [ ] Monitor authentication analytics in Firebase Console
- [ ] Consider implementing SMS retry logic with exponential backoff
- [ ] Add user feedback for OTP expiration (60 seconds)

### 9. Troubleshooting

#### Common Issues:

**1. "invalid-phone-number" error**
- Ensure phone number includes country code: +91XXXXXXXXXX
- Indian numbers should be exactly 10 digits after +91

**2. SMS not received**
- Check Firebase Console → Authentication → Usage for quota
- Verify phone number is not in test numbers list (if using production)
- Try with different phone number/carrier
- Check spam folder (SMS might be filtered)
- Wait 60 seconds, then use "Resend OTP"

**3. "session-expired" error**
- OTP expires after 60 seconds
- Request a new OTP using "Resend OTP" button

**4. "quota-exceeded" error**
- You've hit the free tier limit (10,000/month)
- Upgrade to Blaze plan or wait for next month

**5. Auto-verification not working (Android)**
- Ensure SMS permissions are granted
- Auto-verification only works on Android (not iOS)
- SMS must come from Firebase's number

#### Debug Logs:
Check Flutter console for Firebase Auth logs:
```
flutter run -d <device-id> --verbose
```

Look for lines containing:
- "Sending OTP to:"
- "OTP sent successfully"
- "Verification failed:"
- "Firebase Auth error:"

## Cost Estimation

### Typical Monthly Cost (India)

**Small App (1,000 users)**:
- Signups: 1,000 × 1 = 1,000 verifications
- Logins (25% use phone): 250 verifications/month
- **Total**: 1,250 verifications/month
- **Cost**: ₹0 (within free tier)

**Medium App (10,000 users)**:
- Signups: 2,000 new users/month = 2,000 verifications
- Logins: 20,000 logins/month × 30% phone = 6,000 verifications
- **Total**: 8,000 verifications/month
- **Cost**: ₹0 (within free tier)

**Large App (100,000 users)**:
- Signups: 10,000 new users/month = 10,000 verifications
- Logins: 200,000 logins/month × 30% phone = 60,000 verifications
- **Total**: 70,000 verifications/month
- **Cost**: ₹600/month (60,000 over free tier × ₹0.01)

## Support

For issues with Firebase Phone Authentication:
- Firebase Documentation: https://firebase.google.com/docs/auth/flutter/phone-auth
- Firebase Support: https://firebase.google.com/support
- Stack Overflow: https://stackoverflow.com/questions/tagged/firebase-authentication

## Summary

Phone authentication is now fully implemented in your app with:
- ✅ OTP-based login
- ✅ Phone number signup
- ✅ Automatic verification (Android)
- ✅ Manual OTP entry
- ✅ OTP resend functionality
- ✅ Both farmer and consumer support
- ✅ Hindi/English localization

Users can now choose to authenticate using either:
1. **Email + Password** (traditional method)
2. **Phone + OTP** (passwordless method)
