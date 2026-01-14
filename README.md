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

Use the `VerrifloClient` to create a room or join an existing one:

```dart
import 'package:verriflo_classroom/verriflo_classroom.dart';

// Initialize the client
final client = VerrifloClient(
  baseUrl: 'https://api.verriflo.com',
  organizationId: 'your-org-id',  // From your Verriflo dashboard
);

// Create a room (for teachers)
final createResponse = await client.createRoom(
  CreateRoomRequest(
    roomId: 'math-101',
    title: 'Math 101 - Algebra',
    participant: Participant(
      uid: 'teacher-123',
      name: 'John Teacher',
      role: ParticipantRole.teacher,
    ),
    customization: Customization(
      showLobby: true,
      needChat: true,
      needControlbar: true,
    ),
  ),
);

final token = createResponse.token;
final iframeUrl = createResponse.iframeUrl;

// Or join an existing room (for students)
final joinResponse = await client.joinRoom(
  'math-101',
  JoinRoomRequest(
    participant: Participant(
      uid: 'student-456',
      name: 'Jane Student',
      role: ParticipantRole.student,
    ),
    customization: Customization(
      showLobby: true,
    ),
  ),
);

final token = joinResponse.token;
```

### Step 2: Show the Player

```dart
import 'package:verriflo_classroom/verriflo_classroom.dart';

class ClassroomPage extends StatelessWidget {
  final String iframeUrl; // From CreateRoomResponse or JoinResponse

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VerrifloPlayer(
        iframeUrl: iframeUrl,  // Pass the full iframe URL directly
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
  token: token,
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
  token: token,
  initialQuality: VideoQuality.auto,  // Default
  // Other options: VideoQuality.high (1080p), .medium (720p), .low (480p)
)
```

The built-in control bar includes a quality selector, or you can hide it and build your own:

```dart
VerrifloPlayer(
  token: token,
  showControls: false,  // Hide default controls
)
```

## State Tracking

Track the classroom lifecycle with `onStateChanged`:

```dart
VerrifloPlayer(
  token: token,
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

No special permissions are required. The SDK only receives video/audio streams and doesn't access the camera or microphone.

### Android

Add the internet permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

No camera or microphone permissions are needed since this SDK is for viewing streams only.

## Force Leave Support

You can programmatically force a participant to leave the classroom:

```dart
final controller = VerrifloPlayerController();

VerrifloPlayer(
  token: token,
  controller: controller,
);

// Force leave with optional reason
await controller.forceLeave(
  reason: 'Session timeout',
  roomName: 'math-101',  // Optional: verify room name
);
```

The iframe will receive the `verriflo_force_leave` message and disconnect the participant.

## Full API Reference

### VerrifloClient

| Method | Description |
|--------|-------------|
| `createRoom(CreateRoomRequest)` | Create a new classroom room |
| `joinRoom(String roomId, JoinRoomRequest)` | Join an existing room |
| `isRoomActive(String roomId)` | Check if a room is active |

### VerrifloPlayer

| Property | Type | Description |
|----------|------|-------------|
| `token` | `String?` | Authentication token (optional if `iframeUrl` provided) |
| `iframeUrl` | `String?` | Full iframe URL with token (alternative to separate `token`/`liveBaseUrl`) |
| `liveBaseUrl` | `String` | Base URL for iframe (ignored if `iframeUrl` provided). Default: `https://live.verriflo.com/iframe/live` |
| `controller` | `VerrifloPlayerController?` | Optional controller for programmatic control |
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
