class Category {
  final int id;
  final int userId;
  final String name;
  final String type;
  final int isSystem;
  final int isActive;
  final String createdAt;
  final String updatedAt;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.isSystem,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get system => isSystem == 1;
  bool get active => isActive == 1;
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      isSystem: json['is_system'] as int,
      isActive: json['is_active'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

