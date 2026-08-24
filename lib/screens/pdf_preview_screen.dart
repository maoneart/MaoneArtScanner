import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.printer, color: AppTheme.accentCyan, size: 20),
            tooltip: 'Cetak / Print',
            onPressed: _generatedPdfPath != null ? _printPdf : null,
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2, color: AppTheme.accentEmerald, size: 20),
            tooltip: 'Bagikan PDF',
            onPressed: _generatedPdfPath != null ? _sharePdf : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Paper Size Selection Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                borderRadius: 14,
                child: Row(
                  children: [
                    const Icon(LucideIcons.fileSpreadsheet, color: AppTheme.accentCyan, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Ukuran Kertas:',
                      style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaperSizeOption>(
                          value: _selectedPaper,
                          dropdownColor: AppTheme.bgCard,
                          icon: const Icon(LucideIcons.chevronDown, color: AppTheme.accentCyan, size: 18),
                          items: PaperSizeOption.values.map((opt) {
                            return DropdownMenuItem(
                              value: opt,
                              child: Text(
                                opt.label,
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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
                          Text('Menyusun halaman PDF...', style: TextStyle(color: Color(0xFF94A3B8))),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard.withValues(alpha: 0.8),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _openInApp,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                        ),
                        icon: const Icon(LucideIcons.externalLink, color: Colors.white70, size: 18),
                        label: Text(
                          'Buka di PDF Reader',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _sharePdf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentCyan,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(LucideIcons.send, color: Colors.black, size: 18),
                        label: Text(
                          'Kirim PDF',
                          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
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
