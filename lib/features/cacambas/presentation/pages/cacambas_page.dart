import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/area_atendimento.dart';
import '../../../../core/models/cacamba.dart';
import '../../../../core/models/pagina.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/cacamba_image.dart';
import '../../../auth/data/sessao_provider.dart';
import '../../data/catalogo_repository.dart';
import '../local_entrega_provider.dart';
import '../widgets/escolher_local_sheet.dart';
import 'cacamba_details_page.dart';

typedef _Consulta = ({
  String? tipoResiduo,
  int pagina,
  LocalEntrega local,
  AreaCatalogo area,
});

final _cacambasProvider = FutureProvider.autoDispose
    .family<Pagina<Cacamba>, _Consulta>((ref, consulta) {
      return ref
          .watch(catalogoRepositoryProvider)
          .listarCacambas(
            pagina: consulta.pagina,
            tipoResiduo: consulta.tipoResiduo,
            local: consulta.local,
            area: consulta.area,
          );
    });

class CacambasPage extends ConsumerStatefulWidget {
  const CacambasPage({super.key});

  @override
  ConsumerState<CacambasPage> createState() => _CacambasPageState();
}

class _CacambasPageState extends ConsumerState<CacambasPage> {
  static const allCategory = 'Todas';

  /// `null` = todas as categorias.
  String? _categoria;
  int _paginas = 1;

