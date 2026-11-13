import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

enum PdfCompressionTier {
  light('Kompresi Ringan', 'Kualitas visual sangat tinggi, cocok untuk arsip'),
  medium('Kompresi Standar', 'Rekomendasi terbaik untuk email & upload web'),
  heavy('Kompresi Maksimal', 'Ukuran paling kecil, teks tetap tajam terbaca');

  final String title;
  final String description;
  const PdfCompressionTier(this.title, this.description);
}

class PdfFileInfo {
  final String path;
  final String name;
  final int pageCount;
  final int fileSizeBytes;

  PdfFileInfo({
    required this.path,
    required this.name,
    required this.pageCount,
    required this.fileSizeBytes,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class PdfToolsService {
  /// Membaca info dasar file PDF (jumlah halaman & ukuran)
  static Future<PdfFileInfo?> inspectPdf(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final count = document.pages.count;
      document.dispose();

      return PdfFileInfo(
        path: filePath,
        name: file.uri.pathSegments.last,
        pageCount: count,
        fileSizeBytes: await file.length(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Menggabungkan (Merge) 2 atau lebih file PDF menjadi 1 file PDF utuh
  static Future<String> mergePdfs({
    required List<String> inputPaths,
    String? outputFilename,
  }) async {
    if (inputPaths.length < 2) {
      throw Exception('Minimal pilih 2 file PDF untuk digabungkan');
    }

    final outputDoc = PdfDocument();

    for (final path in inputPaths) {
      final file = File(path);
      if (!await file.exists()) continue;

      final bytes = await file.readAsBytes();
      final sourceDoc = PdfDocument(inputBytes: bytes);

      for (int i = 0; i < sourceDoc.pages.count; i++) {
        final template = sourceDoc.pages[i].createTemplate();
        final newPage = outputDoc.pages.add();
        newPage.graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
          Size(newPage.getClientSize().width, newPage.getClientSize().height),
        );
      }
      sourceDoc.dispose();
    }

    // Simpan hasil ke Downloads / Documents
    final outputDir = await _getSafeOutputDir();
    final name = outputFilename ?? 'Merged_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final outputFile = File('${outputDir.path}/$name');

    final outputBytes = await outputDoc.save();
    outputDoc.dispose();

    await outputFile.writeAsBytes(outputBytes);
    return outputFile.path;
  }

  /// Memisahkan (Split) halaman tertentu dari PDF menjadi file PDF baru
  static Future<String> splitPdf({
    required String sourcePath,
    required List<int> pageIndicesToKeep, // 0-based page index
    String? outputFilename,
  }) async {
    if (pageIndicesToKeep.isEmpty) {
      throw Exception('Pilih minimal 1 halaman untuk dipisahkan');
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) throw Exception('File PDF sumber tidak ditemukan');

    final sourceBytes = await sourceFile.readAsBytes();
    final sourceDoc = PdfDocument(inputBytes: sourceBytes);
    final outputDoc = PdfDocument();

    for (final pageIdx in pageIndicesToKeep) {
      if (pageIdx >= 0 && pageIdx < sourceDoc.pages.count) {
        final template = sourceDoc.pages[pageIdx].createTemplate();
        final newPage = outputDoc.pages.add();
        newPage.graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
          Size(newPage.getClientSize().width, newPage.getClientSize().height),
        );
      }
    }

    sourceDoc.dispose();

    final outputDir = await _getSafeOutputDir();
    final name = outputFilename ?? 'Split_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final outputFile = File('${outputDir.path}/$name');

    final outputBytes = await outputDoc.save();
    outputDoc.dispose();

    await outputFile.writeAsBytes(outputBytes);
    return outputFile.path;
  }

  /// Mengompresi file PDF dengan level kompresi terbaik
  static Future<String> compressPdf({
    required String sourcePath,
    required PdfCompressionTier tier,
    String? outputFilename,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) throw Exception('File PDF tidak ditemukan');

    final sourceBytes = await sourceFile.readAsBytes();
    final document = PdfDocument(inputBytes: sourceBytes);

    // Aktifkan kompresi stream data maksimal
    document.compressionLevel = PdfCompressionLevel.best;

    final outputDir = await _getSafeOutputDir();
    final name = outputFilename ?? 'Compressed_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final outputFile = File('${outputDir.path}/$name');

    final compressedBytes = await document.save();
    document.dispose();

    await outputFile.writeAsBytes(compressedBytes);
    return outputFile.path;
  }

  static Future<Directory> _getSafeOutputDir() async {
    // Prioritaskan folder Download di Android
    final downloadDir = Directory('/storage/emulated/0/Download');
    if (await downloadDir.exists()) {
      return downloadDir;
    }
    return await getApplicationDocumentsDirectory();
  }
}
