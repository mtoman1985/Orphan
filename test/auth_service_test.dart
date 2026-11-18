import 'package:flutter_test/flutter_test.dart';
import 'package:orphan/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startup authentication requires a fresh login', () async {
    SharedPreferences.setMockInitialValues({
      'auth_user': '{"id":"saved-user"}',
      'auth_login_time': DateTime.now().toIso8601String(),
    });

    final auth = AuthService();
    await auth.init(restoreSession: false);

    final preferences = await SharedPreferences.getInstance();
    expect(auth.isAuthenticated, isFalse);
    expect(preferences.containsKey('auth_user'), isFalse);
    expect(preferences.containsKey('auth_login_time'), isFalse);

    await auth.logout();
  });
}
