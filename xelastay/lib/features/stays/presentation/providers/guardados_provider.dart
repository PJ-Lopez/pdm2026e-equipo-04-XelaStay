import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_constants.dart';
import '../../data/models/saved_stay_model.dart';
import '../../domain/entities/saved_stay.dart';

final selectedFilterProvider = StateProvider<String>((ref) => 'Todos (12)');

final savedStaysApiProvider = FutureProvider.autoDispose<List<SavedStay>>((
  ref,
) async {
  final client = http.Client();
  try {
    final response = await client
        .get(
          Uri.parse('${ApiConstants.baseUrl}/stays'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => SavedStayModel.fromJson(item)).toList();
    } else {
      throw Exception(
        'Respuesta ${response.statusCode}: Error en el servidor.',
      );
    }
  } catch (e) {
    throw Exception(
      'No pudimos conectar con xela-stayAPI en Docker en el puerto 3000.',
    );
  } finally {
    client.close();
  }
});
