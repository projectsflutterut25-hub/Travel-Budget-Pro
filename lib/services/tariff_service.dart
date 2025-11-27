import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tariff_config.dart';

class TariffService {
  final _doc = FirebaseFirestore.instance.collection('config').doc('pricing');

  Future<TariffConfig> getConfigOnce() async {
    final snap = await _doc.get();
    if (!snap.exists) {
      // valores por defecto en MXN si aún no hay doc
      final defaultConfig = TariffConfig(
        baseFare: 50,
        pricePerKm: 10,
        pricePerMinute: 2,
        pricePerToll: 35,
        fuelCostPerKm: 0.15,
        extraSedan: 0,
        extraSUV: 50,
        extraVan: 80,
        extraPickup: 40,
        currency: 'MXN',
      );
      await _doc.set(defaultConfig.toMap());
      return defaultConfig;
    }
    return TariffConfig.fromMap(snap.data()!);
  }

  Stream<TariffConfig> watchConfig() {
    return _doc.snapshots().map(
      (snap) => TariffConfig.fromMap(snap.data() ?? {}),
    );
  }

  Future<void> saveConfig(TariffConfig config) async {
    await _doc.set(config.toMap(), SetOptions(merge: true));
  }
}
