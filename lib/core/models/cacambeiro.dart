import 'json_parsing.dart';

/// Dados públicos de um fornecedor (CACAMBEIRO), como aparecem no
/// catálogo e no detalhe da caçamba.
class Cacambeiro {
  final String id;
  final String nomeCompleto;
  final String? horarioInicio;
  final String? horarioFim;
  final double? raioEntregaKm;
  final double? taxaEntrega;
  final double? notaMedia;
  final int totalAvaliacoes;

  /// Só em `GET /cacambeiros`.
  final int? cacambasDisponiveis;

  const Cacambeiro({
    required this.id,
    required this.nomeCompleto,
    this.horarioInicio,
    this.horarioFim,
    this.raioEntregaKm,
    this.taxaEntrega,
    this.notaMedia,
    this.totalAvaliacoes = 0,
    this.cacambasDisponiveis,
  });

  factory Cacambeiro.fromJson(Map<String, dynamic> json) {
    return Cacambeiro(
      id: parseString(json['id']),
      nomeCompleto: parseString(json['nome_completo']),
      horarioInicio: parseStringOrNull(json['horario_inicio']),
      horarioFim: parseStringOrNull(json['horario_fim']),
      raioEntregaKm: parseDoubleOrNull(json['raio_entrega_km']),
      taxaEntrega: parseDoubleOrNull(json['taxa_entrega']),
      notaMedia: parseDoubleOrNull(json['nota_media']),
      totalAvaliacoes: parseInt(json['total_avaliacoes']),
      cacambasDisponiveis: parseIntOrNull(json['cacambas_disponiveis']),
    );
  }
}
