import 'json_parsing.dart';

/// Tabela `enderecos`.
class Endereco {
  /// Vazio num endereço que ainda não foi salvo.
  final String id;

  /// Só dígitos, 8 caracteres.
  final String cep;

  final String logradouro;
  final String numero;
  final String bairro;

  /// Ex.: "São Paulo/SP".
  final String cidadeEstado;

  final DateTime? criadoEm;

  /// Preenchidos pela API ao salvar; nulos se o endereço não foi
  /// localizado no mapa.
  final double? latitude;
  final double? longitude;

  const Endereco({
    this.id = '',
    required this.cep,
    required this.logradouro,
    required this.numero,
    this.bairro = '',
    required this.cidadeEstado,
    this.criadoEm,
    this.latitude,
    this.longitude,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      id: parseString(json['id']),
      cep: parseString(json['cep']),
      logradouro: parseString(json['logradouro']),
      numero: parseString(json['numero']),
      bairro: parseString(json['bairro']),
      cidadeEstado: parseString(json['cidade_estado']),
      criadoEm: parseDate(json['criado_em']),
      latitude: parseDoubleOrNull(json['latitude']),
      longitude: parseDoubleOrNull(json['longitude']),
    );
  }

  /// Corpo de `POST`/`PUT /enderecos`.
  Map<String, dynamic> toJson() {
    return {
      'cep': cep.replaceAll(RegExp(r'\D'), ''),
      'logradouro': logradouro,
      'numero': numero,
      if (bairro.isNotEmpty) 'bairro': bairro,
      'cidade_estado': cidadeEstado,
    };
  }
}
