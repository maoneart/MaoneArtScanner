import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

/// SHADCN UI FLOATING SCANNER ACTION BAR
/// Dock minimalis tanpa bouncing loop murahan, solid 1px border, thumb ergonomics
class ScannerFab extends StatelessWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onGalleryPressed;
  final VoidCallback? onPdfToolsPressed;

  const ScannerFab({
    super.key,
    required this.onScanPressed,
    required this.onGalleryPressed,
    this.onPdfToolsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.borderHover,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Tombol Kamera Scanner (Main CTA)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onScanPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.textMain,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF09090B),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pindai',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF09090B),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 4),

            // 2. Tombol Galeri Impor
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onGalleryPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      color: AppTheme.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            if (onPdfToolsPressed != null) ...[
              Container(
                width: 1,
                height: 18,
                color: AppTheme.border,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),

              // 3. Tombol PDF Suite
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onPdfToolsPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        color: AppTheme.accentCyan,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
