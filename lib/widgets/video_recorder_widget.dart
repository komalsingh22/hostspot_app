import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../providers/question_provider.dart';
import '../screens/video_player_screen.dart';

class VideoRecorderWidget extends ConsumerStatefulWidget {
  const VideoRecorderWidget({super.key});

  @override
  ConsumerState<VideoRecorderWidget> createState() =>
      VideoRecorderWidgetState();
}

class VideoRecorderWidgetState extends ConsumerState<VideoRecorderWidget> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No cameras available')));
        }
        return;
      }

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _showVideoRecordingScreen() async {
    if (!_isInitialized || _controller == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoRecordingScreen(
          controller: _controller!,
          onStop: (path, duration, saved) {
            if (saved && path != null) {
              ref
                  .read(questionProvider.notifier)
                  .setVideoPath(path, duration: duration);
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void startRecording() => _showVideoRecordingScreen();

  @override
  Widget build(BuildContext context) {
    final questionState = ref.watch(questionProvider);

    if (questionState.hasVideo) {
      // Show recorded video preview
      return _buildVideoPreview();
    }

    return const SizedBox.shrink();
  }

  Widget _buildVideoPreview() {
    final questionState = ref.watch(questionProvider);
    final duration = questionState.videoDuration ?? Duration.zero;
    final videoPath = questionState.videoPath;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Video thumbnail with play button
          GestureDetector(
            onTap: () {
              if (videoPath != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VideoPlayerScreen(videoPath: videoPath),
                  ),
                );
              }
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: videoPath != null && File(videoPath).existsSync()
                      ? Image.file(
                          File(videoPath),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                ),
                const Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Video info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Video Recorded',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () {
              ref.read(questionProvider.notifier).deleteVideo();
            },
          ),
        ],
      ),
    );
  }
}

// Video recording screen
class VideoRecordingScreen extends StatefulWidget {
  final CameraController controller;
  final Function(String?, Duration, bool) onStop;

  const VideoRecordingScreen({
    super.key,
    required this.controller,
    required this.onStop,
  });

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  Timer? _timer;
  Duration _recordedDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      await widget.controller.startVideoRecording();

      setState(() {
        _recordedDuration = Duration.zero;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordedDuration = Duration(seconds: timer.tick);
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
      }
    }
  }

  Future<void> _stopRecording({bool save = true}) async {
    _timer?.cancel();

    if (widget.controller.value.isRecordingVideo) {
      final file = await widget.controller.stopVideoRecording();
      widget.onStop(save ? file.path : null, _recordedDuration, save);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(child: CameraPreview(widget.controller)),
          // Top bar with timer and cancel
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => _stopRecording(save: false),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(_recordedDuration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance spacing
                ],
              ),
            ),
          ),
          // Bottom controls
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stop/Finish button
                    GestureDetector(
                      onTap: () => _stopRecording(save: true),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 4),
                        ),
                        child: const Icon(
                          Icons.stop,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}