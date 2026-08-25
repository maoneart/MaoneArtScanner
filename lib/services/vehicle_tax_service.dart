import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/vehicle_tax.dart';

class RegionMeta {
  final String prefix;
  final String regionName;
  final String provinceName;
  final String portalUrl;
  final String samsatName;

  const RegionMeta({
    required this.prefix,
    required this.regionName,
    required this.provinceName,
    required this.portalUrl,
    required this.samsatName,
  });
}

class ParsedPlate {
  final String prefix;
  final String number;
  final String suffix;
  final String? monthYear;

  const ParsedPlate({
    required this.prefix,
    required this.number,
    required this.suffix,
    this.monthYear,
  });

  String get fullPlate => '$prefix $number $suffix'.trim();
}

class VehicleTaxService {
  static const Map<String, RegionMeta> _regionMap = {
    // JABODETABEK & BANTEN
    'B': RegionMeta(
      prefix: 'B',
      regionName: 'DKI Jakarta, Depok, Bekasi, Tangerang',
      provinceName: 'DKI Jakarta',
      portalUrl: 'https://samsat-pkb2.jakarta.go.id/',
      samsatName: 'Bapenda DKI Jakarta / e-Samsat Jakarta',
    ),
    'A': RegionMeta(
      prefix: 'A',
      regionName: 'Serang, Cilegon, Pandeglang, Lebak, Tangerang Kab.',
      provinceName: 'Banten',
      portalUrl: 'https://ditlantas.banten.polri.go.id/',
      samsatName: 'Bapenda Provinsi Banten',
    ),

    // JAWA BARAT
    'D': RegionMeta(
      prefix: 'D',
      regionName: 'Kota & Kab. Bandung, Cimahi, Bandung Barat',
      provinceName: 'Jawa Barat',
      portalUrl: 'https://bapenda.jabarprov.go.id/sambara/',
      samsatName: 'Bapenda Jabar (SAMBARA / Sapawarga)',
    ),
    'E': RegionMeta(
      prefix: 'E',
      regionName: 'Cirebon, Indramayu, Majalengka, Kuningan',
      provinceName: 'Jawa Barat',
      portalUrl: 'https://bapenda.jabarprov.go.id/sambara/',
      samsatName: 'Bapenda Jabar (SAMBARA)',
    ),
    'F': RegionMeta(
      prefix: 'F',
      regionName: 'Bogor, Sukabumi, Cianjur',
      provinceName: 'Jawa Barat',
      portalUrl: 'https://bapenda.jabarprov.go.id/sambara/',
      samsatName: 'Bapenda Jabar (SAMBARA)',
    ),
    'T': RegionMeta(
      prefix: 'T',
      regionName: 'Karawang, Purwakarta, Subang',
      provinceName: 'Jawa Barat',
      portalUrl: 'https://bapenda.jabarprov.go.id/sambara/',
      samsatName: 'Bapenda Jabar (SAMBARA)',
    ),
    'Z': RegionMeta(
      prefix: 'Z',
      regionName: 'Garut, Tasikmalaya, Ciamis, Banjar, Pangandaran',
      provinceName: 'Jawa Barat',
      portalUrl: 'https://bapenda.jabarprov.go.id/sambara/',
      samsatName: 'Bapenda Jabar (SAMBARA)',
    ),

    // JAWA TENGAH & DIY
    'H': RegionMeta(
      prefix: 'H',
      regionName: 'Semarang, Salatiga, Kendal, Demak',
      provinceName: 'Jawa Tengah',
      portalUrl: 'https://new-sakpole.jatengprov.go.id/',
      samsatName: 'Bapenda Jateng (New SAKPOLE)',
    ),
    'G': RegionMeta(
      prefix: 'G',
      regionName: 'Pekalongan, Tegal, Brebes, Batang, Pemalang',
      provinceName: 'Jawa Tengah',
      portalUrl: 'https://new-sakpole.jatengprov.go.id/',
      samsatName: 'Bapenda Jateng (New SAKPOLE)',
    ),
    'K': RegionMeta(
      prefix: 'K',
      regionName: 'Pati, Kudus, Jepara, Rembang, Blora, Grobogan',
      provinceName: 'Jawa Tengah',
      portalUrl: 'https://new-sakpole.jatengprov.go.id/',
      samsatName: 'Bapenda Jateng (New SAKPOLE)',
    ),
    'R': RegionMeta(
      prefix: 'R',
      regionName: 'Banyumas, Purwokerto, Cilacap, Purbalingga, Banjarnegara',
      provinceName: 'Jawa Tengah',
      portalUrl: 'https://new-sakpole.jatengprov.go.id/',
      samsatName: 'Bapenda Jateng (New SAKPOLE)',
    ),
    'AA': RegionMeta(
      prefix: 'AA',
      regionName: 'Magelang, Purworejo, Temanggung, Wonosobo, Kebumen',
      provinceName: 'Jawa Tengah',
      portalUrl: 'https://new-sakpole.jatengprov.go.id/',
      samsatName: 'Bapenda Jateng (New SAKPOLE)',
    ),
    'AD': RegionMeta(
      prefix: 'AD',
      regionName: 'Surakarta (Solo), Boyolali, Klaten, Sukoharjo, Wonogiri, Sragen',
      provinceName: 'Jawa Tengah',
      portalUrl: 'https://new-sakpole.jatengprov.go.id/',
      samsatName: 'Bapenda Jateng (New SAKPOLE)',
    ),
    'AB': RegionMeta(
      prefix: 'AB',
      regionName: 'Kota Yogyakarta, Sleman, Bantul, Gunungkidul, Kulon Progo',
      provinceName: 'DI Yogyakarta',
      portalUrl: 'https://infopkb.jogjaprov.go.id/',
      samsatName: 'Samsat Digital DIY / BPKAD Jogja',
    ),

    // JAWA TIMUR & BALI
    'L': RegionMeta(
      prefix: 'L',
      regionName: 'Surabaya',
      provinceName: 'Jawa Timur',
      portalUrl: 'https://info.dipendajatim.go.id/esamsat/',
      samsatName: 'Bapenda Jawa Timur (e-Samsat Jatim)',
    ),
    'W': RegionMeta(
      prefix: 'W',
      regionName: 'Sidoarjo, Gresik',
      provinceName: 'Jawa Timur',
      portalUrl: 'https://info.dipendajatim.go.id/esamsat/',
      samsatName: 'Bapenda Jawa Timur (e-Samsat Jatim)',
    ),
    'N': RegionMeta(
      prefix: 'N',
      regionName: 'Malang, Batu, Pasuruan, Probolinggo, Lumajang',
      provinceName: 'Jawa Timur',
      portalUrl: 'https://info.dipendajatim.go.id/esamsat/',
      samsatName: 'Bapenda Jawa Timur (e-Samsat Jatim)',
    ),
    'M': RegionMeta(
      prefix: 'M',
      regionName: 'Madura (Bangkalan, Sampang, Pamekasan, Sumenep)',
      provinceName: 'Jawa Timur',
      portalUrl: 'https://info.dipendajatim.go.id/esamsat/',
      samsatName: 'Bapenda Jawa Timur (e-Samsat Jatim)',
    ),
    'P': RegionMeta(
      prefix: 'P',
      regionName: 'Jember, Banyuwangi, Bondowoso, Situbondo',
      provinceName: 'Jawa Timur',
      portalUrl: 'https://info.dipendajatim.go.id/esamsat/',
      samsatName: 'Bapenda Jawa Timur (e-Samsat Jatim)',
    ),
    'S': RegionMeta(
      prefix: 'S',
      regionName: 'Bojonegoro, Mojokerto, Tuban, Lamongan, Jombang',
      provinceName: 'Jawa Timur',
      portalUrl: 'https://info.dipendajatim.go.id/esamsat/',
      samsatName: 'Bapenda Jawa Timur (e-Samsat Jatim)',
    ),
    'AE': RegionMeta(
      prefix: 'AE',
      regionName: 'Madiun, Ngawi, Magetan, Ponorogo, Pacitan',
      provinceName: 'Jawa Timur',
      portalUrl: 'https://info.dipendajatim.go.id/esamsat/',
      samsatName: 'Bapenda Jawa Timur (e-Samsat Jatim)',
    ),
    'AG': RegionMeta(
      prefix: 'AG',
      regionName: 'Kediri, Blitar, Tulungagung, Nganjuk, Trenggalek',
      provinceName: 'Jawa Timur',
      portalUrl: 'https://info.dipendajatim.go.id/esamsat/',
      samsatName: 'Bapenda Jawa Timur (e-Samsat Jatim)',
    ),
    'DK': RegionMeta(
      prefix: 'DK',
      regionName: 'Denpasar, Badung, Gianyar, Tabanan, Buleleng (Bali)',
      provinceName: 'Bali',
      portalUrl: 'https://bapenda.baliprov.go.id/',
      samsatName: 'Bapenda Provinsi Bali',
    ),

    // SUMATERA
    'BK': RegionMeta(
      prefix: 'BK',
      regionName: 'Medan, Deli Serdang, Tebing Tinggi, Binjai',
      provinceName: 'Sumatera Utara',
      portalUrl: 'https://bpprd.sumutprov.go.id/',
      samsatName: 'BPPRD Sumatera Utara (e-Samsat Sumut)',
    ),
    'BL': RegionMeta(
      prefix: 'BL',
      regionName: 'Banda Aceh, Lhokseumawe, Langsa, Sabang',
      provinceName: 'Aceh',
      portalUrl: 'https://bpka.acehprov.go.id/',
      samsatName: 'BPKA Aceh',
    ),
    'BA': RegionMeta(
      prefix: 'BA',
      regionName: 'Padang, Bukittinggi, Pariaman, Payakumbuh',
      provinceName: 'Sumatera Barat',
      portalUrl: 'https://bapenda.sumbarprov.go.id/',
      samsatName: 'Bapenda Sumatera Barat',
    ),
    'BM': RegionMeta(
      prefix: 'BM',
      regionName: 'Pekanbaru, Dumai, Kampar, Siak, Bengkalis',
      provinceName: 'Riau',
      portalUrl: 'https://bapenda.riau.go.id/',
      samsatName: 'Bapenda Riau',
    ),
    'BG': RegionMeta(
      prefix: 'BG',
      regionName: 'Palembang, Prabumulih, Lubuklinggau, Ogan Ilir',
      provinceName: 'Sumatera Selatan',
      portalUrl: 'https://bapenda.sumselprov.go.id/',
      samsatName: 'Bapenda Sumsel (e-Dempo)',
    ),
    'BE': RegionMeta(
      prefix: 'BE',
      regionName: 'Bandar Lampung, Metro, Lampung Selatan',
      provinceName: 'Lampung',
      portalUrl: 'https://bapenda.lampungprov.go.id/',
      samsatName: 'Bapenda Provinsi Lampung',
    ),

    // SULAWESI, KALIMANTAN, NTB & NTT
    'KT': RegionMeta(
      prefix: 'KT',
      regionName: 'Samarinda, Balikpapan, Kutai Kartanegara',
      provinceName: 'Kalimantan Timur',
      portalUrl: 'https://bapenda.kaltimprov.go.id/',
      samsatName: 'Bapenda Kalimantan Timur (SIMPATOR)',
    ),
    'DA': RegionMeta(
      prefix: 'DA',
      regionName: 'Banjarmasin, Banjarbaru, Martapura',
      provinceName: 'Kalimantan Selatan',
      portalUrl: 'https://bakeuda.kalselprov.go.id/',
      samsatName: 'Bakeuda Kalsel',
    ),
    'KB': RegionMeta(
      prefix: 'KB',
      regionName: 'Pontianak, Singkawang, Sambas, Ketapang',
      provinceName: 'Kalimantan Barat',
      portalUrl: 'https://bapenda.kalbarprov.go.id/',
      samsatName: 'Bapenda Kalimantan Barat',
    ),
    'DD': RegionMeta(
      prefix: 'DD',
      regionName: 'Makassar, Gowa, Maros, Pangkep, Takalar',
      provinceName: 'Sulawesi Selatan',
      portalUrl: 'https://bapenda.sulselprov.go.id/',
      samsatName: 'Bapenda Sulawesi Selatan (e-Samsat Sulsel)',
    ),
    'DB': RegionMeta(
      prefix: 'DB',
      regionName: 'Manado, Bitung, Minahasa, Tomohon',
      provinceName: 'Sulawesi Utara',
      portalUrl: 'https://bapenda.sulutprov.go.id/',
      samsatName: 'Bapenda Sulawesi Utara',
    ),
    'DR': RegionMeta(
      prefix: 'DR',
      regionName: 'Mataram, Lombok Barat, Lombok Tengah, Lombok Timur',
      provinceName: 'Nusa Tenggara Barat',
      portalUrl: 'https://bappenda.ntbprov.go.id/',
      samsatName: 'Bappenda NTB (e-Samsat Delivery)',
    ),
  };

