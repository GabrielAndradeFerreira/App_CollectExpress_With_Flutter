import 'package:app_collect_express_with_flutter/core/models/area_atendimento.dart';
import 'package:app_collect_express_with_flutter/features/cacambas/presentation/local_entrega_provider.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Local de entrega usado nos testes do catálogo (centro de São Paulo).
const localDeTeste = LocalEntrega(
  cep: '01310100',
  logradouro: 'Avenida Paulista',
  cidadeEstado: 'São Paulo - SP',
  latitude: -23.5614,
  longitude: -46.6559,
);

class _LocalEntregaFixo extends LocalEntregaNotifier {
  _LocalEntregaFixo(this._inicial);

  final LocalEntrega? _inicial;

  @override
  LocalEntrega? build() => _inicial;
}

/// Começa o teste com o local de entrega já escolhido (ou sem nenhum).
Override localEntregaInicial(LocalEntrega? local) {
  return localEntregaProvider.overrideWith(() => _LocalEntregaFixo(local));
}
