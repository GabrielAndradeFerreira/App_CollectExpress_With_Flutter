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

## Reciclagem (parceiros e coleta de material)

Quem tem material reciclável faz uma **sinalização**; um **parceiro de reciclagem** aprovado agenda a retirada e a API
gera o termo de coleta em PDF, com três assinaturas e um código de autenticação. Rode `npm run migrate:reciclagem` na API antes.

- **Tela pública** (`/reciclagem`, item RECICLAGEM do menu): explica o fluxo e leva a sinalizar, cadastrar-se como
  parceiro ou entrar.
- **Cliente e fornecedor:** *Sinalizar material* (tipos de material, descrição, quantidade estimada, endereço, janela de data
  e hora e observações), com o aceite do termo. O cliente assina na tela; o fornecedor usa a assinatura cadastrada da
  empresa. Em *Minhas sinalizações* acompanham a coleta agendada, baixam o termo, conversam com o parceiro e podem cancelar
  até 24 horas depois do agendamento.
- **Parceiro:** cadastro com CNPJ, responsável, endereço e materiais (conta fica pendente até um admin aprovar). Depois de
  aprovado tem *Início* (resumo e o que falta cadastrar), *Sinalizações* (vitrine com filtro por material, distância e
  período; o endereço completo só aparece depois do agendamento), *Coletas* (termo em PDF, chat, concluir com peso real,
  cancelar), *Conversas* e *Perfil* (dados, materiais, área de atuação no mapa, assinatura e disponibilidade).
- **Admin:** *Parceiros* lista os cadastros de parceiros de reciclagem com aprovar, recusar, suspender e reativar; as
  conversas de coleta aparecem na aba *Coletas* (só leitura).
- O parceiro só agenda com 24 horas ou mais de antecedência e dentro da janela, para quem entrega ter tempo de desistir.

## Acessibilidade

- **Tamanho do texto:** menu lateral > *Tamanho do texto* (Normal, Grande 125% ou Muito grande 150%). Soma-se ao tamanho
  que o sistema já aplica, vale em todas as telas na hora e fica gravado no aparelho (`shared_preferences`).
  As telas principais e as de reciclagem são testadas a 150% em celular de 360 px, sem overflow.
- **Leitor de tela e toque:** botões só com ícone têm descrição (`tooltip`), as bolhas do chat são lidas inteiras (quem
  escreveu, texto, hora e situação), as bolhas de não lidas são lidas por extenso, imagens têm descrição e os botões de
  menu, quantidade e senha têm alvo de pelo menos 48 px.

## Erros, logs e conexão

- **Mensagens:** erro de validação diz o que conferir ("Dados inválidos. Confira: data de início, endereço."), e respostas sem texto (502/503/429) ganham uma mensagem clara.
- **Conexão instável:** consultas (GET) que falham por timeout, queda de rede ou 502/503/504 são repetidas até 2 vezes (2 s e 5 s). O timeout subiu de 15 para 30 s e o app "acorda" a API ao abrir, porque o plano gratuito do Render hiberna. POST nunca é repetido.
- **Sessão:** ao sair pelo menu ou pelas configurações do admin, o app volta para a tela inicial. Se a sessão expirar sozinha, o app também volta para o início e avisa.
- **Rede de segurança:** erro que nenhuma tela tratou vira um aviso na tela e um registro; sem isso a tela ficava parada sem explicação.
- **Logs:** o app envia para `POST /api/logs/app` os erros mostrados ao usuário (com a tela), telas que não carregaram, falhas de rede, exceções, overflows de layout e sessão expirada. Máximo de 40 por execução, sem repetição em 30 s. Veja "Logs de erros" no README da API.
- **Perfil da loja do fornecedor:** agora lê e grava dados reais (nome, telefone, horário e taxa de entrega); antes mostrava dados de exemplo e o botão só fingia salvar.

## Estrutura

```
lib/
  core/
    models/        modelos da API (usuário, caçamba, carrinho, aluguel...)
    network/       ApiClient (Dio), configuração, erros e interceptor de autenticação
    navigation/    rotas nomeadas
    services/      serviços externos (ViaCEP)
    accessibility/ tamanho do texto escolhido pela pessoa
    theme/ widgets/ responsive/ utils/
  features/
    auth/          login, cadastro e sessão
    admin_auth/    login e cadastro do administrador
    cacambas/      catálogo e detalhe
    pedidos/       carrinho, agendamento, confirmação e acompanhamento
    perfil/        perfil e endereços do cliente
    admin/         painéis do fornecedor e do administrador
    reciclagem/    sinalização, agendamento, coletas e perfil do parceiro de reciclagem
    parceiros_reciclagem/  informações sobre os materiais recicláveis
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
| Integradas à API | login (cliente, fornecedor, parceiro e admin), cadastros de cliente, fornecedor, parceiro de reciclagem e admin, catálogo e detalhe, carrinho, agendamento e checkout, acompanhamento e avaliação, perfil do cliente, painel, caçambas e pedidos do fornecedor, painel geral do admin, conversas, sinalização e coletas de reciclagem, painel e perfil do parceiro, gestão de parceiros |
| Pendentes | cadastro de caçamba, busca por CEP na página inicial, relatório financeiro, configurações, perfil da loja |
| Demonstrativas | informações sobre os materiais (`/modelos`) |

## Autores

Gabriel Andrade Ferreira, Leonardo Dias dos Santos e Pedro Henrique Batista dos Santos. Orientação: profa. Edilma Bindá Hungria Melo.
