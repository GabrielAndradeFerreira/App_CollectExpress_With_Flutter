import 'enums.dart';
import 'json_parsing.dart';

/// Tabela `usuarios`.
class Usuario {
  final String id;
  final String nomeCompleto;
  final String email;
  final TipoPerfil? tipoPerfil;
  final StatusUsuario? status;

  /// Fora do cadastro, a API devolve mascarado (`***.***.789-00`).
  final String? documento;

  final String? telefone;
  final DateTime? criadoEm;

  /// Só para CACAMBEIRO, em `GET /usuarios/perfil`.
  final DetalhesCacambeiro? detalhesCacambeiro;

  const Usuario({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    this.tipoPerfil,
    this.status,
    this.documento,
    this.telefone,
    this.criadoEm,
    this.detalhesCacambeiro,
  });

  bool get isAdmin => tipoPerfil == TipoPerfil.admin;

  bool get isCacambeiro => tipoPerfil == TipoPerfil.cacambeiro;

  bool get isConsumidor => tipoPerfil == TipoPerfil.consumidor;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    final detalhes = parseMap(json['detalhes_cacambeiro']);

    return Usuario(
      id: parseString(json['id']),
      nomeCompleto: parseString(json['nome_completo']),
      email: parseString(json['email']),
      tipoPerfil: TipoPerfil.fromApi(json['tipo_perfil']),
      status: StatusUsuario.fromApi(json['status']),
      documento: parseStringOrNull(json['documento']),
      telefone: parseStringOrNull(json['telefone']),
      criadoEm: parseDate(json['criado_em']),
      detalhesCacambeiro: detalhes == null
          ? null
          : DetalhesCacambeiro.fromJson(detalhes),
    );
  }
}

/// Tabela `detalhes_cacambeiro`: dados de atendimento do fornecedor.
class DetalhesCacambeiro {
  /// `HH:MM` ao enviar; a API devolve `HH:MM:SS`.
  final String horarioInicio;
  final String horarioFim;

  /// Raio da área de atendimento. Nulo até o fornecedor definir a cerca.
  final double? raioEntregaKm;
  final double taxaEntrega;

  const DetalhesCacambeiro({
    required this.horarioInicio,
    required this.horarioFim,
    this.raioEntregaKm,
    required this.taxaEntrega,
  });

  factory DetalhesCacambeiro.fromJson(Map<String, dynamic> json) {
    return DetalhesCacambeiro(
      horarioInicio: parseString(json['horario_inicio']),
      horarioFim: parseString(json['horario_fim']),
      raioEntregaKm: parseDoubleOrNull(json['raio_entrega_km']),
      taxaEntrega: parseDouble(json['taxa_entrega']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'horario_inicio': horarioInicio,
      'horario_fim': horarioFim,
      if (raioEntregaKm != null) 'raio_entrega_km': raioEntregaKm,
      'taxa_entrega': taxaEntrega,
    };
  }
}
