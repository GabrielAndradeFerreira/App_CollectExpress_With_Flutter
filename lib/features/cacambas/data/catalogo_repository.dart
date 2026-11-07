import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/area_atendimento.dart';
import '../../../core/models/avaliacao.dart';
import '../../../core/models/cacamba.dart';
import '../../../core/models/cacambeiro.dart';
import '../../../core/models/json_parsing.dart';
import '../../../core/models/pagina.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';

final catalogoRepositoryProvider = Provider<CatalogoRepository>((ref) {
  return CatalogoRepository(ref.watch(apiClientProvider));
});

/// Quais caçambas listar em relação ao local do cliente.
enum AreaCatalogo {
  /// O fornecedor atende o local (ou ainda não definiu a área).
  dentro('dentro'),

  /// O fornecedor definiu a área e ela não cobre o local.
  fora('fora'),
  todas('todas');

  const AreaCatalogo(this.apiValue);

  final String apiValue;
}

/// Catálogo público: caçambas disponíveis, fornecedores e avaliações.
/// Não exige login.
class CatalogoRepository {
  CatalogoRepository(this._api);

  final ApiClient _api;

  /// Só caçambas disponíveis, 20 por página.
  /// [busca] procura no nome e precisa de pelo menos 3 letras.
  ///
  /// Com [local], a API filtra pela área de atendimento dos fornecedores
  /// conforme [area] (por padrão, só as que atendem o local).
  Future<Pagina<Cacamba>> listarCacambas({
    int pagina = 1,
    String? tipoResiduo,
    String? cacambeiroId,
    String? busca,
    LocalEntrega? local,
    AreaCatalogo area = AreaCatalogo.dentro,
  }) async {
    final data = await _api.get(
      '/cacambas',
      auth: false,
      query: {
        'page': pagina,
        'tipo_residuo': ?tipoResiduo,
        'cacambeiro_id': ?cacambeiroId,
        if (busca != null && busca.trim().length >= 3) 'search': busca.trim(),
        if (local != null) ..._queryLocal(local),
        if (local != null) 'area': area.apiValue,
      },
    );

    return Pagina.fromJson(data, Cacamba.fromJson);
  }

  /// Inclui o fornecedor e as últimas avaliações dele. Com [local], vem
  /// também se o fornecedor atende esse local.
  Future<Cacamba> detalheCacamba(String id, {LocalEntrega? local}) async {
    final data = await _api.get(
      '/cacambas/$id',
      auth: false,
      query: {if (local != null) ..._queryLocal(local)},
    );
    return Cacamba.fromJson(parseMap(data) ?? const {});
  }

  Map<String, dynamic> _queryLocal(LocalEntrega local) => {
    'latitude': local.latitude,
    'longitude': local.longitude,
  };

  Future<List<Cacambeiro>> listarFornecedores() async {
    final data = await _api.get('/cacambeiros', auth: false);
    return parseList(data, Cacambeiro.fromJson);
  }

  /// Perfil do fornecedor e as caçambas disponíveis dele.
  Future<({Cacambeiro fornecedor, List<Cacamba> catalogo})> detalheFornecedor(
    String id,
  ) async {
    final json = parseMap(await _api.get('/cacambeiros/$id', auth: false));

    return (
      fornecedor: Cacambeiro.fromJson(parseMap(json?['perfil']) ?? const {}),
      catalogo: parseList(json?['catalogo'], Cacamba.fromJson),
    );
  }

  Future<({List<Avaliacao> avaliacoes, int total, double? notaMedia})>
  avaliacoesDoFornecedor(String id) async {
    final json = parseMap(
      await _api.get('/avaliacoes/cacambeiro/$id', auth: false),
    );
    final resumo = parseMap(json?['resumo']) ?? const {};

    return (
      avaliacoes: parseList(json?['avaliacoes'], Avaliacao.fromJson),
      total: parseInt(resumo['total']),
      notaMedia: parseDoubleOrNull(resumo['nota_media']),
    );
  }
}
