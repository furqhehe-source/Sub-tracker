import 'package:hive/hive.dart';

part 'subscription.g.dart';

@HiveType(typeId: 0)
class Subscription extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double cost;

  @HiveField(3)
  final DateTime billingDate;

  @HiveField(4)
  final String cycle;

  @HiveField(5)
  final bool isFreeTrial;

  @HiveField(6)
  final bool isPaused;

  @HiveField(7)
  final String? brandKey;

  Subscription({
    required this.id,
    required this.name,
    required this.cost,
    required this.billingDate,
    required this.cycle,
    this.isFreeTrial = false,
    this.isPaused = false,
    this.brandKey,
  });

  double get monthlyCost => cycle == 'Yearly' ? cost / 12.0 : cost;

  bool isTrialActive([DateTime? now]) {
    if (!isFreeTrial) return false;
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final billingDay = DateTime(
      billingDate.year,
      billingDate.month,
      billingDate.day,
    );
    return billingDay.isAfter(today);
  }

  Subscription copyWith({
    String? id,
    String? name,
    double? cost,
    DateTime? billingDate,
    String? cycle,
    bool? isFreeTrial,
    bool? isPaused,
    String? brandKey,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      cost: cost ?? this.cost,
      billingDate: billingDate ?? this.billingDate,
      cycle: cycle ?? this.cycle,
      isFreeTrial: isFreeTrial ?? this.isFreeTrial,
      isPaused: isPaused ?? this.isPaused,
      brandKey: brandKey ?? this.brandKey,
    );
  }
}