  /// Mostra as caçambas de quem não atende o local (sem poder alugar).
  bool _foraDaArea = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _usarEnderecoSalvo());
  }

  /// Cliente logado: usa um endereço salvo em vez de pedir o CEP.
  void _usarEnderecoSalvo() {
    if (!mounted) return;

    if (ref.read(sessaoProvider).value?.isConsumidor ?? false) {
      ref.read(localEntregaProvider.notifier).usarEnderecoSalvo();
    }
  }

  void _selecionarCategoria(String? categoria) {
    setState(() {
      _categoria = categoria;
      _paginas = 1;
    });
  }

  void _alternarArea() {
    setState(() {
      _foraDaArea = !_foraDaArea;
      _categoria = null;
      _paginas = 1;
    });
  }

  Future<void> _alterarLocal() async {
    final local = await mostrarEscolherLocalSheet(context);

    if (local != null && mounted) {
      setState(() {
        _categoria = null;
        _paginas = 1;
      });
    }
  }

  void _recarregar() {
    ref.invalidate(_cacambasProvider);
    setState(() => _paginas = 1);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessaoProvider, (_, _) => _usarEnderecoSalvo());

    final local = ref.watch(localEntregaProvider);
    final area = _foraDaArea ? AreaCatalogo.fora : AreaCatalogo.dentro;

    // A API não tem rota pública de categorias: os filtros vêm das
    // categorias das caçambas da primeira página sem filtro.
    final semFiltro = local == null
        ? null
        : ref.watch(
            _cacambasProvider((
              tipoResiduo: null,
              pagina: 1,
              local: local,
              area: area,
            )),
          );
    final categorias = {
      for (final cacamba in semFiltro?.value?.itens ?? const <Cacamba>[])
        cacamba.tipoResiduo,
    }.toList()..sort();
    final filters = <String?>[null, ...categorias];

    final paginas = [
      if (local != null)
        for (var pagina = 1; pagina <= _paginas; pagina++)
          ref.watch(
            _cacambasProvider((
              tipoResiduo: _categoria,
              pagina: pagina,
              local: local,
              area: area,
            )),
          ),
    ];
    final primeira = paginas.firstOrNull;
    final cacambas = [for (final pagina in paginas) ...?pagina.value?.itens];
    final carregandoMais = paginas.length > 1 && paginas.last.isLoading;
    final temProxima = paginas.lastOrNull?.value?.temProxima ?? false;

    return Scaffold(
      drawerScrimColor: const Color(0xD9000000),
      endDrawer: const AppMenuDrawer(),
      bottomNavigationBar: const CustomerBottomNavigation(currentIndex: 1),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
                child: Builder(
                  builder: (scaffoldContext) {
                    return Row(
                      children: [
                        const Expanded(child: AppLogo()),
                        IconButton(
                          tooltip: 'Abrir menu',
                          onPressed: () {
                            Scaffold.of(scaffoldContext).openEndDrawer();
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.lightGray,
                            minimumSize: const Size(46, 46),
                          ),
                          icon: const Icon(Icons.menu_rounded),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Caçambas Disponíveis',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Escolha o volume ideal para sua necessidade',
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    if (local != null) ...[
                      _LocalEntregaBar(local: local, onAlterar: _alterarLocal),
                      const SizedBox(height: 12),
                      if (_foraDaArea)
                        _AvisoForaDaArea(onVoltar: _alternarArea)
                      else
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _alternarArea,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.green,
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.travel_explore, size: 18),
                            label: const Text(
                              'Ver caçambas fora da minha área',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    if (local != null)
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: filters.length,
                          separatorBuilder: (_, _) {
                            return const SizedBox(width: 8);
                          },
                          itemBuilder: (context, index) {
                            final filter = filters[index];
                            final selected = _categoria == filter;

                            return ChoiceChip(
                              label: Text(filter ?? allCategory),
                              selected: selected,
                              showCheckmark: false,
                              onSelected: (_) => _selecionarCategoria(filter),
                              selectedColor: AppColors.green,
                              backgroundColor: AppColors.lightGray,
                              side: BorderSide.none,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : Colors.black54,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (primeira == null)
              SliverToBoxAdapter(child: _PedirCep(onInformar: _alterarLocal))
            else if (primeira.hasError ||
                (primeira.isLoading && !primeira.hasValue))
              SliverToBoxAdapter(
                child: AsyncValueView(
                  value: primeira,
                  onRetry: _recarregar,
                  data: (_) => const SizedBox.shrink(),
                ),
              )
            else if (cacambas.isEmpty)
              SliverToBoxAdapter(child: _EmptyResult(foraDaArea: _foraDaArea))
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverList.separated(
                  itemCount: cacambas.length,
                  separatorBuilder: (_, _) {
                    return const SizedBox(height: 18);
                  },
                  itemBuilder: (context, index) {
                    final cacamba = cacambas[index];

                    return CacambaCard(
                      cacamba: cacamba,
                      onRent: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                CacambaDetailsPage(cacambaId: cacamba.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (temProxima || carregandoMais)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Center(
                      child: carregandoMais
                          ? const CircularProgressIndicator(
                              color: AppColors.green,
                            )
                          : TextButton(
                              onPressed: () => setState(() => _paginas++),
                              child: const Text(
                                'Carregar mais',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
            ],
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 28),
                child: SustainabilityFooter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.foraDaArea});

  final bool foraDaArea;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 50),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_outlined,
            size: 48,
            color: Colors.black38,
          ),
          const SizedBox(height: 12),
          Text(
            foraDaArea
                ? 'Nenhuma caçamba de fornecedores fora da sua área.'
                : 'Nenhuma caçamba disponível para o seu endereço. '
                      'Tente outro CEP de entrega ou veja as caçambas fora '
                      'da sua área.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Estado inicial: o catálogo só abre depois de saber onde é a entrega.
class _PedirCep extends StatelessWidget {
  const _PedirCep({required this.onInformar});

  final VoidCallback onInformar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            const Icon(Icons.place_outlined, size: 44, color: AppColors.green),
            const SizedBox(height: 12),
            const Text(
              'Informe o CEP de entrega',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Assim mostramos só as caçambas de fornecedores que '
              'atendem a sua região.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onInformar,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'Informar CEP',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalEntregaBar extends StatelessWidget {
  const _LocalEntregaBar({required this.local, required this.onAlterar});

  final LocalEntrega local;
  final VoidCallback onAlterar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, color: AppColors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Entrega em ${local.descricao}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: onAlterar,
            style: TextButton.styleFrom(foregroundColor: AppColors.green),
            child: const Text(
              'Alterar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoForaDaArea extends StatelessWidget {
  const _AvisoForaDaArea({required this.onVoltar});

  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Caçambas fora da sua área',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Estes fornecedores não atendem o seu endereço, então não dá '
            'para alugar. Troque o CEP de entrega para ver quem atende.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
          ),
          TextButton(
            onPressed: onVoltar,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green,
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'Voltar para caçambas na minha área',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class CacambaCard extends StatelessWidget {
  final Cacamba cacamba;
  final VoidCallback onRent;

  const CacambaCard({super.key, required this.cacamba, required this.onRent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: AspectRatio(
              aspectRatio: 2.55,
              child: CacambaImage(
                fotoUrl: cacamba.fotoUrl,
                tamanhoM3: cacamba.tamanhoM3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  cacamba.nome,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2E4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formatVolume(cacamba.tamanhoM3),
                  style: const TextStyle(
                    color: Color(0xFF6B9F46),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _CategoryBadge(category: cacamba.tipoResiduo),
          if (!cacamba.podeAlugar) ...[
            const SizedBox(height: 8),
            Text(
              cacamba.distanciaKm == null
                  ? 'Fora da área de atendimento'
                  : 'Fora da área de atendimento · a '
                        '${cacamba.distanciaKm!.toStringAsFixed(1).replaceAll('.', ',')} km',
              style: const TextStyle(
                color: Color(0xFFB26A00),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(color: AppColors.border),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valor da diária',
                      style: TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                    Text(
                      formatMoney(cacamba.precoDiaria),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 105,
                height: 44,
                child: cacamba.podeAlugar
                    ? ElevatedButton(
                        onPressed: onRent,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Alugar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: onRent,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Detalhes',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: AppColors.green,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SustainabilityFooter extends StatelessWidget {
  const SustainabilityFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sustainability,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_outlined, color: AppColors.green),
              SizedBox(width: 8),
              Text(
                'Descarte Sustentável',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Todas as nossas caçambas seguem rigorosamente as normas '
            'ambientais municipais e resoluções do CONAMA. Garantimos o '
            'destino correto para o seu entulho.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.phone_outlined, color: Colors.orange, size: 19),
              SizedBox(width: 8),
              Text(
                'Suporte WhatsApp: (11) 99999-9999',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
