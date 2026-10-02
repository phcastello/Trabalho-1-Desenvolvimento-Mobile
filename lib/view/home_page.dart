import 'package:flutter/material.dart';
import 'package:biblioteca/service/open_library_service.dart';
import 'package:biblioteca/view/book_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _campoController = TextEditingController();
  final apiService = OpenLibraryService();
  String _termo = '';
  String? _mensagem;
  Future<Map<String, dynamic>>? _pesquisa;

  void _pesquisar() {
    final valor = _campoController.text.trim();
    if (valor.isEmpty) {
      setState(() {
        _mensagem = 'Digite um livro, autor ou assunto para pesquisar.';
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _termo = valor;
      _mensagem = null;
      _pesquisa = null;
    });
  }

  void _limpar() {
    _campoController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _termo = '';
      _mensagem = null;
      _pesquisa = null;
    });
  }

  @override
  void dispose() {
    _campoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: const Text('Biblioteca'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _campoController,
                decoration: const InputDecoration(
                  labelText: 'Digite um livro, autor ou assunto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => _pesquisar(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pesquisar,
                      child: const Text('Pesquisar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _limpar,
                      child: const Text('Limpar'),
                    ),
                  ),
                ],
              ),
              if (_mensagem != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _mensagem!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: _termo.isEmpty
                    ? const Center(
                        child: Text(
                          'Pesquise livros e use Ver detalhes para abrir um resultado.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : FutureBuilder<Map<String, dynamic>>(
                        // Inicia aqui e reutiliza a Future nas reconstruções.
                        future: _pesquisa ??= apiService.buscaLivros(_termo),
                        builder: (context, snapshot) {
                          switch (snapshot.connectionState) {
                            case ConnectionState.waiting:
                            case ConnectionState.none:
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
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
            ],
          ),
        ),
      ),
    );
  }

  Widget exibeResultado(
    BuildContext context,
    AsyncSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List livros = snapshot.data?["docs"] ?? [];
    if (livros.isEmpty) {
      return const Center(child: Text('Nenhum livro encontrado.'));
    }
    return ListView.builder(
      itemCount: livros.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> livro = livros[index];
        final List autores = livro['author_name'] ?? [];
        final String autor = autores.isEmpty
            ? 'Autor não informado'
            : autores.join(', ');
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
                      const SizedBox(height: 6),
                      Text(autor),
                      const SizedBox(height: 4),
                      Text(ano),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookPage(livro),
                            ),
                          );
                        },
                        child: const Text('Ver detalhes'),
                      ),
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
