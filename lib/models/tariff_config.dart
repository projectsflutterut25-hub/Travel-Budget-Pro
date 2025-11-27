class TariffConfig {
  final double baseFare;
  final double pricePerKm;
  final double pricePerMinute;
  final double pricePerToll;
  final double fuelCostPerKm;
  final double extraSedan;
  final double extraSUV;
  final double extraVan;
  final double extraPickup;
  final String currency;

  TariffConfig({
    required this.baseFare,
    required this.pricePerKm,
    required this.pricePerMinute,
    required this.pricePerToll,
    required this.fuelCostPerKm,
    required this.extraSedan,
    required this.extraSUV,
    required this.extraVan,
    required this.extraPickup,
    required this.currency,
  });

  factory TariffConfig.fromMap(Map<String, dynamic> data) {
    double read(String key, double def) => (data[key] ?? def).toDouble();

    return TariffConfig(
      baseFare: read('baseFare', 50),
      pricePerKm: read('pricePerKm', 10),
      pricePerMinute: read('pricePerMinute', 2),
      pricePerToll: read('pricePerToll', 35),
      fuelCostPerKm: read('fuelCostPerKm', 0.15),
      extraSedan: read('extraSedan', 0),
      extraSUV: read('extraSUV', 50),
      extraVan: read('extraVan', 80),
      extraPickup: read('extraPickup', 40),
      currency: data['currency'] ?? 'MXN',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baseFare': baseFare,
      'pricePerKm': pricePerKm,
      'pricePerMinute': pricePerMinute,
      'pricePerToll': pricePerToll,
      'fuelCostPerKm': fuelCostPerKm,
      'extraSedan': extraSedan,
      'extraSUV': extraSUV,
      'extraVan': extraVan,
      'extraPickup': extraPickup,
      'currency': currency,
    };
  }
}
