import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/scanned_document.dart';
import '../services/storage_service.dart';
import '../services/ocr_service.dart';
import '../services/pdf_service.dart';

class DocumentListState {
  final List<ScannedDocument> documents;
  final bool isLoading;
  final String searchQuery;
  final String selectedCategory;
  final bool isGridView;
  final String? errorMessage;

  const DocumentListState({
    this.documents = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.selectedCategory = 'Semua',
    this.isGridView = true,
    this.errorMessage,
  });

  DocumentListState copyWith({
    List<ScannedDocument>? documents,
    bool? isLoading,
    String? searchQuery,
    String? selectedCategory,
    bool? isGridView,
    String? errorMessage,
  }) {
    return DocumentListState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isGridView: isGridView ?? this.isGridView,
      errorMessage: errorMessage,
    );
  }

  /// Mendapatkan list dokumen yang telah difilter pencarian & kategori
  List<ScannedDocument> get filteredDocuments {
    return documents.where((doc) {
      // Filter kategori
      final matchCategory = selectedCategory == 'Semua' || 
          doc.category.toLowerCase() == selectedCategory.toLowerCase();

      // Filter query pencarian (judul, OCR text, atau catatan)
      if (!matchCategory) return false;
      if (searchQuery.trim().isEmpty) return true;

      final q = searchQuery.toLowerCase();
      final inTitle = doc.title.toLowerCase().contains(q);
      final inOcr = doc.ocrText.toLowerCase().contains(q);
      final inNotes = doc.notes.toLowerCase().contains(q);
      final inCategory = doc.category.toLowerCase().contains(q);

      return inTitle || inOcr || inNotes || inCategory;
    }).toList();
  }

  int get totalPages => documents.fold(0, (sum, doc) => sum + doc.pageCount);
}

class DocumentNotifier extends StateNotifier<DocumentListState> {
  static const Uuid _uuid = Uuid();

  DocumentNotifier() : super(const DocumentListState()) {
    loadDocuments();
  }

