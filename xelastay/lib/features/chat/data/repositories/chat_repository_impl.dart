import '../../domain/entities/mensaje.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({ChatLocalDataSource? localDataSource})
    : _local = localDataSource ?? ChatLocalDataSource();

  static const largoMaximo = 500;

  final ChatLocalDataSource _local;

  @override
  Future<List<Mensaje>> mensajesDe(int reservaId) =>
      _local.mensajesDe(reservaId);

  @override
  Future<Mensaje> enviar({
    required int reservaId,
    required AutorMensaje autor,
    required String texto,
  }) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) {
      throw const ChatException('Escribe un mensaje antes de enviarlo.');
    }
    if (limpio.length > largoMaximo) {
      throw const ChatException(
        'El mensaje puede tener hasta $largoMaximo caracteres.',
      );
    }
    return _local.enviar(reservaId: reservaId, autor: autor, texto: limpio);
  }
}
