import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

enum FinancialPeriod { hoje, semana, mes, ano }

class RelatorioFinanceiroPage extends StatefulWidget {
  const RelatorioFinanceiroPage({super.key});

  @override
  State<RelatorioFinanceiroPage> createState() =>
      _RelatorioFinanceiroPageState();
}

class _RelatorioFinanceiroPageState extends State<RelatorioFinanceiroPage> {
  FinancialPeriod selectedPeriod = FinancialPeriod.mes;

  final transactions = const [
    FinancialTransaction(
      company: 'Leste Caçambas',
      description: 'Locação 5m³ • Hoje, 10:30',
      value: 350,
      type: TransactionType.income,
    ),
    FinancialTransaction(
      company: 'Paulista Descarte',
      description: 'Locação 3m³ • Hoje, 09:15',
      value: 280,
      type: TransactionType.income,
    ),
    FinancialTransaction(
      company: 'Norte Entulhos',
      description: 'Repasse de saldo • Ontem, 16:00',
      value: 1200,
      type: TransactionType.expense,
    ),
    FinancialTransaction(
      company: 'Vale Verde LTDA',
      description: 'Taxa cadastral • Ontem, 11:20',
      value: 150,
      type: TransactionType.income,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 80),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Relatório Financeiro',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Acompanhe receitas, despesas e margem operacional',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  _PeriodFilters(
                    selectedPeriod: selectedPeriod,
                    onSelected: (period) {
                      setState(() => selectedPeriod = period);
                    },
                  ),
                  const SizedBox(height: 18),
                  const _MetricsGrid(),
                  const SizedBox(height: 24),
                  const _RevenueCostsChart(),
                  const SizedBox(height: 28),
                  const Text(
                    'Últimas Transações',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  ...transactions.map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TransactionCard(transaction: transaction),
                    ),
                  ),
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

class FinancialTransaction {
  final String company;
  final String description;
  final double value;
  final TransactionType type;

  const FinancialTransaction({
    required this.company,
    required this.description,
    required this.value,
    required this.type,
  });
}

enum TransactionType { income, expense }

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

class _PeriodFilters extends StatelessWidget {
  final FinancialPeriod selectedPeriod;
  final ValueChanged<FinancialPeriod> onSelected;

  const _PeriodFilters({
    required this.selectedPeriod,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const periods = [
      (FinancialPeriod.hoje, 'Hoje'),
      (FinancialPeriod.semana, 'Semana'),
      (FinancialPeriod.mes, 'Mês'),
      (FinancialPeriod.ano, 'Ano'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: periods.map((item) {
        final selected = selectedPeriod == item.$1;

        return ChoiceChip(
          label: Text(item.$2),
          selected: selected,
          showCheckmark: false,
          selectedColor: AppColors.green,
          backgroundColor: AppColors.lightGray,
          side: BorderSide.none,
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w700,
          ),
          onSelected: (_) => onSelected(item.$1),
        );
      }).toList(),
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
              child: _MetricCard(
                label: 'Receita Bruta',
                value: 'R\$ 127.450',
                valueColor: AppColors.green,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: _MetricCard(
                label: 'Custos Operacionais',
                value: 'R\$ 42.300',
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Lucro Líquido',
                value: 'R\$ 85.150',
                highlighted: true,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: _MetricCard(label: 'Ticket Médio', value: 'R\$ 338'),
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
        color: highlighted ? const Color(0xFFE7F6E8) : AppColors.lightGray,
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

class _RevenueCostsChart extends StatelessWidget {
  const _RevenueCostsChart();

  static const months = ['Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out'];
  static const revenues = [0.60, 0.70, 0.81, 0.75, 0.90, 1.00];
  static const costs = [0.20, 0.23, 0.25, 0.24, 0.27, 0.30];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
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
            'Receita vs Custos',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Acompanhamento mensal comparativo (Últimos 6 meses)',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(months.length, (index) {
                return Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FractionallySizedBox(
                              heightFactor: revenues[index],
                              child: Container(
                                width: 11,
                                decoration: BoxDecoration(
                                  color: AppColors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            FractionallySizedBox(
                              heightFactor: costs[index],
                              child: Container(
                                width: 11,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        months[index],
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
          const SizedBox(height: 14),
          const Row(
            children: [
              _Legend(color: AppColors.green, label: 'Receita'),
              SizedBox(width: 20),
              _Legend(color: Colors.red, label: 'Custos'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 11),
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final FinancialTransaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final income = transaction.type == TransactionType.income;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.company,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  transaction.description,
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${income ? '+' : '-'} ${_formatMoney(transaction.value)}',
                style: TextStyle(
                  color: income ? AppColors.green : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                income ? 'Entrada' : 'Saída',
                style: const TextStyle(color: Colors.black38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMoney(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'R\$ $integer,${parts.last}';
  }
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 3,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        // A navegação será implementada durante a componentização.
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'Usuários',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          label: 'Parceiros',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money),
          label: 'Finanças',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Config',
        ),
      ],
    );
  }
}
