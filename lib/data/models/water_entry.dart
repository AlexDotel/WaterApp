import '../../core/constants/drink_types.dart';

class WaterEntry {
  const WaterEntry({
    required this.id,
    required this.timestamp,
    required this.volumeMl,
    this.drinkType = DrinkType.water,
  });

  final String id;
  final DateTime timestamp;
  final int volumeMl;
  final DrinkType drinkType;

  /// Hidratación efectiva en ml aplicando el factor de la bebida.
  int get effectiveMl => (volumeMl * drinkType.hydrationFactor).round();

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'volumeMl': volumeMl,
        'drinkType': drinkType.id,
      };

  factory WaterEntry.fromJson(Map<String, dynamic> json) {
    return WaterEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      volumeMl: (json['volumeMl'] as num).toInt(),
      drinkType: DrinkType.fromId(json['drinkType'] as String?),
    );
  }
}