  /// Ekstraksi plat nomor dari foto menggunakan Google ML Kit OCR dengan algoritma cerdas
  static Future<ParsedPlate?> scanPlateFromImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return null;

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognized = await textRecognizer.processImage(inputImage);
      
      // 1. Ekstraksi dari seluruh blok dan baris
      final fullParsed = parsePlateFromRecognizedText(recognized);
      if (fullParsed != null) return fullParsed;

      // 2. Fallback dari raw text
      return parsePlateFromText(recognized.text);
    } catch (_) {
      return null;
    } finally {
      await textRecognizer.close();
    }
  }

  /// Ekstraksi cerdas dari struktur baris & blok Google ML Kit
  static ParsedPlate? parsePlateFromRecognizedText(RecognizedText recognized) {
    String? foundPrefix;
    String? foundNumber;
    String? foundSuffix;
    String? foundMonthYear;

    // Kumpulkan semua baris teks
    final List<String> lines = [];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) lines.add(text);
      }
    }

    // 1. Cari baris bulan & tahun (misal: "08.28", "08-28", "08 28", "12.27")
    final monthYearRegex = RegExp(r'\b(0[1-9]|1[0-2])[\s\.\:\-]([0-9]{2}|20[0-9]{2})\b');
    for (final line in lines) {
      final match = monthYearRegex.firstMatch(line);
      if (match != null) {
        final m = match.group(1)!;
        final yRaw = match.group(2)!;
        final y = yRaw.length == 4 ? yRaw.substring(2) : yRaw;
        foundMonthYear = '$m.$y';
        break;
      }
    }

    // 2. Cari baris plat utama di setiap baris
    for (final line in lines) {
      final parsed = parsePlateFromText(line);
      if (parsed != null) {
        return ParsedPlate(
          prefix: parsed.prefix,
          number: parsed.number,
          suffix: parsed.suffix,
          monthYear: foundMonthYear ?? parsed.monthYear,
        );
      }
    }

    // 3. Gabungkan semua baris dan coba parse keseluruhan
    final combined = lines.join(' ');
    final parsedCombined = parsePlateFromText(combined);
    if (parsedCombined != null) {
      return ParsedPlate(
        prefix: parsedCombined.prefix,
        number: parsedCombined.number,
        suffix: parsedCombined.suffix,
        monthYear: foundMonthYear ?? parsedCombined.monthYear,
      );
    }

    return null;
  }

  /// Normalisasi huruf OCR (koreksi angka yang salah terbaca sebagai huruf)
  static String _cleanOcrLetters(String str) {
    return str.toUpperCase()
        .replaceAll('0', 'O')
        .replaceAll('8', 'B')
        .replaceAll('1', 'I')
        .replaceAll('5', 'S')
        .replaceAll('2', 'Z');
  }

  /// Normalisasi angka OCR (koreksi huruf yang salah terbaca di kolom angka)
  static String _cleanOcrDigits(String str) {
    return str.toUpperCase()
        .replaceAll('O', '0')
        .replaceAll('D', '0')
        .replaceAll('Q', '0')
        .replaceAll('I', '1')
        .replaceAll('L', '1')
        .replaceAll('|', '1')
        .replaceAll('J', '1')
        .replaceAll('Z', '2')
        .replaceAll('E', '3')
        .replaceAll('A', '4')
        .replaceAll('S', '5')
        .replaceAll('G', '6')
        .replaceAll('B', '8')
        .replaceAll('g', '9')
        .replaceAll('q', '9');
  }

  /// Membaca dan menormalisasi string plat nomor (TNKB Indonesia)
  static ParsedPlate? parsePlateFromText(String rawText) {
    if (rawText.trim().isEmpty) return null;

    // Bersihkan karakter selain huruf, angka, titik, strip
    final cleanText = rawText.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\s\.\-]'), ' ');

    // 1. Ekstraksi bulan & tahun jika ada
    String? extractedMonthYear;
    final monthYearMatch = RegExp(r'\b(0[1-9]|1[0-2])[\s\.\:\-]([0-9]{2}|20[0-9]{2})\b').firstMatch(cleanText);
    if (monthYearMatch != null) {
      final m = monthYearMatch.group(1)!;
      final yRaw = monthYearMatch.group(2)!;
      final y = yRaw.length == 4 ? yRaw.substring(2) : yRaw;
      extractedMonthYear = '$m.$y';
    }

    // 2. Regex plat nomor Indonesia standar (misal: B 1234 ABC atau B1234ABC)
    final fullRegex = RegExp(r'\b([A-Z0-9]{1,2})\s*([0-9A-Z]{1,4})\s*([A-Z0-9]{1,3})\b');
    final matches = fullRegex.allMatches(cleanText);

    for (final match in matches) {
      final rawPrefix = match.group(1)!;
      final rawNumber = match.group(2)!;
      final rawSuffix = match.group(3)!;

      final prefix = _cleanOcrLetters(rawPrefix);
      final number = _cleanOcrDigits(rawNumber);
      final suffix = _cleanOcrLetters(rawSuffix);

      if (_isValidPrefix(prefix) && RegExp(r'^[0-9]{1,4}$').hasMatch(number) && RegExp(r'^[A-Z]{1,3}$').hasMatch(suffix)) {
        return ParsedPlate(
          prefix: prefix,
          number: number,
          suffix: suffix,
          monthYear: extractedMonthYear,
        );
      }
    }

    // 3. Fallback token-based scanner
    final tokens = cleanText.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    for (int i = 0; i < tokens.length; i++) {
      final candPrefix = _cleanOcrLetters(tokens[i]);
      if (_isValidPrefix(candPrefix) && i + 1 < tokens.length) {
        final candNumber = _cleanOcrDigits(tokens[i + 1]);
        if (RegExp(r'^[0-9]{1,4}$').hasMatch(candNumber)) {
          String candSuffix = 'XX';
          if (i + 2 < tokens.length) {
            final testSuffix = _cleanOcrLetters(tokens[i + 2]);
            if (RegExp(r'^[A-Z]{1,3}$').hasMatch(testSuffix)) {
              candSuffix = testSuffix;
            }
          }
          return ParsedPlate(
            prefix: candPrefix,
            number: candNumber,
            suffix: candSuffix,
            monthYear: extractedMonthYear,
          );
        }
      }
    }

    return null;
  }

  static bool _isValidPrefix(String prefix) {
    return _regionMap.containsKey(prefix) || RegExp(r'^[A-Z]{1,2}$').hasMatch(prefix);
  }

  /// Mendapatkan metadata wilayah berdasarkan kode plat
  static RegionMeta getRegionMeta(String prefix) {
    final clean = prefix.toUpperCase().trim();
    if (_regionMap.containsKey(clean)) {
      return _regionMap[clean]!;
    }
    return RegionMeta(
      prefix: clean,
      regionName: 'Wilayah $clean (Indonesia)',
      provinceName: 'Indonesia',
      portalUrl: 'https://samsatdigital.id/', // SIGNAL Nasional
      samsatName: 'Samsat Digital Nasional (SIGNAL)',
    );
  }

  /// Mengambil rincian data pajak dan estimasi biaya berbasis data plat & bulan-tahun STNK
  static Future<VehicleTaxInfo> getVehicleTaxDetails(
    ParsedPlate plate, {
    String? vehicleTypeOverride,
  }) async {
    final meta = getRegionMeta(plate.prefix);
    final numberInt = int.tryParse(plate.number) ?? 1000;

    // 1. Menentukan Jenis Kendaraan
    bool isMotorcycle = numberInt >= 2000 && numberInt <= 6999;
    bool isCar = numberInt < 2000;

    if (vehicleTypeOverride != null) {
      if (vehicleTypeOverride.toLowerCase().contains('motor')) {
        isMotorcycle = true;
        isCar = false;
      } else if (vehicleTypeOverride.toLowerCase().contains('mobil')) {
        isCar = true;
        isMotorcycle = false;
      }
    }

    final String vehicleType = isMotorcycle
        ? 'Sepeda Motor'
        : (isCar ? 'Mobil Penumpang' : 'Kendaraan Niaga');

    // 2. Parsing Bulan & Tahun Jatuh Tempo STNK 5 Tahunan
    final now = DateTime.now();
    int stnkMonth = 8; // default Agustus
    int stnkYear = now.year + 2; // default misal 2028

    if (plate.monthYear != null && plate.monthYear!.isNotEmpty) {
      final cleanMY = plate.monthYear!.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanMY.length >= 4) {
        final m = int.tryParse(cleanMY.substring(0, 2)) ?? now.month;
        final ySub = int.tryParse(cleanMY.substring(2)) ?? (now.year % 100 + 2);
        int y = ySub < 100 ? (2000 + ySub) : ySub;
        stnkMonth = (m >= 1 && m <= 12) ? m : now.month;
        stnkYear = y;
      }
    }

    // 3. Tahun Pembuatan Model Kendaraan
    int modelYear = stnkYear - 5;
    if (modelYear < 2005) modelYear = 2018;
    if (modelYear > now.year) modelYear = now.year;

    // 4. Perhitungan Tanggal Jatuh Tempo PKB (Tahunan) dan STNK (5 Tahunan)
    // Jatuh tempo STNK 5 tahunan persis pada bulan & tahun yang diketik
    final DateTime stnkDueDate = DateTime(stnkYear, stnkMonth, 25);

    // Jatuh tempo PKB tahunan berada pada bulan yang sama di tahun pajak berjalan
    int taxDueYear = now.year;
    // Jika bulan STNK tahun ini sudah lewat dari bulan sekarang, maka jatuh tempo tahun ini sudah lewat
    if (now.month > stnkMonth || (now.month == stnkMonth && now.day > 25)) {
      taxDueYear = now.year;
    } else {
      taxDueYear = now.year;
    }
    
    // Jika STNK 5 tahunan sudah mati (misal tahun 2023), maka jatuh tempo PKB juga sudah mati sejak tahun tersebut
    if (stnkYear < now.year) {
      taxDueYear = stnkYear;
    }

    final DateTime taxDueDate = DateTime(taxDueYear, stnkMonth, 25);

    // 5. Evaluasi Status Pajak (Aktif vs Terlambat/Mati)
    final bool isTaxActive = taxDueDate.isAfter(now) && stnkDueDate.isAfter(now);

    // Hitung durasi keterlambatan dalam bulan jika mati
    int lateMonths = 0;
    if (!isTaxActive) {
      final diffDays = now.difference(taxDueDate).inDays;
      lateMonths = (diffDays / 30).ceil();
      if (lateMonths < 1) lateMonths = 1;
      if (lateMonths > 24) lateMonths = 24; // Maksimal denda 24 bulan (UU Pajak Daerah)
    }

    // 6. Generator Merek & Tipe Kendaraan Realistis
    final randomSeed = (plate.fullPlate + vehicleType).hashCode.abs();
    final random = Random(randomSeed);

    final List<String> motorBrands = ['Honda', 'Yamaha', 'Suzuki', 'Kawasaki', 'Vespa'];
    final List<String> motorModels = ['Vario 160 ABS', 'BeAT Street eSP', 'NMAX 155 Connected', 'PCX 160', 'Scoopy Prestige', 'Aerox 155', 'KLX 150'];
    final List<String> carBrands = ['Toyota', 'Honda', 'Daihatsu', 'Mitsubishi', 'Suzuki', 'Hyundai', 'Wuling'];
    final List<String> carModels = ['Avanza 1.5 G CVT', 'Innova Zenix V Hybrid', 'Brio RS 1.2', 'HR-V 1.5 SE', 'Xpander Ultimate', 'Pajero Sport Dakar', 'Stargazer Prime'];
    final List<String> colors = ['Hitam Metalik', 'Putih Mutiara', 'Abu-Abu Metalik', 'Merah Marun', 'Silver Metalik', 'Biru Tua'];

    final brand = isMotorcycle ? motorBrands[random.nextInt(motorBrands.length)] : carBrands[random.nextInt(carBrands.length)];
    final model = isMotorcycle ? motorModels[random.nextInt(motorModels.length)] : carModels[random.nextInt(carModels.length)];
    final color = colors[random.nextInt(colors.length)];
    final int cc = isMotorcycle ? (110 + (random.nextInt(3) * 25)) : (1200 + (random.nextInt(4) * 300));

    // 7. Tarif PKB Pokok & SWDKLLJ
    int pkbPokok;
    int swdkllj;
    if (isMotorcycle) {
      swdkllj = 35000; // SWDKLLJ Motor R2
      pkbPokok = 220000 + ((modelYear - 2015) * 25000) + (cc * 400);
    } else {
      swdkllj = 143000; // SWDKLLJ Mobil R4
      pkbPokok = 2400000 + ((modelYear - 2015) * 350000) + (cc * 400);
    }

    // 8. Perhitungan Denda Akurat
    int pkbDenda = 0;
    int swdklljDenda = 0;
    if (!isTaxActive) {
      // Denda PKB = PKB Pokok x 2% x Jumlah Bulan Terlambat (Maks 48%)
      final double penaltyRate = (lateMonths * 0.02).clamp(0.02, 0.48);
      pkbDenda = (pkbPokok * penaltyRate).round();
      swdklljDenda = isMotorcycle ? (lateMonths > 3 ? 32000 : 16000) : (lateMonths > 3 ? 100000 : 50000);
    }

    final int totalTax = pkbPokok + swdkllj + pkbDenda + swdklljDenda;
    final displayMonthYear = '${stnkMonth.toString().padLeft(2, '0')}.${(stnkYear % 100).toString().padLeft(2, '0')}';

    return VehicleTaxInfo(
      plateNumber: plate.fullPlate,
      prefixCode: plate.prefix,
      numberCode: plate.number,
      suffixCode: plate.suffix,
      plateMonthYear: displayMonthYear,
      regionName: meta.regionName,
      provinceName: meta.provinceName,
      vehicleType: vehicleType,
      brand: brand,
      modelName: model,
      modelYear: modelYear,
      color: color,
      fuelType: 'Bensin',
      cylinderCapacity: cc,
      pkbPokok: pkbPokok,
      swdkllj: swdkllj,
      pkbDenda: pkbDenda,
      swdklljDenda: swdklljDenda,
      totalTax: totalTax,
      taxDueDate: taxDueDate,
      stnkDueDate: stnkDueDate,
      isTaxActive: isTaxActive,
      officialPortalUrl: meta.portalUrl,
      officialSamsatName: meta.samsatName,
    );
  }
}
