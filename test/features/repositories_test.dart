import 'package:app_collect_express_with_flutter/core/models/enums.dart';
import 'package:app_collect_express_with_flutter/core/models/aluguel.dart';
import 'package:app_collect_express_with_flutter/core/models/extensao.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_exception.dart';
import 'package:app_collect_express_with_flutter/features/admin/data/admin_repository.dart';
import 'package:app_collect_express_with_flutter/features/admin/data/fornecedor_repository.dart';
import 'package:app_collect_express_with_flutter/features/cacambas/data/catalogo_repository.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/data/carrinho_repository.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/data/pedidos_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

/// Responde sempre o mesmo `data` e guarda as requisições.
({ApiClient api, FakeApiAdapter adapter}) apiRespondendo(Object? data) {
  final adapter = FakeApiAdapter(
    (_) => FakeResponse(200, {'success': true, 'data': data}),
  );
  final api = ApiClient(
    storage: InMemoryTokenStorage(accessToken: 'jwt'),
    adapter: adapter,
  );
  return (api: api, adapter: adapter);
}

RequestOptions unica(FakeApiAdapter adapter) => adapter.requests.single;

void main() {
  test('catálogo público: filtros na query, sem token, página nova', () async {
    final fake = apiRespondendo({
      'items': [
        {'id': 'c1', 'nome': 'Caçamba 5m³', 'preco_diaria': 120},
      ],
      'pagination': {'total': 1, 'page': 2, 'per_page': 20, 'total_pages': 2},
    });

    final pagina = await CatalogoRepository(fake.api)
        .listarCacambas(pagina: 2, tipoResiduo: 'Madeira', busca: 'ca');

    final request = unica(fake.adapter);
    expect(request.path, '/cacambas');
    // A busca com menos de 3 letras é ignorada (a API recusaria).
    expect(request.queryParameters, {'page': 2, 'tipo_residuo': 'Madeira'});
    expect(bearer(request), isNull);
    expect(pagina.itens.single.precoDiaria, 120);
    expect(pagina.pagina, 2);
  });

  test('carrinho: adicionar manda o item e devolve o carrinho', () async {
    final fake = apiRespondendo({
      'id': 'k1',
      'itens': [
        {'id': 'i1', 'cacamba_id': 'c1', 'quantidade': 1, 'dias_aluguel': 5},
      ],
      'resumo': {'quantidade_itens': 1, 'total_estimado': 640},
    });

    final carrinho = await CarrinhoRepository(fake.api)
        .adicionar(cacambaId: 'c1', diasAluguel: 5);

    final request = unica(fake.adapter);
    expect('${request.method} ${request.path}', 'POST /carrinho/itens');
    expect(bearer(request), 'Bearer jwt');
    expect(sentBody(request), {
      'cacamba_id': 'c1',
      'quantidade': 1,
      'dias_aluguel': 5,
    });
    expect(carrinho.resumo.totalEstimado, 640);
  });

  test('checkout manda a data como YYYY-MM-DD, o aceite e a assinatura', () async {
    final fake = apiRespondendo({
      'id': 'p1',
      'preco_final': '640.00',
      'status_aluguel': 'AGUARDANDO_ENTREGA',
      'contrato_disponivel': true,
    });

    final pedido = await PedidosRepository(fake.api).checkout(
      enderecoId: 'e1',
      dataInicio: DateTime(2026, 11, 3, 14, 30),
      assinaturaBase64: 'data:image/png;base64,AAAA',
    );

    expect(sentBody(unica(fake.adapter)), {
      'endereco_id': 'e1',
      'data_inicio': '2026-11-03',
      'aceite_termos': true,
      'assinatura_base64': 'data:image/png;base64,AAAA',
    });
    expect(pedido.precoFinal, 640);
    expect(pedido.statusAluguel, StatusAluguel.aguardandoEntrega);
  });

  group('contrato e extensão do aluguel', () {
    test('baixa o contrato como bytes, com o token do usuário', () async {
      final fake = apiRespondendo({'qualquer': 'coisa'});

      final bytes = await PedidosRepository(fake.api).baixarContrato('p1');

      final request = unica(fake.adapter);
      expect('${request.method} ${request.path}', 'GET /alugueis/p1/contrato');
      expect(bearer(request), 'Bearer jwt');
      expect(request.responseType, ResponseType.bytes);
      expect(bytes, isNotEmpty);
    });

    test('erro ao baixar mostra a mensagem da API (bytes -> JSON)', () async {
      final adapter = FakeApiAdapter(
        (_) => const FakeResponse(404, {
          'success': false,
          'message': 'Este pedido não possui contrato.',
          'code': 'CONTRACT_NOT_FOUND',
        }),
      );
      final api = ApiClient(
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
        adapter: adapter,
      );

      await expectLater(
        PedidosRepository(api).baixarContrato('p1'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'CONTRACT_NOT_FOUND')
              .having(
                (e) => e.message,
                'message',
                'Este pedido não possui contrato.',
              ),
        ),
      );
    });

    test('solicitar extensão manda os dias e lê a resposta', () async {
      final fake = apiRespondendo({
        'id': 'x1',
        'aluguel_id': 'p1',
        'dias_adicionais': 4,
        'valor': 1200,
        'status': 'SOLICITADA',
      });

      final extensao = await PedidosRepository(fake.api).solicitarExtensao('p1', 4);

      final request = unica(fake.adapter);
      expect('${request.method} ${request.path}', 'POST /alugueis/p1/extensoes');
      expect(sentBody(request), {'dias_adicionais': 4});
      expect(extensao.status, StatusExtensao.solicitada);
      expect(extensao.valor, 1200);
    });

    test('PIX da extensão usa as rotas da extensão', () async {
      final fake = apiRespondendo({
        'id': 'pix1',
        'aluguel_id': 'p1',
        'extensao_id': 'x1',
        'status': 'PENDING',
        'status_pagamento': 'PENDENTE',
        'valor': 1200,
        'copia_cola': '000201',
      });
      final repo = PedidosRepository(fake.api);

      final pix = await repo.gerarPixExtensao('p1', 'x1');
      await repo.consultarPixExtensao('p1', 'x1');
      await repo.simularPagamentoPixExtensao('p1', 'x1');

      expect(fake.adapter.paths, [
        'POST /alugueis/p1/extensoes/x1/pix',
        'GET /alugueis/p1/extensoes/x1/pix',
        'POST /alugueis/p1/extensoes/x1/pix/simular',
      ]);
      expect(pix.extensaoId, 'x1');
      expect(pix.aguardando, isTrue);
    });

    test('fornecedor aceita ou recusa a extensão', () async {
      final fake = apiRespondendo({
        'id': 'x1',
        'aluguel_id': 'p1',
        'dias_adicionais': 4,
        'valor': 1200,
        'status': 'AGUARDANDO_PAGAMENTO',
      });
      final repo = FornecedorRepository(fake.api);

      final aceita = await repo.responderExtensao('p1', 'x1', aceitar: true);
      await repo.responderExtensao('p1', 'x1', aceitar: false);

      expect(fake.adapter.paths, [
        'PATCH /alugueis/p1/extensoes/x1',
        'PATCH /alugueis/p1/extensoes/x1',
      ]);
      expect(sentBody(fake.adapter.requests[0]), {'acao': 'ACEITAR'});
      expect(sentBody(fake.adapter.requests[1]), {'acao': 'RECUSAR'});
      expect(aceita.status, StatusExtensao.aguardandoPagamento);
    });

    test('detalhe do pedido traz contrato e resumo de extensão', () {
      final pedido = Aluguel.fromJson({
        'id': 'p1',
        'dias_aluguel': 7,
        'preco_final': 2140,
        'contrato': {'disponivel': true, 'status': 'GERADO'},
        'extensao': {
          'permite_extensao': true,
          'pode_estender': true,
          'dias_extra': 4,
          'max_dias_por_extensao': 30,
          'diaria_total': 300,
          'atual': {
            'id': 'x1',
            'aluguel_id': 'p1',
            'dias_adicionais': 4,
            'valor': 1200,
            'status': 'PAGA',
          },
        },
      });

      expect(pedido.contratoDisponivel, isTrue);
      expect(pedido.extensao!.podeEstender, isTrue);
      expect(pedido.extensao!.diasExtra, 4);
      expect(pedido.extensao!.diariaTotal, 300);
      expect(pedido.extensao!.atual!.status, StatusExtensao.paga);
    });

    test('pedido antigo, sem contrato nem extensão, continua lendo', () {
      final pedido = Aluguel.fromJson({
        'id': 'p1',
        'dias_aluguel': 7,
        'preco_final': 100,
        'contrato': null,
        'extensao': null,
      });

      expect(pedido.contratoDisponivel, isFalse);
      expect(pedido.extensao, isNull);
    });
  });

  group('fotos e assinatura', () {
    test('criar caçamba manda foto em base64 e permite_extensao', () async {
      final fake = apiRespondendo({'id': 'c1', 'nome': 'Nova'});

      await FornecedorRepository(fake.api).criarCacamba(
        nome: ' Nova ',
        tipoResiduo: 'Entulho',
        tamanhoM3: 5,
        precoDiaria: 120,
        fotoBase64: 'data:image/jpeg;base64,/9j/',
        permiteExtensao: true,
      );

      expect(sentBody(unica(fake.adapter)), {
        'nome': 'Nova',
        'tipo_residuo': 'Entulho',
        'tamanho_m3': 5,
        'preco_diaria': 120,
        'foto_base64': 'data:image/jpeg;base64,/9j/',
        'permite_extensao': true,
      });
    });

    test('criar caçamba sem foto não manda os campos de foto', () async {
      final fake = apiRespondendo({'id': 'c1', 'nome': 'Nova'});

      await FornecedorRepository(fake.api).criarCacamba(
        nome: 'Nova',
        tipoResiduo: 'Entulho',
        tamanhoM3: 5,
        precoDiaria: 120,
      );

      final corpo = sentBody(unica(fake.adapter));
      expect(corpo.containsKey('foto_base64'), isFalse);
      expect(corpo.containsKey('foto_url'), isFalse);
      expect(corpo['permite_extensao'], false);
    });

    test('atualizar caçamba troca a foto e liga a extensão', () async {
      final fake = apiRespondendo({'id': 'c1', 'permite_extensao': true});

      final cacamba = await FornecedorRepository(fake.api).atualizarCacamba(
        'c1',
        fotoBase64: 'data:image/png;base64,AAAA',
        permiteExtensao: true,
      );

      expect(sentBody(unica(fake.adapter)), {
        'foto_base64': 'data:image/png;base64,AAAA',
        'permite_extensao': true,
      });
      expect(cacamba.permiteExtensao, isTrue);
    });

    test('assinatura da empresa: salvar, ler e remover', () async {
      final fake = apiRespondendo({'tem_assinatura': true});
      final repo = FornecedorRepository(fake.api);

      await repo.salvarAssinaturaEmpresa('data:image/png;base64,AAAA');
      await repo.assinaturaEmpresa();
      await repo.removerAssinaturaEmpresa();

      expect(fake.adapter.paths, [
        'PUT /cacambeiros/me/assinatura',
        'GET /cacambeiros/me/assinatura',
        'DELETE /cacambeiros/me/assinatura',
      ]);
      expect(sentBody(fake.adapter.requests.first), {
        'assinatura_base64': 'data:image/png;base64,AAAA',
      });
    });

    test('sem assinatura cadastrada devolve null em vez de erro', () async {
      final adapter = FakeApiAdapter(
        (_) => const FakeResponse(404, {
          'success': false,
          'message': 'Nenhuma assinatura cadastrada.',
          'code': 'SIGNATURE_NOT_FOUND',
        }),
      );
      final api = ApiClient(
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
        adapter: adapter,
      );

      expect(await FornecedorRepository(api).assinaturaEmpresa(), isNull);
    });
  });

  group('fornecedor', () {
    test('atualizar caçamba envia só os campos informados', () async {
      final fake = apiRespondendo({'id': 'c1', 'nome': 'Nova'});

      await FornecedorRepository(fake.api)
          .atualizarCacamba('c1', precoDiaria: 99.9, removerFoto: true);

      expect(sentBody(unica(fake.adapter)), {
        'preco_diaria': 99.9,
        'foto_url': null,
      });
    });

    test('remover caçamba diz se apagou ou só desativou', () async {
      final apagou = apiRespondendo({'id': 'c1', 'removed': true});
      final desativou = apiRespondendo({'id': 'c1', 'disponivel': false});

      expect(
        await FornecedorRepository(apagou.api).removerCacamba('c1'),
        isTrue,
      );
      expect(
        await FornecedorRepository(desativou.api).removerCacamba('c1'),
        isFalse,
      );
    });

    test('avançar status do pedido', () async {
      final fake = apiRespondendo({'id': 'p1', 'status_aluguel': 'EM_USO'});

      final pedido = await FornecedorRepository(fake.api)
          .atualizarStatus('p1', StatusAluguel.emUso);

      final request = unica(fake.adapter);
      expect('${request.method} ${request.path}', 'PATCH /alugueis/p1/status');
      expect(sentBody(request), {'status_aluguel': 'EM_USO'});
      expect(pedido.statusAluguel, StatusAluguel.emUso);
    });
  });

  test('admin: dashboard semanal e filtro de usuários', () async {
    final fake = apiRespondendo({
      'total_usuarios': 10,
      'total_pedidos': 4,
      'receita_total': 1000,
      'lucro_plataforma': 50,
      'cacambeiros_ativos': 2,
      'pedidos_por_status': {'EM_USO': 1, 'FINALIZADO': 3},
      'pedidos_ao_longo_do_tempo': [
        {'date': '2026-10-19', 'count': 4},
      ],
    });
    final repository = AdminRepository(fake.api);

    final dashboard = await repository.dashboard(semanal: true);

    expect(unica(fake.adapter).queryParameters, {'granularity': 'weekly'});
    expect(dashboard.pedidosPorStatus[StatusAluguel.finalizado], 3);
    expect(dashboard.pedidosAoLongoDoTempo.single.data, DateTime(2026, 10, 19));

    final usuarios = apiRespondendo({
      'items': [],
      'pagination': {'total': 0, 'page': 1, 'per_page': 20, 'total_pages': 0},
    });
    await AdminRepository(usuarios.api)
        .listarUsuarios(tipoPerfil: TipoPerfil.cacambeiro, busca: 'joão');

    expect(unica(usuarios.adapter).queryParameters, {
      'page': 1,
      'tipo_perfil': 'CACAMBEIRO',
      'search': 'joão',
    });
  });
}
