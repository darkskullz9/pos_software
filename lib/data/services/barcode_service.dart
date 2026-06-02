class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal();

  String generateEan13FromSeed(String seed) {
    final digits = seed.replaceAll(RegExp(r'\D'), '');

    if(digits.length < 12) {
      throw ArgumentError('EAN-13 requires at least 12 digits.');
    }

    final twelveDigits = digits.substring(0, 12);
    final checkDigit = _calculateCheckDigit(twelveDigits);

    return '$twelveDigits$checkDigit';
  }

  bool isValidEan13(String code) {
    final digits = code.replaceAll(RegExp(r'\D'), '');
    if(digits.length != 13) return false;

    final base = digits.substring(0, 12);
    final checkDigit = int.parse(digits[12]);

    return _calculateCheckDigit(base) == checkDigit;
  }

  int _calculateCheckDigit(String twelveDigits) {
    if(twelveDigits.length != 12) {
      throw ArgumentError('EAN-13 base must contain exactly 12 digits');
    }

    int oddSum = 0;
    int evenSum = 0;

    for(int i = 0; i < 12; i++) {
      final digit = int.parse(twelveDigits[i]);

      if(i.isEven) {
        oddSum += digit;
      } else {
        evenSum += digit;
      }
    }

    final total = oddSum + (evenSum * 3);
    final remainder = total % 10;

    return remainder == 0 ? 0 : 10 - remainder;
  }
}