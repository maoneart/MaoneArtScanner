import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'ocr_service.dart';

enum PaperSizeOption {
  a4('A4 (Standar)', PdfPageFormat.a4),
  letter('Letter', PdfPageFormat.letter),
  legal('Legal / F4', PdfPageFormat.legal),
  fit('Auto Fit Halaman', null);

  final String label;
  final PdfPageFormat? format;
  const PaperSizeOption(this.label, this.format);
}

enum PdfExportMode {
  searchable('Scan + Teks OCR (Bisa Copy & Search)', 'Gambar scan asli dengan teks yang bisa di-select, copy, dan dicari'),
  cleanText('Dokumen Teks Bersih (Word Style)', 'Konversi seluruh teks OCR menjadi format dokumen digital rapi'),
  imageOnly('Gambar Scan Murni', 'Hanya gambar hasil scan tanpa lapisan teks OCR');

  final String label;
  final String description;
  const PdfExportMode(this.label, this.description);
}

class PdfService {
  /// Membuat file PDF (Mendukung Searchable OCR Layer, Clean Word Style, dan Image Only)
  static Future<String?> generatePdf({
    required List<String> imagePaths,
    required String title,
    PaperSizeOption paperSize = PaperSizeOption.a4,
    PdfExportMode mode = PdfExportMode.searchable,
    String? customOcrText,
  }) async {
    if (imagePaths.isEmpty) return null;

    try {
      final pdf = pw.Document(
        title: title,
        author: 'MaoneArt Scanner',
        creator: 'MaoneArt AI Document Engine',
        subject: 'Searchable AI OCR Document',
      );

      if (mode == PdfExportMode.cleanText) {
        // MODE 1: DOKUMEN TEKS BERSIH (WORD STYLE)
        await _buildCleanTextDocument(
          pdf: pdf,
          title: title,
          imagePaths: imagePaths,
          paperSize: paperSize,
          customOcrText: customOcrText,
        );
      } else if (mode == PdfExportMode.searchable) {
        // MODE 2: SEARCHABLE PDF (GAMBAR SCAN + LAPISAN TEKS OCR SELECTABLE & SEARCHABLE)
        await _buildSearchablePdf(
          pdf: pdf,
          imagePaths: imagePaths,
          paperSize: paperSize,
        );
      } else {
        // MODE 3: GAMBAR SCAN MURNI (STANDAR)
        await _buildImageOnlyPdf(
          pdf: pdf,
          imagePaths: imagePaths,
          paperSize: paperSize,
        );
      }

      final outputDir = await getApplicationDocumentsDirectory();
      final sanitizedTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = '${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outputFile = File(p.join(outputDir.path, fileName));

      final Uint8List pdfBytes = await pdf.save();
      await outputFile.writeAsBytes(pdfBytes);

      return outputFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Membuat Searchable PDF: Foto scan tajam dengan lapisan teks OCR transparan persis di atas kata/kalimat
  static Future<void> _buildSearchablePdf({
    required pw.Document pdf,
    required List<String> imagePaths,
    required PaperSizeOption paperSize,
  }) async {
    for (final imagePath in imagePaths) {
      final file = File(imagePath);
      if (!await file.exists()) continue;

      final Uint8List imageBytes = await file.readAsBytes();
      final pw.MemoryImage imageProvider = pw.MemoryImage(imageBytes);

      // Ekstraksi data posisi OCR (boundingBox) dari halaman
      final OcrPageData? ocrData = await OcrService.extractPageData(imagePath);

      if (ocrData == null || ocrData.imageWidth <= 0 || ocrData.imageHeight <= 0) {
        // Fallback jika tidak ada data OCR atau gambar gagal dibaca
        final pageFormat = paperSize.format ?? PdfPageFormat.a4;
        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: const pw.EdgeInsets.all(12),
            build: (context) => pw.Center(child: pw.Image(imageProvider, fit: pw.BoxFit.contain)),
          ),
        );
        continue;
      }

      final double imgW = ocrData.imageWidth;
      final double imgH = ocrData.imageHeight;

      if (paperSize == PaperSizeOption.fit) {
        // Format halaman otomatis mengikuti dimensi gambar
        final pageFormat = PdfPageFormat(imgW, imgH, marginAll: 0);

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  // Layer 1: Gambar Scan Asli
                  pw.Positioned(
                    left: 0,
                    top: 0,
                    child: pw.SizedBox(
                      width: imgW,
                      height: imgH,
                      child: pw.Image(imageProvider, fit: pw.BoxFit.fill),
                    ),
                  ),
                  // Layer 2: Lapisan Teks OCR Selectable & Searchable
                  ...ocrData.lines.map((line) {
                    final double fontSize = (line.height * 0.82).clamp(5.0, 72.0);
                    return pw.Positioned(
                      left: line.left,
                      top: line.top,
                      child: pw.SizedBox(
                        width: line.width,
                        height: line.height,
                        child: pw.Opacity(
                          opacity: 0.0, // Lapisan teks tak kasat mata di atas gambar
                          child: pw.Text(
                            line.text,
                            style: pw.TextStyle(
                              fontSize: fontSize,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      } else {
        // Format kertas standar (A4, Letter, Legal)
        final PdfPageFormat format = paperSize.format ?? PdfPageFormat.a4;
        const double margin = 16.0;
        final double availW = format.width - (margin * 2);
        final double availH = format.height - (margin * 2);

        final double scale = math.min(availW / imgW, availH / imgH);
        final double renderW = imgW * scale;
        final double renderH = imgH * scale;
        final double offsetX = (availW - renderW) / 2;
        final double offsetY = (availH - renderH) / 2;

        pdf.addPage(
          pw.Page(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(margin),
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  // Layer 1: Gambar Scan
                  pw.Positioned(
                    left: offsetX,
                    top: offsetY,
                    child: pw.SizedBox(
                      width: renderW,
                      height: renderH,
                      child: pw.Image(imageProvider, fit: pw.BoxFit.fill),
                    ),
                  ),
                  // Layer 2: Lapisan Teks OCR Selectable & Searchable
                  ...ocrData.lines.map((line) {
                    final double textLeft = offsetX + (line.left * scale);
                    final double textTop = offsetY + (line.top * scale);
                    final double textWidth = line.width * scale;
                    final double textHeight = line.height * scale;
                    final double fontSize = (textHeight * 0.82).clamp(4.0, 60.0);

                    return pw.Positioned(
                      left: textLeft,
                      top: textTop,
                      child: pw.SizedBox(
                        width: textWidth,
                        height: textHeight,
                        child: pw.Opacity(
                          opacity: 0.0, // Teks transparan yang bisa di-select dan dicari di PDF
                          child: pw.Text(
                            line.text,
                            style: pw.TextStyle(
                              fontSize: fontSize,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      }
    }
  }

  /// Membuat Dokumen Teks Bersih (Word-to-PDF Style)
  static Future<void> _buildCleanTextDocument({
    required pw.Document pdf,
    required String title,
    required List<String> imagePaths,
    required PaperSizeOption paperSize,
    String? customOcrText,
  }) async {
    final pageFormat = paperSize.format ?? PdfPageFormat.a4;

    String documentText = customOcrText?.trim() ?? '';
    if (documentText.isEmpty) {
      final ocrResult = await OcrService.extractTextFromDocument(imagePaths);
      documentText = ocrResult.fullText;
    }

    if (documentText.isEmpty) {
      documentText = 'Tidak ada teks yang terdeteksi pada dokumen.';
    }

    final paragraphs = documentText.split('\n');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            margin: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                ),
                pw.Text(
                  'MaoneArt Scanner Doc',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 12),
            margin: const pw.EdgeInsets.only(top: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Dibuat dengan MaoneArt AI Scanner',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              text: title,
              textStyle: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
            ),
            pw.SizedBox(height: 12),
            ...paragraphs.map((p) {
              final trimmed = p.trim();
              if (trimmed.startsWith('--- [ Halaman') && trimmed.endsWith('] ---')) {
                return pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 12),
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    trimmed,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                  ),
                );
              }
              if (trimmed.isEmpty) {
                return pw.SizedBox(height: 8);
              }
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  trimmed,
                  style: const pw.TextStyle(
                    fontSize: 11,
                    lineSpacing: 3,
                    color: PdfColors.black,
                  ),
                ),
              );
            }),
          ];
        },
      ),
    );
  }

  /// Membuat PDF Gambar Saja (Tanpa layer teks)
  static Future<void> _buildImageOnlyPdf({
    required pw.Document pdf,
    required List<String> imagePaths,
    required PaperSizeOption paperSize,
  }) async {
    for (final imagePath in imagePaths) {
      final file = File(imagePath);
      if (!await file.exists()) continue;

      final Uint8List imageBytes = await file.readAsBytes();
      final pw.MemoryImage imageProvider = pw.MemoryImage(imageBytes);

      if (paperSize == PaperSizeOption.fit) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Center(
                  child: pw.Image(imageProvider, fit: pw.BoxFit.contain),
                ),
              );
            },
          ),
        );
      } else {
        final format = paperSize.format ?? PdfPageFormat.a4;
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(12),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(imageProvider, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }
    }
  }

  /// Membuka file PDF di aplikasi PDF reader eksternal
  static Future<void> openPdf(String pdfPath) async {
    try {
      await OpenFilex.open(pdfPath);
    } catch (_) {}
  }

  /// Membagikan file PDF ke aplikasi lain (WhatsApp, Email, Drive, dll)
  static Future<void> sharePdf(String pdfPath, {String? subject}) async {
    try {
      final file = XFile(pdfPath);
      await Share.shareXFiles([file], text: subject ?? 'Dokumen Scan MaoneArt Scanner');
    } catch (_) {}
  }

  /// Membagikan gambar scan langsung (JPG)
  static Future<void> shareImages(List<String> imagePaths, {String? text}) async {
    try {
      final files = imagePaths.map((p) => XFile(p)).toList();
      await Share.shareXFiles(files, text: text ?? 'Hasil Scan Dokumen');
    } catch (_) {}
  }

  /// Mencetak dokumen PDF secara langsung via Printer WiFi/Bluetooth/OS
  static Future<void> printDocument(String pdfPath, {required String title}) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: title,
        );
      }
    } catch (_) {}
  }
}
