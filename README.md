# Biblioteca

Trabalho de Desenvolvimento Mobile com pesquisa de livros na Open Library e
GIFs relacionados ao título na API do Giphy. Package: `biblioteca`.

## Executar

Com Flutter instalado e um emulador Android ou celular conectado:

```sh
flutter pub get
flutter run
```

O aplicativo precisa de internet. Pesquise um livro, autor ou assunto e use
**Ver detalhes** para abrir a BookPage. Nela, **Ver GIF relacionado** abre a
GifPage, onde **Outro GIF** troca a animação, e **Ver livros do autor** abre a
AuthorPage com livros relacionados ao primeiro autor. Sem autor informado,
essa tela mostra uma mensagem e não consulta a API. **Limpar** restaura a tela
inicial. O Enter executa a mesma função do botão **Pesquisar**.

Os três botões de navegação que atendem ao requisito do trabalho são
**Ver detalhes** (HomePage → BookPage), **Ver GIF relacionado** (BookPage →
GifPage) e **Ver livros do autor** (BookPage → AuthorPage). Todos são
`ElevatedButton` e usam `Navigator.push` com `MaterialPageRoute`.
Pesquisar, Limpar, Outro GIF e voltar são funcionalidades adicionais.

Para a apresentação, uma pesquisa verificada é `The Lord of the Rings`.
Os resultados e a disponibilidade dos GIFs dependem das APIs, e alguns títulos
podem não ter GIF relacionado. Ao chegar ao último GIF disponível, o botão
recomeça pelo primeiro.

## Código e referência das aulas

- `lib/main.dart`: `runApp(MaterialApp(...))`, conforme slide 15 da apresentação
  `../Aulas/Consumo-de-API-com-Flutter-Invertexto.pptx`.
- `lib/service/`: adaptação dos slides 8–11: `Uri.parse`, `http.get`, status 200,
  `json.decode`, retorno `Map<String, dynamic>`, `SocketException` e `rethrow`.
  A chave do Giphy fica no service, como o token do exemplo didático.
- `lib/view/home_page.dart`: `StatefulWidget`, `TextField`, `setState`,
  `FutureBuilder`, função `exibeResultado` e acesso direto ao JSON, conforme
  slides 14, 22–31 e 45. Os livros estão em `docs`.
- `lib/view/book_page.dart`: recebe o Map do livro, mostra capa, título, autor
  e ano e possui os botões para abrir a GifPage e a AuthorPage.
- `lib/view/gif_page.dart`: reaproveita a lógica de GIF da antiga BookPage.
  Busca GIFs pelo título,
  incrementa `offset` com `setState` e exibe `data[0]['images']['fixed_height']['url']`
  com `Image.network`.
- `lib/view/author_page.dart`: recebe o primeiro autor como String e reutiliza
  `OpenLibraryService.buscaLivros`, `FutureBuilder` e Cards no padrão da HomePage,
  sem navegação nos resultados.
- A navegação usa `ElevatedButton`, `Navigator.push`, `MaterialPageRoute` e
  `Navigator.pop`, conforme slides 18–20, 46–47.
- Os seis PDFs foram inspecionados, incluindo código em imagens. As aulas de
  funções, coleções, exceções e classes fundamentam os métodos e Maps utilizados.
  Não há exemplo de Giphy nos sete arquivos fornecidos: seu service foi adaptado
  do exemplo Invertexto, sem acrescentar outras camadas.

Adaptações funcionais: URLs próprias das duas APIs, codificação da query com
`Uri.encodeQueryComponent`, espera máxima de 20 segundos por requisição,
mensagens amigáveis e placeholders para campos/imagens ausentes. A Future fica
guardada no estado para não repetir requisições em reconstruções da tela,
como ao abrir o teclado ou voltar de um livro. O controller é descartado em
`dispose`. A permissão `INTERNET` está no manifesto principal para funcionar
também no APK release. Não foi necessário substituir APIs depreciadas das aulas.

O `pubspec.yaml` usa `http: ^1.4.0`, como o slide 5. O Flutter resolveu a versão
compatível 1.6.0 no `pubspec.lock`. Nenhum pacote de estado foi adicionado.

## Verificações

```sh
dart format lib test
flutter analyze
flutter test
flutter build apk --release
```

Os testes verificam queries, status HTTP, falhas de conexão, pesquisa vazia,
Enter, campos opcionais, os três botões de navegação, consulta pelo primeiro
autor, livro sem autor, troca e reinício de offset e limpeza durante uma
requisição. Utilizam somente `flutter_test` e o suporte de testes do pacote `http`.

Verificação em 30/09/2026: `flutter analyze` sem apontamentos, oito testes
aprovados e APK release compilado. O APK foi instalado e executado no emulador
Android Medium Phone: pesquisa, capas, abertura do livro, GIF, Outro GIF,
voltar e Limpar conferidos com as APIs reais.

APK: `build/app/outputs/flutter-apk/app-release.apk`. A assinatura é a de debug
do template Flutter, suficiente para instalar e apresentar o trabalho.
A estrutura iOS foi gerada, mas sua compilação exige macOS e Xcode.

Referências dos endpoints: [busca Open Library](https://openlibrary.org/dev/docs/api/search),
[capas](https://openlibrary.org/dev/docs/api/covers) e
[busca Giphy](https://developers.giphy.com/docs/api/endpoint#search).
