import 'package:hive/hive.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 4)
class CustomerModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String phone;
  @HiveField(3)
  final int points;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.points,
  });
}
