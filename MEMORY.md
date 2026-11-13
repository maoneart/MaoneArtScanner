# Project Memory — MaoneArt Scanner

> **Repository**: [maoneart/scanner](https://github.com/maoneart/scanner)  
> **Framework**: Flutter 3.24+ / Dart 3.x / Riverpod / Android Studio  
> **Package Name**: `com.maoneart.scanner`  
> **Application Version**: v1.2.0 (Build 13)

---

## 📌 Architecture & Technical Decisions
1. **Precision Document Cropper & Straightener (`crop_editor_screen.dart`)**:
   - Memperbaiki isu hasil pemotongan miring/kurang presisi pada scanner sebelumnya.
   - Menggunakan package murni Dart `image: ^4.2.0` (`bakeOrientation`, `copyRotate`, `copyCrop`).
   - Menyediakan interaksi 8 titik handle sentuh (4 sudut + 4 sisi), grid garis bantu *Rule of Thirds*, kuadran rotasi 90°, slider pelurus sudut halus (-30.0° s/d +30.0°), serta preset rasio aspect ratio (A4, KTP/ID, Persegi 1:1, 4:3, 16:9, Bebas).
   - Invalidation image cache instan via `PaintingBinding.instance.imageCache.clear()` agar perubahan langsung terlihat tanpa reload aplikasi.
2. **Integrated Full PDF Tools Suite (`pdf_tools_service.dart` & `pdf_tools_screen.dart`)**:
   - **Baca PDF**: Menampilkan dokumen PDF internal maupun file eksternal dari memori HP dengan `printing: ^5.13.2` (`PdfPreview`).
   - **Kompres PDF**: Mengompresi stream data dan aset dokumen via `syncfusion_flutter_pdf: ^28.2.9` dengan 3 tingkatan (Ringan, Standar, Maksimal).
   - **Pisah PDF (Split)**: Pemisahan halaman dokumen fleksibel (Pilih Semua, Ganjil, Genap, atau seleksi custom).
   - **Gabung PDF (Merge)**: Penggabungan multi-file PDF menjadi satu file utuh dengan urutan reorderable drag-and-drop.
   - Pemilihan file menggunakan `file_picker: ^8.1.4`.
3. **Shadcn UI Design System (Zinc Theme)**:
   - Menghapus total seluruh efek glassmorphic blur berat yang boros baterai dan bergradasi neon.
   - Mengadopsi palet **Zinc Dark** (`#09090B`, `#121215`, `#18181B`, `#27272A`), tipografi *Plus Jakarta Sans* & *JetBrains Mono*, border 1px solid presisi, dock bar navigasi jempol, dan modal simetris 2-kolom (Rule #5).
4. **Auto-Build CI/CD**:
   - GitHub Actions workflow `.github/workflows/build_apk.yml` otomatis membangun universal release APK dan menguploadnya ke GitHub Releases `v1.2.0`.

---

## 🚀 Recent Milestones
- **Milestone 2026-11-13 (v1.2.0)**:
  1. **Perbaikan Fitur Crop & Pelurus Dokumen**:
     - Membangun `CropEditorScreen` interaktif dengan 8 touch handles dan fine degree slider angle (-30° s/d +30°) untuk meluruskan dokumen miring.
     - Menyematkan tombol cepat "Luruskan" di metadata bar atas dan bottom action bar pada `DocumentDetailScreen`.
     - Memperbaiki bug `PaperSizeOption.fit` pada `PdfService` agar tidak lagi hardcoded ke A4 portrait melainkan presisi mengikuti dimensi gambar hasil crop.
  2. **Peluncuran Full PDF Tools Suite**:
     - Membangun `PdfToolsService` dan `PdfToolsScreen` dengan 4 fitur lengkap: Baca PDF, Kompres PDF, Pisah PDF, dan Gabung PDF.
     - Menambahkan tombol akses PDF Suite di Top App Bar dan Floating Action Bar pada `HomeScreen`.
  3. **Rombak Desain Total ke SHADCN UI (Zinc Dark)**:
     - Mengubah `AppTheme`, `GlassContainer` (menjadi solid 1px border card), `CategoryFilterBar`, `DocumentCard`, `ScannerFab`, `MaoneArtModal`, `OcrScreen`, dan `PdfPreviewScreen` menjadi desain minimalis profesional berkelas tinggi.
