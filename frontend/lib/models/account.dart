class Account {
  final int id;
  final int userId;
  final String name;
  final String type;
  final int balance;
  final int initialBalance;
  final int isActive;
  final int version;
  final String createdAt;
  final String updatedAt;

  Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    required this.initialBalance,
    required this.isActive,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get active => isActive == 1;

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      balance: json['balance'] as int,
      initialBalance: json['initial_balance'] as int,
      isActive: json['is_active'] as int,
      version: json['version'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

