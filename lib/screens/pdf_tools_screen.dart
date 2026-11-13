import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import '../services/pdf_service.dart';
import '../services/pdf_tools_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_container.dart';

enum PdfToolTab {
  viewer('Baca PDF', Icons.menu_book_rounded),
  compress('Kompres', Icons.compress_rounded),
  split('Pisah', Icons.call_split_rounded),
  merge('Gabung', Icons.merge_type_rounded);

  final String label;
  final IconData icon;
  const PdfToolTab(this.label, this.icon);
}

class PdfToolsScreen extends StatefulWidget {
  final String? initialFilePath;
  final PdfToolTab initialTab;

  const PdfToolsScreen({
    super.key,
    this.initialFilePath,
    this.initialTab = PdfToolTab.viewer,
  });

  @override
  State<PdfToolsScreen> createState() => _PdfToolsScreenState();
}

class _PdfToolsScreenState extends State<PdfToolsScreen> {
  late PdfToolTab _activeTab;

  // State: Baca PDF
  String? _viewingPdfPath;
  PdfFileInfo? _viewingPdfInfo;

  // State: Kompres PDF
  String? _compressSourcePath;
  PdfFileInfo? _compressSourceInfo;
  PdfCompressionTier _selectedCompressionTier = PdfCompressionTier.medium;
  bool _isCompressing = false;
  String? _compressedResultPath;
  PdfFileInfo? _compressedResultInfo;

  // State: Pisah PDF
  String? _splitSourcePath;
  PdfFileInfo? _splitSourceInfo;
  final Set<int> _selectedPagesToKeep = {}; // 0-based
  bool _isSplitting = false;
  String? _splitResultPath;

