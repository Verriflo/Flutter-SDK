# Verriflo Classroom SDK - Complete Example

This example shows how to use the Verriflo Classroom SDK to create and join rooms.

## Complete Flow Example

```dart
import 'package:flutter/material.dart';
import 'package:verriflo_classroom/verriflo_classroom.dart';

class ClassroomExample extends StatefulWidget {
  final String organizationId;
  
  const ClassroomExample({required this.organizationId, super.key});

  @override
  State<ClassroomExample> createState() => _ClassroomExampleState();
}

class _ClassroomExampleState extends State<ClassroomExample> {
  late final VerrifloClient _client;
  VerrifloPlayerController? _controller;
  String? _token;
  String? _iframeUrl;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _client = VerrifloClient(
      baseUrl: 'https://api.verriflo.com',
      organizationId: widget.organizationId,
      debug: true, // Enable debug logging
    );
  }

  // Create a room (for teachers)
  Future<void> _createRoom() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _client.createRoom(
        CreateRoomRequest(
          roomId: 'math-101-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Math 101 - Algebra',
          description: 'Introduction to algebraic equations',
          participant: Participant(
            uid: 'teacher-123',
            name: 'John Teacher',
            role: ParticipantRole.teacher,
            photoUrl: 'https://example.com/teacher.jpg',
          ),
          customization: Customization(
            showLobby: true,
            showClassTitle: true,
            showLogo: true,
            needChat: true,
            needControlbar: true,
            allowScreenShare: true,
            allowHandRaise: true,
            theme: ClassroomTheme.dark,
          ),
          settings: RoomSettings(
            maxParticipants: 50,
            autoClose: false,
          ),
        ),
      );

      setState(() {
        _token = response.token;
        _iframeUrl = response.iframeUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Join an existing room (for students)
  Future<void> _joinRoom(String roomId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _client.joinRoom(
        roomId,
        JoinRoomRequest(
          participant: Participant(
            uid: 'student-456',
            name: 'Jane Student',
            role: ParticipantRole.student,
            photoUrl: 'https://example.com/student.jpg',
          ),
          customization: Customization(
            showLobby: true,
            needChat: true,
            theme: ClassroomTheme.dark,
          ),
        ),
      );

      setState(() {
        _token = response.token;
        _iframeUrl = response.iframeUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Force leave the classroom
  Future<void> _forceLeave() async {
    if (_controller != null) {
      await _controller!.forceLeave(
        reason: 'Session ended by app',
        roomName: 'math-101',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verriflo Classroom Example')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : _createRoom,
                child: const Text('Create Room (Teacher)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading 
                  ? null 
                  : () => _joinRoom('math-101-1234567890'),
                child: const Text('Join Room (Student)'),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Show the classroom player
    _controller ??= VerrifloPlayerController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Classroom'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _forceLeave,
            tooltip: 'Force Leave',
          ),
        ],
      ),
      body: VerrifloPlayer(
        iframeUrl: _iframeUrl!,  // Pass the full iframe URL directly
        controller: _controller,
        onClassEnded: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Class ended by instructor')),
          );
          Navigator.pop(context);
        },
        onKicked: (reason) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Removed from Class'),
              content: Text(reason ?? 'You were removed by the instructor.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        onEvent: (event) {
          debugPrint('[Verriflo] Event: ${event.type}');
          if (event.type == VerrifloEventType.participantJoined) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${event.participantName} joined'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        onStateChanged: (state) {
          debugPrint('[Verriflo] State: $state');
        },
        onError: (message, error) {
          debugPrint('[Verriflo] Error: $message');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $message'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _client.dispose();
    super.dispose();
  }
}
```

## Key Features Demonstrated

1. **Creating a Room**: Use `createRoom()` to create a new classroom with customization options
2. **Joining a Room**: Use `joinRoom()` to join an existing classroom
3. **Event Handling**: Listen to events like participant joins, class ended, etc.
4. **Force Leave**: Programmatically disconnect a participant using `forceLeave()`
5. **Error Handling**: Proper error handling and user feedback

## Event Types

The SDK sends various events that you can listen to:

- `connected` - Successfully connected to the classroom
- `disconnected` - Disconnected from the classroom
- `participantJoined` - A participant joined
- `participantLeft` - A participant left
- `classEnded` - The instructor ended the class
- `participantKicked` - Current user was kicked
- `reconnecting` - Connection lost, attempting to reconnect
- `reconnected` - Successfully reconnected
- `error` - An error occurred

## Customization Options

You can customize the classroom experience:

- `showLobby` - Show pre-join lobby screen
- `showClassTitle` - Show class title
- `showLogo` - Show organization logo
- `needChat` - Enable chat feature
- `needControlbar` - Show control bar
- `allowScreenShare` - Allow screen sharing
- `allowHandRaise` - Allow hand raising
- `theme` - Set theme (light/dark/system)
