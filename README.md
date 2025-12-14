# Verriflo Classroom SDK

A production-ready Flutter SDK for embedding live video streaming in education applications—built on a high-performance, WebRTC-based streaming adapter.

## Features

- **VerrifloPlayer** — Drop-in video widget with auto-connection
- **Adaptive Streaming** — Automatic quality adjustment based on network conditions  
- **Manual Quality Control** — User-selectable resolution (1080p / 720p / 480p / 360p)
- **Fullscreen Mode** — One-tap fullscreen with landscape rotation
- **Event System** — Lifecycle callbacks for connection state, class end, errors
- **Overlay Support** — Add custom widgets on top of the video

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  verriflo_classroom:
    git:
      url: https://github.com/Verriflo/Flutter-SDK.git
      path: verriflo_classroom
```

## Quick Start

### 1. Get Access Token

Call the Verriflo API to obtain a streaming access token:

```dart
final response = await http.post(
  Uri.parse('https://api.verriflo.com/v1/live/sdk/join'),
  headers: {
    'Content-Type': 'application/json',
    'VF-ORG-ID': 'your-organization-id',
  },
  body: jsonEncode({
    'roomId': 'math-101-lecture',
    'name': 'John Student',
    'email': 'john@student.edu',
  }),
);

final data = jsonDecode(response.body)['data'];
final token = data['livekitToken'];      // Access token
final serverUrl = data['serverUrl'];      // Streaming endpoint
```

### 2. Display Player

```dart
import 'package:verriflo_classroom/verriflo_classroom.dart';

VerrifloPlayer(
  config: VerrifloConfig(
    serverUrl: serverUrl,
    token: token,
  ),
  onEvent: (event) {
    switch (event.type) {
      case VerrifloEventType.connected:
        print('Joined classroom');
        break;
      case VerrifloEventType.classEnded:
        Navigator.pop(context);
        break;
      case VerrifloEventType.error:
        showError(event.message);
        break;
      default:
        break;
    }
  },
)
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `config` | VerrifloConfig | required | Server URL and access token |
| `onEvent` | Function | null | Event callback |
| `showQualitySelector` | bool | true | Show quality settings button |
| `showFullscreenButton` | bool | true | Show fullscreen toggle |
| `initialQuality` | VideoQuality | auto | Initial quality setting |
| `overlay` | Widget | null | Custom overlay widget |
| `loadingWidget` | Widget | null | Custom loading indicator |
| `noVideoWidget` | Widget | null | Custom waiting state |
| `backgroundColor` | Color | black | Background when no video |

## Video Quality

The player supports both automatic and manual quality control:

```dart
// Get player state reference
final playerKey = GlobalKey<VerrifloPlayerState>();

VerrifloPlayer(
  key: playerKey,
  config: config,
);

// Programmatic quality control
playerKey.currentState?.setQuality(VideoQuality.high);   // 1080p
playerKey.currentState?.setQuality(VideoQuality.medium); // 720p
playerKey.currentState?.setQuality(VideoQuality.low);    // 480p
playerKey.currentState?.setQuality(VideoQuality.auto);   // Adaptive
```

## Events

| Event | Description |
|-------|-------------|
| `connected` | Successfully joined classroom |
| `disconnected` | Left or lost connection |
| `classEnded` | Instructor ended the session |
| `participantJoined` | Another student joined |
| `participantLeft` | Student left classroom |
| `trackSubscribed` | Video stream received |
| `trackUnsubscribed` | Video stream ended |
| `connectionQualityChanged` | Quality setting changed |
| `error` | Error occurred |

## Platform Setup

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access for audio</string>
```

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

## Architecture

The SDK uses an adapter pattern to interface with our WebRTC-based streaming infrastructure:

```
┌─────────────────────┐
│  VerrifloPlayer     │  Public API
├─────────────────────┤
│  Streaming Adapter  │  Internal abstraction
├─────────────────────┤
│  WebRTC Transport   │  Low-level protocol
└─────────────────────┘
```

This design ensures stable public APIs while allowing internal optimizations.

## Support

- Documentation: https://docs.verriflo.com
- Email: support@verriflo.com
