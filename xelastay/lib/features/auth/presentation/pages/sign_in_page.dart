import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../widgets/volcano_mark.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _isRegistering = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_isRegistering) {
      await widget.controller.createAccount(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        phone: _phone.text.trim(),
      );
    } else {
      await widget.controller.login(_email.text.trim(), _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = widget.controller.isLoading;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
              children: [
                const _BrandHeader(),
                const SizedBox(height: 32),
                Text(
                  _isRegistering
                      ? 'Tu próxima historia empieza aquí.'
                      : 'Qué bueno tenerte de vuelta.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 30,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isRegistering
                      ? 'Crea tu cuenta para explorar Xela y sus alrededores.'
                      : 'Encuentra un lugar con buenas referencias, en el corazón de Xela.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isRegistering) ...[
                            _field(
                              _name,
                              label: 'Nombre',
                              icon: Icons.person_outline,
                              validator: _required,
                            ),
                            const SizedBox(height: 14),
                          ],
                          _field(
                            _email,
                            label: 'Correo electrónico',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: _emailValidator,
                          ),
                          if (_isRegistering) ...[
                            const SizedBox(height: 14),
                            _field(
                              _phone,
                              label: 'Teléfono (opcional)',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscurePassword,
                            autofillHints: _isRegistering
                                ? const [AutofillHints.newPassword]
                                : const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Escribe tu contraseña';
                              }
                              if (_isRegistering && value.length < 6) {
                                return 'Usa al menos 6 caracteres';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                          if (widget.controller.errorMessage != null) ...[
                            const SizedBox(height: 14),
                            _ErrorBanner(message: widget.controller.errorMessage!),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: isBusy ? null : _submit,
                            child: isBusy
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isRegistering
                                        ? 'Crear cuenta'
                                        : 'Iniciar sesión',
                                  ),
                          ),
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: isBusy
                                ? null
                                : () => setState(() {
                                    _isRegistering = !_isRegistering;
                                    widget.controller.clearError();
                                  }),
                            child: Text(
                              _isRegistering
                                  ? 'Ya tengo una cuenta · Iniciar sesión'
                                  : 'Soy nuevo en XelaStay · Crear cuenta',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Explora primero. Inicia sesión cuando quieras guardar, conversar o solicitar una estadía.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Iterable<String>? autofillHints,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    autofillHints: autofillHints,
    textInputAction: TextInputAction.next,
    validator: validator,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Este campo es obligatorio' : null;

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Escribe tu correo electrónico';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Revisa el formato de tu correo';
    }
    return null;
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(17),
        ),
        alignment: Alignment.center,
        child: const VolcanoMark(size: 42),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('XelaStay', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          const Text(
            'QUETZALTENANGO, GUATEMALA',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ],
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFF8E9EA), borderRadius: BorderRadius.circular(12)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: AppColors.red, size: 19),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: AppColors.ink, height: 1.35))),
      ],
    ),
  );
}
