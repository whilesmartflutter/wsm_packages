import 'package:test/test.dart';
import 'package:wsm_core/wsm_core.dart';

void main() {
  group('Failure', () {
    test('value equality', () {
      expect(const Failure.serverError('boom'), const ServerFailure('boom'));
      expect(const Failure.networkError(), const NetworkFailure());
      expect(
        const Failure.serverError('a'),
        isNot(const Failure.serverError('b')),
      );
    });

    test('hasError is false only for the none sentinel', () {
      expect(const Failure.none().hasError, isFalse);
      expect(const Failure.unknownError().hasError, isTrue);
      expect(const Failure.serverError('x').hasError, isTrue);
    });

    test('validation failure carries field errors', () {
      const failure = Failure.validationError(
        'invalid',
        errors: [
          FieldError(field: 'email', messages: ['taken']),
        ],
      );
      expect((failure as ValidationFailure).errors.single.field, 'email');
    });
  });

  group('FieldError.getErrors', () {
    test('parses map-shaped errors', () {
      final errors = FieldError.getErrors({
        'message': 'Validation failed',
        'errors': {
          'email': ['is taken', 'is invalid'],
          'name': ['is required'],
        },
      });
      expect(errors, hasLength(2));
      expect(errors.first.field, 'email');
      expect(errors.first.messages, ['is taken', 'is invalid']);
    });

    test('parses list-shaped errors', () {
      final errors = FieldError.getErrors({
        'errors': [
          {
            'email': ['is taken'],
          },
          {
            'name': ['is required'],
          },
        ],
      });
      expect(errors, hasLength(2));
      expect(errors.last.field, 'name');
    });

    test('falls back to top-level message', () {
      final errors = FieldError.getErrors({'message': 'Nope'});
      expect(errors.single.field, 'message');
      expect(errors.single.messages, ['Nope']);
    });

    test('returns empty for non-map data', () {
      expect(FieldError.getErrors('oops'), isEmpty);
      expect(FieldError.getErrors(null), isEmpty);
    });
  });
}
