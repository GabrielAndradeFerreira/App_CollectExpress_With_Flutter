import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

class PainelAdminPage extends StatelessWidget {
  const PainelAdminPage({super.key});

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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 50),
              sliver: SliverList(
                delegate: SliverChildListDelegate(const [
                  _WelcomeSection(),
                  SizedBox(height: 24),
                  _MetricsGrid(),
                  SizedBox(height: 24),
                  _WeeklyOrdersCard(),
                  SizedBox(height: 24),
                  _LatestOrdersSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _AdminBottomNavigation(),
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

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, João da Silva!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Caçambas São Paulo Express • CNPJ: 12.345.678/0001-90',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        SizedBox(width: 14),
        CircleAvatar(
          radius: 30,
          backgroundColor: Color(0xFFE0E0E0),
          child: Icon(Icons.person, size: 38, color: Colors.black54),
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(label: 'Caçambas Ativas', value: '12'),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                label: 'Pedidos Hoje',
                value: '5',
                highlighted: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(label: 'Faturamento Mês', value: 'R\$ 8.450'),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _MetricCard(label: 'Avaliação Loja', value: '4.8 ★'),
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
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _WeeklyOrdersCard extends StatelessWidget {
  const _WeeklyOrdersCard();

  static const values = <double>[0.30, 0.55, 0.40, 0.80, 0.60, 1.00, 0.70];

  static const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
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
            'Acompanhamento semanal de locações',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 20),
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
                                color: index == 5
                                    ? AppColors.green
                                    : const Color(0xFF82AA52),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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

class _LatestOrdersSection extends StatelessWidget {
  const _LatestOrdersSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Últimos Pedidos',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        Text(
          'Novos agendamentos e entregas pendentes',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        SizedBox(height: 14),
        _OrderCard(
          number: 'COL-2024-1587',
          customer: 'Maria Silva',
          dumpster: '5m³ Entulho',
          schedule: 'Hoje, 10:30',
          status: 'Em andamento',
          statusColor: Color(0xFF9A6D00),
          statusBackground: Color(0xFFFFF9D9),
        ),
        SizedBox(height: 14),
        _OrderCard(
          number: 'COL-2024-1580',
          customer: 'José Santos',
          dumpster: '3m³ Recicláveis',
          schedule: 'Ontem, 16:45',
          status: 'Concluído',
          statusColor: AppColors.green,
          statusBackground: Color(0xFFE5F6E7),
        ),
        SizedBox(height: 14),
        _OrderCard(
          number: 'COL-2024-1575',
          customer: 'Carlos Souza',
          dumpster: '7m³ Poda',
          schedule: '24 Out, 09:00',
          status: 'Agendado',
          statusColor: Colors.black54,
          statusBackground: Color(0xFFF1F1F1),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String number;
  final String customer;
  final String dumpster;
  final String schedule;
  final String status;
  final Color statusColor;
  final Color statusBackground;

  const _OrderCard({
    required this.number,
    required this.customer,
    required this.dumpster,
    required this.schedule,
    required this.status,
    required this.statusColor,
    required this.statusBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Cliente: $customer • $dumpster',
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
                const SizedBox(height: 7),
                Text(
                  'Agendado para: $schedule',
                  style: const TextStyle(color: Colors.black54, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'R\$ 350,00',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
