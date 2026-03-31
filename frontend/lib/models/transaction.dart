class Transaction {
  final int id;
  final int userId;
  final int accountId;
  final int categoryId;
  final String type;
  final int amount;
  final String? note;
  final String transactionAt;
  final String sourceType;
  final int version;
  final String createdAt;
  final String updatedAt;
  final String? categoryName;
  final String? accountName;

  Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.note,
    required this.transactionAt,
    required this.sourceType,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.accountName,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      accountId: json['account_id'] as int,
      categoryId: json['category_id'] as int,
      type: json['type'] as String,
      amount: json['amount'] as int,
      note: json['note'] as String?,
      transactionAt: json['transaction_at'] as String,
      sourceType: json['source_type'] as String,
      version: json['version'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      categoryName: json['category_name'] as String?,
      accountName: json['account_name'] as String?,
    );
  }
}

/// 新增流水的返回值
class CreateTransactionResult {
  final int id;
  final int accountId;
  final int newBalance;
  final int newVersion;

  CreateTransactionResult({
    required this.id,
    required this.accountId,
    required this.newBalance,
    required this.newVersion,
  });

  factory CreateTransactionResult.fromJson(Map<String, dynamic> json) {
    return CreateTransactionResult(
      id: json['id'] as int,
      accountId: json['account_id'] as int,
      newBalance: json['new_balance'] as int,
      newVersion: json['new_version'] as int,
    );
  }
}

