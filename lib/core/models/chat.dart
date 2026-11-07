import 'enums.dart';
import 'json_parsing.dart';

/// Os três tipos de conversa da API.
enum TipoConversa implements ApiEnum {
  /// Cliente e caçambeiro, ligada a um pedido.
  pedido('PEDIDO'),

  /// Caçambeiro e equipe, livre e com histórico.
  suporteCacambeiro('SUPORTE_CACAMBEIRO'),

  /// Cliente e equipe: aberto pelo cliente e fechado por um admin.
  chamado('CHAMADO');

  const TipoConversa(this.apiValue);

  @override
  final String apiValue;

  static TipoConversa? fromApi(dynamic value) {
    final text = value?.toString().toUpperCase();
    for (final tipo in values) {
      if (tipo.apiValue == text) return tipo;
    }
    return null;
  }
}

class UltimaMensagem {
  final String texto;

  /// Escrita por quem está olhando a lista.
  final bool minha;
  final DateTime? criadaEm;

  const UltimaMensagem({
    required this.texto,
    required this.minha,
    this.criadaEm,
  });

  factory UltimaMensagem.fromJson(Map<String, dynamic> json) {
    return UltimaMensagem(
      texto: parseString(json['texto']),
      minha: parseBool(json['minha']),
      criadaEm: parseDate(json['criada_em']),
    );
  }
}

/// Uma conversa, do ponto de vista de quem consulta a API: o nome do
/// contato já vem certo para cada perfil.
class Conversa {
  final String id;
  final TipoConversa tipo;
  final bool aberta;
  final String? assunto;
  final String? aluguelId;
  final String? pedidoCodigo;
  final String contatoNome;
  final String? contatoDetalhe;
  final UltimaMensagem? ultimaMensagem;
  final DateTime? ultimaAtividadeEm;
  final int naoLidas;

  /// Só admin: alguém denunciou e a equipe ainda não analisou.
  final bool denunciada;
  final bool podeEnviar;
  final String? motivoBloqueio;

  /// Admin acompanhando conversa de pedido.
  final bool somenteLeitura;
  final DateTime? fechadaEm;

  /// Só no detalhe, quando a conversa tem pedido vinculado.
  final PedidoDaConversa? pedido;

  const Conversa({
    required this.id,
    required this.tipo,
    required this.contatoNome,
    this.aberta = true,
    this.assunto,
    this.aluguelId,
    this.pedidoCodigo,
    this.contatoDetalhe,
    this.ultimaMensagem,
    this.ultimaAtividadeEm,
    this.naoLidas = 0,
    this.denunciada = false,
    this.podeEnviar = true,
    this.motivoBloqueio,
    this.somenteLeitura = false,
    this.fechadaEm,
    this.pedido,
  });

  factory Conversa.fromJson(Map<String, dynamic> json) {
    final ultima = parseMap(json['ultima_mensagem']);
    final pedido = parseMap(json['pedido']);

    return Conversa(
      id: parseString(json['id']),
      tipo: TipoConversa.fromApi(json['tipo']) ?? TipoConversa.pedido,
      aberta: parseString(json['status']) != 'FECHADA',
      assunto: parseStringOrNull(json['assunto']),
      aluguelId: parseStringOrNull(json['aluguel_id']),
      pedidoCodigo: parseStringOrNull(json['pedido_codigo']),
      contatoNome: parseString(json['contato_nome']),
      contatoDetalhe: parseStringOrNull(json['contato_detalhe']),
      ultimaMensagem: ultima == null ? null : UltimaMensagem.fromJson(ultima),
      ultimaAtividadeEm: parseDate(json['ultima_atividade_em']),
      naoLidas: parseInt(json['nao_lidas']),
      denunciada: parseBool(json['denunciada']),
      podeEnviar: parseBool(json['pode_enviar'], fallback: true),
      motivoBloqueio: parseStringOrNull(json['motivo_bloqueio']),
      somenteLeitura: parseBool(json['somente_leitura']),
      fechadaEm: parseDate(json['fechada_em']),
      pedido: pedido == null ? null : PedidoDaConversa.fromJson(pedido),
    );
  }

