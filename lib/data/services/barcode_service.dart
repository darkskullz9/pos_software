class BarcodeService {
  String generateEan13FromBase(String base12) {
    if (!RegExp(r'^\d{12}$').hasMatch(base12)) {
      throw Exception('La base doit contenir exactement 12 chiffres');
    }

    final digits = base12.split('').map(int.parse).toList();

    int sumOdd = 0;
    int sumEven = 0;

    for (int i = 0; i < digits.length; i++) {
      if (i.isEven) {
        sumOdd += digits[i];
      } else {
        sumEven += digits[i];
      }
    }

    final total = sumOdd + (sumEven * 3);
    final checkDigit = (10 - (total % 10)) % 10;

    return '$base12$checkDigit';
  }

  String generateClothingBarcode({
    required int productIndex,
    required int categoryCode,
    int? colorCode,
    int? sizeCode,
    int storeCode = 1,
  }) {
    const prefix = '20';

    final store = storeCode.toString().padLeft(2, '0');
    final category = categoryCode.toString().padLeft(2, '0');
    final color = (colorCode ?? 0).toString().padLeft(2, '0');
    final size = (sizeCode ?? 0).toString().padLeft(2, '0');
    final product = (productIndex + 1).toString().padLeft(2, '0');

    final base12 = '$prefix$store$category$color$size$product';
    return generateEan13FromBase(base12);
  }
}