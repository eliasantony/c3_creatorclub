import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentRepository {
  PaymentRepository(this._functions);
  final FirebaseFunctions _functions;

  Future<({String paymentIntentId, String clientSecret})> createBookingIntent({
    required String roomId,
    required DateTime startAt,
    required DateTime endAt,
    required int amountCents,
    required List<int> slotIndices,
    required String yyyymmdd,
    required int openHourStart,
    String currency = 'eur',
  }) async {
    final callable = _functions.httpsCallable('createBookingPaymentIntent');
    final resp = await callable.call({
      'roomId': roomId,
      'startAt': startAt.toUtc().millisecondsSinceEpoch,
      'endAt': endAt.toUtc().millisecondsSinceEpoch,
      'amountCents': amountCents,
      'currency': currency,
      'slotIndices': slotIndices,
      'yyyymmdd': yyyymmdd,
      'openHourStart': openHourStart,
    });
    final data = Map<String, dynamic>.from(resp.data as Map);
    return (
      paymentIntentId: data['paymentIntentId'] as String,
      clientSecret: data['clientSecret'] as String,
    );
  }

  Future<String> createMembershipCheckoutSession({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final callable = _functions.httpsCallable(
      'createMembershipCheckoutSession',
    );
    final resp = await callable.call({
      'priceId': priceId,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
    });
    final data = Map<String, dynamic>.from(resp.data as Map);
    return data['url'] as String;
  }

  Future<String> createBillingPortalSession({required String returnUrl}) async {
    final callable = _functions.httpsCallable('createBillingPortalSession');
    final resp = await callable.call({'returnUrl': returnUrl});
    final data = Map<String, dynamic>.from(resp.data as Map);
    return data['url'] as String;
  }

  Future<bool> syncMembershipForUser() async {
    final callable = _functions.httpsCallable('syncMembershipForUser');
    final resp = await callable.call();
    final data = Map<String, dynamic>.from(resp.data as Map);
    return (data['found'] as bool?) ?? false;
  }

  Future<Map<String, dynamic>> cancelMembership({
    bool immediate = false,
  }) async {
    final callable = _functions.httpsCallable('cancelMembership');
    final resp = await callable.call({'immediate': immediate});
    return Map<String, dynamic>.from(resp.data as Map);
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(FirebaseFunctions.instance);
});
