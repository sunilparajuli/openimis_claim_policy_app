import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/data/remote/api/error/api_error.dart';

void main() {
  test('server failures use the required generic action message', () {
    const error = ApiError(
      type: ApiErrorType.server,
      message: 'sensitive backend detail',
      statusCode: 500,
    );
    expect(error.userMessage, serverActionErrorMessage);
    expect(error.userMessage, isNot(contains('sensitive backend detail')));
  });

  test('business/client errors preserve their specific message', () {
    const error = ApiError(
      type: ApiErrorType.client,
      message: 'Chèque CC240523 déjà utilisé',
      statusCode: 400,
    );
    expect(error.userMessage, 'Chèque CC240523 déjà utilisé');
  });
}
