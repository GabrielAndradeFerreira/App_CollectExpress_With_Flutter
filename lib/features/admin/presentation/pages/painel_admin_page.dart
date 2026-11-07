import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/aluguel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../auth/data/sessao_provider.dart';
import '../../domain/models/fornecedor_dashboard.dart';
import '../fornecedor_providers.dart';
import '../widgets/aviso_pendencias_fornecedor.dart';
import '../widgets/pedido_fornecedor.dart';
import 'detalhes_pedido_page.dart';

import '../../../../core/widgets/app_bottom_navigation.dart';

class PainelAdminPage extends ConsumerWidget {
  const PainelAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _AdminHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 50),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const AvisoPendenciasFornecedor(),
                  const _WelcomeSection(),
                  const SizedBox(height: 24),
                  AsyncValueView(
                    value: ref.watch(fornecedorDashboardProvider),
                    onRetry: () => ref.invalidate(fornecedorDashboardProvider),
                    data: (dashboard) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetricsGrid(dashboard: dashboard),
                        const SizedBox(height: 24),
                        AsyncValueView(
                          value: ref.watch(pedidosRecebidosProvider),
                          onRetry: () =>
                              ref.invalidate(pedidosRecebidosProvider),
                          data: (pedidos) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _WeeklyOrdersCard(pedidos: pedidos),
                              const SizedBox(height: 24),
                              _LatestOrdersSection(pedidos: pedidos),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SupplierBottomNavigation(currentIndex: 0),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class _WelcomeSection extends ConsumerWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(sessaoProvider).value;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario == null ? 'Olá!' : 'Olá, ${usuario.nomeCompleto}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                usuario?.email ?? 'Fornecedor de caçambas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        const CircleAvatar(
          radius: 30,
          backgroundColor: Color(0xFFE0E0E0),
          child: Icon(Icons.person, size: 38, color: Colors.black54),
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final FornecedorDashboard dashboard;

  const _MetricsGrid({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final nota = dashboard.notaMedia;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Pedidos Ativos',
                value: '${dashboard.pedidosAtivos}',
                highlighted: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                label: 'Total de Pedidos',
                value: '${dashboard.totalPedidos}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Receita Líquida',
                value: formatMoney(dashboard.receitaLiquida),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                label: 'Avaliação (${dashboard.totalAvaliacoes})',
                value: nota == null
                    ? '-'
                    : '${nota.toStringAsFixed(1).replaceAll('.', ',')} ★',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'A receita considera só pedidos finalizados e pagos, já descontada '
          'a taxa da plataforma.',
          style: TextStyle(color: Colors.black54, fontSize: 11),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _MetricCard({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFFDEC) : AppColors.lightGray,
        border: highlighted ? Border.all(color: AppColors.yellow) : null,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pedidos recebidos em cada um dos últimos 7 dias, por data do pedido.
class _WeeklyOrdersCard extends StatelessWidget {
  final List<Aluguel> pedidos;

  const _WeeklyOrdersCard({required this.pedidos});

  static const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hoje = DateTime(now.year, now.month, now.day);
    final dias = [
      for (var i = 6; i >= 0; i--) hoje.subtract(Duration(days: i)),
    ];

    final contagem = [
      for (final dia in dias)
        pedidos.where((pedido) {
          final data = pedido.dataPedido?.toLocal();
          return data != null &&
              data.year == dia.year &&
              data.month == dia.month &&
              data.day == dia.day;
        }).length,
    ];
    final maior = contagem.fold(0, (a, b) => a > b ? a : b);

    return Container(
      height: 270,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pedidos da Semana',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          const Text(
            'Pedidos recebidos nos últimos 7 dias',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(dias.length, (index) {
                final isToday = index == dias.length - 1;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            // Uma linha mínima marca os dias sem pedidos.
                            heightFactor: maior == 0
                                ? 0.03
                                : (contagem[index] / maior).clamp(0.03, 1.0),
                            child: Container(
                              width: 24,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppColors.green
                                    : const Color(0xFF82AA52),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${contagem[index]}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        days[dias[index].weekday - 1],
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestOrdersSection extends StatelessWidget {
  final List<Aluguel> pedidos;

  const _LatestOrdersSection({required this.pedidos});

  @override
  Widget build(BuildContext context) {
    final recentes = [...pedidos]
      ..sort((a, b) {
        final dataA = a.dataPedido;
        final dataB = b.dataPedido;
        if (dataA == null) return dataB == null ? 0 : 1;
        if (dataB == null) return -1;
        return dataB.compareTo(dataA);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimos Pedidos',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const Text(
          'Pedidos recebidos mais recentes',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 14),
        if (recentes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                'Você ainda não recebeu pedidos.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          )
        else
          for (final pedido in recentes.take(3)) ...[
            _OrderCard(pedido: pedido),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Aluguel pedido;

  const _OrderCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightGray,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetalhesPedidoPage(aluguelId: pedido.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pedido.consumidorNome ?? 'Cliente',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Pedido em ${formatDate(pedido.dataPedido)} • '
                      '${formatDias(pedido.diasAluguel)}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Início da locação: ${formatDate(pedido.dataInicio)}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusAluguelBadge(status: pedido.statusAluguel),
                  const SizedBox(height: 10),
                  Text(
                    formatMoney(pedido.precoFinal),
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
