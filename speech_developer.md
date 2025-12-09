# Flutter Speech-to-Text & Device Info Integration

This Flutter project demonstrates the integration of **speech-to-text functionality** and **device information retrieval** using the following packages:

- [speech_to_text](https://pub.dev/packages/speech_to_text) – Convert spoken words to text.
- [device_info_plus](https://pub.dev/packages/device_info_plus) – Retrieve device information such as OS version, model, and other hardware/software details.

---

## 📦 Installation

Add the following dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  speech_to_text: ^7.0.0
  device_info_plus: ^9.1.1
```

Then run:

```bash
flutter pub get
```

---

## ⚙️ Android Setup

### Permissions
Add the following permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

Optionally, include this inside `<application>` for speech recognition:

```xml
<queries>
    <intent>
        <action android:name="android.speech.RecognitionService" />
    </intent>
</queries>
```

---

## ⚙️ iOS Setup

Add the following keys to `ios/Runner/Info.plist`:

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Speech recognition is required to convert your voice to text.</string>

<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for speech input.</string>
```

---

## 🎤 Speech-to-Text Example

```dart
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool isListening = false;
  String recognizedText = "";

  Future<void> startListening(Function(String) onResult) async {
    bool available = await _speech.initialize();
    if (available) {
      _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
      );
    }
  }

  void stopListening() {
    _speech.stop();
  }
}
```

---

## 📱 Device Info Example

```dart
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  Future<Map<String, dynamic>> getAndroidInfo() async {
    final info = await deviceInfo.androidInfo;
    return {
      "model": info.model,
      "brand": info.brand,
      "version": info.version.sdkInt,
      "isSecure": info.isDeviceSecure,
    };
  }
}
```

---

## 🧐 Common Issues

### MissingPluginException (speech_to_text)
```bash
flutter clean
flutter pub get
```
Ensure your Android device has **Google Voice Typing** installed.

### Deprecated Fields in device_info_plus
The getter `adbEnabled` is removed in newer versions. Use:

```dart
info.isDeviceSecure
```

or check features:

```dart
info.systemFeatures.contains('android.software.developer_mode')
```

---

## 🎧 Best Practices

- Call `_speech.initialize()` only once.
- Request microphone permission at runtime (especially Android 13+).
- Stop listening before screen navigation.
- Show a UI indicator while listening (e.g., glowing mic icon).

---

## 📔 Example UI Integration

Add a mic button in your page (e.g., complaint description):

```dart
IconButton(
  icon: Icon(Icons.mic, color: Colors.green),
  onPressed: _startSpeechToText,
)
```

Handle speech input:

```dart
void _startSpeechToText() async {
  await _speech.initialize();
  _speech.listen(
    onResult: (res) {
      setState(() {
        messageController.text = res.recognizedWords;
      });
    },
  );
}
```

---

## 📜 Conclusion

This project setup includes:

- Installation and configuration for both packages
- Permissions and platform-specific setup
- Sample implementation for speech-to-text and device info
- Common issues and their fixes
- Best practices for production-ready apps

---

**License:** MIT