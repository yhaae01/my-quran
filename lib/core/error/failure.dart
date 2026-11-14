enum FailureKind { network, timeout, server, parse, notFound, unknown }

/// A user-presentable error raised by the data layer and carried through the
/// domain layer without leaking HTTP/Hive specifics into the UI.
class Failure implements Exception {
  const Failure(this.message, {this.kind = FailureKind.unknown, this.cause});

  final String message;
  final FailureKind kind;
  final Object? cause;

  @override
  String toString() => message;
}
