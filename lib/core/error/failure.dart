import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// A failure caused by a local database or storage error.
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

/// A failure caused by invalid user input or data that failed validation.
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// A failure caused when a requested resource does not exist.
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message);
}

/// A catch-all failure for unexpected errors.
class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super(message);
}
