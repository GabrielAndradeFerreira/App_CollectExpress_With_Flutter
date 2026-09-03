import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

import 'detalhes_pedido_page.dart';
enum AdminOrderStatus { novo, emAndamento, concluido }

class AdminOrder {
  final String number;
  final String customer;
  final String equipment;
  final String address;
  AdminOrderStatus status;

  AdminOrder({
    required this.number,
    required this.customer,
    required this.equipment,
    required this.address,
    required this.status,
  });
}

class GestaoPedidosPage extends StatefulWidget {
  const GestaoPedidosPage({super.key});

  @override
  State<GestaoPedidosPage> createState() => _GestaoPedidosPageState();
}

class _GestaoPedidosPageState extends State<GestaoPedidosPage> {
  AdminOrderStatus selectedFilter = AdminOrderStatus.novo;

  final List<AdminOrder> orders = [
    AdminOrder(
      number: '#COL-2024-1587',
      customer: 'Maria Silva',
      equipment: '5m³ Entulho',
      address: 'Av. Paulista, 1000 - Bela Vista',
      status: AdminOrderStatus.novo,
    ),
    AdminOrder(
      number: '#COL-2024-1582',
      customer: 'Roberto Costa',
      equipment: '7m³ Recicláveis',
      address: 'R. Augusta, 500 - Consolação',
      status: AdminOrderStatus.emAndamento,
    ),
    AdminOrder(
      number: '#COL-2024-1579',
      customer: 'Claudio Pinheiro',
      equipment: '3m³ Poda',
      address: 'Al. Lorena, 250 - Jardins',
      status: AdminOrderStatus.concluido,
    ),
  ];

  List<AdminOrder> get filteredOrders {
    return orders.where((order) => order.status == selectedFilter).toList();
  }

  int count(AdminOrderStatus status) {
    return orders.where((order) => order.status == status).length;
  }

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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 30, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestão de Pedidos',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Monitore e atualize o status das locações',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip(
                            status: AdminOrderStatus.novo,
                            label: 'Novos (${count(AdminOrderStatus.novo)})',
                          ),
                          const SizedBox(width: 10),
                          _filterChip(
                            status: AdminOrderStatus.emAndamento,
                            label:
                                'Em Andamento (${count(AdminOrderStatus.emAndamento)})',
                          ),
                          const SizedBox(width: 10),
                          _filterChip(
                            status: AdminOrderStatus.concluido,
                            label:
                                'Concluídos (${count(AdminOrderStatus.concluido)})',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (filteredOrders.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Nenhum pedido encontrado.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 70),
                sliver: SliverList.separated(
                  itemCount: filteredOrders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];

                    return _OrderCard(
                      order: order,
                      onAccept: () => _changeStatus(
                        order,
                        AdminOrderStatus.emAndamento,
                        'Pedido aceito.',
                      ),
                      onReject: () => _rejectOrder(order),
                      onDelivered: () => _changeStatus(
                        order,
                        AdminOrderStatus.concluido,
                        'Pedido marcado como entregue.',
                      ),
                      onHistory: () => _showHistory(order),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const _AdminBottomNavigation(),
    );
  }

  Widget _filterChip({
    required AdminOrderStatus status,
    required String label,
  }) {
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
        setState(() => selectedFilter = status);
      },
    );
  }

  void _changeStatus(
    AdminOrder order,
    AdminOrderStatus status,
    String message,
  ) {
    setState(() {
      order.status = status;
      selectedFilter = status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.green),
    );
  }

  Future<void> _rejectOrder(AdminOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recusar pedido'),
          content: Text('Deseja recusar o pedido ${order.number}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Recusar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      orders.remove(order);
    });
  }

  void _showHistory(AdminOrder order) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Histórico ${order.number}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              const Text('✓ Pedido criado'),
              const SizedBox(height: 10),
              const Text('✓ Pagamento confirmado'),
              const SizedBox(height: 10),
              const Text('✓ Caçamba entregue'),
              const SizedBox(height: 10),
              const Text('✓ Locação concluída'),
            ],
          ),
        );
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

class _OrderCard extends StatelessWidget {
  final AdminOrder order;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onDelivered;
  final VoidCallback onHistory;

  const _OrderCard({
    required this.order,
    required this.onAccept,
    required this.onReject,
    required this.onDelivered,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  order.number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Cliente: ${order.customer}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            'Equipamento: ${order.equipment}',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 7),
          Text(
            'Endereço: ${order.address}',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.border),
          const SizedBox(height: 10),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    switch (order.status) {
      case AdminOrderStatus.novo:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(46),
                ),
                child: const Text('Recusar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                ),
                child: const Text('Aceitar'),
              ),
            ),
          ],
        );

      case AdminOrderStatus.emAndamento:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDelivered,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
            ),
            child: const Text('Marcar como Entregue'),
          ),
        );

      case AdminOrderStatus.concluido:
        return SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onHistory,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.lightGray,
              foregroundColor: Colors.black54,
              minimumSize: const Size.fromHeight(46),
            ),
            child: const Text('Visualizar Histórico Completo'),
          ),
        );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final AdminOrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color color;
    late Color background;

    switch (status) {
      case AdminOrderStatus.novo:
        label = 'Novo';
        color = const Color(0xFF9A6D00);
        background = const Color(0xFFFFF9D9);

      case AdminOrderStatus.emAndamento:
        label = 'Em Andamento';
        color = AppColors.green;
        background = const Color(0xFFE5F6E7);

      case AdminOrderStatus.concluido:
        label = 'Concluído';
        color = Colors.black54;
        background = AppColors.lightGray;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
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
