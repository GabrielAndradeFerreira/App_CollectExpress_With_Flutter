import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/aluguel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';

import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../auth/data/sessao_provider.dart';
import '../../data/admin_repository.dart';
import '../../domain/models/admin_dashboard.dart';

final _dashboardProvider = FutureProvider.autoDispose<AdminDashboard>((ref) {
  return ref.watch(adminRepositoryProvider).dashboard();
});

final _pedidosRecentesProvider = FutureProvider.autoDispose<List<Aluguel>>((
  ref,
) async {
  final pagina = await ref.watch(adminRepositoryProvider).listarPedidos();
  final pedidos = [...pagina.itens]
    ..sort(
      (a, b) =>
          (b.dataPedido ?? DateTime(0)).compareTo(a.dataPedido ?? DateTime(0)),
    );
  return pedidos.take(3).toList();
});

class AdminGeralPage extends ConsumerWidget {
  const AdminGeralPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nome = ref.watch(sessaoProvider).value?.nomeCompleto;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _AdminHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 70),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _WelcomeSection(nome: nome),
                  const SizedBox(height: 26),
                  AsyncValueView(
                    value: ref.watch(_dashboardProvider),
                    onRetry: () => ref.invalidate(_dashboardProvider),
                    data: (dashboard) => Column(
                      children: [
                        _MetricsGrid(dashboard: dashboard),
                        const SizedBox(height: 26),
                        _OrdersChart(pontos: dashboard.pedidosAoLongoDoTempo),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _RecentActivity(),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PlatformAdminBottomNavigation(currentIndex: 0),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
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
                tooltip: 'Abrir menu',
                onPressed: () {
                  Scaffold.of(scaffoldContext).openEndDrawer();
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightGray,
                  minimumSize: const Size(48, 48),
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

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({this.nome});

  final String? nome;

  @override
  Widget build(BuildContext context) {
    final primeiroNome = nome?.trim().split(' ').first;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, ${primeiroNome == null || primeiroNome.isEmpty ? 'Administrador' : primeiroNome}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Visão geral da operação da Collect Xpress',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const CircleAvatar(
          radius: 29,
          backgroundColor: Color(0xFFE0E0E0),
          child: Icon(Icons.person, color: Colors.black54, size: 36),
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.dashboard});

  final AdminDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total Usuários',
                value: '${dashboard.totalUsuarios}',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _MetricCard(
                label: 'Parceiros Ativos',
                value: '${dashboard.cacambeirosAtivos}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total de Pedidos',
                value: '${dashboard.totalPedidos}',
                highlighted: true,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              // Só conta pedidos pagos.
              child: _MetricCard(
                label: 'Receita Total',
                value: formatMoney(dashboard.receitaTotal),
                valueColor: AppColors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool highlighted;

  const _MetricCard({
    required this.label,
    required this.value,
    this.valueColor,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFFDED) : AppColors.lightGray,
        border: highlighted ? Border.all(color: AppColors.yellow) : null,
        borderRadius: BorderRadius.circular(18),
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
              style: TextStyle(
                color: valueColor ?? Colors.black,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pedidos por dia nos últimos 7 dias. A API não tem receita por dia.
class _OrdersChart extends StatelessWidget {
  const _OrdersChart({required this.pontos});

  final List<PontoGrafico> pontos;

  static const _diasDaSemana = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];

  @override
  Widget build(BuildContext context) {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final datas = [
      for (var i = 6; i >= 0; i--) hoje.subtract(Duration(days: i)),
    ];
    final quantidades = [
      for (final data in datas)
        pontos
            .where((p) => p.data != null && DateUtils.isSameDay(p.data, data))
            .fold<int>(0, (total, p) => total + p.quantidade),
    ];
    final maximo = quantidades.fold<int>(0, (a, b) => a > b ? a : b);
    final values = [
      for (final quantidade in quantidades)
        maximo == 0 ? 0.0 : quantidade / maximo,
    ];
    final days = [for (final data in datas) _diasDaSemana[data.weekday - 1]];

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
          const SizedBox(height: 4),
          Text(
            maximo == 0
                ? 'Nenhum pedido nos últimos 7 dias'
                : 'Pedidos por dia nos últimos 7 dias',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (index) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: values[index],
                            child: Container(
                              width: 24,
                              decoration: BoxDecoration(
                                color: index == days.length - 1
                                    ? AppColors.green
                                    : AppColors.yellow,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${quantidades[index]}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        days[index],
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

/// Os pedidos mais recentes. A API não tem um feed de atividades.
class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pedidos Recentes',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        AsyncValueView(
          value: ref.watch(_pedidosRecentesProvider),
          onRetry: () => ref.invalidate(_pedidosRecentesProvider),
          data: (pedidos) {
            if (pedidos.isEmpty) {
              return const Text(
                'Nenhum pedido ainda.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              );
            }

            return Column(
              children: [
                for (final pedido in pedidos) ...[
                  _ActivityCard(
                    title: 'Pedido de ${pedido.consumidorNome ?? 'cliente'}',
                    description: [
                      if (pedido.cacambeiroNome != null)
                        'Fornecedor: ${pedido.cacambeiroNome}',
                      formatMoney(pedido.precoFinal),
                    ].join(' · '),
                    time: formatDate(pedido.dataPedido),
                    tag: pedido.statusAluguel?.label ?? 'Pedido',
                    tagColor: AppColors.green,
                    tagBackground: const Color(0xFFE5F6E7),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final String tag;
  final Color tagColor;
  final Color tagBackground;

  const _ActivityCard({
    required this.title,
    required this.description,
    required this.time,
    required this.tag,
    required this.tagColor,
    required this.tagBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(color: Colors.black38, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: tagBackground,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: tagColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
REMOVENDO POIS O TRECHO ABAIXO FOI SUBSTITUIDO POR:
{
bottomNavigationBar: const SupplierBottomNavigation(
  currentIndex: 0,
),
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        // A navegação será implementada na etapa de componentização.
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Usuários',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          activeIcon: Icon(Icons.local_shipping),
          label: 'Parceiros',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money),
          label: 'Finanças',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Config',
        ),
      ],
    );
  }
}
*/
