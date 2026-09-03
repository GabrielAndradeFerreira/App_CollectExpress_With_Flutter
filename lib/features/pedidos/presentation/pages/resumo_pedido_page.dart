import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

class ResumoPedidoPage extends StatefulWidget {
  const ResumoPedidoPage({super.key});

  @override
  State<ResumoPedidoPage> createState() => _ResumoPedidoPageState();
}

class _ResumoPedidoPageState extends State<ResumoPedidoPage> {
  int selectedDays = 3;

  double get subtotal {
    switch (selectedDays) {
      case 5:
        return 400;
      case 7:
        return 450;
      default:
        return 350;
    }
  }

  double get discount => subtotal * 0.10;
  double get total => subtotal - discount;

  String formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawerScrimColor: const Color(0xD9000000),
      endDrawer: const AppMenuDrawer(),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const _PageHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumo do seu Pedido',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const Text(
                          'Confirme os detalhes da locação',
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                        const SizedBox(height: 18),
                        _buildProductCard(),
                        const SizedBox(height: 28),
                        const _SectionTitle('Endereço de entrega:'),
                        const SizedBox(height: 10),
                        const _AddressCard(),
                        const SizedBox(height: 28),
                        const _SectionTitle('Resumo de Valores:'),
                        const SizedBox(height: 10),
                        _buildValuesCard(),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _finishOrder,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            child: const Text(
                              'Finalizar Pedido',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
      bottomNavigationBar: const _PedidoBottomNavigation(),
    );
  }

  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/cacamba_5m.jpg',
                  width: 115,
                  height: 115,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 115,
                    height: 115,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caçamba 5m³ - Entulho',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Período padrão: 3 dias',
                      style: TextStyle(color: Colors.black54),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'R\$ 350,00',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          const Text(
            'Alterar período de locação:',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PeriodButton(
                  days: 3,
                  subtitle: 'Incluso',
                  selected: selectedDays == 3,
                  onTap: () => setState(() => selectedDays = 3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PeriodButton(
                  days: 5,
                  subtitle: '+ R\$ 50',
                  selected: selectedDays == 5,
                  onTap: () => setState(() => selectedDays = 5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PeriodButton(
                  days: 7,
                  subtitle: '+ R\$ 100',
                  selected: selectedDays == 7,
                  onTap: () => setState(() => selectedDays = 7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValuesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _ValueRow(
            label: 'Subtotal Caçamba (1x)',
            value: formatMoney(subtotal),
          ),
          const SizedBox(height: 8),
          const _ValueRow(
            label: 'Taxa de Entrega',
            value: 'Grátis',
            valueColor: AppColors.green,
          ),
          const SizedBox(height: 8),
          _ValueRow(
            label: 'Desconto Primeira Locação',
            value: '- ${formatMoney(discount)}',
            valueColor: Colors.red,
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border),
          const SizedBox(height: 6),
          _ValueRow(
            label: 'Valor Total:',
            value: formatMoney(total),
            valueColor: AppColors.green,
            bold: true,
          ),
        ],
      ),
    );
  }

  void _finishOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pedido finalizado com sucesso!'),
        backgroundColor: AppColors.green,
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
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

class _PeriodButton extends StatelessWidget {
  final int days;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.days,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.green : Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$days dias',
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.location_on_outlined, color: AppColors.green),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avenida Paulista, 1000',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Bela Vista, São Paulo - SP • CEP 01311-200',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _ValueRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? Colors.black : Colors.black54,
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.black,
            fontSize: bold ? 19 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

class _SustainabilityFooter extends StatelessWidget {
  const _SustainabilityFooter();

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
          Text(
            '☎  Suporte WhatsApp: (11) 99999-9999',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PedidoBottomNavigation extends StatelessWidget {
  const _PedidoBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2,
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
