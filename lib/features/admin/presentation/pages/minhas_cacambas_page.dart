import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/cacamba.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/cacamba_image.dart';
import '../../data/fornecedor_repository.dart';
import '../fornecedor_providers.dart';
import 'cadastrar_cacamba_page.dart';

import '../../../../core/widgets/app_bottom_navigation.dart';

enum _AcaoCacamba {
  editar,
  alternarDisponibilidade,
  alternarExtensao,
  excluir,
}

class MinhasCacambasPage extends ConsumerStatefulWidget {
  const MinhasCacambasPage({super.key});

  @override
  ConsumerState<MinhasCacambasPage> createState() => _MinhasCacambasPageState();
}

class _MinhasCacambasPageState extends ConsumerState<MinhasCacambasPage> {
  String selectedFilter = 'Todas';

  final Set<String> _processando = {};

  List<Cacamba> _filtrar(List<Cacamba> cacambas) {
    switch (selectedFilter) {
      case 'Disponíveis':
        return cacambas.where((item) => item.disponivel).toList();
      case 'Indisponíveis':
        return cacambas.where((item) => !item.disponivel).toList();
      default:
        return cacambas;
    }
  }

  Future<void> _openRegistration() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CadastrarCacambaPage()),
    );

    if (!mounted || created != true) return;

    ref.invalidate(minhasCacambasProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Caçamba cadastrada. Ela já aparece no catálogo.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  Future<void> _editar(Cacamba cacamba) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CadastrarCacambaPage(cacamba: cacamba),
      ),
    );

    if (!mounted || salvou != true) return;

    ref.invalidate(minhasCacambasProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Caçamba atualizada.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  Future<void> _onAcao(Cacamba cacamba, _AcaoCacamba acao) async {
    switch (acao) {
      case _AcaoCacamba.editar:
        await _editar(cacamba);
      case _AcaoCacamba.alternarDisponibilidade:
        await _alternarDisponibilidade(cacamba);
      case _AcaoCacamba.alternarExtensao:
        await _alternarExtensao(cacamba);
      case _AcaoCacamba.excluir:
        await _excluir(cacamba);
    }
  }

  Future<void> _alternarDisponibilidade(Cacamba cacamba) async {
    final disponivel = !cacamba.disponivel;

    setState(() => _processando.add(cacamba.id));
    try {
      await ref
          .read(fornecedorRepositoryProvider)
          .atualizarCacamba(cacamba.id, disponivel: disponivel);
      if (!mounted) return;

      ref.invalidate(minhasCacambasProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            disponivel
                ? 'Caçamba marcada como disponível.'
                : 'Caçamba marcada como indisponível.',
          ),
          backgroundColor: AppColors.green,
        ),
      );
    } on ApiException catch (error) {
      if (mounted) showApiError(context, error);
    } finally {
      if (mounted) setState(() => _processando.remove(cacamba.id));
    }
  }

  Future<void> _alternarExtensao(Cacamba cacamba) async {
    final permite = !cacamba.permiteExtensao;

    setState(() => _processando.add(cacamba.id));
    try {
      await ref
          .read(fornecedorRepositoryProvider)
          .atualizarCacamba(cacamba.id, permiteExtensao: permite);
      if (!mounted) return;

      ref.invalidate(minhasCacambasProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            permite
                ? 'Extensão de aluguel ativada para esta caçamba.'
                : 'Extensão de aluguel desativada para esta caçamba.',
          ),
          backgroundColor: AppColors.green,
        ),
      );
    } on ApiException catch (error) {
      if (mounted) showApiError(context, error);
    } finally {
      if (mounted) setState(() => _processando.remove(cacamba.id));
    }
  }

  Future<void> _excluir(Cacamba cacamba) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir caçamba'),
          content: Text(
            'Deseja excluir "${cacamba.nome}"? Se ela já tiver pedidos, '
            'será apenas desativada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processando.add(cacamba.id));
    try {
      final removida = await ref
          .read(fornecedorRepositoryProvider)
          .removerCacamba(cacamba.id);
      if (!mounted) return;

      ref.invalidate(minhasCacambasProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            removida
                ? 'Caçamba excluída.'
                : 'A caçamba tem histórico de pedidos, então foi apenas '
                      'desativada.',
          ),
          backgroundColor: removida ? AppColors.green : null,
        ),
      );
    } on ApiException catch (error) {
      if (mounted) showApiError(context, error);
    } finally {
      if (mounted) setState(() => _processando.remove(cacamba.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      floatingActionButton: FloatingActionButton(
        onPressed: _openRegistration,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _AdminHeader()),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 30, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minhas Caçambas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Gerencie seus equipamentos e disponibilidade',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AsyncValueView(
                value: ref.watch(minhasCacambasProvider),
                onRetry: () => ref.invalidate(minhasCacambasProvider),
                data: _buildCacambas,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SupplierBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildCacambas(List<Cacamba> cacambas) {
    final filtradas = _filtrar(cacambas);
    final disponiveis = cacambas.where((item) => item.disponivel).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterButton('Todas', 'Todas (${cacambas.length})'),
                const SizedBox(width: 10),
                _filterButton('Disponíveis', 'Disponíveis ($disponiveis)'),
                const SizedBox(width: 10),
                _filterButton(
                  'Indisponíveis',
                  'Indisponíveis (${cacambas.length - disponiveis})',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (filtradas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  cacambas.isEmpty
                      ? 'Você ainda não cadastrou caçambas.'
                      : 'Nenhuma caçamba encontrada.',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            for (final cacamba in filtradas) ...[
              _CacambaCard(
                cacamba: cacamba,
                processando: _processando.contains(cacamba.id),
                onAcao: (acao) => _onAcao(cacamba, acao),
              ),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }

  Widget _filterButton(String filter, String label) {
    final selected = selectedFilter == filter;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.green,
      backgroundColor: AppColors.lightGray,
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black54,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) {
        setState(() {
          selectedFilter = filter;
        });
      },
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(child: AppLogo()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 4, backgroundColor: AppColors.green),
                SizedBox(width: 6),
                Text(
                  'Painel Admin',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightGray,
                  minimumSize: const Size(46, 46),
                ),
                icon: const Icon(Icons.menu_rounded),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CacambaCard extends StatelessWidget {
  final Cacamba cacamba;
  final bool processando;
  final ValueChanged<_AcaoCacamba> onAcao;

  const _CacambaCard({
    required this.cacamba,
    required this.processando,
    required this.onAcao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 142,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 120,
              height: double.infinity,
              child: CacambaImage(
                fotoUrl: cacamba.fotoUrl,
                tamanhoM3: cacamba.tamanhoM3,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cacamba.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${formatVolume(cacamba.tamanhoM3)} • ${cacamba.tipoResiduo}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      text: formatMoney(cacamba.precoDiaria),
                      children: const [
                        TextSpan(
                          text: '/dia',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatusBadge(disponivel: cacamba.disponivel),
              if (cacamba.permiteExtensao) ...[
                const SizedBox(height: 4),
                const _ExtensaoBadge(),
              ],
              const Spacer(),
              if (processando)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.green,
                    ),
                  ),
                )
              else
                PopupMenuButton<_AcaoCacamba>(
                  tooltip: 'Opções',
                  icon: const Icon(Icons.more_vert, color: Colors.black54),
                  onSelected: onAcao,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: _AcaoCacamba.editar,
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: _AcaoCacamba.alternarDisponibilidade,
                      child: Text(
                        cacamba.disponivel
                            ? 'Marcar como indisponível'
                            : 'Marcar como disponível',
                      ),
                    ),
                    PopupMenuItem(
                      value: _AcaoCacamba.alternarExtensao,
                      child: Text(
                        cacamba.permiteExtensao
                            ? 'Não permitir extensão do aluguel'
                            : 'Permitir extensão do aluguel',
                      ),
                    ),

                    const PopupMenuItem(
                      value: _AcaoCacamba.excluir,
                      child: Text(
                        'Excluir',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Marca as caçambas que aceitam pedidos de extensão de aluguel.
class _ExtensaoBadge extends StatelessWidget {
  const _ExtensaoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('badge_extensao'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Text(
        'Extensão ativa',
        style: TextStyle(
          color: Color(0xFF8A6100),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool disponivel;

  const _StatusBadge({required this.disponivel});

  @override
  Widget build(BuildContext context) {
    final label = disponivel ? 'Disponível' : 'Indisponível';
    final foregroundColor = disponivel ? AppColors.green : Colors.red;
    final backgroundColor = disponivel
        ? const Color(0xFFE7F6E8)
        : const Color(0xFFFFE8E8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
/*
REMOVENDO POIS O TRECHO ABAIXO FOI SUBSTITUIDO POR:
{
bottomNavigationBar: const SupplierBottomNavigation(
  currentIndex: 2,
),
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      onTap: (_) {},
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.delete_outline),
          label: 'Caçambas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_outlined),
          label: 'Pedidos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}
*/
