import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../models/scanned_document.dart';
import '../providers/document_provider.dart';
import '../services/pdf_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_container.dart';

class PdfPreviewScreen extends ConsumerStatefulWidget {
  final ScannedDocument document;

  const PdfPreviewScreen({super.key, required this.document});

  @override
  ConsumerState<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends ConsumerState<PdfPreviewScreen> {
  PaperSizeOption _selectedPaper = PaperSizeOption.a4;
  PdfExportMode _selectedMode = PdfExportMode.searchable;
  String? _generatedPdfPath;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _buildPdf();
  }

  Future<void> _buildPdf() async {
    setState(() => _isGenerating = true);
    final path = await ref.read(documentProvider.notifier).generateAndSavePdf(
      widget.document.id,
      paperSize: _selectedPaper,
      mode: _selectedMode,
    );
    if (mounted) {
      setState(() {
        _generatedPdfPath = path;
        _isGenerating = false;
      });
    }
  }

  void _sharePdf() {
    if (_generatedPdfPath != null) {
      PdfService.sharePdf(_generatedPdfPath!, subject: widget.document.title);
    }
  }

  void _openInApp() {
    if (_generatedPdfPath != null) {
      PdfService.openPdf(_generatedPdfPath!);
    }
  }

  void _printPdf() {
    if (_generatedPdfPath != null) {
      PdfService.printDocument(_generatedPdfPath!, title: widget.document.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(
          'Export PDF',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: AppTheme.accentCyan, size: 20),
            tooltip: 'Cetak / Print',
            onPressed: _generatedPdfPath != null ? _printPdf : null,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.accentEmerald, size: 20),
            tooltip: 'Bagikan PDF',
            onPressed: _generatedPdfPath != null ? _sharePdf : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Controls: Paper Size & PDF Mode
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Column(
                children: [
                  // Mode Selection Bar (Searchable vs Word-style vs Pure Image)
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    borderRadius: 10,
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentCyan, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Mode PDF:',
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textDim, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<PdfExportMode>(
                              value: _selectedMode,
                              isExpanded: true,
                              dropdownColor: AppTheme.bgCard,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.accentCyan, size: 18),
                              items: PdfExportMode.values.map((mode) {
                                return DropdownMenuItem(
                                  value: mode,
                                  child: Text(
                                    mode.label,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newVal) {
                                if (newVal != null && newVal != _selectedMode) {
                                  setState(() => _selectedMode = newVal);
                                  _buildPdf();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Paper Size Selection Bar
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    borderRadius: 10,
                    child: Row(
                      children: [
                        const Icon(Icons.description_rounded, color: AppTheme.accentEmerald, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Ukuran Kertas:',
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textDim, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<PaperSizeOption>(
                              value: _selectedPaper,
                              dropdownColor: AppTheme.bgCard,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.accentEmerald, size: 18),
                              items: PaperSizeOption.values.map((opt) {
                                return DropdownMenuItem(
                                  value: opt,
                                  child: Text(
                                    opt.label,
                                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newVal) {
                                if (newVal != null && newVal != _selectedPaper) {
                                  setState(() => _selectedPaper = newVal);
                                  _buildPdf();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main PDF Viewer / Preview
            Expanded(
              child: _isGenerating || _generatedPdfPath == null
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppTheme.accentCyan),
                          SizedBox(height: 16),
                          Text('Menyusun halaman PDF...', style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: PdfPreview(
                          build: (format) async {
                            final file = File(_generatedPdfPath!);
                            return await file.readAsBytes();
                          },
                          canChangeOrientation: false,
                          canChangePageFormat: false,
                          canDebug: false,
                          allowPrinting: true,
                          allowSharing: true,
                          previewPageMargin: const EdgeInsets.all(8),
                          pdfFileName: '${widget.document.title}.pdf',
                          loadingWidget: const Center(
                            child: CircularProgressIndicator(color: AppTheme.accentCyan),
                          ),
                        ),
                      ),
                    ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppTheme.bgCard,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _openInApp,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: AppTheme.bgSurface,
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, color: AppTheme.textMuted, size: 16),
                        label: Text(
                          'Buka di PDF Reader',
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textMain, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _sharePdf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.textMain,
                          foregroundColor: const Color(0xFF09090B),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.send_rounded, color: Color(0xFF09090B), size: 16),
                        label: Text(
                          'Kirim PDF',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF09090B), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
