import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class OpenLibraryService {
  Future<Map<String, dynamic>> buscaLivros(String valor) async {
    try {
      final uri = Uri.parse(
        'https://openlibrary.org/search.json'
        '?q=${Uri.encodeQueryComponent(valor)}&limit=10',
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
