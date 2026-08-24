import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

enum PaperSizeOption {
  a4('A4 (Standar)', PdfPageFormat.a4),
  letter('Letter', PdfPageFormat.letter),
  legal('Legal / F4', PdfPageFormat.legal),
  fit('Auto Fit Halaman', null);

  final String label;
  final PdfPageFormat? format;
  const PaperSizeOption(this.label, this.format);
}

class PdfService {
  /// Membuat file PDF dari kumpulan gambar scan
  static Future<String?> generatePdf({
    required List<String> imagePaths,
    required String title,
    PaperSizeOption paperSize = PaperSizeOption.a4,
  }) async {
    if (imagePaths.isEmpty) return null;

    try {
      final pdf = pw.Document(
        title: title,
        author: 'MaoneArt Scanner',
        creator: 'MaoneArt CamScanner Engine',
      );

      for (final imagePath in imagePaths) {
        final file = File(imagePath);
        if (!await file.exists()) continue;

        final Uint8List imageBytes = await file.readAsBytes();
        final pw.MemoryImage imageProvider = pw.MemoryImage(imageBytes);

        if (paperSize == PaperSizeOption.fit) {
          // Buat halaman sesuai aspect ratio gambar
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
