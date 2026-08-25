import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ScannerFab extends StatefulWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onGalleryPressed;

  const ScannerFab({
    super.key,
    required this.onScanPressed,
    required this.onGalleryPressed,
  });

  @override
  State<ScannerFab> createState() => _ScannerFabState();
}

class _ScannerFabState extends State<ScannerFab> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0284C7), // Vibrant Blue Cyan
              Color(0xFF007AFF), // Apple / CamScanner Blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007AFF).withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Tombol Kamera Scanner (Left Action)
              InkWell(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
                onTap: widget.onScanPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),

              // Garis Pemisah Tipis
              Container(
                width: 1,
                height: 24,
                color: Colors.white.withValues(alpha: 0.28),
              ),

              // 2. Tombol Galeri Impor (Right Action)
              InkWell(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(28)),
                onTap: widget.onGalleryPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
