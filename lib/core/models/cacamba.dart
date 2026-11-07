import 'avaliacao.dart';
import 'cacambeiro.dart';
import 'json_parsing.dart';

/// Tabela `cacambas`.
class Cacamba {
  final String id;
  final String? cacambeiroId;
  final String nome;

  /// Nome de uma categoria cadastrada (ex.: "Entulho de Obra").
  final String tipoResiduo;

  final double tamanhoM3;
  final double precoDiaria;
  final String? fotoUrl;
  final bool disponivel;

  /// O fornecedor aceita pedidos de extensão do aluguel desta caçamba.
  final bool permiteExtensao;
  final DateTime? criadoEm;

  /// Só no detalhe (`GET /cacambas/:id`).
  final Cacambeiro? cacambeiro;

  /// Só no detalhe: as 10 avaliações mais recentes do fornecedor.
  final List<Avaliacao> avaliacoes;

  /// Só quando o catálogo é consultado com a localização do cliente.
  /// `null` = não avaliado; `false` = o fornecedor não atende o local.
  final bool? dentroDaArea;

  /// Distância do fornecedor até o local do cliente.
  final double? distanciaKm;

  /// O fornecedor já definiu a área de atendimento.
  final bool areaDefinida;

  const Cacamba({
    required this.id,
    required this.nome,
    required this.tipoResiduo,
    required this.tamanhoM3,
    required this.precoDiaria,
    this.cacambeiroId,
    this.fotoUrl,
    this.disponivel = true,
    this.permiteExtensao = false,
    this.criadoEm,
    this.cacambeiro,
    this.avaliacoes = const [],
    this.dentroDaArea,
    this.distanciaKm,
    this.areaDefinida = false,
  });

  /// Só pode alugar se o local do cliente não foi avaliado ou se está
  /// dentro da área de atendimento.
  bool get podeAlugar => dentroDaArea != false;

  factory Cacamba.fromJson(Map<String, dynamic> json) {
    final cacambeiro = parseMap(json['cacambeiro']);

    return Cacamba(
      id: parseString(json['id']),
      cacambeiroId: parseStringOrNull(
        json['cacambeiro_id'] ?? cacambeiro?['id'],
      ),
      nome: parseString(json['nome']),
      tipoResiduo: parseString(json['tipo_residuo']),
      tamanhoM3: parseDouble(json['tamanho_m3']),
      precoDiaria: parseDouble(json['preco_diaria']),
      fotoUrl: parseStringOrNull(json['foto_url']),
      disponivel: parseBool(json['disponivel'], fallback: true),
      permiteExtensao: parseBool(json['permite_extensao']),
      criadoEm: parseDate(json['criado_em']),
      cacambeiro: cacambeiro == null ? null : Cacambeiro.fromJson(cacambeiro),
      avaliacoes: parseList(json['avaliacoes'], Avaliacao.fromJson),
      dentroDaArea: json['dentro_da_area'] is bool
          ? json['dentro_da_area'] as bool
          : null,
      distanciaKm: parseDoubleOrNull(json['distancia_km']),
      areaDefinida: parseBool(json['area_definida']),
    );
  }
}
