import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/host_stay.dart';
import '../../domain/usecases/create_host_stay.dart';

class CreateHostStayPage extends StatefulWidget {
  const CreateHostStayPage({super.key, required this.createHostStay});
  final CreateHostStay createHostStay;

  @override
  State<CreateHostStayPage> createState() => _CreateHostStayPageState();
}

class _CreateHostStayPageState extends State<CreateHostStayPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _address = TextEditingController();
  final _zone = TextEditingController(text: 'Quetzaltenango');
  final _reference = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _capacity = TextEditingController(text: '2');
  final _bedrooms = TextEditingController(text: '1');
  final _beds = TextEditingController(text: '1');
  final _bathrooms = TextEditingController(text: '1');
  final _rules = TextEditingController();
  String _propertyType = 'apartment';
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _title, _description, _price, _address, _zone, _reference,
      _latitude, _longitude, _capacity, _bedrooms, _beds, _bathrooms, _rules,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final stay = await widget.createHostStay(HostStayDraft(
        title: _title.text.trim(),
        description: _description.text.trim(),
        propertyType: _propertyType,
        capacity: int.parse(_capacity.text),
        bedrooms: int.parse(_bedrooms.text),
        beds: int.parse(_beds.text),
        bathrooms: int.parse(_bathrooms.text),
        priceInQuetzales: double.parse(_price.text.replaceAll(',', '.')),
        latitude: double.parse(_latitude.text.replaceAll(',', '.')),
        longitude: double.parse(_longitude.text.replaceAll(',', '.')),
        address: _address.text.trim(),
        zone: _zone.text.trim(),
        localReference: _reference.text.trim(),
        rules: _rules.text.trim().isEmpty ? null : _rules.text.trim(),
      ));
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => _StaySubmittedPage(stay: stay)),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Registrar alojamiento')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text('Cuéntanos de tu espacio', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 27)),
            const SizedBox(height: 8),
            const Text('La ubicación y la referencia ayudan a verificarlo y a que los huéspedes lo encuentren.'),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Tu alojamiento'),
            _textField(_title, 'Nombre del alojamiento', required: true, maxLength: 70),
            const SizedBox(height: 12),
            _textField(_description, 'Descripción', required: true, maxLines: 4, maxLength: 1000),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _propertyType,
              decoration: const InputDecoration(labelText: 'Tipo de espacio'),
              items: const [
                DropdownMenuItem(value: 'apartment', child: Text('Apartamento')),
                DropdownMenuItem(value: 'house', child: Text('Casa')),
                DropdownMenuItem(value: 'room', child: Text('Habitación')),
                DropdownMenuItem(value: 'cabin', child: Text('Cabaña')),
              ],
              onChanged: (value) => setState(() => _propertyType = value ?? 'apartment'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _numberField(_capacity, 'Huéspedes', min: 1)),
              const SizedBox(width: 10),
              Expanded(child: _numberField(_bedrooms, 'Habitaciones', min: 0)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _numberField(_beds, 'Camas', min: 1)),
              const SizedBox(width: 10),
              Expanded(child: _numberField(_bathrooms, 'Baños', min: 1)),
            ]),
            const SizedBox(height: 12),
            _textField(_price, 'Precio por noche (Q)', required: true, keyboard: const TextInputType.numberWithOptions(decimal: true), prefix: 'Q '),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Ubicación en Xela'),
            _textField(_address, 'Dirección', required: true),
            const SizedBox(height: 12),
            _textField(_zone, 'Zona o barrio', required: true),
            const SizedBox(height: 12),
            _textField(_reference, 'Referencia local', required: true, helper: 'Ej. a una cuadra del Parque Central'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _coordinateField(_latitude, 'Latitud', min: -90, max: 90)),
              const SizedBox(width: 10),
              Expanded(child: _coordinateField(_longitude, 'Longitud', min: -180, max: 180)),
            ]),
            const SizedBox(height: 8),
            const Text('Usa coordenadas decimales del pin del mapa. La app agregará selección visual de ubicación en una siguiente iteración.', style: TextStyle(color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Reglas (opcional)'),
            _textField(_rules, 'Información para huéspedes', maxLines: 3, maxLength: 500),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8E9EA), borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: const TextStyle(color: AppColors.ink)),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enviar a revisión'),
            ),
            const SizedBox(height: 12),
            const Text('Tu alojamiento quedará pendiente de verificación y no aparecerá en el catálogo hasta ser aprobado.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, height: 1.4)),
          ],
        ),
      ),
    ),
  );

  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboard,
    String? helper,
    String? prefix,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    maxLines: maxLines,
    maxLength: maxLength,
    validator: required ? (value) => value == null || value.trim().isEmpty ? 'Este campo es obligatorio' : null : null,
    decoration: InputDecoration(labelText: label, helperText: helper, prefixText: prefix),
  );

  Widget _numberField(TextEditingController controller, String label, {required int min}) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: (value) {
      final parsed = int.tryParse(value ?? '');
      if (parsed == null || parsed < min) return 'Mínimo $min';
      return null;
    },
    decoration: InputDecoration(labelText: label),
  );

  Widget _coordinateField(TextEditingController controller, String label, {required double min, required double max}) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
    validator: (value) {
      final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
      if (parsed == null || parsed < min || parsed > max) return 'Coordenada inválida';
      return null;
    },
    decoration: InputDecoration(labelText: label),
  );
}

class _StaySubmittedPage extends StatelessWidget {
  const _StaySubmittedPage({required this.stay});
  final HostStay stay;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(color: AppColors.blueSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.fact_check_outlined, size: 42, color: AppColors.blue),
                ),
                const SizedBox(height: 24),
                Text('Recibimos tu alojamiento', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28)),
                const SizedBox(height: 12),
                Text(stay.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const Text('Está pendiente de verificación física. Te avisaremos cuando haya una actualización.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, height: 1.5)),
                const SizedBox(height: 28),
                FilledButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('Volver a anfitriones')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
