/// Unified exception type used across all repository and notifier layers.
///
/// Using a sealed class means every call site is forced by the compiler
/// to handle all failure cases — no silent unhandled exceptions.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Supabase returned a non-success response.
final class ServerException extends AppException {
  const ServerException(super.message);
}

/// A required resource was not found (404 equivalent).
final class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

/// The user is not authenticated when authentication is required.
final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'User is not authenticated.']);
}

/// Input failed validation before reaching the repository.
final class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Device-level error (no internet, storage failure, etc.).
final class LocalException extends AppException {
  const LocalException(super.message);
}