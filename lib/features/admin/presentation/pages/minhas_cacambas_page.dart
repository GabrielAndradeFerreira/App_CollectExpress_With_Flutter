import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../domain/models/admin_cacamba.dart';
import 'cadastrar_cacamba_page.dart';

class MinhasCacambasPage extends StatefulWidget {
  const MinhasCacambasPage({super.key});

  @override
  State<MinhasCacambasPage> createState() => _MinhasCacambasPageState();
}

class _MinhasCacambasPageState extends State<MinhasCacambasPage> {
  String selectedFilter = 'Todas';

  final List<AdminCacamba> cacambas = [
    const AdminCacamba(
      id: '1',
      title: 'Caçamba 5m³ - Entulho',
      region: 'Zona Sul',
      price: 350,
      period: '5 dias',
      imagePath: 'assets/images/cacamba_5m.jpg',
      status: AdminCacambaStatus.disponivel,
    ),
    const AdminCacamba(
      id: '2',
      title: 'Caçamba 3m³ - Poda',
      region: 'Zona Oeste',
      price: 290,
      period: '5 dias',
      imagePath: 'assets/images/cacamba_3m.jpg',
      status: AdminCacambaStatus.alugada,
    ),
    const AdminCacamba(
      id: '3',
      title: 'Caçamba 7m³ - Reciclável',
      region: 'Centro',
      price: 420,
      period: '5 dias',
      imagePath: 'assets/images/cacamba_7m.jpg',
      status: AdminCacambaStatus.manutencao,
    ),
    const AdminCacamba(
      id: '4',
      title: 'Caçamba 5m³ - Mista',
      region: 'Zona Norte',
      price: 370,
      period: '5 dias',
      imagePath: 'assets/images/cacamba_5m.jpg',
      status: AdminCacambaStatus.disponivel,
    ),
  ];

  List<AdminCacamba> get filteredCacambas {
    switch (selectedFilter) {
      case 'Disponíveis':
        return cacambas
            .where((item) => item.status == AdminCacambaStatus.disponivel)
            .toList();
      case 'Alugadas':
        return cacambas
            .where((item) => item.status == AdminCacambaStatus.alugada)
            .toList();
      default:
        return cacambas;
    }
  }

  int get availableCount => cacambas
      .where((item) => item.status == AdminCacambaStatus.disponivel)
      .length;

  int get rentedCount => cacambas
      .where((item) => item.status == AdminCacambaStatus.alugada)
      .length;

  Future<void> _openRegistration() async {
    final newCacamba = await Navigator.of(context).push<AdminCacamba>(
      MaterialPageRoute(builder: (_) => const CadastrarCacambaPage()),
    );

    if (newCacamba == null || !mounted) return;

    setState(() {
      cacambas.insert(0, newCacamba);
      selectedFilter = 'Todas';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Caçamba adicionada à lista!'),
        backgroundColor: AppColors.green,
      ),
    );
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 30, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Minhas Caçambas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Gerencie seus equipamentos e disponibilidade',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterButton('Todas', 'Todas (${cacambas.length})'),
                          const SizedBox(width: 10),
                          _filterButton(
                            'Disponíveis',
                            'Disponíveis ($availableCount)',
                          ),
                          const SizedBox(width: 10),
                          _filterButton('Alugadas', 'Alugadas ($rentedCount)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (filteredCacambas.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Nenhuma caçamba encontrada.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                sliver: SliverList.separated(
                  itemCount: filteredCacambas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _CacambaCard(cacamba: filteredCacambas[index]);
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const _AdminBottomNavigation(),
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
  final AdminCacamba cacamba;

  const _CacambaCard({required this.cacamba});

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
            child: Image.asset(
              cacamba.imagePath,
              width: 143,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return Container(
                  width: 143,
                  color: AppColors.lightGray,
                  child: const Icon(Icons.image_outlined),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cacamba.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Região: ${cacamba.region}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatMoney(cacamba.price),
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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
              _StatusBadge(status: cacamba.status),
              const Spacer(),
              Text(
                'Período: ${cacamba.period}',
                style: const TextStyle(color: Colors.black54, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final AdminCacambaStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color foregroundColor;
    late Color backgroundColor;

    switch (status) {
      case AdminCacambaStatus.disponivel:
        label = 'Disponível';
        foregroundColor = AppColors.green;
        backgroundColor = const Color(0xFFE7F6E8);
      case AdminCacambaStatus.alugada:
        label = 'Alugada';
        foregroundColor = const Color(0xFF9A6D00);
        backgroundColor = const Color(0xFFFFF8D9);
      case AdminCacambaStatus.manutencao:
        label = 'Manutenção';
        foregroundColor = Colors.red;
        backgroundColor = const Color(0xFFFFE8E8);
    }

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
