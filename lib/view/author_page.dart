import 'package:flutter/material.dart';
import 'package:biblioteca/service/open_library_service.dart';

class AuthorPage extends StatefulWidget {
  const AuthorPage(this.autor, {super.key});

  final String autor;

  @override
  State<AuthorPage> createState() => _AuthorPageState();
}

class _AuthorPageState extends State<AuthorPage> {
  final apiService = OpenLibraryService();
  Future<Map<String, dynamic>>? _pesquisa;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: const Text('Livros do autor'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: widget.autor == 'Autor não informado'
              ? const Center(
                  child: Text('Este livro não possui autor informado.'),
                )
              : FutureBuilder<Map<String, dynamic>>(
                  future: _pesquisa ??= apiService.buscaLivros(widget.autor),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                      case ConnectionState.none:
                        return const Center(child: CircularProgressIndicator());
                      default:
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Não foi possível buscar os livros. Verifique sua conexão e tente novamente.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        } else {
                          return exibeResultado(context, snapshot);
                        }
                    }
                  },
                ),
        ),
      ),
    );
  }

  Widget exibeResultado(
    BuildContext context,
    AsyncSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List livros = snapshot.data?['docs'] ?? [];
    if (livros.isEmpty) {
      return const Center(child: Text('Nenhum livro encontrado.'));
    }
    return ListView.builder(
      itemCount: livros.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> livro = livros[index];
        final String ano =
            livro['first_publish_year']?.toString() ?? 'Ano não informado';
        final capa = livro['cover_i'];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 65,
                  height: 95,
                  child: capa == null
                      ? const Icon(Icons.book, size: 48, color: Colors.brown)
                      : Image.network(
                          'https://covers.openlibrary.org/b/id/$capa-M.jpg?default=false',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.book,
                                size: 48,
                                color: Colors.brown,
                              ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        livro['title'] ?? 'Título não informado',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(ano),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
