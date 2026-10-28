import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    } else if (Platform.isAndroid) {
      // 10.0.2.2 es el alias de localhost para el emulador de Android hacia tu PC con Docker
      return 'http://10.0.2.2:3000/api/v1';
    } else {
      return 'http://localhost:3000/api/v1';
    }
  }
}
