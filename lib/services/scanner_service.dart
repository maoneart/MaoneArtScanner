import 'dart:io';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'storage_service.dart';

class ScannerResult {
  final List<String> imagePaths;
  final String? pdfPath;
  final bool isSuccess;
  final String? errorMessage;

  ScannerResult({
    required this.imagePaths,
    this.pdfPath,
    required this.isSuccess,
    this.errorMessage,
  });

  factory ScannerResult.success(List<String> paths, {String? pdf}) {
    return ScannerResult(
      imagePaths: paths,
      pdfPath: pdf,
      isSuccess: true,
    );
  }

  factory ScannerResult.failed(String message) {
    return ScannerResult(
      imagePaths: [],
      isSuccess: false,
      errorMessage: message,
    );
  }

  factory ScannerResult.canceled() {
    return ScannerResult(
      imagePaths: [],
      isSuccess: false,
    );
  }
}

class ScannerService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Menjalankan CamScanner AI Document Scanner (ML Kit)
  /// Mendukung deteksi sudut kertas otomatis, auto-crop, perspektif, dan filter
  static Future<ScannerResult> startDocumentScan({int pageLimit = 50}) async {
    try {
      final options = DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full, // CamScanner-like interactive editing & multi-page
        isGalleryImport: true,
        pageLimit: pageLimit,
      );

      final documentScanner = DocumentScanner(options: options);
      final DocumentScanningResult result = await documentScanner.scanDocument();

      if (result.images == null || result.images!.isEmpty) {
        return ScannerResult.canceled();
      }

      // Simpan gambar secara permanen ke direktori aplikasi
      final permanentPaths = await StorageService.persistScannedImages(result.images!);
      return ScannerResult.success(permanentPaths, pdf: result.pdf?.pageCount != null ? result.pdf?.pageCount.toString() : null);
    } catch (e) {
      // Jika ML Kit gagal (misalnya di emulator/device tanpa Google Play Services),
      // otomatis fallback ke Image Picker kamera
      return await pickFromCamera();
    }
  }

  /// Mengambil foto dokumen dari Kamera biasa (Fallback)
  static Future<ScannerResult> pickFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (photo == null) return ScannerResult.canceled();

      final permanentPaths = await StorageService.persistScannedImages([photo.path]);
      return ScannerResult.success(permanentPaths);
    } catch (e) {
      return ScannerResult.failed('Gagal membuka kamera: ${e.toString()}');
    }
  }

  /// Mengimpor dokumen dari Galeri foto (Multi-image picker)
  static Future<ScannerResult> pickFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 100,
      );

      if (images.isEmpty) return ScannerResult.canceled();

      final tempPaths = images.map((x) => x.path).toList();
      final permanentPaths = await StorageService.persistScannedImages(tempPaths);
      return ScannerResult.success(permanentPaths);
    } catch (e) {
      return ScannerResult.failed('Gagal mengambil gambar dari galeri: ${e.toString()}');
    }
  }

  /// Menambah halaman baru ke dokumen yang sudah ada
  static Future<List<String>> addNewPages({required bool fromCamera}) async {
    if (fromCamera) {
      final result = await startDocumentScan(pageLimit: 20);
      if (result.isSuccess && result.imagePaths.isNotEmpty) {
        return result.imagePaths;
      }
      return [];
    } else {
      final result = await pickFromGallery();
      if (result.isSuccess && result.imagePaths.isNotEmpty) {
        return result.imagePaths;
      }
      return [];
    }
  }
}
