import 'package:app_collect_express_with_flutter/core/models/aluguel.dart';
import 'package:app_collect_express_with_flutter/core/models/cacamba.dart';
import 'package:app_collect_express_with_flutter/core/models/carrinho.dart';
import 'package:app_collect_express_with_flutter/core/models/endereco.dart';
import 'package:app_collect_express_with_flutter/core/models/enums.dart';
import 'package:app_collect_express_with_flutter/core/models/json_parsing.dart';
import 'package:app_collect_express_with_flutter/core/models/pagina.dart';
import 'package:app_collect_express_with_flutter/core/models/usuario.dart';
import 'package:flutter_test/flutter_test.dart';

// Exemplos no formato da branch feature/flutter-integration da API.
void main() {
  test('Usuario do perfil, com DECIMAL vindo como texto', () {
    final usuario = Usuario.fromJson({
      'id': 'u1',
      'nome_completo': 'Fornecedor Teste',
      'email': 'f@teste.com',
      'tipo_perfil': 'CACAMBEIRO',
      'documento': '***.***.789-00',
      'telefone': '11999999999',
      'status': 'ATIVO',
      'criado_em': '2026-10-01T12:00:00.000Z',
      'detalhes_cacambeiro': {
        'horario_inicio': '08:00:00',
        'horario_fim': '18:00:00',
        'raio_entrega_km': '50.00',
        'taxa_entrega': '25.50',
      },
    });

    expect(usuario.tipoPerfil, TipoPerfil.cacambeiro);
    expect(usuario.isCacambeiro, isTrue);
    expect(usuario.status, StatusUsuario.ativo);
    expect(usuario.criadoEm, DateTime.utc(2026, 10, 1, 12));
    expect(usuario.detalhesCacambeiro!.raioEntregaKm, 50);
    expect(usuario.detalhesCacambeiro!.taxaEntrega, 25.5);
  });

  test('Cacamba do detalhe, com fornecedor e avaliações', () {
    final cacamba = Cacamba.fromJson({
      'id': 'c1',
      'cacambeiro_id': 'u1',
      'nome': 'Caçamba 5m³',
      'tipo_residuo': 'Entulho de Obra',
      'tamanho_m3': 5,
      'preco_diaria': 120.5,
      'foto_url': null,
      'disponivel': true,
      'criado_em': '2026-10-01T12:00:00.000Z',
      'cacambeiro': {
        'id': 'u1',
        'nome_completo': 'Fornecedor Teste',
        'telefone': '11999999999',
        'horario_inicio': '08:00:00',
        'horario_fim': '18:00:00',
        'raio_entrega_km': 30,
        'taxa_entrega': 40,
        'nota_media': 4.5,
        'total_avaliacoes': 2,
      },
      'avaliacoes': [
        {
          'id': 'a1',
          'nota': 5,
          'comentario': 'Ótimo',
          'data_avaliacao': '2026-10-02T10:00:00.000Z',
          'consumidor_nome': 'Cliente',
        },
      ],
    });

    expect(cacamba.precoDiaria, 120.5);
    expect(cacamba.fotoUrl, isNull);
    expect(cacamba.cacambeiro!.notaMedia, 4.5);
    expect(cacamba.cacambeiro!.totalAvaliacoes, 2);
    expect(cacamba.avaliacoes.single.consumidorNome, 'Cliente');
  });

  test('Carrinho vazio e com itens', () {
    final vazio = Carrinho.fromJson({
      'id': null,
      'consumidor_id': 'u2',
      'cacambeiro_id': null,
      'criado_em': null,
      'itens': [],
      'resumo': {
        'quantidade_itens': 0,
        'subtotal': 0,
        'taxa_entrega': 0,
        'total_estimado': 0,
      },
    });
    expect(vazio.isEmpty, isTrue);
    expect(vazio.id, isNull);

    final carrinho = Carrinho.fromJson({
      'id': 'k1',
      'consumidor_id': 'u2',
      'cacambeiro_id': 'u1',
      'itens': [
        {
          'id': 'i1',
          'cacamba_id': 'c1',
          'quantidade': 2,
          'dias_aluguel': 3,
          'subtotal': 723,
          'cacamba': {
            'id': 'c1',
            'nome': 'Caçamba 5m³',
            'tipo_residuo': 'Entulho de Obra',
            'tamanho_m3': 5,
            'preco_diaria': 120.5,
            'disponivel': true,
          },
        },
      ],
      'resumo': {
        'quantidade_itens': 2,
        'subtotal': 723,
        'taxa_entrega': 40,
        'total_estimado': 763,
      },
    });

    expect(carrinho.itens.single.cacamba!.nome, 'Caçamba 5m³');
    expect(carrinho.resumo.totalEstimado, 763);
  });

  test('Aluguel do detalhe', () {
    final aluguel = Aluguel.fromJson({
      'id': 'p1',
      'codigo': 'COL-ABCDEF1234',
      'data_pedido': '2026-10-20T15:00:00.000Z',
      'data_inicio': '2026-10-25T00:00:00.000Z',
      'dias_aluguel': 3,
      'status_aluguel': 'EM_USO',
      'status_pagamento': 'PENDENTE',
      'valores': {
        'subtotal_itens': 723,
        'taxa_entrega': 40,
        'preco_final': 763,
      },
      'consumidor': {
        'id': 'u2',
        'nome_completo': 'Cliente',
        'email': 'c@teste.com',
        'telefone': '11988887777',
      },
      'cacambeiro': {
        'id': 'u1',
        'nome_completo': 'Fornecedor Teste',
        'email': 'f@teste.com',
        'telefone': '11999999999',
        'horario_inicio': '08:00:00',
        'horario_fim': '18:00:00',
      },
      'endereco': {
        'id': 'e1',
        'cep': '01311200',
        'logradouro': 'Av. Paulista',
        'numero': '1000',
        'bairro': 'Bela Vista',
        'cidade_estado': 'São Paulo/SP',
      },
      'itens': [
        {
          'id': 'ia1',
          'quantidade': 2,
          'dias_aluguel': 3,
          'preco_diaria': 120.5,
          'subtotal': 723,
          'cacamba': {
            'id': 'c1',
            'nome': 'Caçamba 5m³',
            'tipo_residuo': 'Entulho de Obra',
            'tamanho_m3': 5,
            'foto_url': null,
          },
        },
      ],
      'avaliacao': null,
      'etapas': [
        {
          'status': 'AGUARDANDO_ENTREGA',
          'titulo': 'Aguardando entrega',
          'concluida': true,
          'atual': false,
          'pendente': false,
        },
        {
          'status': 'EM_USO',
          'titulo': 'Em uso',
          'concluida': false,
          'atual': true,
          'pendente': false,
        },
      ],
    });

    expect(aluguel.codigo, 'COL-ABCDEF1234');
    expect(aluguel.precoFinal, 763);
    expect(aluguel.subtotalItens, 723);
    // Só a data, sem deslocar o dia por causa do fuso.
    expect(aluguel.dataInicio, DateTime(2026, 10, 25));
    expect(aluguel.statusAluguel, StatusAluguel.emUso);
    expect(aluguel.consumidorId, 'u2');
    expect(aluguel.cacambeiroNome, 'Fornecedor Teste');
    expect(aluguel.endereco!.id, 'e1');
    expect(aluguel.itens.single.cacamba!.nome, 'Caçamba 5m³');
    expect(aluguel.avaliacao, isNull);
    expect(aluguel.etapas.last.atual, isTrue);
  });

  test('Aluguel da gestão do fornecedor, com dados achatados na linha', () {
    final aluguel = Aluguel.fromJson({
      'id': 'p1',
      'consumidor_id': 'u2',
      'cacambeiro_id': 'u1',
      'endereco_id': 'e1',
      'data_pedido': '2026-10-20T15:00:00.000Z',
      'data_inicio': '2026-10-25',
      'dias_aluguel': 3,
      'preco_final': '763.00',
      'status_pagamento': 'PENDENTE',
      'status_aluguel': 'AGUARDANDO_ENTREGA',
      'consumidor_nome': 'Cliente',
      'logradouro': 'Av. Paulista',
      'numero': '1000',
      'bairro': 'Bela Vista',
      'cidade_estado': 'São Paulo/SP',
      'cep': '01311200',
    });

    expect(aluguel.precoFinal, 763);
    expect(aluguel.dataInicio, DateTime(2026, 10, 25));
    expect(aluguel.consumidorNome, 'Cliente');
    expect(aluguel.endereco!.id, 'e1');
    expect(aluguel.endereco!.logradouro, 'Av. Paulista');
  });

  group('Pagina', () {
    test('formato novo {items, pagination}', () {
      final pagina = Pagina.fromJson({
        'items': [
          {'id': 'c1', 'nome': 'A'},
        ],
        'pagination': {
          'total': 21,
          'page': 1,
          'per_page': 20,
          'total_pages': 2,
        },
      }, Cacamba.fromJson);

      expect(pagina.itens.single.nome, 'A');
      expect(pagina.total, 21);
      expect(pagina.temProxima, isTrue);
    });

    test('formato antigo {data, total, page, totalPages}', () {
      final pagina = Pagina.fromJson({
        'data': [
          {'id': 'c1', 'nome': 'A'},
        ],
        'total': 1,
        'page': 1,
        'totalPages': 1,
      }, Cacamba.fromJson);

      expect(pagina.itens, hasLength(1));
      expect(pagina.temProxima, isFalse);
    });
  });

  test('Endereco.toJson manda o CEP só com dígitos e omite bairro vazio', () {
    const endereco = Endereco(
      cep: '01311-200',
      logradouro: 'Av. Paulista',
      numero: '1000',
      cidadeEstado: 'São Paulo/SP',
    );

    expect(endereco.toJson(), {
      'cep': '01311200',
      'logradouro': 'Av. Paulista',
      'numero': '1000',
      'cidade_estado': 'São Paulo/SP',
    });
  });

  test('formatApiDate', () {
    expect(formatApiDate(DateTime(2026, 3, 7)), '2026-03-07');
  });
}
