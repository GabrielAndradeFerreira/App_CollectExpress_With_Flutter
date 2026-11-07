import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/aluguel.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/models/pagina.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../auth/data/sessao_provider.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../data/pedidos_repository.dart';
import '../pedidos_format.dart';
import 'acompanhar_pedido_page.dart';

/// Uma página (20 pedidos) dos pedidos do cliente logado.
final _meusPedidosProvider = FutureProvider.autoDispose
    .family<Pagina<Aluguel>, int>((ref, pagina) {
      return ref.watch(pedidosRepositoryProvider).meusPedidos(pagina: pagina);
    });

class MeusPedidosPage extends ConsumerStatefulWidget {
  const MeusPedidosPage({super.key});

  @override
  ConsumerState<MeusPedidosPage> createState() => _MeusPedidosPageState();
}

class _MeusPedidosPageState extends ConsumerState<MeusPedidosPage> {
  /// Quantas páginas de pedidos estão sendo mostradas.
  int _paginas = 1;

  @override
  Widget build(BuildContext context) {
    // Depois de entrar pelo botão "Entrar" (erro 401), recarrega a lista.
    ref.listen(sessaoProvider.select((sessao) => sessao.value?.id), (
      anterior,
      atual,
    ) {
      if (atual != null && atual != anterior) _recarregar();
    });

    final paginas = [
      for (var pagina = 1; pagina <= _paginas; pagina++)
        ref.watch(_meusPedidosProvider(pagina)),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      drawerScrimColor: const Color(0xD9000000),
      endDrawer: const AppMenuDrawer(),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: _recarregar,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _PageHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meus Pedidos',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Acompanhe o andamento das suas locações de caçamba',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 22),
                      _buildPedidos(paginas),
                    ],
                  ),
                ),
              ),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_SustainabilityFooter()],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomerBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildPedidos(List<AsyncValue<Pagina<Aluguel>>> paginas) {
    final itens = <Widget>[];

    for (var i = 0; i < paginas.length; i++) {
      final numeroPagina = i + 1;
      final pagina = paginas[i];

      if (!pagina.hasValue) {
        itens.add(
          AsyncValueView<Pagina<Aluguel>>(
            value: pagina,
            onRetry: () => ref.invalidate(_meusPedidosProvider(numeroPagina)),
            data: (_) => const SizedBox.shrink(),
          ),
        );
        break;
      }

      final dados = pagina.value!;

      if (i == 0 && dados.itens.isEmpty) return const _EmptyOrdersView();

      for (final pedido in dados.itens) {
        itens.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _OrderCard(
              pedido: pedido,
              onTrack: () => _abrirPedido(pedido),
              onChat: () => abrirConversaDoPedido(context, ref, pedido.id),
            ),
          ),
        );
      }

      if (i == paginas.length - 1) {
        if (dados.temProxima) {
          itens.add(
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _paginas++),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF267A2D),
                ),
                icon: const Icon(Icons.expand_more),
                label: const Text(
                  'Ver mais pedidos',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          );
        }

        itens.addAll([
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.services, (route) => false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Alugar Outra Caçamba',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ]);
      }
    }

    return Column(children: itens);
  }

  Future<void> _recarregar() async {
    setState(() => _paginas = 1);
    ref.invalidate(_meusPedidosProvider);

    try {
      await ref.read(_meusPedidosProvider(1).future);
    } catch (_) {
      // O erro aparece na própria lista.
    }
  }

  Future<void> _abrirPedido(Aluguel pedido) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AcompanharPedidoPage(aluguelId: pedido.id),
      ),
    );

    // O status pode ter mudado enquanto o pedido estava aberto.
    if (mounted) ref.invalidate(_meusPedidosProvider);
  }
}

class _EmptyOrdersView extends StatelessWidget {
  const _EmptyOrdersView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 42,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhum pedido no momento',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Você ainda não fez nenhum pedido de caçamba. '
            'Escolha o modelo ideal para sua obra ou reforma e finalize sua solicitação.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.services, (route) => false);
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.search),
              label: const Text(
                'Buscar Caçambas Disponíveis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Aluguel pedido;
  final VoidCallback onTrack;
  final VoidCallback onChat;

  const _OrderCard({
    required this.pedido,
    required this.onTrack,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final status = pedido.statusAluguel;
    final pagamento = pedido.statusPagamento;
    final endereco = pedido.endereco;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pedido.codigo ?? 'Pedido de ${formatDate(pedido.dataPedido)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (status != null) _StatusBadge(status: status),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Detalhes do pedido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.green,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pedido.cacambeiroNome ?? 'Locação de caçamba',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Período contratado: ${formatDias(pedido.diasAluguel)}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatMoney(pedido.precoFinal),
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (pagamento != null)
                        Text(
                          'Pagamento ${pagamento.label}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Informações de Entrega
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Início: ${formatDate(pedido.dataInicio)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (endereco != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${endereco.ruaENumero} - ${endereco.regiaoECep}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Ação
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onTrack,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text(
                  status == StatusAluguel.finalizado
                      ? 'Ver Pedido'
                      : 'Acompanhar Pedido',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                key: Key('pedido_chat_${pedido.id}'),
                onPressed: onChat,
                style: TextButton.styleFrom(foregroundColor: AppColors.green),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text(
                  'Conversar com a empresa',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final StatusAluguel status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, text) = switch (status) {
      StatusAluguel.finalizado => (const Color(0xFFE8F5E9), AppColors.green),
      StatusAluguel.emUso || StatusAluguel.aguardandoRetirada => (
        const Color(0xFFE3F2FD),
        Colors.blue.shade700,
      ),
      StatusAluguel.aguardandoEntrega => (
        const Color(0xFFEAF6E8),
        AppColors.green,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Row(
        children: [
          const Expanded(child: AppLogo()),
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

class _SustainabilityFooter extends StatelessWidget {
  const _SustainabilityFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco_outlined, color: AppColors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Descarte Sustentável Garantido',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Seus resíduos são destinados a centros de triagem e reciclagem certificados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
