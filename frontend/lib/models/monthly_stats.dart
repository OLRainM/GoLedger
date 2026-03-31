class MonthlyStats {
  final int year;
  final int month;
  final int totalIncome;
  final int totalExpense;
  final int balance;

  MonthlyStats({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      year: json['year'] as int,
      month: json['month'] as int,
      totalIncome: json['total_income'] as int,
      totalExpense: json['total_expense'] as int,
      balance: json['balance'] as int,
    );
  }
}

