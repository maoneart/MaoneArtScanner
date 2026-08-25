import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/scanned_document.dart';
import '../providers/document_provider.dart';
import '../services/pdf_service.dart';
import '../services/scanner_service.dart';
import '../utils/app_theme.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/document_card.dart';
import '../widgets/glass_container.dart';
import '../widgets/maoneart_modal.dart';
import '../widgets/scanner_fab.dart';
import 'document_detail_screen.dart';
import 'ocr_screen.dart';
import 'pdf_preview_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startCameraScan() async {
    final result = await ScannerService.startDocumentScan(pageLimit: 50);
    if (result.isSuccess && result.imagePaths.isNotEmpty) {
      final doc = await ref.read(documentProvider.notifier).createDocument(
        pagePaths: result.imagePaths,
        category: 'Dokumen',
      );

      if (doc != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: doc.id)),
        );
      }
    }
  }

  Future<void> _startGalleryImport() async {
    final result = await ScannerService.pickFromGallery();
    if (result.isSuccess && result.imagePaths.isNotEmpty) {
      final doc = await ref.read(documentProvider.notifier).createDocument(
        pagePaths: result.imagePaths,
        category: 'Dokumen',
      );

      if (doc != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: doc.id)),
        );
      }
    }
  }

  Future<void> _handleDocumentAction(ScannedDocument doc, DocumentAction action) async {
    switch (action) {
      case DocumentAction.pdf:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PdfPreviewScreen(document: doc)),
        );
        break;

      case DocumentAction.ocr:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OcrScreen(document: doc)),
        );
        break;

      case DocumentAction.share:
        PdfService.shareImages(doc.pagePaths, text: doc.title);
        break;

      case DocumentAction.rename:
        final newTitle = await MaoneArtModal.showInputModal(
          context,
          title: 'Ganti Nama Dokumen',
          initialValue: doc.title,
          hintText: 'Nama baru dokumen...',
          icon: Icons.edit_rounded,
        );
        if (newTitle != null && newTitle.isNotEmpty && newTitle != doc.title) {
          await ref.read(documentProvider.notifier).renameDocument(doc.id, newTitle);
        }
        break;

      case DocumentAction.category:
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
                        'Pilih Kategori',
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
                            onSelected: (_) => Navigator.of(context).pop(category),
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
        break;

      case DocumentAction.delete:
        final confirm = await MaoneArtModal.showConfirmModal(
          context,
          title: 'Hapus Dokumen?',
          message: 'Dokumen "${doc.title}" akan dihapus permanen.',
          confirmText: 'Hapus',
          cancelText: 'Batal',
          isDanger: true,
          icon: Icons.delete_outline_rounded,
        );
        if (confirm) {
          await ref.read(documentProvider.notifier).deleteDocument(doc.id);
        }
        break;
    }
  }

  void _showInfoModal() {
    MaoneArtModal.showAlertModal(
      context,
      title: 'MaoneArt Scanner v1.0',
      message: 'Aplikasi Smart AI Document Scanner dengan Google ML Kit Paper Detection, Perspective Auto-Crop, Offline OCR Text Extractor, dan Multi-Page PDF Exporter.',
      icon: Icons.document_scanner_rounded,
      iconColor: AppTheme.accentCyan,
      buttonText: 'Tutup',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentProvider);
    final filteredDocs = state.filteredDocuments;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.document_scanner_rounded, color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MaoneArt Scanner',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${state.documents.length} Dokumen • ${state.totalPages} Halaman',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearchExpanded = !_isSearchExpanded;
                        if (!_isSearchExpanded) {
                          _searchController.clear();
                          ref.read(documentProvider.notifier).setSearchQuery('');
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      state.isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                      color: AppTheme.accentCyan,
                      size: 20,
                    ),
                    tooltip: state.isGridView ? 'Tampilan List' : 'Tampilan Grid',
                    onPressed: () => ref.read(documentProvider.notifier).toggleViewMode(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 20),
                    onPressed: _showInfoModal,
                  ),
                ],
              ),
            ),

            // Search Bar (if expanded)
            if (_isSearchExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  borderRadius: 14,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Cari judul, OCR teks, atau catatan...',
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search_rounded, color: AppTheme.accentCyan, size: 18),
                    ),
                    onChanged: (val) {
                      ref.read(documentProvider.notifier).setSearchQuery(val);
                    },
                  ),
                ),
              ),

            // Category Filter Chips
            CategoryFilterBar(
              selectedCategory: state.selectedCategory,
              onCategorySelected: (cat) {
                ref.read(documentProvider.notifier).setSelectedCategory(cat);
              },
            ),

            const SizedBox(height: 12),

            // Document List / Grid Area
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.accentCyan,
                backgroundColor: AppTheme.bgCard,
                onRefresh: () => ref.read(documentProvider.notifier).loadDocuments(),
                child: filteredDocs.isEmpty
                    ? _buildEmptyState()
                    : state.isGridView
                        ? GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              return DocumentCard(
                                document: doc,
                                isGrid: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: doc.id)),
                                  );
                                },
                                onActionSelected: (action) => _handleDocumentAction(doc, action),
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              return DocumentCard(
                                document: doc,
                                isGrid: false,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: doc.id)),
                                  );
                                },
                                onActionSelected: (action) => _handleDocumentAction(doc, action),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScannerFab(
        onScanPressed: _startCameraScan,
        onGalleryPressed: _startGalleryImport,
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentCyan.withValues(alpha: 0.1),
                      border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: const Icon(Icons.find_in_page_rounded, color: AppTheme.accentCyan, size: 44),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum Ada Dokumen',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mulai scan dokumen fisik, nota/struk, atau impor foto dari galeri untuk mendeteksi teks dan membuat berkas PDF.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _startCameraScan,
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 18),
                    label: Text(
                      'Scan Sekarang',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
