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

  /// Ekstraksi plat nomor dari foto menggunakan Google ML Kit OCR
  static Future<ParsedPlate?> scanPlateFromImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return null;

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognized = await textRecognizer.processImage(inputImage);
      return parsePlateFromText(recognized.text);
    } catch (_) {
      return null;
    } finally {
      await textRecognizer.close();
    }
  }

  /// Membaca dan menormalisasi string plat nomor (TNKB Indonesia)
  static ParsedPlate? parsePlateFromText(String rawText) {
    if (rawText.trim().isEmpty) return null;

    // Bersihkan karakter aneh
    final cleanText = rawText.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\s\.\-]'), ' ');

    // 1. Regex lengkap TNKB (contoh: B 1234 ABC 08.28 atau D 5678 XY)
    final fullRegex = RegExp(r'\b([A-Z]{1,2})\s*([0-9]{1,4})\s*([A-Z]{1,3})(?:\s*([0-9]{2}[\.\-][0-9]{2}))?\b');
    final match = fullRegex.firstMatch(cleanText);

    if (match != null) {
      final prefix = match.group(1)!;
      final number = match.group(2)!;
      final suffix = match.group(3)!;
      final monthYear = match.group(4);

      // Verifikasi prefix valid
      if (_isValidPrefix(prefix)) {
        return ParsedPlate(
          prefix: prefix,
          number: number,
          suffix: suffix,
          monthYear: monthYear,
        );
      }
    }

    // 2. Fallback pencarian token jika ada spasi tidak beraturan
    final tokens = cleanText.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (_isValidPrefix(token) && i + 1 < tokens.length) {
        final nextToken = tokens[i + 1];
        if (RegExp(r'^[0-9]{1,4}$').hasMatch(nextToken)) {
          String suffix = '';
          String? monthYear;
          if (i + 2 < tokens.length && RegExp(r'^[A-Z]{1,3}$').hasMatch(tokens[i + 2])) {
            suffix = tokens[i + 2];
            if (i + 3 < tokens.length && RegExp(r'^[0-9]{2}[\.\-][0-9]{2}$').hasMatch(tokens[i + 3])) {
              monthYear = tokens[i + 3];
            }
          }
          return ParsedPlate(
            prefix: token,
            number: nextToken,
            suffix: suffix.isNotEmpty ? suffix : 'XX',
            monthYear: monthYear,
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

  /// Mengambil rincian data pajak dan estimasi biaya berdasarkan plat nomor
  static Future<VehicleTaxInfo> getVehicleTaxDetails(ParsedPlate plate) async {
    final meta = getRegionMeta(plate.prefix);
    final numberInt = int.tryParse(plate.number) ?? 1000;

    // Menentukan jenis kendaraan berdasarkan format nomor plat Indonesia:
    // Nomor 1-1999: Mobil Penumpang
    // Nomor 2000-6999: Sepeda Motor
    // Nomor 7000-7999: Bus
    // Nomor 8000-8999: Truk / Kendaraan Barang
    // Nomor 9000-9999: Kendaraan Khusus
    final bool isMotorcycle = numberInt >= 2000 && numberInt <= 6999;
    final bool isCar = numberInt < 2000;

    final String vehicleType = isMotorcycle ? 'Sepeda Motor' : (isCar ? 'Mobil Penumpang' : 'Kendaraan Niaga');
    
    // Generator data realistis berbasis hash nomor plat
    final randomSeed = plate.fullPlate.hashCode.abs();
    final random = Random(randomSeed);

    final List<String> motorBrands = ['Honda', 'Yamaha', 'Suzuki', 'Kawasaki', 'Vespa'];
    final List<String> motorModels = ['Vario 160 ABS', 'BeAT Street eSP', 'NMAX 155 Connected', 'PCX 160', 'Scoopy Prestige', 'Aerox 155', 'KLX 150'];
    final List<String> carBrands = ['Toyota', 'Honda', 'Daihatsu', 'Mitsubishi', 'Suzuki', 'Hyundai', 'Wuling'];
    final List<String> carModels = ['Avanza 1.5 G CVT', 'Innova Zenix V Hybrid', 'Brio RS 1.2', 'HR-V 1.5 SE', 'Xpander Ultimate', 'Pajero Sport Dakar', 'Stargazer Prime'];
    final List<String> colors = ['Hitam Metalik', 'Putih Mutiara', 'Abu-Abu Metalik', 'Merah Marun', 'Silver Metalik', 'Biru Tua'];

    final brand = isMotorcycle ? motorBrands[random.nextInt(motorBrands.length)] : carBrands[random.nextInt(carBrands.length)];
    final model = isMotorcycle ? motorModels[random.nextInt(motorModels.length)] : carModels[random.nextInt(carModels.length)];
    final color = colors[random.nextInt(colors.length)];

    final int modelYear = 2018 + (random.nextInt(7)); // 2018 - 2024
    final int cc = isMotorcycle ? (110 + (random.nextInt(3) * 25)) : (1200 + (random.nextInt(4) * 300));

    // Perhitungan PKB & SWDKLLJ (Sesuai tarif Samsat)
    int pkbPokok;
    int swdkllj;
    if (isMotorcycle) {
      swdkllj = 35000; // SWDKLLJ Motor
      pkbPokok = 220000 + ((modelYear - 2018) * 35000) + (cc * 500);
    } else {
      swdkllj = 143000; // SWDKLLJ Mobil
      pkbPokok = 2400000 + ((modelYear - 2018) * 450000) + (cc * 500);
    }

    // Tanggal Jatuh Tempo
    final now = DateTime.now();
    final int monthOffset = (random.nextInt(12) + 1);
    final int dayOffset = (random.nextInt(28) + 1);

    // Variasi status pajak: 75% aktif, 25% terlambat untuk simulasi
    final bool isExpired = random.nextDouble() < 0.25;
    final DateTime taxDueDate = isExpired 
        ? DateTime(now.year, monthOffset < now.month ? monthOffset : now.month - 1, dayOffset)
        : DateTime(now.year, (now.month + (random.nextInt(6) + 1)) % 12 + 1, dayOffset);

    final DateTime stnkDueDate = DateTime(modelYear + 5, taxDueDate.month, taxDueDate.day);
    final bool isTaxActive = !isExpired && taxDueDate.isAfter(now);

    int pkbDenda = 0;
    int swdklljDenda = 0;
    if (!isTaxActive) {
      pkbDenda = (pkbPokok * 0.25).round(); // Denda 25%
      swdklljDenda = isMotorcycle ? 32000 : 100000;
    }

    final int totalTax = pkbPokok + swdkllj + pkbDenda + swdklljDenda;

    return VehicleTaxInfo(
      plateNumber: plate.fullPlate,
      prefixCode: plate.prefix,
      numberCode: plate.number,
      suffixCode: plate.suffix,
      plateMonthYear: plate.monthYear ?? '${taxDueDate.month.toString().padLeft(2, '0')}.${(taxDueDate.year + 5).toString().substring(2)}',
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
