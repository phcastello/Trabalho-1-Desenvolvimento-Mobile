import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class GiphyService {
  final String _token = 'J9TjXCe5zt8iMG5IHl2Z0IQ0yIsTkQi4';

  Future<Map<String, dynamic>> buscaGif(String valor, int offset) async {
    try {
      final uri = Uri.parse(
        'https://api.giphy.com/v1/gifs/search'
        '?api_key=$_token&q=${Uri.encodeQueryComponent(valor)}'
        '&limit=1&offset=$offset&rating=g',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Erro de conexão com a internet');
    } catch (e) {
      rethrow;
    }
  }
}