  /// Memuat semua dokumen dari penyimpanan lokal
  Future<void> loadDocuments() async {
    state = state.copyWith(isLoading: true);
    try {
      final docs = await StorageService.loadDocuments();
      state = state.copyWith(documents: docs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Membuat dokumen baru dari hasil scan
  Future<ScannedDocument?> createDocument({
    required List<String> pagePaths,
    String? customTitle,
    String category = 'Dokumen',
    bool autoRunOcr = false,
  }) async {
    if (pagePaths.isEmpty) return null;

    state = state.copyWith(isLoading: true);
    try {
      final now = DateTime.now();
      final title = customTitle?.trim().isNotEmpty == true
          ? customTitle!.trim()
          : 'Dokumen_${now.day}${now.month}${now.year}_${now.hour}${now.minute}${now.second}';

      String ocrText = '';
      if (autoRunOcr) {
        final ocrResult = await OcrService.extractTextFromDocument(pagePaths);
        if (ocrResult.isSuccess) {
          ocrText = ocrResult.fullText;
        }
      }

      final newDoc = ScannedDocument(
        id: _uuid.v4(),
        title: title,
        createdAt: now,
        updatedAt: now,
        category: category,
        pagePaths: pagePaths,
        ocrText: ocrText,
      );

      final updatedList = [newDoc, ...state.documents];
      await StorageService.saveDocuments(updatedList);

      state = state.copyWith(documents: updatedList, isLoading: false);
      return newDoc;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Menambah halaman baru ke dokumen
  Future<void> addPages(String docId, List<String> newPaths) async {
    if (newPaths.isEmpty) return;

    final index = state.documents.indexWhere((d) => d.id == docId);
    if (index == -1) return;

    final oldDoc = state.documents[index];
    final updatedPages = [...oldDoc.pagePaths, ...newPaths];
    final updatedDoc = oldDoc.copyWith(
      pagePaths: updatedPages,
      updatedAt: DateTime.now(),
      pdfPath: null, // Reset PDF cached path karena ada halaman baru
    );

    final updatedList = List<ScannedDocument>.from(state.documents);
    updatedList[index] = updatedDoc;
    await StorageService.saveDocuments(updatedList);

    state = state.copyWith(documents: updatedList);
  }

  /// Menghapus satu halaman dari dokumen
  Future<void> deletePage(String docId, int pageIndex) async {
    final index = state.documents.indexWhere((d) => d.id == docId);
    if (index == -1) return;

    final oldDoc = state.documents[index];
    if (pageIndex < 0 || pageIndex >= oldDoc.pagePaths.length) return;

    final pageToDelete = oldDoc.pagePaths[pageIndex];
    await StorageService.deletePageFile(pageToDelete);

    final updatedPages = List<String>.from(oldDoc.pagePaths)..removeAt(pageIndex);

    if (updatedPages.isEmpty) {
      // Jika semua halaman dihapus, hapus dokumen
      await deleteDocument(docId);
    } else {
      final updatedDoc = oldDoc.copyWith(
        pagePaths: updatedPages,
        updatedAt: DateTime.now(),
        pdfPath: null,
      );

      final updatedList = List<ScannedDocument>.from(state.documents);
      updatedList[index] = updatedDoc;
      await StorageService.saveDocuments(updatedList);

      state = state.copyWith(documents: updatedList);
    }
  }

  /// Mengubah urutan halaman
  Future<void> reorderPages(String docId, int oldIndex, int newIndex) async {
    final index = state.documents.indexWhere((d) => d.id == docId);
    if (index == -1) return;

    final oldDoc = state.documents[index];
    final pages = List<String>.from(oldDoc.pagePaths);
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = pages.removeAt(oldIndex);
    pages.insert(newIndex, item);

    final updatedDoc = oldDoc.copyWith(
      pagePaths: pages,
      updatedAt: DateTime.now(),
      pdfPath: null,
    );

    final updatedList = List<ScannedDocument>.from(state.documents);
    updatedList[index] = updatedDoc;
    await StorageService.saveDocuments(updatedList);

    state = state.copyWith(documents: updatedList);
  }

  /// Mengubah judul dokumen
  Future<void> renameDocument(String docId, String newTitle) async {
    final index = state.documents.indexWhere((d) => d.id == docId);
    if (index == -1) return;

    final updatedDoc = state.documents[index].copyWith(
      title: newTitle.trim(),
      updatedAt: DateTime.now(),
    );

    final updatedList = List<ScannedDocument>.from(state.documents);
    updatedList[index] = updatedDoc;
    await StorageService.saveDocuments(updatedList);

    state = state.copyWith(documents: updatedList);
  }

  /// Mengubah kategori dokumen
  Future<void> updateCategory(String docId, String category) async {
    final index = state.documents.indexWhere((d) => d.id == docId);
    if (index == -1) return;

    final updatedDoc = state.documents[index].copyWith(
      category: category,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<ScannedDocument>.from(state.documents);
    updatedList[index] = updatedDoc;
    await StorageService.saveDocuments(updatedList);

    state = state.copyWith(documents: updatedList);
  }

  /// Mengubah catatan dokumen
  Future<void> updateNotes(String docId, String notes) async {
    final index = state.documents.indexWhere((d) => d.id == docId);
    if (index == -1) return;

    final updatedDoc = state.documents[index].copyWith(
      notes: notes,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<ScannedDocument>.from(state.documents);
    updatedList[index] = updatedDoc;
    await StorageService.saveDocuments(updatedList);

    state = state.copyWith(documents: updatedList);
  }

  /// Menjalankan dan memperbarui OCR Text pada dokumen
  Future<String> runOcrForDocument(String docId) async {
    final index = state.documents.indexWhere((d) => d.id == docId);
    if (index == -1) return '';

    final doc = state.documents[index];
    final result = await OcrService.extractTextFromDocument(doc.pagePaths);

    if (result.isSuccess) {
      final updatedDoc = doc.copyWith(
        ocrText: result.fullText,
        updatedAt: DateTime.now(),
      );

      final updatedList = List<ScannedDocument>.from(state.documents);
      updatedList[index] = updatedDoc;
      await StorageService.saveDocuments(updatedList);

      state = state.copyWith(documents: updatedList);
      return result.fullText;
    }
    return '';
  }

  /// Memperbarui hasil edit teks OCR
  Future<void> saveOcrText(String docId, String text) async {
    final index = state.documents.indexWhere((d) => d.id == docId);
    if (index == -1) return;

    final updatedDoc = state.documents[index].copyWith(
      ocrText: text,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<ScannedDocument>.from(state.documents);
    updatedList[index] = updatedDoc;
    await StorageService.saveDocuments(updatedList);

    state = state.copyWith(documents: updatedList);
  }

  /// Generate & simpan path PDF untuk dokumen
  Future<String?> generateAndSavePdf(
    String docId, {
    PaperSizeOption paperSize = PaperSizeOption.a4,
    PdfExportMode mode = PdfExportMode.searchable,
  }) async {
    final index = state.documents.indexWhere((d) => d.id == docId);
    if (index == -1) return null;

    final doc = state.documents[index];
    final pdfPath = await PdfService.generatePdf(
      imagePaths: doc.pagePaths,
      title: doc.title,
      paperSize: paperSize,
      mode: mode,
      customOcrText: doc.ocrText,
    );

    if (pdfPath != null) {
      final updatedDoc = doc.copyWith(
        pdfPath: pdfPath,
        updatedAt: DateTime.now(),
      );

      final updatedList = List<ScannedDocument>.from(state.documents);
      updatedList[index] = updatedDoc;
      await StorageService.saveDocuments(updatedList);

      state = state.copyWith(documents: updatedList);
    }
    return pdfPath;
  }

  /// Menghapus dokumen
  Future<void> deleteDocument(String docId) async {
    final index = state.documents.indexWhere((d) => d.id == docId);
    if (index == -1) return;

    final doc = state.documents[index];
    await StorageService.deleteDocumentFiles(doc);

    final updatedList = List<ScannedDocument>.from(state.documents)..removeAt(index);
    await StorageService.saveDocuments(updatedList);

    state = state.copyWith(documents: updatedList);
  }

  /// Set query pencarian
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Set kategori terpilih
  void setSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Toggle grid / list view
  void toggleViewMode() {
    state = state.copyWith(isGridView: !state.isGridView);
  }
}

final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentListState>((ref) {
  return DocumentNotifier();
});

/// Kategori bawaan CamScanner
const List<String> kDocumentCategories = [
  'Semua',
  'Dokumen',
  'Pajak & STNK',
  'Struk/Nota',
  'KTP/ID',
  'Sertifikat',
  'Catatan',
  'Surat',
  'Lainnya',
];
