import 'package:flutter/material.dart';
import 'package:biblioteca/view/gif_page.dart';
import 'package:biblioteca/view/author_page.dart';

class BookPage extends StatelessWidget {
  const BookPage(this.livro, {super.key});

  final Map<String, dynamic> livro;

  @override
  Widget build(BuildContext context) {
    final List autores = livro['author_name'] ?? [];
    final String autor = autores.isEmpty
        ? 'Autor não informado'
        : autores.join(', ');
    final String ano =
        livro['first_publish_year']?.toString() ?? 'Ano não informado';
    final capa = livro['cover_i'];
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: const Text('Livro selecionado'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 200,
                child: capa == null
                    ? const Icon(Icons.book, size: 100, color: Colors.brown)
                    : Image.network(
                        'https://covers.openlibrary.org/b/id/$capa-M.jpg?default=false',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.book,
                              size: 100,
                              color: Colors.brown,
                            ),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                livro['title'] ?? 'Título não informado',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(autor, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Primeira publicação: $ano', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GifPage(livro)),
                  );
                },
                child: const Text('Ver GIF relacionado'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final String primeiroAutor = autores.isEmpty
                      ? 'Autor não informado'
                      : autores[0];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuthorPage(primeiroAutor),
                    ),
                  );
                },
                child: const Text('Ver livros do autor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
