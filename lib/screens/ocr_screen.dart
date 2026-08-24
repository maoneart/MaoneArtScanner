import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scanned_document.dart';
import '../providers/document_provider.dart';
import '../services/ocr_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/maoneart_modal.dart';

class OcrScreen extends ConsumerStatefulWidget {
  final ScannedDocument document;

  const OcrScreen({super.key, required this.document});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  late TextEditingController _textController;
  bool _isEditing = false;
  bool _isProcessing = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.document.ocrText);
    if (widget.document.ocrText.trim().isEmpty) {
      _runOcrRecognition();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runOcrRecognition() async {
    setState(() => _isProcessing = true);
    try {
      final ocrText = await ref.read(documentProvider.notifier).runOcrForDocument(widget.document.id);
      if (mounted) {
        setState(() {
          _textController.text = ocrText;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        MaoneArtModal.showAlertModal(
          context,
          title: 'Gagal OCR',
          message: 'Terjadi kendala saat membaca teks dokumen: $e',
          iconColor: AppTheme.accentRose,
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final newText = _textController.text;
    await ref.read(documentProvider.notifier).saveOcrText(widget.document.id, newText);
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teks OCR berhasil disimpan', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.accentEmerald,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyToClipboard() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCheck, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text('Seluruh teks berhasil disalin!', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppTheme.accentCyan,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareText() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    Share.share(text, subject: 'Hasil OCR - ${widget.document.title}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(
          'Hasil Ekstraksi OCR',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Search Toggle
          IconButton(
            icon: Icon(_isSearchOpen ? LucideIcons.x : LucideIcons.search, size: 20),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          // Re-run OCR
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20, color: AppTheme.accentCyan),
            tooltip: 'Scan Ulang OCR',
            onPressed: _isProcessing ? null : _runOcrRecognition,
          ),
          // Edit or Save Toggle
          IconButton(
            icon: Icon(_isEditing ? LucideIcons.check : LucideIcons.edit2, size: 20, color: AppTheme.accentEmerald),
            tooltip: _isEditing ? 'Simpan' : 'Edit Teks',
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar in OCR
            if (_isSearchOpen)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  borderRadius: 14,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Cari kata dalam teks OCR...',
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                      border: InputBorder.none,
                      icon: const Icon(LucideIcons.search, color: AppTheme.accentCyan, size: 18),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
              ),

            // Main Text Area
            Expanded(
              child: _isProcessing
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppTheme.accentCyan),
                          SizedBox(height: 16),
                          Text(
                            'Membaca teks dari dokumen...',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(18),
                        borderRadius: 20,
                        child: _isEditing
                            ? TextField(
                                controller: _textController,
                                maxLines: null,
                                expands: true,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.6,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Teks OCR...',
                                ),
                              )
                            : SingleChildScrollView(
                                child: SelectableText(
                                  _textController.text.isEmpty
                                      ? 'Belum ada teks yang diekstrak. Tekan tombol Scan Ulang untuk membaca dokumen.'
                                      : _textController.text,
                                  style: GoogleFonts.inter(
                                    color: _textController.text.isEmpty
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFFE2E8F0),
                                    fontSize: 15,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                      ),
                    ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard.withValues(alpha: 0.8),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _copyToClipboard,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.accentCyan.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.1),
                        ),
                        icon: const Icon(LucideIcons.copy, color: AppTheme.accentCyan, size: 18),
                        label: Text(
                          'Salin Teks',
                          style: GoogleFonts.outfit(
                            color: AppTheme.accentCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _shareText,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentEmerald,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(LucideIcons.share2, color: Colors.white, size: 18),
                        label: Text(
                          'Bagikan',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
