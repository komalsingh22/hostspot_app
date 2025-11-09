import 'dart:async';
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
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Duration _recordedDuration = Duration.zero;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioPath;
  final List<double> _waveformData = [];
  double _currentAmplitude = 0.0;
  int _amplitudeUpdateCount = 0;

  @override
  void initState() {
    super.initState();
    // ignore: avoid_print
    print('🎤 [AUDIO RECORDER] Widget initialized');
    _initializeWaveform();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      // ignore: avoid_print
      print('▶️ [AUDIO RECORDER] Player state changed: $state');
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Listen for player completion
    _audioPlayer.onPlayerComplete.listen((_) {
      // ignore: avoid_print
      print('✅ [AUDIO RECORDER] Audio playback completed');
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _initializeWaveform() {
    // Initialize with zero waveform data
    _waveformData.clear();
    for (int i = 0; i < 20; i++) {
      _waveformData.add(0.1);
    }
  }

  Future<void> _startRecording() async {
    try {
      // ignore: avoid_print
      print('🎤 [AUDIO RECORDER] Starting recording...');

      // Check if recorder is already recording
      final isAlreadyRecording = await _audioRecorder.isRecording();
      // ignore: avoid_print
      print('🎤 [AUDIO RECORDER] Is already recording: $isAlreadyRecording');

      if (isAlreadyRecording) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Already recording')));
        }
        return;
      }

      // Request microphone permission
      // ignore: avoid_print
      print('🎤 [AUDIO RECORDER] Requesting microphone permission...');
      final status = await Permission.microphone.request();
      // ignore: avoid_print
      print(
        '🎤 [AUDIO RECORDER] Permission status: $status (granted: ${status.isGranted})',
      );

      if (!status.isGranted) {
        // ignore: avoid_print
        print('❌ [AUDIO RECORDER] Microphone permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission is required to record audio',
              ),
            ),
          );
        }
        return;
      }

      // Get directory for audio file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audio_$timestamp.m4a';
      _audioPath = '${directory.path}/$fileName';
      // ignore: avoid_print
      print('🎤 [AUDIO RECORDER] Audio file path: $_audioPath');

      // Start recording with proper configuration
      // ignore: avoid_print
      print('🎤 [AUDIO RECORDER] Starting recorder with config...');
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 2,
        ),
        path: _audioPath!,
      );

      // Verify recording actually started
      await Future.delayed(const Duration(milliseconds: 100));
      final isRecordingNow = await _audioRecorder.isRecording();
      // ignore: avoid_print
      print('🎤 [AUDIO RECORDER] Recording started: $isRecordingNow');

      if (!isRecordingNow) {
        // ignore: avoid_print
        print(
          '❌ [AUDIO RECORDER] Failed to start recording - isRecording() returned false',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start recording')),
          );
        }
        return;
      }

      setState(() {
        _isRecording = true;
        _recordedDuration = Duration.zero;
        _currentAmplitude = 0.0;
      });

      ref.read(questionProvider.notifier).setRecordingAudio(true);

      // Start listening to amplitude changes for real waveform data
      // ignore: avoid_print
      print('🎤 [AUDIO RECORDER] Setting up amplitude listener...');
      _amplitudeUpdateCount = 0; // Reset counter when starting recording
      _amplitudeSubscription = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen(
            (amplitude) {
              if (mounted && _isRecording) {
                _amplitudeUpdateCount++;
                // Log amplitude values every 10 updates (~1 second)
                if (_amplitudeUpdateCount % 10 == 0) {
                  final normalized = ((amplitude.current + 160) / 160).clamp(
                    0.0,
                    1.0,
                  );
                  // ignore: avoid_print
                  print(
                    '📊 [AUDIO RECORDER] Amplitude - current: ${amplitude.current.toStringAsFixed(2)} dB, normalized: ${normalized.toStringAsFixed(2)}',
                  );
                }

                setState(() {
                  // Normalize amplitude (typically ranges from -160 to 0 dB)
                  // Convert to 0-1 range for visualization
                  _currentAmplitude = (amplitude.current + 160) / 160;
                  _currentAmplitude = _currentAmplitude.clamp(0.0, 1.0);

                  // Update waveform data with real amplitude
                  _updateWaveformWithAmplitude(_currentAmplitude);
                });
              }
            },
            onError: (error) {
              // ignore: avoid_print
              print('❌ [AUDIO RECORDER] Amplitude stream error: $error');
            },
          );
      // ignore: avoid_print
      print('✅ [AUDIO RECORDER] Amplitude listener set up successfully');

      // Start timer for duration
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          setState(() {
            _recordedDuration = Duration(seconds: timer.tick);
          });
        } else {
          timer.cancel();
        }
      });

      // ignore: avoid_print
      print('✅ [AUDIO RECORDER] Recording started successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('❌ [AUDIO RECORDER] Error starting recording: $e');
      // ignore: avoid_print
      print('❌ [AUDIO RECORDER] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
      }
      setState(() {
        _isRecording = false;
      });
      ref.read(questionProvider.notifier).setRecordingAudio(false);
    }
  }

  void _updateWaveformWithAmplitude(double amplitude) {
    // Shift existing data to the left
    if (_waveformData.isNotEmpty) {
      _waveformData.removeAt(0);
      // Add new amplitude data at the end
      // Add some variation for visual appeal while keeping it based on real data
      final variation = 0.1 + amplitude * 0.9;
      _waveformData.add(variation.clamp(0.1, 1.0));
    }
  }

  Future<void> _stopRecording({bool save = true}) async {
    try {
      // ignore: avoid_print
      print('🛑 [AUDIO RECORDER] Stopping recording (save: $save)...');
      // ignore: avoid_print
      print('🛑 [AUDIO RECORDER] Current recording state: $_isRecording');
      // ignore: avoid_print
      print(
        '🛑 [AUDIO RECORDER] Recorded duration: ${_formatDuration(_recordedDuration)}',
      );

      _timer?.cancel();
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;

      if (!_isRecording) {
        // ignore: avoid_print
        print('⚠️ [AUDIO RECORDER] Not recording, skipping stop');
        return;
      }

      String? path;
      try {
        // Stop the recording and get the file path
        // ignore: avoid_print
        print('🛑 [AUDIO RECORDER] Calling recorder.stop()...');
        path = await _audioRecorder.stop();
        // ignore: avoid_print
        print('🛑 [AUDIO RECORDER] Recorder stopped. Path returned: $path');
      } catch (e, stackTrace) {
        // ignore: avoid_print
        print('❌ [AUDIO RECORDER] Error stopping recorder: $e');
        // ignore: avoid_print
        print('❌ [AUDIO RECORDER] Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error stopping recorder: $e')),
          );
        }
        // Try to use stored path as fallback
        path = _audioPath;
        // ignore: avoid_print
        print('🛑 [AUDIO RECORDER] Using fallback path: $path');
      }

      setState(() {
        _isRecording = false;
        _currentAmplitude = 0.0;
      });

      ref.read(questionProvider.notifier).setRecordingAudio(false);

      if (save && path != null) {
        // ignore: avoid_print
        print('💾 [AUDIO RECORDER] Saving recording to: $path');

        // Verify file exists and has content
        final file = File(path);
        final fileExists = file.existsSync();
        // ignore: avoid_print
        print('💾 [AUDIO RECORDER] File exists: $fileExists');

        if (fileExists) {
          final fileSize = await file.length();
          // ignore: avoid_print
          print('💾 [AUDIO RECORDER] File size: $fileSize bytes');

          if (fileSize > 0) {
            ref
                .read(questionProvider.notifier)
                .setAudioPath(path, duration: _recordedDuration);
            // ignore: avoid_print
            print(
              '✅ [AUDIO RECORDER] Recording saved successfully: $path (${_formatDuration(_recordedDuration)})',
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Recording saved (${_formatDuration(_recordedDuration)})',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            // ignore: avoid_print
            print('❌ [AUDIO RECORDER] File is empty, deleting...');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error: Recording file is empty')),
              );
            }
            // Delete empty file
            try {
              await file.delete();
              // ignore: avoid_print
              print('🗑️ [AUDIO RECORDER] Empty file deleted');
            } catch (e) {
              // ignore: avoid_print
              print('⚠️ [AUDIO RECORDER] Error deleting empty file: $e');
            }
          }
        } else {
          // ignore: avoid_print
          print('❌ [AUDIO RECORDER] File does not exist at path: $path');
          // Try stored path as fallback
          if (_audioPath != null) {
            // ignore: avoid_print
            print('💾 [AUDIO RECORDER] Trying fallback path: $_audioPath');
            final fallbackFile = File(_audioPath!);
            if (fallbackFile.existsSync()) {
              final fileSize = await fallbackFile.length();
              // ignore: avoid_print
              print(
                '💾 [AUDIO RECORDER] Fallback file exists, size: $fileSize bytes',
              );

              if (fileSize > 0) {
                ref
                    .read(questionProvider.notifier)
                    .setAudioPath(_audioPath!, duration: _recordedDuration);
                // ignore: avoid_print
                print('✅ [AUDIO RECORDER] Recording saved using fallback path');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Recording saved (${_formatDuration(_recordedDuration)})',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                return;
              }
            } else {
              // ignore: avoid_print
              print('❌ [AUDIO RECORDER] Fallback file also does not exist');
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: Recording file not found')),
            );
          }
        }
      } else {
        // ignore: avoid_print
        print('🚫 [AUDIO RECORDER] Recording cancelled, deleting files...');
        // Delete the file if cancelled
        if (path != null) {
          try {
            final file = File(path);
            if (file.existsSync()) {
              await file.delete();
              // ignore: avoid_print
              print('🗑️ [AUDIO RECORDER] Cancelled file deleted: $path');
            }
          } catch (e) {
            // ignore: avoid_print
            print('⚠️ [AUDIO RECORDER] Error deleting cancelled file: $e');
          }
        }
        if (_audioPath != null) {
          try {
            final file = File(_audioPath!);
            if (file.existsSync()) {
              await file.delete();
              // ignore: avoid_print
              print(
                '🗑️ [AUDIO RECORDER] Cancelled audio path file deleted: $_audioPath',
              );
            }
          } catch (e) {
            // ignore: avoid_print
            print(
              '⚠️ [AUDIO RECORDER] Error deleting cancelled audio path file: $e',
            );
          }
        }
        setState(() {
          _recordedDuration = Duration.zero;
          _audioPath = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Recording cancelled')));
        }
      }
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('❌ [AUDIO RECORDER] Error in _stopRecording: $e');
      // ignore: avoid_print
      print('❌ [AUDIO RECORDER] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error stopping recording: $e')));
      }
      setState(() {
        _isRecording = false;
        _currentAmplitude = 0.0;
      });
      ref.read(questionProvider.notifier).setRecordingAudio(false);
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      // ignore: avoid_print
      print('▶️ [AUDIO RECORDER] Playing audio: $path');
      final file = File(path);
      if (!file.existsSync()) {
        // ignore: avoid_print
        print('❌ [AUDIO RECORDER] Audio file not found: $path');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Audio file not found')));
        }
        return;
      }

      final fileSize = await file.length();
      // ignore: avoid_print
      print('▶️ [AUDIO RECORDER] Audio file size: $fileSize bytes');

      await _audioPlayer.play(DeviceFileSource(path));
      // ignore: avoid_print
      print('✅ [AUDIO RECORDER] Audio playback started');
      setState(() {
        _isPlaying = true;
      });
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('❌ [AUDIO RECORDER] Error playing audio: $e');
      // ignore: avoid_print
      print('❌ [AUDIO RECORDER] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
      }
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error pausing audio: $e')));
      }
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      // Ignore errors
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
    // ignore: avoid_print
    print('🗑️ [AUDIO RECORDER] Widget disposing...');
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    // ignore: avoid_print
    print('✅ [AUDIO RECORDER] Widget disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionState = ref.watch(questionProvider);

    // Reset internal state if audio was deleted externally
    if (!questionState.hasAudio && _audioPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _audioPath = null;
            _isPlaying = false;
            _recordedDuration = Duration.zero;
          });
          _stopAudio();
        }
      });
    }

    if (questionState.hasAudio && !_isRecording) {
      // Show recorded audio preview
      return _buildAudioPreview();
    }

    if (_isRecording) {
      // Show recording UI with real waveform
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
          // Checkmark button (save recording)
          GestureDetector(
            onTap: () => _stopRecording(save: true),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF5BA3F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
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
                // Real waveform visualization
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
            onPressed: () async {
              // Stop audio playback
              await _stopAudio();
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
    if (waveformData.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF5BA3F5)
      ..style = PaintingStyle.fill;

    final barWidth = size.width / waveformData.length;
    final maxHeight = size.height * 0.8;
    final centerY = size.height / 2;

    for (int i = 0; i < waveformData.length; i++) {
      final amplitude = waveformData[i].clamp(0.0, 1.0);
      final height = amplitude * maxHeight;

      // Ensure minimum height for visibility
      final barHeight = height < 2.0 ? 2.0 : height;
      final x = i * barWidth + barWidth / 2;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, centerY),
          width: barWidth * 0.6,
          height: barHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is WaveformPainter) {
      return oldDelegate.waveformData != waveformData;
    }
    return true;
  }
}
