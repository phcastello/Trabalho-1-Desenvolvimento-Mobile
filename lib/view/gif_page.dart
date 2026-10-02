import 'package:flutter/material.dart';
import 'package:biblioteca/service/giphy_service.dart';

class GifPage extends StatefulWidget {
  const GifPage(this.livro, {super.key});

  final Map<String, dynamic> livro;

  @override
  State<GifPage> createState() => _GifPageState();
}

class _GifPageState extends State<GifPage> {
  final apiService = GiphyService();
  int _offset = 0;
  int _totalGifs = 0;
  Future<Map<String, dynamic>>? _pesquisaGif;

  void _outroGif() {
    setState(() {
      _offset += 1;
      if ((_totalGifs > 0 && _offset >= _totalGifs) || _offset > 4999) {
        _offset = 0;
      }
      _pesquisaGif = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: const Text('GIF relacionado'),
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
              Text(
                widget.livro['title'] ?? 'Título não informado',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, dynamic>>(
                future: _pesquisaGif ??= apiService.buscaGif(
                  widget.livro['title'] ?? '',
                  _offset,
                ),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                    case ConnectionState.none:
                      return const SizedBox(
                        height: 240,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    default:
                      if (snapshot.hasError) {
                        return const SizedBox(
                          height: 240,
                          child: Center(
                            child: Text('Não foi possível carregar o GIF.'),
                          ),
                        );
                      } else {
                        return exibeResultado(context, snapshot);
                      }
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _outroGif,
                child: const Text('Outro GIF'),
              ),
              const SizedBox(height: 8),
              const Text('Powered by GIPHY', textAlign: TextAlign.center),
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
    final List gifs = snapshot.data?['data'] ?? [];
    _totalGifs = snapshot.data?['pagination']?['total_count'] ?? 0;
    if (gifs.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: Text('Nenhum GIF relacionado encontrado.')),
      );
    }
    final String? url = gifs[0]['images']?['fixed_height']?['url'];
    if (url == null || url.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: Text('Nenhum GIF relacionado encontrado.')),
      );
    }
    return Image.network(
      url,
      height: 240,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) => const SizedBox(
        height: 240,
        child: Center(child: Text('Não foi possível carregar o GIF.')),
      ),
    );
  }
}
