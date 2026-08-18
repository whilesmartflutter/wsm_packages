import 'package:equatable/equatable.dart';

/// One field's validation errors, as returned by the API's 422 payloads.
class FieldError extends Equatable {
  const FieldError({required this.field, required this.messages});

  factory FieldError.fromJson(Map<String, dynamic> json) => FieldError(
        field: json['field'] as String,
        messages: List<String>.from(json['messages'] as List<dynamic>),
      );

  final String field;
  final List<String> messages;

  Map<String, dynamic> toJson() => {'field': field, 'messages': messages};

  /// Parses the `errors` key of an API error body. Supports both shapes the
  /// backends emit: a map of `field -> [messages]`, or a list of such maps.
  /// Falls back to a single `message` key when no structured errors exist.
  static List<FieldError> getErrors(dynamic data) {
    if (data is! Map) return const [];

    final errors = data['errors'];

    if (errors is Map) {
      try {
        return errors.entries
            .map(
              (e) => FieldError(
                field: e.key.toString(),
                messages: List<String>.from(e.value as List<dynamic>),
              ),
            )
            .toList();
      } catch (_) {
        // Fall through to the message fallback below.
      }
    }

    if (errors is List) {
      try {
        return List<Map<String, dynamic>>.from(errors)
            .expand(
              (e) => e.entries.map(
                (entry) => FieldError(
                  field: entry.key,
                  messages: List<String>.from(entry.value as List<dynamic>),
                ),
              ),
            )
            .toList();
      } catch (_) {
        // Fall through to the message fallback below.
      }
    }

    final message = data['message'];
    if (message is String) {
      return [
        FieldError(field: 'message', messages: [message]),
      ];
    }

    return const [];
  }

  @override
  List<Object?> get props => [field, messages];
}
