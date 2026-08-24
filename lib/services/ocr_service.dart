import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String fullText;
  final List<String> pageTexts;
  final bool isSuccess;
  final String? errorMessage;

  OcrResult({
    required this.fullText,
    required this.pageTexts,
    required this.isSuccess,
    this.errorMessage,
  });

  factory OcrResult.success(String fullText, List<String> pageTexts) {
    return OcrResult(
      fullText: fullText,
      pageTexts: pageTexts,
      isSuccess: true,
    );
  }

  factory OcrResult.failed(String error) {
    return OcrResult(
      fullText: '',
      pageTexts: [],
      isSuccess: false,
      errorMessage: error,
    );
  }
}

class OcrService {
  /// Ekstraksi teks (OCR) dari satu gambar
  static Future<String> extractTextFromImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return '';

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      return '';
    } finally {
      await textRecognizer.close();
    }
  }

  /// Ekstraksi teks (OCR) dari seluruh halaman dokumen
  static Future<OcrResult> extractTextFromDocument(List<String> pagePaths) async {
    if (pagePaths.isEmpty) {
      return OcrResult.failed('Tidak ada halaman gambar untuk di-scan');
    }

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final List<String> pageTexts = [];
    final StringBuffer fullTextBuffer = StringBuffer();

    try {
      for (int i = 0; i < pagePaths.length; i++) {
        final path = pagePaths[i];
        final file = File(path);
        if (await file.exists()) {
          final inputImage = InputImage.fromFilePath(path);
          final RecognizedText recognized = await textRecognizer.processImage(inputImage);
          final text = recognized.text.trim();
          pageTexts.add(text);

          if (text.isNotEmpty) {
            if (pagePaths.length > 1) {
              fullTextBuffer.writeln('--- [ Halaman ${i + 1} ] ---');
            }
            fullTextBuffer.writeln(text);
            fullTextBuffer.writeln();
          }
        } else {
          pageTexts.add('');
        }
      }

      final combined = fullTextBuffer.toString().trim();
      return OcrResult.success(
        combined.isNotEmpty ? combined : 'Tidak ditemukan teks yang dapat dibaca pada dokumen ini.',
        pageTexts,
      );
    } catch (e) {
      return OcrResult.failed('Gagal membaca OCR: ${e.toString()}');
    } finally {
      await textRecognizer.close();
    }
  }
}
