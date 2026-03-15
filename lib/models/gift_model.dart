class Gift {
  final String id;
  final String name;
  final String icon;
  final int cost;

  Gift({
    required this.id,
    required this.name,
    required this.icon,
    required this.cost,
  });

  factory Gift.fromMap(Map<String, dynamic> data) {
    return Gift(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      icon: data['icon'] ?? '',
      cost: data['cost'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'cost': cost,
    };
  }
}
