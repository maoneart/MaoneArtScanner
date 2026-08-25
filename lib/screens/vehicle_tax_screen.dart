import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/vehicle_tax.dart';
import '../providers/document_provider.dart';
import '../services/scanner_service.dart';
import '../services/vehicle_tax_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/maoneart_modal.dart';

class VehicleTaxScreen extends ConsumerStatefulWidget {
  final String? initialPlate;

  const VehicleTaxScreen({super.key, this.initialPlate});

  @override
  ConsumerState<VehicleTaxScreen> createState() => _VehicleTaxScreenState();
}

class _VehicleTaxScreenState extends ConsumerState<VehicleTaxScreen> {
  final TextEditingController _prefixController = TextEditingController(text: 'B');
  final TextEditingController _numberController = TextEditingController(text: '1234');
  final TextEditingController _suffixController = TextEditingController(text: 'ABC');
  final TextEditingController _monthController = TextEditingController(text: '08');
  final TextEditingController _yearController = TextEditingController(text: '28');

  String _selectedVehicleType = 'Auto';
  String? _selectedModel;
  bool _isLoading = false;
  VehicleTaxInfo? _taxInfo;
  String? _scannedImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlate != null && widget.initialPlate!.isNotEmpty) {
      final parsed = VehicleTaxService.parsePlateFromText(widget.initialPlate!);
      if (parsed != null) {
        _prefixController.text = parsed.prefix;
        _numberController.text = parsed.number;
        _suffixController.text = parsed.suffix;
        if (parsed.monthYear != null && parsed.monthYear!.isNotEmpty) {
          final cleanMY = parsed.monthYear!.replaceAll(RegExp(r'[^0-9]'), '');
          if (cleanMY.length >= 4) {
            _monthController.text = cleanMY.substring(0, 2);
            _yearController.text = cleanMY.substring(2);
          }
        }
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTax();
    });
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _numberController.dispose();
    _suffixController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _scanPlateWithCamera() async {
    try {
      final result = await ScannerService.pickFromCamera();
      if (result.isSuccess && result.imagePaths.isNotEmpty) {
        final path = result.imagePaths.first;
        setState(() {
          _scannedImagePath = path;
          _isLoading = true;
        });

        final parsed = await VehicleTaxService.scanPlateFromImage(path);
        if (parsed != null) {
          _prefixController.text = parsed.prefix;
          _numberController.text = parsed.number;
          _suffixController.text = parsed.suffix;
          if (parsed.monthYear != null && parsed.monthYear!.isNotEmpty) {
            final cleanMY = parsed.monthYear!.replaceAll(RegExp(r'[^0-9]'), '');
            if (cleanMY.length >= 4) {
              _monthController.text = cleanMY.substring(0, 2);
              _yearController.text = cleanMY.substring(2);
            }
          }
          await _checkTax();
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            MaoneArtModal.showAlertModal(
              context,
              title: 'Plat Tidak Terbaca Jelas',
              message: 'Pastikan foto plat nomor kendaraan terlihat jelas, terang, dan tidak terpotong. Anda juga dapat mengetik plat dan bulan/tahun secara manual di atas.',
              icon: Icons.error_outline_rounded,
              iconColor: Colors.amber,
              buttonText: 'Coba Lagi',
            );
          }
        }
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scanPlateFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (image != null) {
        setState(() {
          _scannedImagePath = image.path;
          _isLoading = true;
        });

        final parsed = await VehicleTaxService.scanPlateFromImage(image.path);
        if (parsed != null) {
          _prefixController.text = parsed.prefix;
          _numberController.text = parsed.number;
          _suffixController.text = parsed.suffix;
          if (parsed.monthYear != null && parsed.monthYear!.isNotEmpty) {
            final cleanMY = parsed.monthYear!.replaceAll(RegExp(r'[^0-9]'), '');
            if (cleanMY.length >= 4) {
              _monthController.text = cleanMY.substring(0, 2);
              _yearController.text = cleanMY.substring(2);
            }
          }
          await _checkTax();
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            MaoneArtModal.showAlertModal(
              context,
              title: 'Plat Tidak Terdeteksi',
              message: 'Tidak ditemukan format plat nomor Indonesia pada gambar tersebut. Anda dapat memasukkan nomor plat dan masa berlaku STNK secara manual.',
              icon: Icons.search_off_rounded,
              iconColor: Colors.amber,
              buttonText: 'Mengerti',
            );
          }
        }
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkTax() async {
    final prefix = _prefixController.text.trim().toUpperCase();
    final number = _numberController.text.trim();
    final suffix = _suffixController.text.trim().toUpperCase();
    final month = _monthController.text.trim();
    final year = _yearController.text.trim();

    if (prefix.isEmpty || number.isEmpty) return;

    setState(() => _isLoading = true);

    final monthYearStr = (month.isNotEmpty && year.isNotEmpty) ? '$month.$year' : null;

    final plate = ParsedPlate(
      prefix: prefix,
      number: number,
      suffix: suffix,
      monthYear: monthYearStr,
    );

    final result = await VehicleTaxService.getVehicleTaxDetails(
      plate,
      vehicleTypeOverride: _selectedVehicleType == 'Auto' ? null : _selectedVehicleType,
      customModelName: _selectedModel,
    );

    if (mounted) {
      setState(() {
        _taxInfo = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _openOfficialPortal() async {
    if (_taxInfo == null) return;
    final Uri url = Uri.parse(_taxInfo!.officialPortalUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        Clipboard.setData(ClipboardData(text: _taxInfo!.officialPortalUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link portal e-Samsat disalin ke clipboard')),
        );
      }
    }
  }

  void _shareTaxDetails() {
    if (_taxInfo == null) return;
    final t = _taxInfo!;
    final text = '''
📄 INFORMASI PAJAK KENDARAAN BERMOTOR
━━━━━━━━━━━━━━━━━━━━
🚗 Plat Nomor   : ${t.plateNumber}
🏛️ Wilayah      : ${t.regionName} (${t.provinceName})
🏷️ Kendaraan    : ${t.brand} ${t.modelName} (${t.modelYear})
🎨 Warna / CC   : ${t.color} • ${t.cylinderCapacity} cc

📅 Status Pajak : ${t.isTaxActive ? 'AKTIF / BERLAKU' : 'TERLAMBAT / MATI'}
⏰ Jatuh Tempo  : ${t.formattedTaxDueDate}
📑 STNK 5 Tahun : ${t.formattedStnkDueDate}

💰 RINCIAN TAGIHAN:
• PKB Pokok     : ${t.formattedPkbPokok}
• SWDKLLJ       : ${t.formattedSwdkllj}
• Denda PKB     : ${t.formattedPkbDenda}
• Denda SWDKLLJ : ${t.formattedSwdklljDenda}
━━━━━━━━━━━━━━━━━━━━
💵 TOTAL BIAYA  : ${t.formattedTotalTax}

Diperiksa via MaoneArt Scanner & e-Samsat
''';
    Share.share(text, subject: 'Info Pajak ${t.plateNumber}');
  }

  Future<void> _saveAsDocumentNote() async {
    if (_taxInfo == null) return;
    final t = _taxInfo!;
    final title = 'Pajak Kendaraan ${t.plateNumber}';

    // Buat dokumen atau catatan
    if (_scannedImagePath != null) {
      final doc = await ref.read(documentProvider.notifier).createDocument(
        pagePaths: [_scannedImagePath!],
        category: 'Pajak & STNK',
      );
      if (doc != null) {
        await ref.read(documentProvider.notifier).renameDocument(doc.id, title);
        await ref.read(documentProvider.notifier).updateNotes(doc.id, 'PKB: ${t.formattedTotalTax} • Jatuh Tempo: ${t.formattedTaxDueDate}');
        if (mounted) {
          MaoneArtModal.showAlertModal(
            context,
            title: 'Tersimpan ke Dokumen',
            message: 'Informasi dan foto plat nomor $title berhasil disimpan ke daftar dokumen Anda.',
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppTheme.accentEmerald,
            buttonText: 'Selesai',
          );
        }
      }
    } else {
      Clipboard.setData(ClipboardData(text: '${t.plateNumber} - ${t.formattedTotalTax} - Jatuh Tempo: ${t.formattedTaxDueDate}'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rincian pajak berhasil disalin ke clipboard')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Cek Pajak Plat Nomor',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.accentEmerald, size: 20),
            tooltip: 'Bagikan Rincian Pajak',
            onPressed: _taxInfo != null ? _shareTaxDetails : null,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Scan Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _scanPlateWithCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.black),
                      label: Text(
                        'Foto Plat (Kamera)',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _scanPlateFromGallery,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.photo_library_rounded, size: 18, color: AppTheme.accentEmerald),
                      label: Text(
                        'Pilih dari Galeri',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Realistic Indonesian TNKB Plate View & Inputs
              _buildPlateVisualizer(),
              const SizedBox(height: 12),

              // Quick Preset Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      'Pilih Cepat: ',
                      style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    _buildPresetChip('B 1234 KZZ', month: '08', year: '28', model: 'Daihatsu Ayla', labelNote: 'Bekasi • Ayla'),
                    _buildPresetChip('F 1999 AB', month: '12', year: '27', model: 'Toyota Avanza', labelNote: 'Kota Bogor • Avanza'),
                    _buildPresetChip('F 5678 FBA', month: '05', year: '29', model: 'Yamaha NMAX 155', labelNote: 'Kab. Bogor • NMAX'),
                    _buildPresetChip('B 3456 KZZ', month: '10', year: '26', model: 'Honda BeAT', labelNote: 'Bekasi • BeAT'),
                    _buildPresetChip('B 8888 ZAB', month: '03', year: '24', model: 'Daihatsu Ayla', labelNote: 'Depok • Mati Pajak'),
                    _buildPresetChip('D 1500 ABC', month: '09', year: '28', model: 'Honda Brio', labelNote: 'Bandung • Brio'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Tax Details & Bill Card
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppTheme.accentCyan),
                        SizedBox(height: 16),
                        Text('Mengecek data e-Samsat & Bapenda...', style: TextStyle(color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                )
              else if (_taxInfo != null)
                _buildTaxResultCard(_taxInfo!)
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Masukkan nomor plat atau foto plat nomor kendaraan untuk memeriksa status & tarif pajak.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Desain visual plat nomor Indonesia (TNKB) realistis dengan input yang bisa diedit langsung
  Widget _buildPlateVisualizer() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Embossed License Plate Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white70, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                // Plate Main Text Field (Prefix, Number, Suffix)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Kode Wilayah (e.g. B / D / AB)
                    SizedBox(
                      width: 55,
                      child: TextField(
                        controller: _prefixController,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 2,
                        style: GoogleFonts.robotoMono(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'B',
                          hintStyle: TextStyle(color: Colors.white24),
                        ),
                        onChanged: (_) => _checkTax(),
                      ),
                    ),
                    const Text(' ', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    // Nomor Polisi (e.g. 1234)
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _numberController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 4,
                        style: GoogleFonts.robotoMono(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '1234',
                          hintStyle: TextStyle(color: Colors.white24),
                        ),
                        onChanged: (_) => _checkTax(),
                      ),
                    ),
                    const Text(' ', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    // Seri Belakang (e.g. ABC)
                    SizedBox(
                      width: 75,
                      child: TextField(
                        controller: _suffixController,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 3,
                        style: GoogleFonts.robotoMono(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'ABC',
                          hintStyle: TextStyle(color: Colors.white24),
                        ),
                        onChanged: (_) => _checkTax(),
                      ),
                    ),
                  ],
                ),
                // Month / Year Subtext (Editable: e.g. 08 . 28)
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppTheme.accentCyan, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        'STNK: ',
                        style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      // Bulan (01-12)
                      SizedBox(
                        width: 28,
                        child: TextField(
                          controller: _monthController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 2,
                          style: GoogleFonts.robotoMono(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: '08',
                            hintStyle: TextStyle(color: Colors.white24),
                          ),
                          onChanged: (_) => _checkTax(),
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      // Tahun 5 Tahunan (misal 28 / 29)
                      SizedBox(
                        width: 28,
                        child: TextField(
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 2,
                          style: GoogleFonts.robotoMono(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: '28',
                            hintStyle: TextStyle(color: Colors.white24),
                          ),
                          onChanged: (_) => _checkTax(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Vehicle Type Selector (Auto / Sepeda Motor / Mobil Penumpang)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTypeChip('Auto', Icons.auto_awesome_rounded),
              const SizedBox(width: 8),
              _buildTypeChip('Sepeda Motor', Icons.two_wheeler_rounded),
              const SizedBox(width: 8),
              _buildTypeChip('Mobil Penumpang', Icons.directions_car_filled_rounded),
            ],
          ),
          const SizedBox(height: 10),

          // Model Selector Horizontal Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Model: ',
                  style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                _buildModelChip('Daihatsu Ayla'),
                _buildModelChip('Toyota Agya'),
                _buildModelChip('Honda Brio'),
                _buildModelChip('Toyota Calya'),
                _buildModelChip('Daihatsu Sigra'),
                _buildModelChip('Toyota Avanza'),
                _buildModelChip('Mitsubishi Xpander'),
                _buildModelChip('Honda BeAT'),
                _buildModelChip('Honda Vario 160'),
                _buildModelChip('Yamaha NMAX 155'),
                _buildModelChip('Honda PCX 160'),
                _buildModelChip('Mitsubishi Pajero Sport'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Text(
            '💡 Ketuk huruf plat, kotak STNK (Bulan/Tahun), atau Model di atas untuk mengedit',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Tampilan Rincian Data Pajak Kendaraan & Tagihan e-Samsat
  Widget _buildTaxResultCard(VehicleTaxInfo info) {
    return Column(
      children: [
        // Status Badge Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: info.isTaxActive ? AppTheme.accentEmerald.withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: info.isTaxActive ? AppTheme.accentEmerald.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                info.isTaxActive ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: info.isTaxActive ? AppTheme.accentEmerald : Colors.redAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.isTaxActive ? 'PAJAK AKTIF & BERLAKU' : 'PAJAK TERLAMBAT / MATI',
                      style: GoogleFonts.outfit(
                        color: info.isTaxActive ? AppTheme.accentEmerald : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      info.isTaxActive ? 'Jatuh tempo: ${info.formattedTaxDueDate}' : 'Lewat jatuh tempo: ${info.formattedTaxDueDate}',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (info.isLiveApiData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentEmerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.accentEmerald, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: AppTheme.accentEmerald, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        'LIVE SAMSAT',
                        style: GoogleFonts.outfit(color: AppTheme.accentEmerald, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Detail Kendaraan
        GlassContainer(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_car_rounded, color: AppTheme.accentCyan, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Spesifikasi Kendaraan',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 20),
              _buildInfoRow('Wilayah / Samsat', info.regionName),
              _buildInfoRow('Provinsi', info.provinceName),
              _buildInfoRow('Jenis Kendaraan', info.vehicleType),
              _buildInfoRow('Merek & Tipe', '${info.brand} ${info.modelName}'),
              _buildInfoRow('Tahun Pembuatan', '${info.modelYear}'),
              _buildInfoRow('Warna Kendaraan', info.color),
              _buildInfoRow('Kapasitas Mesin', '${info.cylinderCapacity} cc (${info.fuelType})'),
              _buildInfoRow('Masa Berlaku STNK', info.formattedStnkDueDate),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rincian Biaya Pajak
        GlassContainer(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppTheme.accentEmerald, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Rincian Pajak Kendaraan (PKB)',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 20),
              _buildInfoRow('PKB Pokok (Pajak Kendaraan)', info.formattedPkbPokok),
              _buildInfoRow('SWDKLLJ (Jasa Raharja)', info.formattedSwdkllj),
              if (info.pkbDenda > 0) _buildInfoRow('Denda PKB', info.formattedPkbDenda, isDanger: true),
              if (info.swdklljDenda > 0) _buildInfoRow('Denda SWDKLLJ', info.formattedSwdklljDenda, isDanger: true),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL BIAYA PAJAK',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    info.formattedTotalTax,
                    style: GoogleFonts.outfit(
                      color: AppTheme.accentCyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons: Open Official e-Samsat & Save Note
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _saveAsDocumentNote,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.save_rounded, color: Colors.white70, size: 18),
                  label: Text(
                    'Simpan Hasil',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openOfficialPortal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentEmerald,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.open_in_browser_rounded, color: Colors.black, size: 18),
                  label: Text(
                    'Portal e-Samsat',
                    style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.outfit(
                color: isDanger ? Colors.redAccent : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String title, IconData icon) {
    final isSelected = _selectedVehicleType == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = title;
        });
        _checkTax();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accentCyan : Colors.white24,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppTheme.accentCyan : Colors.white60,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelChip(String modelName) {
    final isSelected = _selectedModel == modelName;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedModel = isSelected ? null : modelName;
          });
          _checkTax();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentEmerald.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.accentEmerald : Colors.white24,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Text(
            modelName,
            style: GoogleFonts.outfit(
              color: isSelected ? AppTheme.accentEmerald : Colors.white70,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String fullPlate, {String? month, String? year, String? model, String? labelNote}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(labelNote != null ? '$fullPlate ($labelNote)' : fullPlate),
        labelStyle: GoogleFonts.robotoMono(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: const Color(0xFF1E293B),
        side: const BorderSide(color: Color(0xFF334155)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onPressed: () {
          final parsed = VehicleTaxService.parsePlateFromText(fullPlate);
          if (parsed != null) {
            _prefixController.text = parsed.prefix;
            _numberController.text = parsed.number;
            _suffixController.text = parsed.suffix;
            if (month != null) _monthController.text = month;
            if (year != null) _yearController.text = year;
            if (model != null) _selectedModel = model;
            _checkTax();
          }
        },
      ),
    );
  }
}
