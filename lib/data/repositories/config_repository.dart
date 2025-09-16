import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

class PricingConfig {
  PricingConfig({
    required this.priceId,
    required this.priceCents,
    required this.currency,
    this.checkoutBaseUrl,
  });
  final String priceId;
  final int priceCents;
  final String currency;
  final String? checkoutBaseUrl; // e.g. https://yourapp.web.app
}

final pricingConfigProvider = FutureProvider<PricingConfig?>((ref) async {
  final fs = ref.watch(firestoreProvider);
  final doc = await fs.collection('config').doc('membership_pricing').get();
  if (!doc.exists) return null;
  final data = doc.data() ?? {};
  final priceId = data['priceId'] as String?;
  final priceCents = (data['priceCents'] as num?)?.toInt();
  final currency = data['currency'] as String? ?? 'eur';
  final checkoutBaseUrl = data['checkoutBaseUrl'] as String?; // optional
  if (priceId == null || priceCents == null) return null;
  return PricingConfig(
    priceId: priceId,
    priceCents: priceCents,
    currency: currency,
    checkoutBaseUrl: checkoutBaseUrl,
  );
});
