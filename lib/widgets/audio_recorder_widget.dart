import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/question_provider.dart';

class AudioRecorderWidget extends ConsumerStatefulWidget {
  const AudioRecorderWidget({super.key});

  @override
  ConsumerState<AudioRecorderWidget> createState() =>
      AudioRecorderWidgetState();
}

class AudioRecorderWidgetState extends ConsumerState<AudioRecorderWidget> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  Duration _recordedDuration = Duration.zero;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioPath;
  final List<double> _waveformData = [];

  @override
  void initState() {
    super.initState();
    _initializeWaveform();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  void _initializeWaveform() {
    // Initialize with random waveform data for visualization
    _waveformData.clear();
    for (int i = 0; i < 20; i++) {
      _waveformData.add(0.3);
    }
  }

  Future<void> _startRecording() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
        return;
      }

      // Get directory for audio file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _audioPath = '${directory.path}/$fileName';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _audioPath!,
      );

      setState(() {
        _isRecording = true;
        _recordedDuration = Duration.zero;
      });

      ref.read(questionProvider.notifier).setRecordingAudio(true);

      // Start timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordedDuration = Duration(seconds: timer.tick);
          // Update waveform data (simulated - in real app, use actual audio amplitude)
          _updateWaveform();
        });
      });

      // Update waveform periodically
      _updateWaveformPeriodically();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
      }
    }
  }

  void _updateWaveform() {
    // Simulate waveform data - in production, get actual amplitude from recorder
    for (int i = 0; i < _waveformData.length; i++) {
      _waveformData[i] = 0.2 + Random().nextDouble() * 0.8;
    }
  }

  void _updateWaveformPeriodically() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      setState(() {
        _updateWaveform();
      });
    });
  }

  Future<void> _stopRecording({bool save = true}) async {
    try {
      _timer?.cancel();
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
      });

      ref.read(questionProvider.notifier).setRecordingAudio(false);

      if (save && path != null) {
        ref
            .read(questionProvider.notifier)
            .setAudioPath(path, duration: _recordedDuration);
      } else {
        // Delete the file if cancelled
        if (_audioPath != null && File(_audioPath!).existsSync()) {
          await File(_audioPath!).delete();
        }
        setState(() {
          _recordedDuration = Duration.zero;
          _audioPath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error stopping recording: $e')));
      }
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
      }
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error pausing audio: $e')));
      }
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
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionState = ref.watch(questionProvider);

    if (questionState.hasAudio && !_isRecording) {
      // Show recorded audio preview
      return _buildAudioPreview();
    }

    if (_isRecording) {
      // Show recording UI with waveform
      return _buildRecordingUI();
    }

    return const SizedBox.shrink();
  }

  Widget _buildRecordingUI() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Checkmark icon
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF5BA3F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          // Recording text and waveform
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recording Audio...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Waveform visualization
                SizedBox(
                  height: 30,
                  child: CustomPaint(
                    painter: WaveformPainter(_waveformData),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
          // Duration
          Text(
            _formatDuration(_recordedDuration),
            style: const TextStyle(
              color: Color(0xFF5BA3F5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          // Cancel button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () => _stopRecording(save: false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview() {
    final questionState = ref.watch(questionProvider);
    final duration = questionState.audioDuration ?? Duration.zero;
    final audioPath = questionState.audioPath;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Play button
          GestureDetector(
            onTap: () {
              if (_isPlaying) {
                _pauseAudio();
              } else {
                if (audioPath != null) {
                  _playAudio(audioPath);
                }
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF5BA3F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Audio info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Audio Recorded',
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
              _audioPlayer.stop();
              ref.read(questionProvider.notifier).deleteAudio();
            },
          ),
        ],
      ),
    );
  }

  void startRecording() => _startRecording();
}

// Waveform painter for audio visualization
class WaveformPainter extends CustomPainter {
  final List<double> waveformData;

  WaveformPainter(this.waveformData);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final barWidth = size.width / waveformData.length;
    final maxHeight = size.height;

    for (int i = 0; i < waveformData.length; i++) {
      final height = waveformData[i] * maxHeight * 0.8;
      final x = i * barWidth + barWidth / 2;
      final centerY = size.height / 2;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, centerY),
          width: barWidth * 0.6,
          height: height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}