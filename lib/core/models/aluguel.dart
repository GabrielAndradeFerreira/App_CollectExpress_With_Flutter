import 'avaliacao.dart';
import 'cacamba.dart';
import 'endereco.dart';
import 'enums.dart';
import 'extensao.dart';
import 'json_parsing.dart';

/// Tabelas `alugueis` + `itens_aluguel` (um pedido).
///
/// As listagens trazem só os dados principais e os nomes das partes;
/// o detalhe (`GET /alugueis/:id`) traz também itens, contatos e etapas.
class Aluguel {
  final String id;

  /// Código amigável (`COL-XXXXXXXXXX`), só no detalhe.
  final String? codigo;

  final String? consumidorId;
  final String? cacambeiroId;
  final String? enderecoId;
  final DateTime? dataPedido;
  final DateTime? dataInicio;
  final int diasAluguel;
  final double precoFinal;
  final StatusPagamento? statusPagamento;
  final StatusAluguel? statusAluguel;

  final String? consumidorNome;
  final String? cacambeiroNome;

  /// Contatos completos, só no detalhe.
  final ContatoPedido? consumidor;
  final ContatoPedido? cacambeiro;

  final Endereco? endereco;

  /// Só no detalhe.
  final double? subtotalItens;
  final double? taxaEntrega;
  final List<ItemAluguel> itens;
  final Avaliacao? avaliacao;
  final List<EtapaAluguel> etapas;

  /// Só no detalhe: existe contrato em PDF (pedidos novos têm; os
  /// anteriores ao recurso não).
  final bool contratoDisponivel;

  /// Só no detalhe: regras e estado da extensão do aluguel.
  final ResumoExtensao? extensao;

  const Aluguel({
    required this.id,
    required this.diasAluguel,
    required this.precoFinal,
    this.codigo,
    this.consumidorId,
    this.cacambeiroId,
    this.enderecoId,
    this.dataPedido,
    this.dataInicio,
    this.statusPagamento,
    this.statusAluguel,
    this.consumidorNome,
    this.cacambeiroNome,
    this.consumidor,
    this.cacambeiro,
    this.endereco,
    this.subtotalItens,
    this.taxaEntrega,
    this.itens = const [],
    this.avaliacao,
    this.etapas = const [],
    this.contratoDisponivel = false,
    this.extensao,
  });

  factory Aluguel.fromJson(Map<String, dynamic> json) {
    final valores = parseMap(json['valores']) ?? const {};
    final cacambeiro = parseMap(json['cacambeiro']);
    final avaliacao = parseMap(json['avaliacao']);
    final contrato = parseMap(json['contrato']);
    final extensao = parseMap(json['extensao']);

    // No detalhe, os dados das partes vêm aninhados; na gestão de pedidos
    // do fornecedor, o endereço vem achatado na linha.
    final consumidor = parseMap(json['consumidor']);
    final endereco =
        parseMap(json['endereco']) ??
        (json['logradouro'] != null
            ? {...json, 'id': json['endereco_id']}
            : null);

    return Aluguel(
      id: parseString(json['id']),
      codigo: parseStringOrNull(json['codigo']),
      consumidorId: parseStringOrNull(
        json['consumidor_id'] ?? consumidor?['id'],
      ),
      cacambeiroId: parseStringOrNull(
        json['cacambeiro_id'] ?? cacambeiro?['id'],
      ),
      enderecoId: parseStringOrNull(json['endereco_id'] ?? endereco?['id']),
      dataPedido: parseDate(json['data_pedido']),
      dataInicio: parseDateOnly(json['data_inicio']),
      diasAluguel: parseInt(json['dias_aluguel']),
      precoFinal: parseDouble(json['preco_final'] ?? valores['preco_final']),
      statusPagamento: StatusPagamento.fromApi(json['status_pagamento']),
      statusAluguel: StatusAluguel.fromApi(json['status_aluguel']),
      consumidorNome: parseStringOrNull(
        json['consumidor_nome'] ?? consumidor?['nome_completo'],
      ),
      cacambeiroNome: parseStringOrNull(
        json['cacambeiro_nome'] ?? cacambeiro?['nome_completo'],
      ),
      consumidor: consumidor == null
          ? null
          : ContatoPedido.fromJson(consumidor),
      cacambeiro: cacambeiro == null
          ? null
          : ContatoPedido.fromJson(cacambeiro),
      endereco: endereco == null ? null : Endereco.fromJson(endereco),
      subtotalItens: parseDoubleOrNull(valores['subtotal_itens']),
      taxaEntrega: parseDoubleOrNull(valores['taxa_entrega']),
      itens: parseList(json['itens'], ItemAluguel.fromJson),
      avaliacao: avaliacao == null ? null : Avaliacao.fromJson(avaliacao),
      etapas: parseList(json['etapas'], EtapaAluguel.fromJson),
      contratoDisponivel: parseBool(contrato?['disponivel']),
      extensao: extensao == null ? null : ResumoExtensao.fromJson(extensao),
    );
  }
}

