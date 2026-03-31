import '../core/http/api_client.dart';
import '../core/http/api_response.dart';
import '../models/transaction.dart';

class TransactionService {
  final _client = ApiClient();

  /// 新增流水
  Future<ApiResponse<CreateTransactionResult>> create({
    required int accountId,
    required int categoryId,
    required String type,
    required int amount,
    String? note,
    required String transactionAt,
  }) async {
    final body = <String, dynamic>{
      'account_id': accountId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'transaction_at': transactionAt,
    };
    if (note != null && note.isNotEmpty) body['note'] = note;

    final resp = await _client.post('/api/transactions', data: body);
    return ApiResponse.fromJson(
      resp.data as Map<String, dynamic>,
      (data) => CreateTransactionResult.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 流水列表 (分页+筛选)
  Future<ApiResponse<PageData<Transaction>>> list({
    int page = 1,
    int pageSize = 20,
    int? accountId,
    int? categoryId,
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (accountId != null) params['account_id'] = accountId;
    if (categoryId != null) params['category_id'] = categoryId;
    if (type != null) params['type'] = type;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final resp = await _client.get('/api/transactions', queryParameters: params);
    return ApiResponse.fromJson(
      resp.data as Map<String, dynamic>,
      (data) => PageData.fromJson(
        data as Map<String, dynamic>,
        Transaction.fromJson,
      ),
    );
  }

  /// 流水详情
  Future<ApiResponse<Transaction>> detail(int id) async {
    final resp = await _client.get('/api/transactions/$id');
    return ApiResponse.fromJson(
      resp.data as Map<String, dynamic>,
      (data) => Transaction.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 编辑流水
  Future<ApiResponse<void>> update(int id, {
    int? accountId,
    int? categoryId,
    String? type,
    int? amount,
    String? note,
    String? transactionAt,
    required int version,
  }) async {
    final body = <String, dynamic>{'version': version};
    if (accountId != null) body['account_id'] = accountId;
    if (categoryId != null) body['category_id'] = categoryId;
    if (type != null) body['type'] = type;
    if (amount != null) body['amount'] = amount;
    if (note != null) body['note'] = note;
    if (transactionAt != null) body['transaction_at'] = transactionAt;

    final resp = await _client.put('/api/transactions/$id', data: body);
    return ApiResponse.fromJson(resp.data as Map<String, dynamic>, null);
  }

  /// 删除流水 (软删除)
  Future<ApiResponse<void>> delete(int id, {required int version}) async {
    final resp = await _client.delete(
      '/api/transactions/$id',
      queryParameters: {'version': version},
    );
    return ApiResponse.fromJson(resp.data as Map<String, dynamic>, null);
  }
}

