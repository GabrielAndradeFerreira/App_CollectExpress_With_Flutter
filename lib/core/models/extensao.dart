import 'enums.dart';
import 'json_parsing.dart';

/// Estado de um pedido de extensão de aluguel.
///
/// SOLICITADA -> AGUARDANDO_PAGAMENTO (caçambeiro aceitou, 24 h para
/// pagar) -> PAGA. Também pode terminar em RECUSADA, EXPIRADA ou CANCELADA.
enum StatusExtensao implements ApiEnum {
  solicitada('SOLICITADA'),
  aguardandoPagamento('AGUARDANDO_PAGAMENTO'),
  paga('PAGA'),
  recusada('RECUSADA'),
  expirada('EXPIRADA'),
  cancelada('CANCELADA');

  const StatusExtensao(this.apiValue);

  @override
  final String apiValue;

  static StatusExtensao? fromApi(dynamic value) {
    final text = value?.toString().toUpperCase();
    for (final item in values) {
      if (item.apiValue == text) return item;
    }
    return null;
  }

  String get label => switch (this) {
    solicitada => 'Aguardando resposta do fornecedor',
    aguardandoPagamento => 'Aceita: aguardando pagamento',
    paga => 'Extensão paga',
    recusada => 'Recusada pelo fornecedor',
    expirada => 'Expirada',
    cancelada => 'Cancelada',
  };

  /// Ainda depende de alguém: o fornecedor responder ou o cliente pagar.
  bool get emAberto => this == solicitada || this == aguardandoPagamento;
}

/// Tabela `extensoes_aluguel`.
class Extensao {
  final String id;
  final String aluguelId;
  final int diasAdicionais;
  final double valor;
  final StatusExtensao? status;
  final DateTime? solicitadaEm;

  /// Prazo (48 h) para o fornecedor responder.
  final DateTime? solicitacaoExpiraEm;
  final DateTime? respondidaEm;

  /// Prazo (24 h após o aceite) para o cliente pagar.
  final DateTime? pagamentoExpiraEm;
  final DateTime? pagoEm;

  const Extensao({
    required this.id,
    required this.aluguelId,
    required this.diasAdicionais,
    required this.valor,
    this.status,
    this.solicitadaEm,
    this.solicitacaoExpiraEm,
    this.respondidaEm,
    this.pagamentoExpiraEm,
    this.pagoEm,
  });

  factory Extensao.fromJson(Map<String, dynamic> json) {
    return Extensao(
      id: parseString(json['id']),
      aluguelId: parseString(json['aluguel_id']),
      diasAdicionais: parseInt(json['dias_adicionais']),
      valor: parseDouble(json['valor']),
      status: StatusExtensao.fromApi(json['status']),
      solicitadaEm: parseDate(json['solicitada_em']),
      solicitacaoExpiraEm: parseDate(json['solicitacao_expira_em']),
      respondidaEm: parseDate(json['respondida_em']),
      pagamentoExpiraEm: parseDate(json['pagamento_expira_em']),
      pagoEm: parseDate(json['pago_em']),
    );
  }
}

/// Resumo de extensão que vem no detalhe do pedido.
class ResumoExtensao {
  /// Todas as caçambas do pedido permitem extensão.
  final bool permiteExtensao;

  /// Dá para pedir uma extensão agora.
  final bool podeEstender;

  /// Código do motivo quando [podeEstender] é falso (ex.:
  /// `EXTENSION_INVALID_STATUS`, `ORDER_NOT_PAID`).
  final String? motivoBloqueio;

  /// Dias já acrescentados por extensões pagas.
  final int diasExtra;

  /// Maior valor aceito em um pedido (respeita o teto de 90 dias).
  final int maxDiasPorExtensao;

  /// Soma das diárias dos itens: valor de 1 dia de extensão.
  final double diariaTotal;

  /// Extensão mais recente, se houver.
  final Extensao? atual;

  const ResumoExtensao({
    required this.permiteExtensao,
    required this.podeEstender,
    this.motivoBloqueio,
    this.diasExtra = 0,
    this.maxDiasPorExtensao = 0,
    this.diariaTotal = 0,
    this.atual,
  });

  factory ResumoExtensao.fromJson(Map<String, dynamic> json) {
    final atual = parseMap(json['atual']);

    return ResumoExtensao(
      permiteExtensao: parseBool(json['permite_extensao']),
      podeEstender: parseBool(json['pode_estender']),
      motivoBloqueio: parseStringOrNull(json['motivo_bloqueio']),
      diasExtra: parseInt(json['dias_extra']),
      maxDiasPorExtensao: parseInt(json['max_dias_por_extensao']),
      diariaTotal: parseDouble(json['diaria_total']),
      atual: atual == null ? null : Extensao.fromJson(atual),
    );
  }
}
