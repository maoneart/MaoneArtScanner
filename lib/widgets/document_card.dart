import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/scanned_document.dart';
import '../utils/app_theme.dart';
import 'glass_container.dart';

enum DocumentAction { pdf, ocr, category, rename, share, delete }

class DocumentCard extends StatelessWidget {
  final ScannedDocument document;
  final bool isGrid;
  final VoidCallback onTap;
  final Function(DocumentAction) onActionSelected;

  const DocumentCard({
    super.key,
    required this.document,
    this.isGrid = true,
    required this.onTap,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return _buildGridCard(context);
    }
    return _buildListCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final formattedDate = dateFormat.format(document.updatedAt);

    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 12,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Thumbnail with Badges
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildThumbnail(),
                
                // Gradient overlay at top & bottom of thumbnail
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),

                // Page Count Badge (Top Left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.layers_rounded, size: 12, color: AppTheme.accentCyan),
                        const SizedBox(width: 4),
                        Text(
                          '${document.pageCount} Hal',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppTheme.textMain,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Category Tag (Top Right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      document.category,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.accentCyan,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // OCR Ready Badge (Bottom Left)
                if (document.hasOcr)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 10, color: AppTheme.accentPurple),
                          const SizedBox(width: 4),
                          Text(
                            'OCR',
                            style: GoogleFonts.jetBrainsMono(
                              color: AppTheme.accentPurple,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Document Details Footer
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textMain,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _buildPopupMenu(context),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.textDim,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final formattedDate = dateFormat.format(document.updatedAt);

    return GlassContainer(
      padding: const EdgeInsets.all(10),
      borderRadius: 12,
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onTap,
      child: Row(
        children: [
          // Thumbnail Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 58,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnail(),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${document.pageCount}p',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.accentEmerald.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        document.category,
                        style: GoogleFonts.outfit(
                          color: AppTheme.accentEmerald,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (document.hasOcr) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'OCR',
                          style: GoogleFonts.outfit(
                            color: AppTheme.accentPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Action Menu
          _buildPopupMenu(context),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (document.thumbnailPath.isNotEmpty && File(document.thumbnailPath).existsSync()) {
      return Image.file(
        File(document.thumbnailPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackThumbnail(),
      );
    }
    return _buildFallbackThumbnail();
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      color: AppTheme.bgSurface,
      child: const Center(
        child: Icon(
          Icons.description_rounded,
          color: Color(0xFF475569),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: AppTheme.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppTheme.border),
          ),
          elevation: 10,
        ),
      ),
      child: PopupMenuButton<DocumentAction>(
        icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textDim, size: 18),
        padding: EdgeInsets.zero,
        onSelected: onActionSelected,
        itemBuilder: (context) => [
          _buildPopupMenuItem(
            DocumentAction.pdf,
            Icons.picture_as_pdf_rounded,
            'Export PDF',
            AppTheme.accentCyan,
          ),
          _buildPopupMenuItem(
            DocumentAction.ocr,
            Icons.auto_awesome_rounded,
            'Ekstrak Teks (OCR)',
            AppTheme.accentPurple,
          ),
          _buildPopupMenuItem(
            DocumentAction.share,
            Icons.share_rounded,
            'Bagikan Dokumen',
            AppTheme.accentEmerald,
          ),
          _buildPopupMenuItem(
            DocumentAction.rename,
            Icons.edit_rounded,
            'Ganti Nama',
            AppTheme.textMuted,
          ),
          _buildPopupMenuItem(
            DocumentAction.category,
            Icons.label_rounded,
            'Ubah Kategori',
            AppTheme.textMuted,
          ),
          const PopupMenuDivider(height: 1),
          _buildPopupMenuItem(
            DocumentAction.delete,
            Icons.delete_outline_rounded,
            'Hapus Dokumen',
            AppTheme.accentRose,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<DocumentAction> _buildPopupMenuItem(
    DocumentAction value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem<DocumentAction>(
      value: value,
      height: 38,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
