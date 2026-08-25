import 'package:intl/intl.dart';

class VehicleTaxInfo {
  final String plateNumber; // e.g. B 1234 ABC
  final String prefixCode; // e.g. B
  final String numberCode; // e.g. 1234
  final String suffixCode; // e.g. ABC
  final String? plateMonthYear; // e.g. 08.28

  final String regionName; // e.g. DKI Jakarta / Jadetabek
  final String provinceName; // e.g. DKI Jakarta
  final String vehicleType; // e.g. Sepeda Motor / Mobil Penumpang
  final String brand; // e.g. Honda / Toyota
  final String modelName; // e.g. Vario 160 / Avanza
  final int modelYear; // e.g. 2022
  final String color; // e.g. Hitam Metalik
  final String fuelType; // e.g. Bensin
  final int cylinderCapacity; // e.g. 156 cc

  final int pkbPokok;
  final int swdkllj;
  final int pkbDenda;
  final int swdklljDenda;
  final int totalTax;

  final DateTime taxDueDate; // Jatuh tempo tahunan
  final DateTime stnkDueDate; // Jatuh tempo 5 tahunan (STNK)
  final bool isTaxActive;

  final String officialPortalUrl;
  final String officialSamsatName;

  const VehicleTaxInfo({
    required this.plateNumber,
    required this.prefixCode,
    required this.numberCode,
    required this.suffixCode,
    this.plateMonthYear,
    required this.regionName,
    required this.provinceName,
    required this.vehicleType,
    required this.brand,
    required this.modelName,
    required this.modelYear,
    required this.color,
    required this.fuelType,
    required this.cylinderCapacity,
    required this.pkbPokok,
    required this.swdkllj,
    required this.pkbDenda,
    required this.swdklljDenda,
    required this.totalTax,
    required this.taxDueDate,
    required this.stnkDueDate,
    required this.isTaxActive,
    required this.officialPortalUrl,
    required this.officialSamsatName,
  });

  static String _safeCurrency(int amount) {
    try {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
    } catch (_) {
      final str = amount.toString();
      final buffer = StringBuffer();
      int count = 0;
      for (int i = str.length - 1; i >= 0; i--) {
        buffer.write(str[i]);
        count++;
        if (count % 3 == 0 && i != 0) {
          buffer.write('.');
        }
      }
      return 'Rp ${buffer.toString().split('').reversed.join('')}';
    }
  }

  static String _safeDate(DateTime date) {
    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final monthName = (date.month >= 1 && date.month <= 12) ? months[date.month - 1] : '${date.month}';
      return '${date.day.toString().padLeft(2, '0')} $monthName ${date.year}';
    }
  }

  String get formattedPkbPokok => _safeCurrency(pkbPokok);
  String get formattedSwdkllj => _safeCurrency(swdkllj);
  String get formattedPkbDenda => _safeCurrency(pkbDenda);
  String get formattedSwdklljDenda => _safeCurrency(swdklljDenda);
  String get formattedTotalTax => _safeCurrency(totalTax);

  String get formattedTaxDueDate => _safeDate(taxDueDate);
  String get formattedStnkDueDate => _safeDate(stnkDueDate);
}
