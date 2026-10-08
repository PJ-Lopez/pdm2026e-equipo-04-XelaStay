import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/become_host.dart';
import '../../domain/usecases/register_account.dart';
import '../../domain/usecases/restore_session.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required SignIn signIn,
    required RegisterAccount register,
    required RestoreSession restoreSession,
    required BecomeHost becomeHost,
    required SignOut signOut,
  }) : _signIn = signIn,
       _register = register,
       _restoreSession = restoreSession,
       _becomeHost = becomeHost,
       _signOut = signOut;

  final SignIn _signIn;
  final RegisterAccount _register;
  final RestoreSession _restoreSession;
  final BecomeHost _becomeHost;
  final SignOut _signOut;

  AppUser? user;
  bool isLoading = true;
  String? errorMessage;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();
    try {
      user = await _restoreSession();
    } catch (error) {
      errorMessage = _friendlyMessage(error);
      user = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) => _perform(() async {
    final session = await _signIn(email, password);
    user = session.user;
  });

  Future<bool> createAccount({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) => _perform(() async {
    final session = await _register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
    user = session.user;
  });

  Future<bool> activateHostMode() => _perform(() async {
    user = await _becomeHost();
  });

  Future<void> logout() async {
    errorMessage = null;
    try {
      await _signOut();
      user = null;
    } catch (error) {
      errorMessage = _friendlyMessage(error);
    }
    notifyListeners();
  }

  Future<bool> _perform(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      errorMessage = _friendlyMessage(error);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  String _friendlyMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) return 'Correo o contraseña incorrectos.';
      if (error.statusCode == 403) {
        return 'Esta cuenta no está disponible. Contacta a soporte.';
      }
      if (error.statusCode == 409) {
        return 'Ya existe una cuenta con ese correo electrónico.';
      }
      if (error.statusCode == 0) {
        return 'No pudimos conectar. Revisa tu conexión e inténtalo de nuevo.';
      }
      return 'No se pudo completar la solicitud. Revisa tus datos e inténtalo de nuevo.';
    }
    if (error is FormatException) {
      return 'No pudimos leer la información. Inténtalo de nuevo.';
    }
    return 'Ocurrió un problema. Inténtalo de nuevo.';
  }

}
