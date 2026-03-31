// 后端统一响应模型

class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({required this.code, required this.message, this.data});

  bool get isSuccess => code == 0;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'] != null && fromData != null
          ? fromData(json['data'])
          : json['data'] as T?,
    );
  }
}

/// 分页响应
class PageData<T> {
  final List<T> list;
  final int total;
  final int page;
  final int pageSize;

  PageData({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PageData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    return PageData(
      list: (json['list'] as List<dynamic>)
          .map((e) => itemFromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
    );
  }
}

