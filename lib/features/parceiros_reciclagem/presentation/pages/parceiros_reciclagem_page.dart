import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

import 'agendar_coleta_page.dart';

enum PartnerSort { nearest, bestRating, lowestPrice }

class RecyclingPartner {
  final String name;
  final List<String> materials;
  final String address;
  final double distance;
  final double pricePerKg;
  final double rating;

  const RecyclingPartner({
    required this.name,
    required this.materials,
    required this.address,
    required this.distance,
    required this.pricePerKg,
    required this.rating,
  });
}

class ParceirosReciclagemPage extends StatefulWidget {
  const ParceirosReciclagemPage({super.key});

  @override
  State<ParceirosReciclagemPage> createState() =>
      _ParceirosReciclagemPageState();
}

class _ParceirosReciclagemPageState extends State<ParceirosReciclagemPage> {
  PartnerSort selectedSort = PartnerSort.nearest;

  final List<RecyclingPartner> partners = const [
    RecyclingPartner(
      name: 'EcoRecicla SP',
      materials: ['PET', 'Alumínio'],
      address: 'Av. Paulista, 1000 - Bela Vista',
      distance: 1.2,
      pricePerKg: 1.20,
      rating: 4.9,
    ),
    RecyclingPartner(
      name: 'Recicla Verde',
      materials: ['PET', 'Papelão'],
      address: 'Rua Augusta, 450 - Consolação',
      distance: 2.5,
      pricePerKg: 1.15,
      rating: 4.8,
    ),
    RecyclingPartner(
      name: 'Metais & Plásticos Centro',
      materials: ['PET', 'Vidro'],
      address: 'Al. Santos, 800 - Cerqueira César',
      distance: 3.1,
      pricePerKg: 1.10,
      rating: 4.7,
    ),
    RecyclingPartner(
      name: 'SP Reúsa',
      materials: ['Plásticos', 'Metais'],
      address: 'Rua Bela Cintra, 1200 - Consolação',
      distance: 4,
      pricePerKg: 1,
      rating: 4.5,
    ),
  ];

  List<RecyclingPartner> get sortedPartners {
    final result = List<RecyclingPartner>.from(partners);

    switch (selectedSort) {
      case PartnerSort.nearest:
        result.sort((a, b) => a.distance.compareTo(b.distance));
      case PartnerSort.bestRating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case PartnerSort.lowestPrice:
        result.sort((a, b) => a.pricePerKg.compareTo(b.pricePerKg));
    }

    return result;
  }

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
            const SliverToBoxAdapter(child: _PageHeader()),
            const SliverToBoxAdapter(child: _HeroSection()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _sortChip(
                        sort: PartnerSort.nearest,
                        label: 'Mais Próximos',
                      ),
                      const SizedBox(width: 8),
                      _sortChip(
                        sort: PartnerSort.bestRating,
                        label: 'Melhor Avaliação',
                      ),
                      const SizedBox(width: 8),
                      _sortChip(
                        sort: PartnerSort.lowestPrice,
                        label: 'Menor Preço',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 80),
              sliver: SliverList.separated(
                itemCount: sortedPartners.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final partner = sortedPartners[index];

                  return _PartnerCard(
                    partner: partner,
                    onSchedule: () => _scheduleCollection(partner),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavigation(),
    );
  }

  Widget _sortChip({required PartnerSort sort, required String label}) {
    final selected = selectedSort == sort;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.green,
      backgroundColor: const Color(0xFFFFF8DD),
      side: selected
          ? BorderSide.none
          : const BorderSide(color: AppColors.yellow),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      onSelected: (_) {
        setState(() {
          selectedSort = sort;
        });
      },
    );
  }

  void _scheduleCollection(RecyclingPartner partner) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AgendarColetaPage(
          partnerName: partner.name,
          pricePerKg: partner.pricePerKg,
        ),
      ),
    );
  }

  /*static String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }*/
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

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

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF39953B),
      padding: const EdgeInsets.fromLTRB(24, 42, 24, 44),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parceiros de reciclagem',
            style: TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Encontre pontos de coleta e parceiros especializados '
            'para o material selecionado.',
            style: TextStyle(color: Colors.white, fontSize: 17, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final RecyclingPartner partner;
  final VoidCallback onSchedule;

  const _PartnerCard({required this.partner, required this.onSchedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4C9),
        border: Border.all(color: AppColors.yellow),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  partner.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 13, color: Color(0xFF795500)),
                    const SizedBox(width: 4),
                    Text(
                      partner.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...partner.materials.map(
                (material) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.yellow),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    material,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Text(
                '• ${partner.distance.toStringAsFixed(1)} km',
                style: const TextStyle(color: Colors.black54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            partner.address,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Paga até: ',
                style: TextStyle(color: Colors.black54, fontSize: 11),
              ),
              Text(
                '${_formatMoney(partner.pricePerKg)}/kg',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: onSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Agendar Coleta'),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 4,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        // Será conectado durante a componentização da navegação.
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
