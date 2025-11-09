import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/question_provider.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/video_recorder_widget.dart';

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key});

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  final TextEditingController _textController = TextEditingController();
  final int _maxCharacterLimit = 600;
  final GlobalKey<AudioRecorderWidgetState> _audioRecorderKey = GlobalKey();
  final GlobalKey<VideoRecorderWidgetState> _videoRecorderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _textController.text;
    if (text.length <= _maxCharacterLimit) {
      ref.read(questionProvider.notifier).updateText(text);
    } else {
      _textController.text = text.substring(0, _maxCharacterLimit);
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _maxCharacterLimit),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final questionState = ref.read(questionProvider);

    // Log the state
    // ignore: avoid_print
    print('Question Screen State:');
    // ignore: avoid_print
    print('Text: ${questionState.text}');
    // ignore: avoid_print
    print('Has Audio: ${questionState.hasAudio}');
    // ignore: avoid_print
    print('Has Video: ${questionState.hasVideo}');
    // ignore: avoid_print
    print('Audio Path: ${questionState.audioPath}');
    // ignore: avoid_print
    print('Video Path: ${questionState.videoPath}');

    // Navigate to next screen (placeholder)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _NextScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionState = ref.watch(questionProvider);
    final characterCount = _textController.text.length;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Step indicator
                    const Text(
                      '02',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Question
                    const Text(
                      'Why do you want to host with us?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Instructions
                    Text(
                      'Tell us about your intent and what motivates you to create experiences.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Text input field
                    _buildTextInputField(characterCount),
                    const SizedBox(height: 16),
                    // Audio recorder widget
                    AudioRecorderWidget(key: _audioRecorderKey),
                    // Video recorder widget
                    VideoRecorderWidget(key: _videoRecorderKey),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom action bar
            _buildBottomActionBar(questionState),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            iconSize: 24,
            onPressed: () => Navigator.pop(context),
          ),
          // Progress indicator - Blue waveform
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CustomPaint(
                size: const Size(double.infinity, 20),
                painter: WavyProgressPainter(
                  progress: 0.66, // 2/3 of the way (step 02 of 03)
                ),
              ),
            ),
          ),
          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
            iconSize: 24,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputField(int characterCount) {
    final isFocused = FocusScope.of(context).focusedChild != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused ? const Color(0xFF5BA3F5) : Colors.transparent,
              width: 2,
            ),
          ),
          child: TextField(
            controller: _textController,
            maxLines: 8,
            maxLength: _maxCharacterLimit,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: '/ Start typing here',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '', // Hide default counter
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(_maxCharacterLimit),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$characterCount / $_maxCharacterLimit',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(QuestionState questionState) {
    final hasMedia = questionState.hasMedia;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.grey[800]!, width: 1)),
      ),
      child: Row(
        children: [
          // Record buttons (hidden when media is recorded)
          if (!hasMedia) ...[
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.35,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Audio button
                    Expanded(
                      child: _buildRecordButton(
                        icon: Icons.mic,
                        isActive: questionState.isRecordingAudio,
                        onTap: () {
                          if (!questionState.hasAudio) {
                            _audioRecorderKey.currentState
                                ?.startRecording();
                          }
                        },
                      ),
                    ),
                    // Separator
                    Container(
                      width: 1,
                      height: 56,
                      color: Colors.grey[700],
                    ),
                    // Video button
                    Expanded(
                      child: _buildRecordButton(
                        icon: Icons.videocam,
                        isActive: questionState.isRecordingVideo,
                        onTap: () {
                          if (!questionState.hasVideo) {
                            _videoRecorderKey.currentState
                                ?.startRecording();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Next button (animated width)
          Expanded(
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A2A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF5BA3F5) : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

// Custom painter for wavy progress indicator (reused from experience screen)
class WavyProgressPainter extends CustomPainter {
  final double progress;

  WavyProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.grey[700]!.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xFF5BA3F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final waveCount = 14;
    final waveWidth = size.width / waveCount;

    final waveformPattern = [
      0.4,
      0.9,
      0.6,
      1.0,
      0.7,
      0.95,
      0.5,
      0.85,
      0.65,
      0.9,
      0.55,
      0.8,
      0.75,
      1.0,
    ];
    final maxWaveHeight = size.height * 0.75;

    // Draw background waveform
    final backgroundPath = Path();
    for (int i = 0; i < waveCount; i++) {
      final x = i * waveWidth;
      final waveHeight =
          waveformPattern[i % waveformPattern.length] * maxWaveHeight;
      final topY = centerY - waveHeight / 2;
      final bottomY = centerY + waveHeight / 2;

      if (i == 0) {
        backgroundPath.moveTo(x, centerY);
      }

      backgroundPath.quadraticBezierTo(
        x + waveWidth / 4,
        topY,
        x + waveWidth / 2,
        centerY,
      );

      backgroundPath.quadraticBezierTo(
        x + waveWidth * 3 / 4,
        bottomY,
        x + waveWidth,
        centerY,
      );
    }
    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw progress waveform
    final progressWidth = size.width * progress;
    final progressWaveCount = (progressWidth / waveWidth).ceil();

    if (progressWaveCount > 0) {
      final progressPath = Path();
      for (int i = 0; i < progressWaveCount && i < waveCount; i++) {
        final x = i * waveWidth;
        final waveHeight =
            waveformPattern[i % waveformPattern.length] * maxWaveHeight;
        final topY = centerY - waveHeight / 2;
        final bottomY = centerY + waveHeight / 2;

        final waveEndX = (i + 1) * waveWidth;
        final isPartialWave = waveEndX > progressWidth && progressWidth > x;

        if (i == 0) {
          progressPath.moveTo(x, centerY);
        }

        if (isPartialWave) {
          final progressPointX = progressWidth;
          final progressRatio = (progressPointX - x) / waveWidth;

          if (progressRatio > 0.5) {
            progressPath.quadraticBezierTo(
              x + waveWidth / 4,
              topY,
              x + waveWidth / 2,
              centerY,
            );
            final partialBottomY =
                centerY + (bottomY - centerY) * ((progressRatio - 0.5) * 2);
            progressPath.quadraticBezierTo(
              x + waveWidth / 2 + (progressPointX - x - waveWidth / 2) / 2,
              partialBottomY,
              progressPointX,
              centerY,
            );
          } else {
            final partialTopY =
                centerY - (centerY - topY) * (progressRatio * 2);
            progressPath.quadraticBezierTo(
              x + (progressPointX - x) / 2,
              partialTopY,
              progressPointX,
              centerY,
            );
          }
        } else {
          progressPath.quadraticBezierTo(
            x + waveWidth / 4,
            topY,
            x + waveWidth / 2,
            centerY,
          );
          progressPath.quadraticBezierTo(
            x + waveWidth * 3 / 4,
            bottomY,
            x + waveWidth,
            centerY,
          );
        }
      }
      canvas.drawPath(progressPath, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is WavyProgressPainter) {
      return oldDelegate.progress != progress;
    }
    return true;
  }
}

// Placeholder next screen
class _NextScreen extends StatelessWidget {
  const _NextScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Next Screen', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Next Screen',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
