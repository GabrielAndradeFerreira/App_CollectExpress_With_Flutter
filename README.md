# CollectExpress – aplicativo Flutter

Aplicativo multiplataforma (Web e Android) do CollectExpress, plataforma de locação de caçambas que reúne consumidores, fornecedores de caçambas e administradores. O app consome a [CollectExpressAPI](https://github.com/CollectOrganization/CollectExpressAPI) (Node.js, Express e PostgreSQL).

Projeto acadêmico do Curso Superior de Tecnologia em Desenvolvimento de Software Multiplataforma da Fatec Mauá.

## Tecnologias

| Uso | Pacote |
| :- | :- |
| Interface | Flutter 3 e Dart 3 |
| Estado e injeção de dependências | flutter_riverpod |
| Cliente HTTP da API | dio |
| Armazenamento dos tokens | flutter_secure_storage |
| URL da API pelo arquivo `.env` | flutter_dotenv |
| Consulta de CEP (ViaCEP) | http |
| Tipografia | google_fonts |
| Mapa da área de atendimento (OpenStreetMap, gratuito) | flutter_map e latlong2 |
| Links externos (atribuição do mapa) | url_launcher |

## Como rodar

Pré-requisitos: Flutter SDK (stable) e a API rodando, local ou publicada.

```bash
flutter pub get

# Sem --dart-define, a URL da API vem do API_URL do arquivo .env
# (versionado com http://localhost:3001/api)
flutter run -d chrome

# Android (emulador): o localhost da máquina é 10.0.2.2
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:3001/api
```

Para gerar as versões de distribuição:

```bash
flutter build web --dart-define=API_URL=https://sua-api/api
flutter build apk --dart-define=API_URL=https://sua-api/api
```

O nome antigo `API_BASE_URL` também é aceito no `--dart-define`.

### APK de teste no celular Android

O celular não enxerga o `localhost` do computador. Gere o APK apontando para a API publicada (https):

```bash
flutter build apk --release --dart-define=API_URL=https://sua-api.onrender.com/api
```

O arquivo sai em `build/app/outputs/flutter-apk/app-release.apk`. Para instalar, copie-o para o celular e
permita "instalar apps de fontes desconhecidas". O APK usa a chave de depuração, então serve só para testes.
A permissão `INTERNET` já está no manifesto principal.

## Área de atendimento (cerca virtual)

- **Fornecedor:** em *Perfil da loja > Área de atendimento* marca o centro no mapa (toque ou CEP da base) e
  escolhe o raio de 1 a 200 km. Ao entrar no painel sem área ou sem assinatura, aparece um aviso (uma vez por sessão).
- **Cliente:** o catálogo pede o CEP de entrega (ou usa o primeiro endereço salvo) e lista só as caçambas de
  fornecedores que atendem o local. O botão *Ver caçambas fora da minha área* mostra as demais, sem aluguel:
  só dá para ver o que o fornecedor oferece.
- O mapa usa tiles públicos do OpenStreetMap, com a atribuição exigida. Para uso intenso, troque o provedor.
- A API valida tudo de novo no checkout (`OUT_OF_SERVICE_AREA`). Rode `npm run migrate:area` na API antes.

## Conversas (chat)

Nova aba **Conversas** nos três perfis, com bolha de não lidas na aba e em cada conversa:

- **Cliente:** um chat por pedido com a empresa ("Conversar com a empresa" em Meus pedidos e no acompanhamento) e
  chamados com o suporte (botão *Novo chamado*; um aberto por vez, pedido opcional).
- **Caçambeiro:** um chat por pedido recebido ("Conversar com o cliente") e a conversa com o suporte.
- **Admin:** abas *Chamados*, *Fornecedores* e *Pedidos* (esta só leitura), busca, filtro de denunciadas e botão
  para encerrar chamados. "Configurações" saiu da barra e foi para o menu lateral.

Na conversa: voltar, nome do contato e menu (⋮) com *Ver dados do pedido* e *Denunciar conversa* (avisa os admins por e-mail).
O app atualiza a conversa aberta a cada 5 s, a lista a cada 15 s e as bolhas a cada 30 s. Telefones não aparecem mais
entre as partes. A API envia um e-mail a quem deixa mensagem sem ler por 8 horas. Rode `npm run migrate:chat` na API antes.
## Estrutura

```
lib/
  core/
    models/        modelos da API (usuário, caçamba, carrinho, aluguel...)
    network/       ApiClient (Dio), configuração, erros e interceptor de autenticação
    navigation/    rotas nomeadas
    services/      serviços externos (ViaCEP)
    theme/ widgets/ responsive/ utils/
  features/
    auth/          login, cadastro e sessão
    admin_auth/    login e cadastro do administrador
    cacambas/      catálogo e detalhe
    pedidos/       carrinho, agendamento, confirmação e acompanhamento
    perfil/        perfil e endereços do cliente
    admin/         painéis do fornecedor e do administrador
    parceiros_reciclagem/  telas demonstrativas de reciclagem
    institucional/ página "Saiba mais"
test/              testes de modelos, ApiClient, repositórios e telas
tool/              scripts que geram as evidências de teste
```

Cada funcionalidade separa a camada de dados (`data/`: repositórios e providers que chamam a API) da camada de apresentação (`presentation/`: páginas e widgets). As telas leem os dados pelos providers do Riverpod, e os repositórios usam um único `ApiClient`.

## Autenticação

O login devolve um access token (JWT) e, nas versões da API que o fornecem, um refresh token. Os dois ficam no `flutter_secure_storage`. O `AuthInterceptor` coloca o token nas requisições e, quando a API responde 401, renova a sessão em `POST /auth/refresh` e repete a requisição uma vez. Se a renovação falhar, a sessão é encerrada.

## Testes

```bash
flutter analyze
flutter test
```

A saída completa da última execução está em [test-results/flutter-test.txt](test-results/flutter-test.txt).

`dart run tool/cep_evidence.dart` consulta o ViaCEP com o mesmo serviço usado nos formulários e grava o resultado em [test-results/cep-evidence.txt](test-results/cep-evidence.txt).

## Situação das telas

| Situação | Telas |
| :- | :- |
| Integradas à API | login (cliente, fornecedor e admin), cadastro de cliente, cadastro de admin, catálogo e detalhe, carrinho, agendamento e checkout, acompanhamento e avaliação, perfil do cliente, painel, caçambas e pedidos do fornecedor, painel geral do admin |
| Pendentes | envio dos cadastros de fornecedor e de parceiro de reciclagem, cadastro de caçamba, busca por CEP na página inicial, gestão de usuários e de parceiros, relatório financeiro, configurações, perfil da loja |
| Demonstrativas | telas de reciclagem (materiais, parceiros e coletas) |

## Autores

Gabriel Andrade Ferreira, Leonardo Dias dos Santos e Pedro Henrique Batista dos Santos. Orientação: profa. Edilma Bindá Hungria Melo.
