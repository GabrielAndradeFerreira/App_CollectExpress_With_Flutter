import 'endereco.dart';
import 'json_parsing.dart';

/// Ponto no mapa onde o cliente quer receber a caçamba. Vem de um CEP
/// (`GET /localizacao/cep/:cep`) ou de um endereço já salvo.
class LocalEntrega {
  /// Só dígitos, 8 caracteres.
  final String cep;
  final String logradouro;
  final String bairro;

  /// Ex.: "São Paulo - SP".
  final String cidadeEstado;
  final double latitude;
  final double longitude;

  const LocalEntrega({
    required this.cep,
    this.logradouro = '',
    this.bairro = '',
    this.cidadeEstado = '',
    required this.latitude,
    required this.longitude,
  });

  /// Resposta de `GET /localizacao/cep/:cep`. Devolve `null` quando o
  /// CEP existe mas a API não conseguiu localizá-lo no mapa.
  static LocalEntrega? fromCepJson(Map<String, dynamic> json) {
    final latitude = parseDoubleOrNull(json['latitude']);
    final longitude = parseDoubleOrNull(json['longitude']);

    if (latitude == null || longitude == null) return null;

    return LocalEntrega(
      cep: parseString(json['cep']).replaceAll(RegExp(r'\D'), ''),
      logradouro: parseString(json['logradouro']),
      bairro: parseString(json['bairro']),
      cidadeEstado: parseString(json['cidade_estado']),
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Usa as coordenadas de um endereço salvo, se ele tiver.
  static LocalEntrega? fromEndereco(Endereco endereco) {
    final latitude = endereco.latitude;
    final longitude = endereco.longitude;

    if (latitude == null || longitude == null) return null;

    return LocalEntrega(
      cep: endereco.cep.replaceAll(RegExp(r'\D'), ''),
      logradouro: endereco.logradouro,
      bairro: endereco.bairro,
      cidadeEstado: endereco.cidadeEstado,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Texto curto para a barra do catálogo.
  String get descricao {
    final partes = [
      if (logradouro.isNotEmpty) logradouro,
      if (cidadeEstado.isNotEmpty) cidadeEstado,
    ];
    final texto = partes.join(' · ');

    return texto.isEmpty ? 'CEP ${formatarCep(cep)}' : texto;
  }

  static String formatarCep(String cep) {
    final digitos = cep.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 8) return cep;
    return '${digitos.substring(0, 5)}-${digitos.substring(5)}';
  }

  @override
  bool operator ==(Object other) {
    return other is LocalEntrega &&
        other.cep == cep &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(cep, latitude, longitude);
}

/// Cerca virtual circular do fornecedor (`/cacambeiros/me/area`).
class AreaAtendimento {
  final bool definida;
  final double? latitude;
  final double? longitude;

  /// Mesmo sem [definida], pode vir o raio antigo como sugestão.
  final double? raioKm;

  const AreaAtendimento({
    this.definida = false,
    this.latitude,
    this.longitude,
    this.raioKm,
  });

  factory AreaAtendimento.fromJson(Map<String, dynamic> json) {
    return AreaAtendimento(
      definida: parseBool(json['definida']),
      latitude: parseDoubleOrNull(json['latitude']),
      longitude: parseDoubleOrNull(json['longitude']),
      raioKm: parseDoubleOrNull(json['raio_km']),
    );
  }
}

enum PendenciaFornecedor { areaAtendimento, assinatura }

/// O que falta o fornecedor cadastrar (`/cacambeiros/me/pendencias`).
class PendenciasFornecedor {
  final bool areaDefinida;
  final bool assinaturaCadastrada;
  final List<PendenciaFornecedor> pendencias;

  const PendenciasFornecedor({
    this.areaDefinida = true,
    this.assinaturaCadastrada = true,
    this.pendencias = const [],
  });

  factory PendenciasFornecedor.fromJson(Map<String, dynamic> json) {
    final codigos = json['pendencias'] is List
        ? (json['pendencias'] as List).map((item) => item.toString())
        : const <String>[];

    return PendenciasFornecedor(
      areaDefinida: parseBool(json['area_definida'], fallback: true),
      assinaturaCadastrada: parseBool(
        json['assinatura_cadastrada'],
        fallback: true,
      ),
      pendencias: [
        for (final codigo in codigos)
          if (codigo == 'AREA_ATENDIMENTO')
            PendenciaFornecedor.areaAtendimento
          else if (codigo == 'ASSINATURA')
            PendenciaFornecedor.assinatura,
      ],
    );
  }

  bool get temPendencias => pendencias.isNotEmpty;
}
