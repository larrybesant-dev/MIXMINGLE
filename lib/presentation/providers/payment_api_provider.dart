import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/payment_api.dart';

final paymentApiProvider = Provider<PaymentApi>((ref) => PaymentApi());
