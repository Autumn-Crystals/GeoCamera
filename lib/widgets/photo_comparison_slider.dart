import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PhotoComparisonSlider extends StatefulWidget {
  final String beforeImagePath; // file path
  final String afterImagePath; // file path
  final String beforeLabel;
  final String afterLabel;

  const PhotoComparisonSlider({
    super.key,
    required this.beforeImagePath,
    required this.afterImagePath,
    this.beforeLabel = 'Initial',
    this.afterLabel = 'Latest',
  });

  @override
  State<PhotoComparisonSlider> createState() => _PhotoComparisonSliderState();
}

class _PhotoComparisonSliderState extends State<PhotoComparisonSlider> {
  double _sliderPosition = 0.5;

  Widget _buildImage(String imagePath) {
    // Check if it's a base64 string or file path
    if (imagePath.startsWith('data:') || imagePath.contains(',')) {
      // Base64 image
      final base64String = imagePath.contains(',')
          ? imagePath.split(',').last
          : imagePath;
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppTheme.bgElevated,
          child: const Icon(Icons.park, color: AppTheme.primary, size: 48),
        ),
      );
    } else {
      // File path
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppTheme.bgElevated,
          child: const Icon(Icons.park, color: AppTheme.primary, size: 48),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // After image (full width)
          Positioned.fill(
            child: _buildImage(widget.afterImagePath),
          ),

          // Before image (clipped by slider position)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * _sliderPosition,
            child: ClipRect(
              child: _buildImage(widget.beforeImagePath),
            ),
          ),

          // Slider line
          Positioned(
            left: MediaQuery.of(context).size.width * _sliderPosition - 2,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),

          // Slider handle
          Positioned(
            left: MediaQuery.of(context).size.width * _sliderPosition - 20,
            top: MediaQuery.of(context).size.height * 0.5 - 70,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.compare_arrows,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
          ),

          // Labels
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.beforeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.afterLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Gesture detector for dragging
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _sliderPosition = (details.localPosition.dx /
                          MediaQuery.of(context).size.width)
                      .clamp(0.0, 1.0);
                });
              },
              onTapDown: (details) {
                setState(() {
                  _sliderPosition = (details.localPosition.dx /
                          MediaQuery.of(context).size.width)
                      .clamp(0.0, 1.0);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
