import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/aluguel.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../fornecedor_providers.dart';
import '../widgets/pedido_fornecedor.dart';
import 'detalhes_pedido_page.dart';

import '../../../../core/widgets/app_bottom_navigation.dart';

class GestaoPedidosPage extends ConsumerStatefulWidget {
  const GestaoPedidosPage({super.key});

  @override
  ConsumerState<GestaoPedidosPage> createState() => _GestaoPedidosPageState();
}

class _GestaoPedidosPageState extends ConsumerState<GestaoPedidosPage> {
  /// `null` mostra todos os pedidos.
  StatusAluguel? selectedFilter;

  final Set<String> _atualizando = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _AdminHeader()),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 30, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestão de Pedidos',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Monitore e atualize o status das locações',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AsyncValueView(
                value: ref.watch(pedidosRecebidosProvider),
                onRetry: () => ref.invalidate(pedidosRecebidosProvider),
                data: _buildPedidos,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SupplierBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildPedidos(List<Aluguel> pedidos) {
    final filtrados = selectedFilter == null
        ? pedidos
        : pedidos
              .where((pedido) => pedido.statusAluguel == selectedFilter)
              .toList();

    int count(StatusAluguel status) {
      return pedidos.where((pedido) => pedido.statusAluguel == status).length;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(status: null, label: 'Todos (${pedidos.length})'),
                for (final status in StatusAluguel.values) ...[
                  const SizedBox(width: 10),
                  _filterChip(
                    status: status,
                    label: '${status.label} (${count(status)})',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (filtrados.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  pedidos.isEmpty
                      ? 'Você ainda não recebeu pedidos.'
                      : 'Nenhum pedido encontrado.',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            for (final pedido in filtrados) ...[
              _OrderCard(
                order: pedido,
                atualizando: _atualizando.contains(pedido.id),
                onTap: () => _openOrderDetails(pedido),
                onAdvance: () => _avancarStatus(pedido),
                onChat: () => abrirConversaDoPedido(context, ref, pedido.id),
              ),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }

  Widget _filterChip({required StatusAluguel? status, required String label}) {
    final selected = selectedFilter == status;

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
          selectedFilter = status;
        });
      },
    );
  }

  void _openOrderDetails(Aluguel order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalhesPedidoPage(aluguelId: order.id),
      ),
    );
  }

  Future<void> _avancarStatus(Aluguel pedido) async {
    final proximo = pedido.statusAluguel?.proximo;
    if (proximo == null || _atualizando.contains(pedido.id)) return;

    if (!await confirmarAvancoStatus(context, proximo) || !mounted) return;

    setState(() => _atualizando.add(pedido.id));
    try {
      final atualizado = await avancarStatusPedido(
        context,
        ref,
        pedido.id,
        proximo,
      );

      // Com um filtro ativo, segue o pedido para a nova etapa.
      if (atualizado && mounted && selectedFilter != null) {
        setState(() => selectedFilter = proximo);
      }
    } finally {
      if (mounted) setState(() => _atualizando.remove(pedido.id));
    }
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
            builder: (scaffoldContext) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(scaffoldContext).openEndDrawer();
                },
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

class _OrderCard extends StatelessWidget {
  final Aluguel order;
  final bool atualizando;
  final VoidCallback onTap;
  final VoidCallback onAdvance;
  final VoidCallback onChat;

  const _OrderCard({
    required this.order,
    required this.atualizando,
    required this.onTap,
    required this.onAdvance,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final pagamento = order.statusPagamento?.label ?? '-';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.consumidorNome ?? 'Cliente',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusAluguelBadge(status: order.statusAluguel),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Endereço: ${formatEnderecoPedido(order.endereco)}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 7),
              Text(
                'Início: ${formatDate(order.dataInicio)} • '
                '${formatDias(order.diasAluguel)}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 7),
              Text(
                'Valor: ${formatMoney(order.precoFinal)} • '
                'Pagamento: $pagamento',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 18),
              const Divider(color: AppColors.border),
              const SizedBox(height: 10),
              _buildActions(),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  key: Key('pedido_chat_${order.id}'),
                  onPressed: onChat,
                  style: TextButton.styleFrom(foregroundColor: AppColors.green),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text(
                    'Conversar com o cliente',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final proximo = order.statusAluguel?.proximo;

    if (proximo == null) {
      return SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.lightGray,
            foregroundColor: Colors.black54,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: const Text(
            'Visualizar Detalhes do Pedido',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: atualizando ? null : onAdvance,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.green.withValues(alpha: 0.55),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: atualizando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                textoAvancarStatus(proximo),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
