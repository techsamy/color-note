import 'package:huenote/core/network/api_client.dart';
import 'package:huenote/features/auth/domain/account.dart';

typedef SignInResult = ({String token, Account account, bool isNew});

class AuthApi {
  new(this._api, {required this.deviceId, this.deviceName});

  final ApiClient _api;
  final String deviceId;
  final String? deviceName;

  Map<String, dynamic> get _device => {
    'device_uuid': deviceId,
    'device_name': ?deviceName,
  };

  Future<SignInResult> register(
    String email,
    String password, {
    String? name,
  }) => _signIn('/auth/register', {
    'email': email,
    'password': password,
    'name': ?name,
  });

  Future<SignInResult> login(String email, String password) =>
      _signIn('/auth/login', {'email': email, 'password': password});

  Future<SignInResult> google(String idToken) =>
      _signIn('/auth/google', {'id_token': idToken});

  Future<SignInResult> _signIn(String path, Map<String, dynamic> body) async {
    final res = await _api.post(path, {...body, ..._device});
    final data = res['data'] as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      account: Account.fromJson(data['user'] as Map<String, dynamic>),
      isNew: data['is_new'] as bool? ?? false,
    );
  }

  Future<void> logout() => _api.post('/auth/logout');

  Future<void> forgotPassword(String email) =>
      _api.post('/auth/password/forgot', {'email': email});

  /// Password for email accounts; Google-only accounts send an ID token.
  Future<void> deleteAccount({String? password, String? idToken}) =>
      _api.delete('/me', {'password': ?password, 'id_token': ?idToken});
}
