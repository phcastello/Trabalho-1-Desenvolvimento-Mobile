import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:biblioteca/service/giphy_service.dart';
import 'package:biblioteca/service/open_library_service.dart';
import 'package:biblioteca/view/author_page.dart';
import 'package:biblioteca/view/book_page.dart';
import 'package:biblioteca/view/gif_page.dart';
import 'package:biblioteca/view/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Open Library preserva acentos e caracteres especiais na pesquisa', () {
    const termo = 'José & literatura + #livros?';
    return http.runWithClient(
      () async {
        final dados = await OpenLibraryService().buscaLivros(termo);
        expect(dados['docs'][0]['title'], 'Livro');
      },
      () => MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.host, 'openlibrary.org');
        expect(request.url.path, '/search.json');
        expect(request.url.queryParameters['q'], termo);
        expect(request.url.queryParameters['limit'], '10');
        return http.Response(
          json.encode({
            'docs': [
              {'title': 'Livro'},
            ],
          }),
          200,
        );
      }),
    );
  });

  test('Giphy envia o título do livro e o offset', () {
    return http.runWithClient(
      () async {
        final dados = await GiphyService().buscaGif('The Lord of the Rings', 1);
        expect(dados['data'], isEmpty);
      },
      () => MockClient((request) async {
        expect(request.url.host, 'api.giphy.com');
        expect(request.url.path, '/v1/gifs/search');
        expect(request.url.queryParameters['q'], 'The Lord of the Rings');
        expect(request.url.queryParameters['offset'], '1');
        expect(request.url.queryParameters['limit'], '1');
        expect(request.url.queryParameters['api_key'], isNotEmpty);
        return http.Response('{"data":[]}', 200);
      }),
    );
  });

  test('Os dois services rejeitam respostas HTTP sem sucesso', () {
    return http.runWithClient(() async {
      await expectLater(
        OpenLibraryService().buscaLivros('Livro'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        GiphyService().buscaGif('Livro', 0),
        throwsA(isA<Exception>()),
      );
    }, () => MockClient((request) async => http.Response('Falha', 503)));
  });

  test('Os dois services tratam SocketException', () {
    return http.runWithClient(
      () async {
        final erro = throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('conexão com a internet'),
          ),
        );
        await expectLater(OpenLibraryService().buscaLivros('Livro'), erro);
        await expectLater(GiphyService().buscaGif('Livro', 0), erro);
      },
      () =>
          MockClient((request) async => throw const SocketException('Offline')),
    );
  });

  testWidgets('Pesquisa vazia por botão e Enter não faz requisições', (tester) {
    return http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: HomePage()));
        await tester.enterText(find.byType(TextField), '   ');
        await tester.tap(find.text('Pesquisar'));
        await tester.pump();
        expect(
          find.text('Digite um livro, autor ou assunto para pesquisar.'),
          findsOneWidget,
        );
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();
        await tester.tap(find.text('Limpar'));
        await tester.pump();
        expect(
          find.text('Digite um livro, autor ou assunto para pesquisar.'),
          findsNothing,
        );
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
      },
      () => MockClient((request) async {
        fail('Uma pesquisa vazia não deve consultar a API.');
      }),
    );
  });

  testWidgets('Pesquisa por Enter, dados opcionais, outro GIF e voltar', (
    tester,
  ) {
    int buscas = 0;
    final offsets = <String>[];
    return http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: HomePage()));
        await tester.enterText(find.byType(TextField), '  Livro  ');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        expect(find.text('Autor não informado'), findsOneWidget);
        expect(find.text('Ano não informado'), findsOneWidget);
        expect(find.byIcon(Icons.book), findsOneWidget);
        expect(buscas, 1);
        final detalhes = find.widgetWithText(ElevatedButton, 'Ver detalhes');
        expect(detalhes, findsOneWidget);
        await tester.tap(detalhes);
        await tester.pumpAndSettle();
        expect(find.byType(BookPage), findsOneWidget);
        expect(find.text('Autor não informado'), findsOneWidget);
        expect(
          find.text('Primeira publicação: Ano não informado'),
          findsOneWidget,
        );
        expect(offsets, isEmpty);
        final livrosAutor = find.widgetWithText(
          ElevatedButton,
          'Ver livros do autor',
        );
        expect(livrosAutor, findsOneWidget);
        await tester.ensureVisible(livrosAutor);
        await tester.tap(livrosAutor);
        await tester.pumpAndSettle();
        expect(find.byType(AuthorPage), findsOneWidget);
        expect(
          find.text('Este livro não possui autor informado.'),
          findsOneWidget,
        );
        expect(buscas, 1);
        expect(offsets, isEmpty);
        await tester.tap(find.byTooltip('Voltar'));
        await tester.pumpAndSettle();
        expect(find.byType(BookPage), findsOneWidget);
        final verGif = find.widgetWithText(
          ElevatedButton,
          'Ver GIF relacionado',
        );
        expect(verGif, findsOneWidget);
        await tester.ensureVisible(verGif);
        await tester.tap(verGif);
        await tester.pumpAndSettle();
        expect(find.byType(GifPage), findsOneWidget);
        expect(
          tester.widget<GifPage>(find.byType(GifPage)).livro['title'],
          'Livro',
        );
        expect(find.text('Nenhum GIF relacionado encontrado.'), findsOneWidget);
        await tester.ensureVisible(find.text('Outro GIF'));
        await tester.tap(find.text('Outro GIF'));
        await tester.pumpAndSettle();
        expect(offsets, ['0', '1']);
        await tester.tap(find.text('Outro GIF'));
        await tester.pumpAndSettle();
        expect(offsets, ['0', '1', '0']);
        tester.element(find.byType(GifPage)).markNeedsBuild();
        await tester.pumpAndSettle();
        expect(offsets, ['0', '1', '0']);
        await tester.tap(find.byTooltip('Voltar'));
        await tester.pumpAndSettle();
        expect(find.byType(BookPage), findsOneWidget);
        await tester.tap(find.byTooltip('Voltar'));
        await tester.pumpAndSettle();
        expect(buscas, 1);
        expect(find.text('Livro'), findsOneWidget);
        await tester.tap(find.text('Limpar'));
        await tester.pumpAndSettle();
        expect(find.text('Livro'), findsNothing);
        expect(find.text('Ver detalhes'), findsNothing);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
      },
      () => MockClient((request) async {
        if (request.url.host == 'openlibrary.org') {
          buscas++;
          expect(request.url.queryParameters['q'], 'Livro');
          return http.Response('{"docs":[{"title":"Livro"}]}', 200);
        }
        expect(request.url.queryParameters['q'], 'Livro');
        offsets.add(request.url.queryParameters['offset']!);
        return http.Response('{"data":[],"pagination":{"total_count":2}}', 200);
      }),
    );
  });

  testWidgets('Ver livros do autor consulta somente o primeiro autor', (
    tester,
  ) {
    int buscas = 0;
    const livro = {
      'title': 'Livro selecionado',
      'author_name': ['José & Silva', 'Outro autor'],
      'first_publish_year': 2001,
    };
    return http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: BookPage(livro)));
        expect(find.text('José & Silva, Outro autor'), findsOneWidget);
        expect(find.text('Primeira publicação: 2001'), findsOneWidget);
        expect(buscas, 0);
        final botao = find.widgetWithText(
          ElevatedButton,
          'Ver livros do autor',
        );
        await tester.ensureVisible(botao);
        await tester.tap(botao);
        await tester.pumpAndSettle();
        expect(find.byType(AuthorPage), findsOneWidget);
        expect(
          tester.widget<AuthorPage>(find.byType(AuthorPage)).autor,
          'José & Silva',
        );
        expect(find.text('Outro livro'), findsOneWidget);
        expect(find.text('1998'), findsOneWidget);
        expect(find.text('Ano não informado'), findsOneWidget);
        expect(find.byIcon(Icons.book), findsNWidgets(2));
        expect(find.text('Ver detalhes'), findsNothing);
        tester.element(find.byType(AuthorPage)).markNeedsBuild();
        await tester.pumpAndSettle();
        expect(buscas, 1);
        await tester.tap(find.byTooltip('Voltar'));
        await tester.pumpAndSettle();
        expect(find.byType(BookPage), findsOneWidget);
        expect(buscas, 1);
      },
      () => MockClient((request) async {
        buscas++;
        expect(request.url.host, 'openlibrary.org');
        expect(request.url.queryParameters['q'], 'José & Silva');
        return http.Response(
          '{"docs":[{"title":"Outro livro","first_publish_year":1998},'
          '{"title":"Livro sem ano"}]}',
          200,
        );
      }),
    );
  });

  testWidgets('Lista de autores vazia também navega sem consultar a API', (
    tester,
  ) {
    return http.runWithClient(
      () async {
        await tester.pumpWidget(
          const MaterialApp(
            home: BookPage({'title': 'Livro', 'author_name': []}),
          ),
        );
        expect(find.text('Autor não informado'), findsOneWidget);
        final botao = find.widgetWithText(
          ElevatedButton,
          'Ver livros do autor',
        );
        await tester.ensureVisible(botao);
        await tester.tap(botao);
        await tester.pumpAndSettle();
        expect(find.byType(AuthorPage), findsOneWidget);
        expect(
          find.text('Este livro não possui autor informado.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
      () => MockClient((request) async {
        fail('Livro sem autor não deve consultar a API.');
      }),
    );
  });

  testWidgets('AuthorPage mostra carregamento e ausência de resultados', (
    tester,
  ) {
    final resposta = Completer<http.Response>();
    return http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: AuthorPage('Autor')));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      resposta.complete(http.Response('{"docs":[]}', 200));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum livro encontrado.'), findsOneWidget);
    }, () => MockClient((request) => resposta.future));
  });

  testWidgets('AuthorPage mostra erro de requisição', (tester) {
    return http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: AuthorPage('Autor')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Não foi possível buscar os livros.'),
        findsOneWidget,
      );
    }, () => MockClient((request) async => http.Response('Falha', 503)));
  });

  testWidgets('GifPage mostra carregamento e erro de requisição', (tester) {
    final resposta = Completer<http.Response>();
    return http.runWithClient(() async {
      await tester.pumpWidget(
        const MaterialApp(home: GifPage({'title': 'Livro'})),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      resposta.complete(http.Response('Falha', 503));
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível carregar o GIF.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Outro GIF'), findsOneWidget);
    }, () => MockClient((request) => resposta.future));
  });

  testWidgets('GifPage exibe a URL do GIF com Image.network', (tester) {
    const url = 'https://media.giphy.com/media/livro/200.gif';
    return http.runWithClient(
      () async {
        await tester.pumpWidget(
          const MaterialApp(home: GifPage({'title': 'Livro'})),
        );
        await tester.pumpAndSettle();
        final imagem = tester.widget<Image>(find.byType(Image));
        expect((imagem.image as NetworkImage).url, url);
        expect(imagem.height, 240);
        expect(find.text('Powered by GIPHY'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      () => MockClient((request) async {
        expect(request.url.queryParameters['q'], 'Livro');
        return http.Response(
          json.encode({
            'data': [
              {
                'images': {
                  'fixed_height': {'url': url},
                },
              },
            ],
            'pagination': {'total_count': 1},
          }),
          200,
        );
      }),
    );
  });

  testWidgets('Sem resultados e erro de requisição aparecem na tela', (tester) {
    int buscas = 0;
    return http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: HomePage()));
        await tester.enterText(find.byType(TextField), 'Livro');
        await tester.tap(find.text('Pesquisar'));
        await tester.pumpAndSettle();
        expect(find.text('Nenhum livro encontrado.'), findsOneWidget);
        await tester.tap(find.text('Pesquisar'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Não foi possível buscar os livros.'),
          findsOneWidget,
        );
      },
      () => MockClient((request) async {
        buscas++;
        return buscas == 1
            ? http.Response('{"docs":[]}', 200)
            : http.Response('Falha', 503);
      }),
    );
  });

  testWidgets('Limpar durante o carregamento descarta o resultado antigo', (
    tester,
  ) {
    final resposta = Completer<http.Response>();
    return http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.enterText(find.byType(TextField), 'Livro');
      await tester.tap(find.text('Pesquisar'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Limpar'));
      await tester.pump();
      resposta.complete(
        http.Response('{"docs":[{"title":"Livro antigo"}]}', 200),
      );
      await tester.pumpAndSettle();
      expect(find.text('Livro antigo'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    }, () => MockClient((request) => resposta.future));
  });
}
