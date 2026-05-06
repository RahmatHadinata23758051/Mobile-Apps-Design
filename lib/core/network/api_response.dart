class ApiResponse<T> {
  final bool status;
  final String message;
  final T? data;

  const ApiResponse({required this.status, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw)? parser,
  ) {
    final rawData = json['data'];

    return ApiResponse<T>(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      data: parser != null ? parser(rawData) : rawData as T?,
    );
  }
}