  // State: Gabung PDF
  final List<String> _mergeInputPaths = [];
  bool _isMerging = false;
  String? _mergeResultPath;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    if (widget.initialFilePath != null) {
      _loadInitialFile(widget.initialFilePath!);
    }
  }

  Future<void> _loadInitialFile(String path) async {
    _viewingPdfPath = path;
    _viewingPdfInfo = await PdfToolsService.inspectPdf(path);
    if (mounted) setState(() {});
  }

  // --- ACTIONS ---

  Future<void> _pickSinglePdf({required Function(String path) onPicked}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      onPicked(result.files.single.path!);
    }
  }

  Future<void> _pickMultiPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        for (final p in result.paths) {
          if (p != null && !_mergeInputPaths.contains(p)) {
            _mergeInputPaths.add(p);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        title: Text(
          'PDF Tools Suite',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textMain,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Segmented Tabs Header (Shadcn UI style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.bgCard,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: PdfToolTab.values.map((tab) {
                final isSelected = _activeTab == tab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.bgSurface : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppTheme.borderHover : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tab.icon,
                            size: 15,
                            color: isSelected ? AppTheme.accentCyan : AppTheme.textDim,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tab.label,
                            style: GoogleFonts.plusJakartaSans(
                              color: isSelected ? AppTheme.textMain : AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Active Tab Body
          Expanded(
            child: _buildTabBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_activeTab) {
      case PdfToolTab.viewer:
        return _buildViewerTab();
      case PdfToolTab.compress:
        return _buildCompressTab();
      case PdfToolTab.split:
        return _buildSplitTab();
      case PdfToolTab.merge:
        return _buildMergeTab();
    }
  }

  // ==========================================
  // TAB 1: BACA PDF (VIEWER)
  // ==========================================
  Widget _buildViewerTab() {
    if (_viewingPdfPath == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, size: 28, color: AppTheme.accentCyan),
              ),
              const SizedBox(height: 16),
              Text(
                'Buka & Baca Dokumen PDF',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih file PDF dari memori HP untuk membaca, memperbesar, mencetak, atau membagikan langsung.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _pickSinglePdf(onPicked: (path) => _loadInitialFile(path)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Pilih File PDF'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Top File Meta Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.bgCard,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _viewingPdfInfo?.name ?? 'Dokumen PDF',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_viewingPdfInfo?.pageCount ?? 1} Halaman • ${_viewingPdfInfo?.formattedSize ?? ''}',
                      style: GoogleFonts.jetBrainsMono(color: AppTheme.textDim, fontSize: 11),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickSinglePdf(onPicked: (path) => _loadInitialFile(path)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                label: const Text('Ganti', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),

        // PdfPreview Viewer Widget
        Expanded(
          child: ClipRRect(
            child: PdfPreview(
              build: (format) async {
                final file = File(_viewingPdfPath!);
                return await file.readAsBytes();
              },
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              allowPrinting: true,
              allowSharing: true,
              pdfFileName: _viewingPdfInfo?.name ?? 'Document.pdf',
              loadingWidget: const Center(
                child: CircularProgressIndicator(color: AppTheme.accentCyan),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: KOMPRES PDF
  // ==========================================
  Widget _buildCompressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Pick File
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1. File Sumber PDF', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14)),
                    if (_compressSourcePath != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _compressSourcePath = null;
                            _compressSourceInfo = null;
                            _compressedResultPath = null;
                            _compressedResultInfo = null;
                          });
                        },
                        child: const Text('Ganti', style: TextStyle(color: AppTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_compressSourcePath == null)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickSinglePdf(onPicked: (path) async {
                        final info = await PdfToolsService.inspectPdf(path);
                        setState(() {
                          _compressSourcePath = path;
                          _compressSourceInfo = info;
                          _compressedResultPath = null;
                        });
                      }),
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text('Pilih File PDF'),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.accentRose, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_compressSourceInfo?.name ?? '', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1),
                              Text('Ukuran Asli: ${_compressSourceInfo?.formattedSize} • ${_compressSourceInfo?.pageCount} Hal', style: GoogleFonts.jetBrainsMono(color: AppTheme.textDim, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Step 2: Tier Selection
          if (_compressSourcePath != null) ...[
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2. Level Optimasi Kompresi', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  ...PdfCompressionTier.values.map((tier) {
                    final isSelected = _selectedCompressionTier == tier;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCompressionTier = tier),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.bgSurface : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? AppTheme.accentCyan : AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              color: isSelected ? AppTheme.accentCyan : AppTheme.textDim,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tier.title, style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(tier.description, style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Compress Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isCompressing ? null : _handleCompress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.black,
                ),
                icon: _isCompressing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.compress_rounded, size: 20),
                label: Text(_isCompressing ? 'Mengompresi PDF...' : 'Mulai Kompresi', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          // Step 3: Compression Result Card
          if (_compressedResultPath != null && _compressedResultInfo != null) ...[
            const SizedBox(height: 20),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              border: Border.all(color: AppTheme.accentEmerald, width: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.accentEmerald, size: 22),
                      const SizedBox(width: 8),
                      Text('Kompresi Sukses!', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ukuran Semula:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            Text(_compressSourceInfo?.formattedSize ?? '', style: GoogleFonts.jetBrainsMono(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const Divider(color: AppTheme.border, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ukuran Baru:', style: TextStyle(color: AppTheme.accentEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(_compressedResultInfo!.formattedSize, style: GoogleFonts.jetBrainsMono(color: AppTheme.accentEmerald, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => PdfService.openPdf(_compressedResultPath!),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Buka PDF'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => PdfService.sharePdf(_compressedResultPath!, subject: 'PDF Terkompresi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentEmerald,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Bagikan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleCompress() async {
    if (_compressSourcePath == null) return;
    setState(() => _isCompressing = true);

    try {
      final outPath = await PdfToolsService.compressPdf(
        sourcePath: _compressSourcePath!,
        tier: _selectedCompressionTier,
      );
      final outInfo = await PdfToolsService.inspectPdf(outPath);

      setState(() {
        _compressedResultPath = outPath;
        _compressedResultInfo = outInfo;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Gagal kompres: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompressing = false);
    }
  }

  // ==========================================
  // TAB 3: PISAH PDF (SPLIT)
  // ==========================================
  Widget _buildSplitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Pick File
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1. File Sumber PDF', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14)),
                    if (_splitSourcePath != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _splitSourcePath = null;
                            _splitSourceInfo = null;
                            _selectedPagesToKeep.clear();
                            _splitResultPath = null;
                          });
                        },
                        child: const Text('Ganti', style: TextStyle(color: AppTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_splitSourcePath == null)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickSinglePdf(onPicked: (path) async {
                        final info = await PdfToolsService.inspectPdf(path);
                        setState(() {
                          _splitSourcePath = path;
                          _splitSourceInfo = info;
                          _selectedPagesToKeep.clear();
                          // Default centang semua
                          if (info != null) {
                            for (int i = 0; i < info.pageCount; i++) {
                              _selectedPagesToKeep.add(i);
                            }
                          }
                        });
                      }),
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text('Pilih File PDF'),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.accentPurple, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_splitSourceInfo?.name ?? '', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1),
                              Text('${_splitSourceInfo?.pageCount} Halaman total', style: GoogleFonts.jetBrainsMono(color: AppTheme.textDim, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          if (_splitSourceInfo != null) ...[
            const SizedBox(height: 14),

            // Step 2: Page Selection Matrix
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('2. Pilih Halaman Yang Disimpan', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${_selectedPagesToKeep.length} Terpilih', style: GoogleFonts.jetBrainsMono(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick selection chips
                  Row(
                    children: [
                      _buildMiniChip('Pilih Semua', () {
                        setState(() {
                          _selectedPagesToKeep.clear();
                          for (int i = 0; i < _splitSourceInfo!.pageCount; i++) {
                            _selectedPagesToKeep.add(i);
                          }
                        });
                      }),
                      const SizedBox(width: 6),
                      _buildMiniChip('Halaman Ganjil', () {
                        setState(() {
                          _selectedPagesToKeep.clear();
                          for (int i = 0; i < _splitSourceInfo!.pageCount; i += 2) {
                            _selectedPagesToKeep.add(i);
                          }
                        });
                      }),
                      const SizedBox(width: 6),
                      _buildMiniChip('Halaman Genap', () {
                        setState(() {
                          _selectedPagesToKeep.clear();
                          for (int i = 1; i < _splitSourceInfo!.pageCount; i += 2) {
                            _selectedPagesToKeep.add(i);
                          }
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Grid Pages
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_splitSourceInfo!.pageCount, (index) {
                      final isChecked = _selectedPagesToKeep.contains(index);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isChecked) {
                              _selectedPagesToKeep.remove(index);
                            } else {
                              _selectedPagesToKeep.add(index);
                            }
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 54,
                          decoration: BoxDecoration(
                            color: isChecked ? AppTheme.accentCyan.withValues(alpha: 0.15) : AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isChecked ? AppTheme.accentCyan : AppTheme.border,
                              width: isChecked ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                size: 16,
                                color: isChecked ? AppTheme.accentCyan : AppTheme.textDim,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${index + 1}',
                                style: GoogleFonts.jetBrainsMono(
                                  color: isChecked ? AppTheme.textMain : AppTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Split Action
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: (_isSplitting || _selectedPagesToKeep.isEmpty) ? null : _handleSplit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.black,
                ),
                icon: _isSplitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.call_split_rounded, size: 20),
                label: Text(_isSplitting ? 'Memisahkan Halaman...' : 'Ekspor Halaman Terpilih', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          if (_splitResultPath != null) ...[
            const SizedBox(height: 20),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              border: Border.all(color: AppTheme.accentEmerald, width: 1.5),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.accentEmerald, size: 22),
                      const SizedBox(width: 8),
                      Text('PDF Baru Berhasil Dibuat!', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => PdfService.openPdf(_splitResultPath!),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Buka PDF'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => PdfService.sharePdf(_splitResultPath!, subject: 'PDF Hasil Split'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentEmerald,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Bagikan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ),
    );
  }

  Future<void> _handleSplit() async {
    if (_splitSourcePath == null || _selectedPagesToKeep.isEmpty) return;
    setState(() => _isSplitting = true);

    try {
      final sortedIndices = _selectedPagesToKeep.toList()..sort();
      final outPath = await PdfToolsService.splitPdf(
        sourcePath: _splitSourcePath!,
        pageIndicesToKeep: sortedIndices,
      );

      setState(() => _splitResultPath = outPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Gagal pisah PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSplitting = false);
    }
  }

  // ==========================================
  // TAB 4: GABUNG PDF (MERGE)
  // ==========================================
  Widget _buildMergeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daftar File PDF yang Digabung', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14)),
              ElevatedButton.icon(
                onPressed: _pickMultiPdfs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Tambah PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_mergeInputPaths.isEmpty)
            GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.post_add_rounded, size: 40, color: AppTheme.textDim),
                    const SizedBox(height: 12),
                    Text('Belum ada file PDF yang dipilih', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('Pilih minimal 2 file PDF untuk disatukan', style: GoogleFonts.plusJakartaSans(color: AppTheme.textDim, fontSize: 11)),
                  ],
                ),
              ),
            )
          else ...[
            Text('Tarik dan geser ikon handle di kanan untuk mengubah urutan file:', style: GoogleFonts.plusJakartaSans(color: AppTheme.textDim, fontSize: 11)),
            const SizedBox(height: 8),

            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mergeInputPaths.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _mergeInputPaths.removeAt(oldIndex);
                  _mergeInputPaths.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final path = _mergeInputPaths[index];
                final filename = path.split('/').last;

                return Container(
                  key: ValueKey(path),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Center(
                          child: Text('${index + 1}', style: GoogleFonts.jetBrainsMono(color: AppTheme.accentCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(filename, style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textDim),
                        onPressed: () => setState(() => _mergeInputPaths.removeAt(index)),
                      ),
                      const Icon(Icons.drag_handle_rounded, size: 20, color: AppTheme.textDim),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: (_isMerging || _mergeInputPaths.length < 2) ? null : _handleMerge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.black,
                ),
                icon: _isMerging
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.merge_type_rounded, size: 20),
                label: Text(_isMerging ? 'Menggabungkan PDF...' : 'Gabungkan ${_mergeInputPaths.length} File PDF', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          if (_mergeResultPath != null) ...[
            const SizedBox(height: 20),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              border: Border.all(color: AppTheme.accentEmerald, width: 1.5),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.accentEmerald, size: 22),
                      const SizedBox(width: 8),
                      Text('PDF Berhasil Digabungkan!', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => PdfService.openPdf(_mergeResultPath!),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Buka PDF'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => PdfService.sharePdf(_mergeResultPath!, subject: 'PDF Gabungan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentEmerald,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Bagikan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleMerge() async {
    if (_mergeInputPaths.length < 2) return;
    setState(() => _isMerging = true);

    try {
      final outPath = await PdfToolsService.mergePdfs(
        inputPaths: _mergeInputPaths,
      );

      setState(() => _mergeResultPath = outPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Gagal gabung PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isMerging = false);
    }
  }
}
