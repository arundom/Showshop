import 'package:flutter/foundation.dart';

/// Simple in-memory admin session for privileged actions.
class AdminAuthProvider extends ChangeNotifier {
  AdminAuthProvider({String? adminPasscode})
    : _adminPasscode = (adminPasscode ?? _defaultAdminPasscode).trim();

  static const _defaultAdminPasscode = String.fromEnvironment(
    'ADMIN_PASSCODE',
    defaultValue: 'change-me',
  );

  final String _adminPasscode;
  bool _isAdmin = false;

  bool get isAdmin => _isAdmin;

  bool login(String passcode) {
    if (passcode.trim() != _adminPasscode) {
      return false;
    }

    _isAdmin = true;
    notifyListeners();
    return true;
  }

  void logout() {
    if (!_isAdmin) return;
    _isAdmin = false;
    notifyListeners();
  }
}
