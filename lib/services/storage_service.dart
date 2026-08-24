import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/scanned_document.dart';

class StorageService {
  static const String _storageKey = 'maoneart_scanned_documents';
  static const Uuid _uuid = Uuid();

  /// Mendapatkan direktori penyimpanan lokal aplikasi untuk dokumen
  static Future<Directory> getDocumentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final docsDir = Directory(path.join(appDir.path, 'scanned_docs'));
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir;
  }

  /// Menyimpan file gambar hasil scan ke direktori permanen aplikasi
  static Future<List<String>> persistScannedImages(List<String> tempPaths) async {
    final docsDir = await getDocumentsDirectory();
    final List<String> permanentPaths = [];

    for (final tempPath in tempPaths) {
      final file = File(tempPath);
      if (await file.exists()) {
        final extension = path.extension(tempPath).isNotEmpty ? path.extension(tempPath) : '.jpg';
        final uniqueName = 'page_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}$extension';
        final targetPath = path.join(docsDir.path, uniqueName);
        
        final savedFile = await file.copy(targetPath);
        permanentPaths.add(savedFile.path);
      }
    }
    return permanentPaths;
  }

  /// Memuat semua dokumen yang tersimpan
  static Future<List<ScannedDocument>> loadDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final List<ScannedDocument> docs = [];

      for (final item in jsonList) {
        try {
          final doc = ScannedDocument.fromMap(item as Map<String, dynamic>);
          docs.add(doc);
        } catch (_) {
          // Lewati jika data rusak
        }
      }

      // Urutkan dari yang terbaru
      docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return docs;
    } catch (e) {
      return [];
    }
  }

  /// Menyimpan seluruh list dokumen ke SharedPreferences
  static Future<void> saveDocuments(List<ScannedDocument> docs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = docs.map((doc) => doc.toMap()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }

  /// Menghapus file gambar dokumen dari disk
  static Future<void> deleteDocumentFiles(ScannedDocument doc) async {
    for (final pagePath in doc.pagePaths) {
      try {
        final file = File(pagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    if (doc.pdfPath != null) {
      try {
        final pdfFile = File(doc.pdfPath!);
        if (await pdfFile.exists()) {
          await pdfFile.delete();
        }
      } catch (_) {}
    }
  }

  /// Menghapus single page image
  static Future<void> deletePageFile(String pagePath) async {
    try {
      final file = File(pagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
