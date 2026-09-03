import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

class DetalhesPedidoPage extends StatefulWidget {
  const DetalhesPedidoPage({super.key});

  @override
  State<DetalhesPedidoPage> createState() => _DetalhesPedidoPageState();
}

class _DetalhesPedidoPageState extends State<DetalhesPedidoPage> {
  bool deliveryConfirmed = false;

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
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 70),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Detalhes do Pedido',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Informações completas de entrega e pagamento',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _StatusCard(deliveryConfirmed: deliveryConfirmed),

                  const SizedBox(height: 28),
                  const _SectionTitle('Informações do Cliente'),
                  const SizedBox(height: 12),
                  const _CustomerCard(),

                  const SizedBox(height: 28),
                  const _SectionTitle('Serviço & Pagamento'),
                  const SizedBox(height: 12),
                  const _PaymentCard(),

                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          deliveryConfirmed ? null : _confirmDelivery,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.green.withValues(alpha: 0.5),
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        deliveryConfirmed
                            ? 'Entrega Confirmada'
                            : 'Confirmar Entrega da Caçamba',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _contactCustomer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.green,
                        side: const BorderSide(color: AppColors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Contatar Cliente via WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
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

  void _confirmDelivery() {
    setState(() {
      deliveryConfirmed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entrega confirmada com sucesso!'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  void _contactCustomer() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A integração com o WhatsApp será adicionada depois.'),
      ),
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
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          const Expanded(child: AppLogo()),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.green,
                ),
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

class _StatusCard extends StatelessWidget {
  final bool deliveryConfirmed;

  const _StatusCard({required this.deliveryConfirmed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status da Locação: #COL-2024-1587',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          const _TimelineItem(
            title: 'Pedido Recebido',
            subtitle: '✓ Concluído às 09:12',
            completed: true,
          ),
          const _TimelineItem(
            title: 'Entrega Agendada',
            subtitle: '✓ Hoje às 14:00',
            completed: true,
          ),
          _TimelineItem(
            title: 'Caçamba Entregue',
            subtitle: deliveryConfirmed
                ? '✓ Entrega confirmada'
                : 'Aguardando confirmação',
            completed: deliveryConfirmed,
          ),
          const _TimelineItem(
            title: 'Coleta Agendada',
            subtitle: '28 Out às 16:00',
            completed: false,
            showLine: false,
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool completed;
  final bool showLine;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.completed,
    this.showLine = true,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed
                        ? AppColors.green
                        : const Color(0xFFE8E8E8),
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE1E1E1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: completed ? Colors.black : Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            'Nome: Maria Silva',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          const Text(
            'Telefone: (11) 98888-7777',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Endereço: Av. Paulista, 1000 - Bela Vista, São Paulo - SP',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: 145,
              child: Image.asset(
                'assets/images/mapa_entrega.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return Container(
                    color: AppColors.lightGray,
                    child: const Center(
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 55,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          _InformationRow(
            label: 'Caçamba Alugada:',
            value: '5m³ - Entulho Obra',
          ),
          SizedBox(height: 14),
          _InformationRow(
            label: 'Período Contratado:',
            value: '5 Dias Corridos',
          ),
          SizedBox(height: 14),
          _InformationRow(
            label: 'Método de Pagamento:',
            value: 'PIX (Pago ✓)',
            valueColor: AppColors.green,
          ),
          SizedBox(height: 14),
          Divider(color: AppColors.border),
          SizedBox(height: 8),
          _InformationRow(
            label: 'Valor Total:',
            value: 'R\$ 350,00',
            valueColor: AppColors.green,
            highlighted: true,
          ),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool highlighted;

  const _InformationRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: highlighted ? Colors.black : Colors.black54,
              fontSize: highlighted ? 15 : 13,
              fontWeight:
                  highlighted ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            color: valueColor ?? Colors.black,
            fontSize: highlighted ? 20 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation();

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