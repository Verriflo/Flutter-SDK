# Verriflo Classroom SDK for Flutter

Embed live video classrooms in your Flutter app with just a few lines of code. Built for education platforms that need reliable, high-quality streaming without the complexity.

## Why This SDK?

We built this because integrating live video into education apps shouldn't require a WebRTC PhD. The SDK handles all the messy bits—ICE candidates, TURN servers, adaptive bitrate, reconnection logic—so you can focus on your app.

**What you get:**
- Drop-in `VerrifloPlayer` widget that just works
- Quality control (auto-adaptive or manual 480p/720p/1080p)
- Event callbacks for class lifecycle (ended, kicked, reconnecting)
- Fullscreen mode with proper orientation handling
- Works on iOS, Android, and desktop

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  verriflo_classroom:
    git:
      url: https://github.com/Verriflo/Flutter-SDK.git
```

Then run `flutter pub get`.

## Quick Start

### Step 1: Get a Token

Your backend needs to call our API to get a streaming token. Here's what that looks like from Flutter (though you'd typically do this server-side):

```dart
final response = await http.post(
  Uri.parse('https://api.verriflo.com/v1/live/sdk/join'),
  headers: {
    'Content-Type': 'application/json',
    'VF-ORG-ID': 'your-org-id',  // From your Verriflo dashboard
  },
  body: jsonEncode({
    'roomId': 'math-101',
    'name': 'Jane Student', 
    'email': 'jane@school.edu',
  }),
);

final token = jsonDecode(response.body)['data']['livekitToken'];
```

### Step 2: Show the Player

```dart
import 'package:verriflo_classroom/verriflo_classroom.dart';

class ClassroomPage extends StatelessWidget {
  final String token;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VerrifloPlayer(
        joinUrl: 'https://live.verriflo.com/sdk/live?token=$token',
        onClassEnded: () {
          // Teacher ended the class
          Navigator.pop(context);
        },
        onKicked: (reason) {
          // Student was removed
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Removed from class'),
              content: Text(reason ?? 'You were removed by the instructor.'),
            ),
          );
        },
      ),
    );
  }
}
```

That's it. The player handles connection, reconnection, and UI states automatically.

## Handling Events

For more control, use the `onEvent` callback to respond to any event:

```dart
VerrifloPlayer(
  joinUrl: joinUrl,
  onEvent: (event) {
    switch (event.type) {
      case VerrifloEventType.connected:
        print('Joined the classroom');
        break;
      case VerrifloEventType.participantJoined:
        print('${event.participantName} joined');
        break;
      case VerrifloEventType.reconnecting:
        // Maybe show a subtle banner
        break;
      case VerrifloEventType.error:
        print('Something went wrong: ${event.message}');
        break;
      default:
        break;
    }
  },
)
```

### Available Events

| Event | When it fires |
|-------|---------------|
| `connected` | Successfully joined the classroom |
| `disconnected` | Left or lost connection |
| `reconnecting` | Connection dropped, trying to reconnect |
| `reconnected` | Back online after reconnection |
| `classEnded` | Instructor ended the session |
| `participantKicked` | You were removed from the classroom |
| `participantJoined` | Someone else joined |
| `participantLeft` | Someone else left |
| `qualityChanged` | Video quality was adjusted |
| `error` | Something went wrong |

## Video Quality

By default, quality adapts automatically based on network conditions. Users can also manually select a quality:

```dart
VerrifloPlayer(
  joinUrl: joinUrl,
  initialQuality: VideoQuality.auto,  // Default
  // Other options: VideoQuality.high (1080p), .medium (720p), .low (480p)
)
```

The built-in control bar includes a quality selector, or you can hide it and build your own:

```dart
VerrifloPlayer(
  joinUrl: joinUrl,
  showControls: false,  // Hide default controls
)
```

## State Tracking

Track the classroom lifecycle with `onStateChanged`:

```dart
VerrifloPlayer(
  joinUrl: joinUrl,
  onStateChanged: (state) {
    // state is one of: connecting, connected, reconnecting, ended, kicked, error
    if (state == ClassroomState.reconnecting) {
      showReconnectingBanner();
    }
  },
)
```

## Platform Setup

### iOS

Add camera and microphone permissions to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is needed for audio</string>
```

### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
```

## Full API Reference

### VerrifloPlayer

| Property | Type | Description |
|----------|------|-------------|
| `joinUrl` | `String` | Required. The URL with token from API |
| `initialQuality` | `VideoQuality` | Starting quality. Default: `auto` |
| `showControls` | `bool` | Show built-in control bar. Default: `true` |
| `onEvent` | `Function(VerrifloEvent)` | All events callback |
| `onStateChanged` | `Function(ClassroomState)` | Lifecycle state callback |
| `onClassEnded` | `VoidCallback` | Convenience callback for class end |
| `onKicked` | `Function(String?)` | Convenience callback for removal |
| `onError` | `Function(String, dynamic)` | Error callback |
| `onFullscreenToggle` | `VoidCallback` | Handle fullscreen changes |
| `isFullscreen` | `bool` | Current fullscreen state |
| `backgroundColor` | `Color` | Background color. Default: black |

### VideoQuality

```dart
VideoQuality.auto    // Adapts to network (recommended)
VideoQuality.low     // 480p
VideoQuality.medium  // 720p
VideoQuality.high    // 1080p
```

### ClassroomState

```dart
ClassroomState.idle         // Not connected
ClassroomState.connecting   // Joining classroom
ClassroomState.connected    // Active session
ClassroomState.reconnecting // Temporarily disconnected
ClassroomState.ended        // Class finished
ClassroomState.kicked       // Removed from class
ClassroomState.error        // Something broke
```

## Common Issues

**"Room not found" error**  
The teacher hasn't started the class yet. The room is created when the instructor joins.

**Video not loading on Android**  
Make sure you've added the INTERNET permission and your network allows WebRTC traffic.

**Quality stuck on low**  
Check network conditions. The adaptive algorithm prioritizes smooth playback over resolution.

## Need Help?

- **Docs**: [docs.verriflo.com](https://docs.verriflo.com)
- **Issues**: [GitHub Issues](https://github.com/Verriflo/Flutter-SDK/issues)
- **Email**: support@verriflo.com

---

Built with ❤️ by the Verriflo team
