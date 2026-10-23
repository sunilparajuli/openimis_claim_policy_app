import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/data/remote/api/providers/http_service_provider.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/http_service.dart';
import 'package:openimis_claim_policy_app/feature/login/models/login_request_model.dart';

final openImisAuthRepositoryProvider = Provider<OpenImisAuthRepository>(
  (ref) => OpenImisAuthRepository(ref.watch(httpServiceProvider)),
);

class OpenImisAuthResult {
  const OpenImisAuthResult({required this.token, required this.expiresOn});

  final String token;
  final int expiresOn;
}

/// Authentication contract used by both openIMIS Java mobile applications.
class OpenImisAuthRepository {
  OpenImisAuthRepository(this._http);

  final HttpService _http;

  Future<OpenImisAuthResult> login(LoginRequestModel request) async {
    final response = await _http.post<Map<String, dynamic>>(
      'api/api_fhir_r4/login/',
      data: {'username': request.userName.trim(), 'password': request.password},
    );
    final body = response.data;
    final token = body?['token']?.toString();
    final expiresOn = body?['exp'];
    if (token == null || token.isEmpty || expiresOn is! num) {
      throw const FormatException('Invalid login response from openIMIS.');
    }
    return OpenImisAuthResult(token: token, expiresOn: expiresOn.toInt());
  }
}