class ItemAluguel {
  final String id;
  final String? cacambaId;
  final int quantidade;
  final int diasAluguel;

  /// Preço da diária no momento do pedido.
  final double precoDiaria;

  final double subtotal;

  /// Resumo da caçamba (sem preço atual nem disponibilidade).
  final Cacamba? cacamba;

  const ItemAluguel({
    required this.id,
    required this.quantidade,
    required this.diasAluguel,
    required this.precoDiaria,
    required this.subtotal,
    this.cacambaId,
    this.cacamba,
  });

  factory ItemAluguel.fromJson(Map<String, dynamic> json) {
    final cacamba = parseMap(json['cacamba']);
    final quantidade = parseInt(json['quantidade']);
    final dias = parseInt(json['dias_aluguel']);
    final precoDiaria = parseDouble(json['preco_diaria']);

    return ItemAluguel(
      id: parseString(json['id']),
      cacambaId: parseStringOrNull(json['cacamba_id'] ?? cacamba?['id']),
      quantidade: quantidade,
      diasAluguel: dias,
      precoDiaria: precoDiaria,
      subtotal:
          parseDoubleOrNull(json['subtotal']) ??
          quantidade * dias * precoDiaria,
      cacamba: cacamba == null ? null : Cacamba.fromJson(cacamba),
    );
  }
}

/// Nome e e-mail de uma das partes do pedido. O telefone não é divulgado:
/// a conversa entre as partes acontece no chat.
class ContatoPedido {
  final String id;
  final String nomeCompleto;
  final String? email;

  /// Só para o fornecedor.
  final String? horarioInicio;
  final String? horarioFim;

  const ContatoPedido({
    required this.id,
    required this.nomeCompleto,
    this.email,
    this.horarioInicio,
    this.horarioFim,
  });

  factory ContatoPedido.fromJson(Map<String, dynamic> json) {
    return ContatoPedido(
      id: parseString(json['id']),
      nomeCompleto: parseString(json['nome_completo']),
      email: parseStringOrNull(json['email']),
      horarioInicio: parseStringOrNull(json['horario_inicio']),
      horarioFim: parseStringOrNull(json['horario_fim']),
    );
  }
}

/// Uma das 4 etapas do acompanhamento do pedido.
class EtapaAluguel {
  final StatusAluguel? status;
  final String titulo;
  final bool concluida;
  final bool atual;
  final bool pendente;

  const EtapaAluguel({
    required this.titulo,
    this.status,
    this.concluida = false,
    this.atual = false,
    this.pendente = false,
  });

  factory EtapaAluguel.fromJson(Map<String, dynamic> json) {
    return EtapaAluguel(
      status: StatusAluguel.fromApi(json['status']),
      titulo: parseString(json['titulo']),
      concluida: parseBool(json['concluida']),
      atual: parseBool(json['atual']),
      pendente: parseBool(json['pendente']),
    );
  }
}
