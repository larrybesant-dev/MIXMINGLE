// lib/models/subscription_plan_model.dart

class SubscriptionPlanModel {
  final String id;
  final String name;
  final double price;
  final List<String> features;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.features,
  });
}
