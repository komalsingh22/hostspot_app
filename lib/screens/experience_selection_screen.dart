import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experience.dart';
import '../providers/experience_provider.dart';
import '../providers/experience_selection_provider.dart';
import '../widgets/experience_card.dart';
import 'question_screen.dart';

class ExperienceSelectionScreen extends ConsumerStatefulWidget {
  final String? apiUrl;

  const ExperienceSelectionScreen({super.key, this.apiUrl});

  @override
  ConsumerState<ExperienceSelectionScreen> createState() =>
      _ExperienceSelectionScreenState();
}

class _ExperienceSelectionScreenState
    extends ConsumerState<ExperienceSelectionScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final int _maxCharacterLimit = 250;
  final List<Experience> _displayedExperiences = [];

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_onDescriptionChanged);
  }

  void _onDescriptionChanged() {
    final text = _descriptionController.text;
    if (text.length <= _maxCharacterLimit) {
      ref.read(experienceSelectionProvider.notifier).updateDescription(text);
    } else {
      _descriptionController.text = text.substring(0, _maxCharacterLimit);
      _descriptionController.selection = TextSelection.fromPosition(
        TextPosition(offset: _maxCharacterLimit),
      );
    }
  }

  void _toggleExperienceSelection(Experience experience) {
    final selectionState = ref.read(experienceSelectionProvider);
    final allExperiences = selectionState.experiences.isEmpty
        ? _displayedExperiences
        : selectionState.experiences;

    // Update state through provider (this will trigger reordering)
    ref
        .read(experienceSelectionProvider.notifier)
        .toggleExperienceSelection(experience.id, allExperiences);
  }

  void _handleNext() {
    final selectionState = ref.read(experienceSelectionProvider);

    // Log the state (as per requirements)
    // ignore: avoid_print
    print(
      'Selected Experience IDs: ${selectionState.selectedExperienceIds.toList()}',
    );
    // ignore: avoid_print
    print('Description: ${selectionState.description}');
    // ignore: avoid_print
    print(
      'Selected Experiences: ${selectionState.experiences.where((e) => selectionState.selectedExperienceIds.contains(e.id)).map((e) => e.name).toList()}',
    );
    // ignore: avoid_print
    print('Full State: $selectionState');

    // Navigate to question screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuestionScreen()),
    );
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_onDescriptionChanged);
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final experiencesAsync = ref.watch(experiencesProvider);
    final selectionState = ref.watch(experienceSelectionProvider);

    // Initialize experiences when loaded
    experiencesAsync.whenData((experiences) {
      if (selectionState.experiences.isEmpty && experiences.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(experienceSelectionProvider.notifier)
              .setExperiences(experiences);
          _displayedExperiences.clear();
          _displayedExperiences.addAll(experiences);
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress indicator
            _buildHeader(),
            // Main content
            Expanded(
              child: experiencesAsync.when(
                data: (experiences) {
                  final displayedExperiences =
                      selectionState.experiences.isNotEmpty
                      ? selectionState.experiences
                      : experiences;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Step indicator
                        const Text(
                          '01',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Question
                        const Text(
                          'What kind of hotspots do you want to host?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Experience cards with animation
                        SizedBox(
                          height: 180,
                          child: _buildAnimatedExperienceList(
                            displayedExperiences,
                            selectionState,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Description text field
                        _buildDescriptionField(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading experiences: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
            // Next button
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedExperienceList(
    List<Experience> experiences,
    ExperienceSelectionState selectionState,
  ) {
    return ListView.builder(
      key: PageStorageKey('experience_list'),
      scrollDirection: Axis.horizontal,
      itemCount: experiences.length,
      itemBuilder: (context, index) {
        final experience = experiences[index];
        final isSelected = selectionState.selectedExperienceIds.contains(
          experience.id,
        );

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.95 + (value * 0.05),
              child: Opacity(
                opacity: value,
                child: ExperienceCard(
                  experience: experience,
                  isSelected: isSelected,
                  onTap: () => _toggleExperienceSelection(experience),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              // Progress indicator - Blue waveform
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: CustomPaint(
                    size: const Size(double.infinity, 20),
                    painter: WavyProgressPainter(
                      progress: 0.33, // 1/3 of the way (step 01 of 03)
                    ),
                  ),
                ),
              ),
              // Close button
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    final characterCount = _descriptionController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF5BA3F5), // Blue border
              width: 2,
            ),
          ),
          child: TextField(
            controller: _descriptionController,
            maxLines: 5,
            maxLength: _maxCharacterLimit,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: '/ Describe your perfect hotspot',
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

  Widget _buildNextButton() {
    final selectionState = ref.watch(experienceSelectionProvider);
    final isEnabled = selectionState.selectedExperienceIds.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isEnabled ? _handleNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled
                ? const Color(0xFF2A2A2A)
                : Colors.grey[800],
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for waveform progress indicator
class WavyProgressPainter extends CustomPainter {
  final double progress;

  WavyProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Background (inactive) waveform
    final backgroundPaint = Paint()
      ..color = Colors.grey[700]!.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Progress (active) waveform - Vibrant blue color
    final progressPaint = Paint()
      ..color =
          const Color(0xFF5BA3F5) // Vibrant blue color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final waveCount = 14; // Number of waves for smoother appearance
    final waveWidth = size.width / waveCount;

    // Waveform pattern with varying heights (like audio waveform) - more variation
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
    final maxWaveHeight =
        size.height * 0.75; // Slightly reduced for better visibility

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

      // Draw upward wave
      backgroundPath.quadraticBezierTo(
        x + waveWidth / 4,
        topY,
        x + waveWidth / 2,
        centerY,
      );

      // Draw downward wave
      backgroundPath.quadraticBezierTo(
        x + waveWidth * 3 / 4,
        bottomY,
        x + waveWidth,
        centerY,
      );
    }
    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw progress waveform (blue, only the completed portion)
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

        // Check if this wave is partially completed
        final waveEndX = (i + 1) * waveWidth;
        final isPartialWave = waveEndX > progressWidth && progressWidth > x;

        if (i == 0) {
          progressPath.moveTo(x, centerY);
        }

        if (isPartialWave) {
          // Partial wave - only draw up to progress point
          final progressPointX = progressWidth;
          final progressRatio = (progressPointX - x) / waveWidth;

          if (progressRatio > 0.5) {
            // Draw full upward wave and partial downward
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
            // Only draw partial upward wave
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
          // Complete wave
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
