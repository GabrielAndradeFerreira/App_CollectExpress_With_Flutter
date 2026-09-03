import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

import 'cacamba_details_page.dart';

class CacambasPage extends StatefulWidget {
  const CacambasPage({super.key});

  @override
  State<CacambasPage> createState() => _CacambasPageState();
}

class _CacambasPageState extends State<CacambasPage> {
  String selectedFilter = 'Todas';

  final List<String> filters = const [
    'Todas',
    'Obras/Entulho',
    'Limpeza/Podas',
    'Recicláveis',
  ];

  final List<Cacamba> cacambas = const [
    Cacamba(
      title: 'Caçamba 3m³ (Pequena)',
      volume: '3m³',
      recommendation: 'Pequenas reformas e entulho leve',
      capacity: 'Até 3 toneladas',
      price: 280,
      imagePath: 'assets/images/cacamba_3m.jpg',
    ),
    Cacamba(
      title: 'Caçamba 5m³ (Média)',
      volume: '5m³',
      recommendation: 'Reformas médias e grandes descartes',
      capacity: 'Até 5 toneladas',
      price: 350,
      imagePath: 'assets/images/cacamba_5m.jpg',
    ),
    Cacamba(
      title: 'Caçamba 7m³ (Grande)',
      volume: '7m³',
      recommendation: 'Demolições e grandes volumes comerciais',
      capacity: 'Até 7 toneladas',
      price: 420,
      imagePath: 'assets/images/cacamba_7m.jpg',
    ),
  ];

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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
                child: Builder(
                  builder: (context) {
                    return Row(
                      children: [
                        const Expanded(child: AppLogo()),
                        IconButton(
                          onPressed: () {
                            Scaffold.of(context).openEndDrawer();
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.lightGray,
                            minimumSize: const Size(46, 46),
                          ),
                          icon: const Icon(Icons.menu_rounded),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Caçambas Disponíveis',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Escolha o volume ideal para sua necessidade',
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = filters[index];
                          final selected = selectedFilter == filter;

                          return ChoiceChip(
                            label: Text(filter),
                            selected: selected,
                            showCheckmark: false,
                            onSelected: (_) {
                              setState(() {
                                selectedFilter = filter;
                              });
                            },
                            selectedColor: AppColors.green,
                            backgroundColor: AppColors.lightGray,
                            side: BorderSide.none,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverList.separated(
                itemCount: cacambas.length,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  return CacambaCard(
                    cacamba: cacambas[index],
                    onRent: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CacambaDetailsPage(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 28),
                child: SustainabilityFooter(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CacambasBottomNavigation(),
    );
  }
}

class CacambaCard extends StatelessWidget {
  final Cacamba cacamba;
  final VoidCallback onRent;

  const CacambaCard({super.key, required this.cacamba, required this.onRent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: AspectRatio(
              aspectRatio: 2.55,
              child: Image.asset(
                cacamba.imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 52,
                        color: Colors.black38,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  cacamba.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2E4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cacamba.volume,
                  style: const TextStyle(
                    color: Color(0xFF6B9F46),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Recomendado para: ${cacamba.recommendation}',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            cacamba.capacity,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valor da diária',
                      style: TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                    Text(
                      _formatPrice(cacamba.price),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 105,
                height: 44,
                child: ElevatedButton(
                  onPressed: onRent,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Alugar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatPrice(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class Cacamba {
  final String title;
  final String volume;
  final String recommendation;
  final String capacity;
  final double price;
  final String imagePath;

  const Cacamba({
    required this.title,
    required this.volume,
    required this.recommendation,
    required this.capacity,
    required this.price,
    required this.imagePath,
  });
}

class SustainabilityFooter extends StatelessWidget {
  const SustainabilityFooter({super.key});

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
          Row(
            children: [
              Icon(Icons.phone_outlined, color: Colors.orange, size: 19),
              SizedBox(width: 8),
              Text(
                'Suporte WhatsApp: (11) 99999-9999',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CacambasBottomNavigation extends StatelessWidget {
  const CacambasBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      onTap: (_) {
        // A navegação será implementada posteriormente.
      },
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
