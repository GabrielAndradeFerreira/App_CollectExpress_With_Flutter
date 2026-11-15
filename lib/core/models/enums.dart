// Enums do schema.sql da API.

abstract interface class ApiEnum {
  /// Texto que a API usa para o valor.
  String get apiValue;
}

enum TipoPerfil implements ApiEnum {
  consumidor('CONSUMIDOR'),
  cacambeiro('CACAMBEIRO'),
  parceiro('PARCEIRO'),
  admin('ADMIN');

  const TipoPerfil(this.apiValue);

  @override
  final String apiValue;

  static TipoPerfil? fromApi(dynamic value) => _fromApi(values, value);
}

enum StatusUsuario implements ApiEnum {
  pendente('PENDENTE'),
  ativo('ATIVO'),
  suspenso('SUSPENSO');

  const StatusUsuario(this.apiValue);

  @override
  final String apiValue;

  static StatusUsuario? fromApi(dynamic value) => _fromApi(values, value);
}

enum StatusAluguel implements ApiEnum {
  aguardandoEntrega('AGUARDANDO_ENTREGA'),
  emUso('EM_USO'),
  aguardandoRetirada('AGUARDANDO_RETIRADA'),
  finalizado('FINALIZADO');

  const StatusAluguel(this.apiValue);

  @override
  final String apiValue;

  static StatusAluguel? fromApi(dynamic value) => _fromApi(values, value);
}

enum StatusPagamento implements ApiEnum {
  pendente('PENDENTE'),
  pago('PAGO');

  const StatusPagamento(this.apiValue);

  @override
  final String apiValue;

  static StatusPagamento? fromApi(dynamic value) => _fromApi(values, value);
}

T? _fromApi<T extends ApiEnum>(List<T> values, dynamic value) {
  final text = value?.toString().toUpperCase();
  for (final item in values) {
    if (item.apiValue == text) return item;
  }
  return null;
}
