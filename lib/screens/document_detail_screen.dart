import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/scanned_document.dart';
import '../providers/document_provider.dart';
import '../services/pdf_service.dart';
import '../services/scanner_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/maoneart_modal.dart';
import 'ocr_screen.dart';
import 'pdf_preview_screen.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ScannedDocument? _getDocument(DocumentListState state) {
    try {
      return state.documents.firstWhere((d) => d.id == widget.documentId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleRename(ScannedDocument doc) async {
    final newTitle = await MaoneArtModal.showInputModal(
      context,
      title: 'Ganti Nama Dokumen',
      initialValue: doc.title,
      hintText: 'Nama dokumen...',
      icon: Icons.edit_rounded,
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != doc.title) {
      await ref.read(documentProvider.notifier).renameDocument(doc.id, newTitle);
    }
  }

  Future<void> _handleChangeCategory(ScannedDocument doc) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              color: AppTheme.bgCard,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Kategori Dokumen',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kDocumentCategories.where((c) => c != 'Semua').map((category) {
                      final isSelected = category == doc.category;
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: AppTheme.accentEmerald,
                        backgroundColor: AppTheme.bgSurface,
                        labelStyle: GoogleFonts.outfit(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          Navigator.of(context).pop(category);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await ref.read(documentProvider.notifier).updateCategory(doc.id, selected);
    }
  }

  Future<void> _handleEditNotes(ScannedDocument doc) async {
    final notes = await MaoneArtModal.showInputModal(
      context,
      title: 'Catatan Dokumen',
      initialValue: doc.notes,
      hintText: 'Tulis keterangan atau catatan penting di sini...',
      maxLines: 4,
      icon: Icons.description_rounded,
    );

    if (notes != null) {
      await ref.read(documentProvider.notifier).updateNotes(doc.id, notes);
    }
  }

  Future<void> _handleAddPages(ScannedDocument doc) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              color: AppTheme.bgCard,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tambah Halaman Baru',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              final newPaths = await ScannerService.addNewPages(fromCamera: false);
                              if (newPaths.isNotEmpty) {
                                await ref.read(documentProvider.notifier).addPages(doc.id, newPaths);
                              }
                            },
                            icon: const Icon(Icons.photo_library_rounded, color: AppTheme.accentEmerald),
                            label: Text('Dari Galeri', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              final newPaths = await ScannerService.addNewPages(fromCamera: true);
                              if (newPaths.isNotEmpty) {
                                await ref.read(documentProvider.notifier).addPages(doc.id, newPaths);
                              }
                            },
                            icon: const Icon(Icons.camera_alt_rounded, color: Colors.black),
                            label: Text('Scan Kamera', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentCyan,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDeletePage(ScannedDocument doc) async {
    final confirm = await MaoneArtModal.showConfirmModal(
      context,
      title: 'Hapus Halaman Ini?',
      message: 'Halaman ${_currentPageIndex + 1} dari ${doc.pageCount} akan dihapus secara permanen.',
      confirmText: 'Hapus Halaman',
      cancelText: 'Batal',
      isDanger: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirm) {
      final oldIndex = _currentPageIndex;
      await ref.read(documentProvider.notifier).deletePage(doc.id, oldIndex);
      if (oldIndex >= doc.pagePaths.length - 1 && oldIndex > 0) {
        setState(() => _currentPageIndex = oldIndex - 1);
      }
    }
  }

  Future<void> _handleDeleteDocument(ScannedDocument doc) async {
    final confirm = await MaoneArtModal.showConfirmModal(
      context,
      title: 'Hapus Seluruh Dokumen?',
      message: 'Dokumen "${doc.title}" beserta seluruh halamannya akan dihapus permanen dari perangkat.',
      confirmText: 'Hapus Dokumen',
      cancelText: 'Batal',
      isDanger: true,
      icon: Icons.warning_amber_rounded,
    );

    if (confirm) {
      await ref.read(documentProvider.notifier).deleteDocument(doc.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleShare(ScannedDocument doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              color: AppTheme.bgCard,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bagikan Dokumen',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              PdfService.shareImages(doc.pagePaths, text: doc.title);
                            },
                            icon: const Icon(Icons.photo_library_rounded, color: AppTheme.accentEmerald),
                            label: Text('File Gambar (JPG)', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => PdfPreviewScreen(document: doc)),
                              );
                            },
                            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.black),
                            label: Text('File PDF', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentCyan,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(documentProvider);
    final doc = _getDocument(docState);

    if (doc == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(),
        body: const Center(child: Text('Dokumen tidak ditemukan', style: TextStyle(color: Colors.white))),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final formattedDate = dateFormat.format(doc.updatedAt);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _handleRename(doc),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  doc.title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit_rounded, color: AppTheme.accentCyan, size: 14),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.accentEmerald, size: 20),
            tooltip: 'Bagikan',
            onPressed: () => _handleShare(doc),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRose, size: 20),
            tooltip: 'Hapus Dokumen',
            onPressed: () => _handleDeleteDocument(doc),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Metadata Bar (Category, Date, Page Counter)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _handleChangeCategory(doc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.accentEmerald.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            doc.category,
                            style: GoogleFonts.outfit(
                              color: AppTheme.accentEmerald,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppTheme.accentEmerald),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formattedDate,
                    style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      '${_currentPageIndex + 1} / ${doc.pageCount}',
                      style: GoogleFonts.outfit(
                        color: AppTheme.accentCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Interactive Image Carousel
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlassContainer(
                  padding: EdgeInsets.zero,
                  borderRadius: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: doc.pagePaths.length,
                      onPageChanged: (index) {
                        setState(() => _currentPageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final imagePath = doc.pagePaths[index];
                        final file = File(imagePath);

                        if (!file.existsSync()) {
                          return const Center(
                            child: Icon(Icons.broken_image_rounded, size: 48, color: Color(0xFF64748B)),
                          );
                        }

                        return InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.file(
                              file,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Horizontal Page Thumbnail Strip
            if (doc.pagePaths.length > 1)
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: doc.pagePaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentPageIndex;
                    final path = doc.pagePaths[index];
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppTheme.accentCyan : Colors.white.withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: AppTheme.bgSurface),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),

            // CamScanner Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard.withValues(alpha: 0.95),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Export PDF',
                    color: AppTheme.accentCyan,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PdfPreviewScreen(document: doc)),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.auto_awesome_rounded,
                    label: 'OCR Teks',
                    color: AppTheme.accentPurple,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => OcrScreen(document: doc)),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Tambah Hal',
                    color: AppTheme.accentEmerald,
                    onTap: () => _handleAddPages(doc),
                  ),
                  _buildActionButton(
                    icon: Icons.edit_note_rounded,
                    label: 'Catatan',
                    color: AppTheme.accentAmber,
                    onTap: () => _handleEditNotes(doc),
                  ),
                  _buildActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Hapus Hal',
                    color: AppTheme.accentRose,
                    onTap: () => _handleDeletePage(doc),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
