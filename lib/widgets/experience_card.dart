import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/experience.dart';

class ExperienceCard extends StatelessWidget {
  final Experience experience;
  final bool isSelected;
  final VoidCallback onTap;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Background image with grayscale filter for unselected
              if (!isSelected)
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: CachedNetworkImage(
                    imageUrl: experience.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.error, color: Colors.white),
                    ),
                  ),
                )
              else
                CachedNetworkImage(
                  imageUrl: experience.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[700],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[700],
                    child: const Icon(Icons.error, color: Colors.white),
                  ),
                ),
              // Gradient overlay for better text visibility
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              // Stamp-like serrated edges effect
              CustomPaint(size: Size.infinite, painter: StampPainter()),
              // Content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experience.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    // Icon placeholder - you can replace with actual icon from API
                    if (experience.iconUrl != null)
                      CachedNetworkImage(
                        imageUrl: experience.iconUrl!,
                        width: 40,
                        height: 40,
                        color: Colors.white,
                      )
                    else
                      _getIconForExperience(experience.name),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getIconForExperience(String name) {
    IconData iconData;
    switch (name.toUpperCase()) {
      case 'PARTY':
        iconData = Icons.music_note;
        break;
      case 'DINNER':
        iconData = Icons.restaurant;
        break;
      case 'BRUNCH':
        iconData = Icons.breakfast_dining;
        break;
      case 'DRINKS':
        iconData = Icons.local_bar;
        break;
      default:
        iconData = Icons.star;
    }
    return Icon(iconData, color: Colors.white, size: 40);
  }
}

// Custom painter for stamp-like serrated edges
class StampPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    const serrationSize = 8.0;
    const serrationCount = 4;

    // Top edge with serrations
    for (int i = 0; i < serrationCount; i++) {
      final x = (size.width / serrationCount) * i;
      path.moveTo(x, 0);
      path.lineTo(x + (size.width / serrationCount) / 2, -serrationSize);
      path.lineTo(x + (size.width / serrationCount), 0);
    }

    // Right edge with serrations
    for (int i = 0; i < serrationCount; i++) {
      final y = (size.height / serrationCount) * i;
      path.moveTo(size.width, y);
      path.lineTo(
        size.width + serrationSize,
        y + (size.height / serrationCount) / 2,
      );
      path.lineTo(size.width, y + (size.height / serrationCount));
    }

    // Bottom edge with serrations
    for (int i = 0; i < serrationCount; i++) {
      final x = size.width - (size.width / serrationCount) * i;
      path.moveTo(x, size.height);
      path.lineTo(
        x - (size.width / serrationCount) / 2,
        size.height + serrationSize,
      );
      path.lineTo(x - (size.width / serrationCount), size.height);
    }

    // Left edge with serrations
    for (int i = 0; i < serrationCount; i++) {
      final y = size.height - (size.height / serrationCount) * i;
      path.moveTo(0, y);
      path.lineTo(-serrationSize, y - (size.height / serrationCount) / 2);
      path.lineTo(0, y - (size.height / serrationCount));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
