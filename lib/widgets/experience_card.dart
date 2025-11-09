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
        margin: const EdgeInsets.only(right: 32),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          color: Colors
              .transparent, // Transparent background to show image borders
          child: isSelected
              ? CachedNetworkImage(
                  imageUrl: experience.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit
                      .contain, // Use contain to show full image without cuts
                  alignment: Alignment.center,
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
                )
              : ColorFiltered(
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
                    fit: BoxFit
                        .contain, // Use contain to show full image without cuts
                    alignment: Alignment.center,
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
                ),
        ),
      ),
    );
  }
}
