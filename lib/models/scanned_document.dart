import 'dart:convert';

class ScannedDocument {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String category;
  final List<String> pagePaths;
  final String ocrText;
  final String? pdfPath;
  final String notes;

  ScannedDocument({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.category = 'Dokumen',
    required this.pagePaths,
    this.ocrText = '',
    this.pdfPath,
    this.notes = '',
  });

  int get pageCount => pagePaths.length;
  String get thumbnailPath => pagePaths.isNotEmpty ? pagePaths.first : '';
  bool get hasOcr => ocrText.trim().isNotEmpty;
  int get wordCount => ocrText.trim().isEmpty 
      ? 0 
      : ocrText.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;

  ScannedDocument copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    List<String>? pagePaths,
    String? ocrText,
    String? pdfPath,
    String? notes,
  }) {
    return ScannedDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      pagePaths: pagePaths ?? this.pagePaths,
      ocrText: ocrText ?? this.ocrText,
      pdfPath: pdfPath ?? this.pdfPath,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'category': category,
      'pagePaths': pagePaths,
      'ocrText': ocrText,
      'pdfPath': pdfPath,
      'notes': notes,
    };
  }

  factory ScannedDocument.fromMap(Map<String, dynamic> map) {
    return ScannedDocument(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Dokumen Tanpa Judul',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      category: map['category'] ?? 'Dokumen',
      pagePaths: List<String>.from(map['pagePaths'] ?? []),
      ocrText: map['ocrText'] ?? '',
      pdfPath: map['pdfPath'],
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ScannedDocument.fromJson(String source) => 
      ScannedDocument.fromMap(json.decode(source));
}
