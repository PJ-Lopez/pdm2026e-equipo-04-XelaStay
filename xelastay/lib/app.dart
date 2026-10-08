import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/domain/entities/app_user.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/profile_page.dart';
import 'features/auth/presentation/pages/sign_in_page.dart';
import 'features/hosts/domain/usecases/create_host_stay.dart';
import 'features/hosts/presentation/pages/create_host_stay_page.dart';
import 'features/hosts/presentation/pages/host_dashboard_page.dart';
import 'features/stays/domain/usecases/get_public_stays.dart';
import 'features/stays/presentation/pages/home_screen.dart';

class XelaStayApp extends StatefulWidget {
  const XelaStayApp({
    super.key,
    required this.authController,
    required this.createHostStay,
    required this.getPublicStays,
  });

  final AuthController authController;
  final CreateHostStay createHostStay;
  final GetPublicStays getPublicStays;

  @override
  State<XelaStayApp> createState() => _XelaStayAppState();
}

class _XelaStayAppState extends State<XelaStayApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.authController.initialize();
  }

  @override
  void dispose() {
    widget.authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.authController,
    builder: (context, _) => MaterialApp(
      title: 'XelaStay',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: buildAppTheme(),
      home: _homeForState(),
    ),
  );

  Widget _homeForState() {
    final auth = widget.authController;
    if (auth.isLoading && auth.user == null) return const _SplashPage();
    final user = auth.user;
    if (user == null) return SignInPage(controller: auth);
    return _GuestAppShell(
      user: user,
      authController: auth,
      getPublicStays: widget.getPublicStays,
      onOpenHosts: () => _navigatorKey.currentState?.push<void>(
        MaterialPageRoute<void>(builder: (_) => _hostDashboard(user)),
      ),
    );
  }

  Widget _hostDashboard(AppUser user) => HostDashboardPage(
    user: user,
    authController: widget.authController,
    createStay: (context) async {
      await _navigatorKey.currentState?.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CreateHostStayPage(createHostStay: widget.createHostStay),
        ),
      );
    },
  );
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.landscape_outlined, size: 48, color: Color(0xFF244D82)),
          SizedBox(height: 16),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

class _GuestAppShell extends StatefulWidget {
  const _GuestAppShell({
    required this.user,
    required this.authController,
    required this.getPublicStays,
    required this.onOpenHosts,
  });

  final AppUser user;
  final AuthController authController;
  final GetPublicStays getPublicStays;
  final VoidCallback onOpenHosts;

  @override
  State<_GuestAppShell> createState() => _GuestAppShellState();
}

class _GuestAppShellState extends State<_GuestAppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _selectedIndex,
      children: [
        HomeScreen(
          user: widget.user,
          getPublicStays: widget.getPublicStays,
          onOpenProfile: () => setState(() => _selectedIndex = 1),
        ),
        ProfilePage(
          user: widget.user,
          authController: widget.authController,
          onOpenHosts: widget.onOpenHosts,
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Explorar',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    ),
  );
}
