import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/become_host.dart';
import 'features/auth/domain/usecases/register_account.dart';
import 'features/auth/domain/usecases/restore_session.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/hosts/data/datasources/hosts_remote_data_source.dart';
import 'features/hosts/data/repositories/hosts_repository_impl.dart';
import 'features/hosts/domain/usecases/create_host_stay.dart';
import 'features/stays/data/datasources/stays_remote_data_source.dart';
import 'features/stays/data/repositories/stays_repository_impl.dart';
import 'features/stays/domain/usecases/get_public_stays.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();
  final apiClient = ApiClient();
  final localAuth = AuthLocalDataSource(storage);
  final authRemote = AuthRemoteDataSource(apiClient);
  final authRepository = AuthRepositoryImpl(remote: authRemote, local: localAuth);
  final authController = AuthController(
    signIn: SignIn(authRepository),
    register: RegisterAccount(authRepository),
    restoreSession: RestoreSession(authRepository),
    becomeHost: BecomeHost(authRepository),
    signOut: SignOut(authRepository),
  );
  final hostsRemote = HostsRemoteDataSource(apiClient, localAuth.readToken);
  final hostsRepository = HostsRepositoryImpl(hostsRemote);
  final staysRemote = StaysRemoteDataSource(apiClient, localAuth.readToken);
  final staysRepository = StaysRepositoryImpl(staysRemote);

  runApp(XelaStayApp(
    authController: authController,
    createHostStay: CreateHostStay(hostsRepository),
    getPublicStays: GetPublicStays(staysRepository),
  ));
}
