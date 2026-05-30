class RentItem {
  final String deposit;
  final String monthlyRent;
  final String exclusiveArea;
  final String buildingName;
  final String district;
  final String floor;
  final String buildYear;
  final String dealDate;

  const RentItem({
    required this.deposit,
    required this.monthlyRent,
    required this.exclusiveArea,
    required this.buildingName,
    required this.district,
    required this.floor,
    required this.buildYear,
    required this.dealDate,
  });

  factory RentItem.fromJson(Map<String, dynamic> json) {
    final y = json['dealYear'] as String? ?? '';
    final m = json['dealMonth'] as String? ?? '';
    final d = json['dealDay'] as String? ?? '';
    final date = (y.isNotEmpty && m.isNotEmpty && d.isNotEmpty)
        ? '$y.$m.$d'
        : '-';
    return RentItem(
      deposit: json['deposit'] as String? ?? '-',
      monthlyRent: json['monthlyRent'] as String? ?? '-',
      exclusiveArea: json['exclusiveArea'] as String? ?? '-',
      buildingName: (json['buildingName'] as String? ?? '').trim(),
      district: (json['district'] as String? ?? '').trim(),
      floor: json['floor'] as String? ?? '-',
      buildYear: json['buildYear'] as String? ?? '-',
      dealDate: date,
    );
  }
}