  bool get ehChamado => tipo == TipoConversa.chamado;

  /// Quem não é o admin só tem o chat do pedido com dados vinculados.
  bool get temPedido => aluguelId != null;
}

/// Resumo do pedido mostrado no menu (⋮) da conversa. Sem telefone.
class PedidoDaConversa {
  final String codigo;
  final StatusAluguel? status;
  final StatusPagamento? pagamento;
  final DateTime? dataPedido;
  final DateTime? dataInicio;
  final int diasAluguel;
  final double precoFinal;
  final String enderecoTexto;
  final List<ItemDoPedidoChat> itens;

  const PedidoDaConversa({
    required this.codigo,
    this.status,
    this.pagamento,
    this.dataPedido,
    this.dataInicio,
    this.diasAluguel = 0,
    this.precoFinal = 0,
    this.enderecoTexto = '',
    this.itens = const [],
  });

  factory PedidoDaConversa.fromJson(Map<String, dynamic> json) {
    final endereco = parseMap(json['endereco']) ?? const {};
    final bairro = parseString(endereco['bairro']);
    final cidade = parseString(endereco['cidade_estado']);

    return PedidoDaConversa(
      codigo: parseString(json['codigo']),
      status: StatusAluguel.fromApi(json['status_aluguel']),
      pagamento: StatusPagamento.fromApi(json['status_pagamento']),
      dataPedido: parseDate(json['data_pedido']),
      dataInicio: parseDateOnly(json['data_inicio']),
      diasAluguel: parseInt(json['dias_aluguel']),
      precoFinal: parseDouble(json['preco_final']),
      enderecoTexto: [
        '${parseString(endereco['logradouro'])}, '
            '${parseString(endereco['numero'])}',
        if (bairro.isNotEmpty) bairro,
        if (cidade.isNotEmpty) cidade,
      ].join(' - '),
      itens: parseList(json['itens'], ItemDoPedidoChat.fromJson),
    );
  }
}

class ItemDoPedidoChat {
  final String nome;
  final String tipoResiduo;
  final double tamanhoM3;
  final int quantidade;
  final int diasAluguel;
  final double precoDiaria;

  const ItemDoPedidoChat({
    required this.nome,
    this.tipoResiduo = '',
    this.tamanhoM3 = 0,
    this.quantidade = 1,
    this.diasAluguel = 0,
    this.precoDiaria = 0,
  });

  factory ItemDoPedidoChat.fromJson(Map<String, dynamic> json) {
    return ItemDoPedidoChat(
      nome: parseString(json['nome']),
      tipoResiduo: parseString(json['tipo_residuo']),
      tamanhoM3: parseDouble(json['tamanho_m3']),
      quantidade: parseInt(json['quantidade']),
      diasAluguel: parseInt(json['dias_aluguel']),
      precoDiaria: parseDouble(json['preco_diaria']),
    );
  }
}

class Mensagem {
  /// Cresce a cada mensagem; serve de cursor para buscar só as novas.
  final int id;
  final String texto;
  final bool minha;
  final DateTime? criadaEm;

  /// O outro lado já abriu a conversa depois desta mensagem.
  final bool lida;

  /// Só para a equipe: qual admin escreveu.
  final String? remetenteNome;

  const Mensagem({
    required this.id,
    required this.texto,
    required this.minha,
    this.criadaEm,
    this.lida = false,
    this.remetenteNome,
  });

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    return Mensagem(
      id: parseInt(json['id']),
      texto: parseString(json['texto']),
      minha: parseBool(json['minha']),
      criadaEm: parseDate(json['criada_em']),
      lida: parseBool(json['lida']),
      remetenteNome: parseStringOrNull(json['remetente_nome']),
    );
  }
}

/// Total de conversas e de mensagens aguardando leitura.
class NaoLidas {
  final int conversas;
  final int mensagens;

  const NaoLidas({this.conversas = 0, this.mensagens = 0});

  static const zero = NaoLidas();

  factory NaoLidas.fromJson(Map<String, dynamic> json) {
    return NaoLidas(
      conversas: parseInt(json['conversas']),
      mensagens: parseInt(json['mensagens']),
    );
  }
}
