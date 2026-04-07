class AdminApiException implements Exception {
  const AdminApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
