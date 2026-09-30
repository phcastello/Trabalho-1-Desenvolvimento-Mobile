import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:biblioteca/service/giphy_service.dart';
import 'package:biblioteca/service/open_library_service.dart';
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
        await tester.tap(find.text('Livro'));
        await tester.pumpAndSettle();
        expect(find.text('Nenhum GIF relacionado encontrado.'), findsOneWidget);
        await tester.ensureVisible(find.text('Outro GIF'));
        await tester.tap(find.text('Outro GIF'));
        await tester.pumpAndSettle();
        expect(offsets, ['0', '1']);
        await tester.tap(find.byTooltip('Voltar'));
        await tester.pumpAndSettle();
        expect(buscas, 1);
        expect(find.text('Livro'), findsOneWidget);
        await tester.tap(find.text('Limpar'));
        await tester.pumpAndSettle();
        expect(find.text('Livro'), findsNothing);
      },
      () => MockClient((request) async {
        if (request.url.host == 'openlibrary.org') {
          buscas++;
          expect(request.url.queryParameters['q'], 'Livro');
          return http.Response('{"docs":[{"title":"Livro"}]}', 200);
        }
        expect(request.url.queryParameters['q'], 'Livro');
        offsets.add(request.url.queryParameters['offset']!);
        return http.Response('{"data":[],"pagination":{"total_count":0}}', 200);
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
