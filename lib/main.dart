import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Streamer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AudioStreamPage(title: 'Audio Streamer'),
    );
  }
}

class AudioStreamPage extends StatefulWidget {
  const AudioStreamPage({super.key, required this.title});

  final String title;

  @override
  State<AudioStreamPage> createState() => _AudioStreamPageState();
}

class _AudioStreamPageState extends State<AudioStreamPage> {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  StreamSubscription? _recorderSubscription;
  http.Client? _httpClient;
  StreamController<Uint8List>? _audioStreamController;
  final TextEditingController _endpointController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    _recorder = FlutterSoundRecorder();

    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required')),
      );
      return;
    }

    await _recorder!.openRecorder();
  }

  Future<void> _startRecording() async {
    if (_recorder!.isRecording) {
      return;
    }

    String endpoint = _endpointController.text.trim();
    print("Connecting to: $endpoint");

    try {
      _httpClient = http.Client();
      _audioStreamController = StreamController<Uint8List>();

      await _recorder!.startRecorder(
        toStream: _audioStreamController!.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
      );

      _recorderSubscription = _audioStreamController!.stream.listen((data) {
        _httpClient!.post(Uri.parse(endpoint), body: data);
      });

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to HTTP endpoint')),
      );
      return;
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      await _recorder!.stopRecorder();
      _recorderSubscription?.cancel();

      await _audioStreamController?.close();

      setState(() {
        _isRecording = false;
      });
    }
  }

  @override
  void dispose() {
    _recorder!.closeRecorder();
    _recorderSubscription?.cancel();
    _audioStreamController?.close();
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _endpointController,
                decoration: const InputDecoration(
                  labelText: 'Enter HTTP Endpoint',
                  hintText: 'https://your-ngrok-endpoint.ngrok-free.app',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Stop Streaming' : 'Start Streaming'),
            ),
          ],
        ),
      ),
    );
  }
}
