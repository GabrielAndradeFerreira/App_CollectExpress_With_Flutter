import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

enum PartnerStatus { ativo, pendente, suspenso }

class Partner {
  final String name;
  final String cnpj;
  final String region;
  final double? rating;
  final int orders;
  PartnerStatus status;

  Partner({
    required this.name,
    required this.cnpj,
    required this.region,
    required this.rating,
    required this.orders,
    required this.status,
  });
}

class GestaoParceirosPage extends StatefulWidget {
  const GestaoParceirosPage({super.key});

  @override
  State<GestaoParceirosPage> createState() => _GestaoParceirosPageState();
}

class _GestaoParceirosPageState extends State<GestaoParceirosPage> {
  final searchController = TextEditingController();

  PartnerStatus? selectedFilter = PartnerStatus.ativo;
  String searchText = '';

  final partners = <Partner>[
    Partner(
      name: 'Leste Caçambas e Remoção',
      cnpj: '14.283.454/0001-08',
      region: 'Zona Leste - SP',
      rating: 4.9,
      orders: 312,
      status: PartnerStatus.ativo,
    ),
    Partner(
      name: 'Paulista Descarte Ecológico',
      cnpj: '45.109.876/0001-90',
      region: 'Zona Sul - SP',
      rating: 4.7,
      orders: 189,
      status: PartnerStatus.ativo,
    ),
    Partner(
      name: 'Norte Entulhos SP',
      cnpj: '08.123.456/0002-12',
      region: 'Zona Norte - SP',
      rating: 4.5,
      orders: 142,
      status: PartnerStatus.ativo,
    ),
    Partner(
      name: 'Vale Verde Gestão de Resíduos',
      cnpj: '22.334.455/0001-44',
      region: 'Centro - SP',
      rating: null,
      orders: 0,
      status: PartnerStatus.pendente,
    ),
    Partner(
      name: 'Oeste Coleta Ambiental',
      cnpj: '55.444.333/0001-20',
      region: 'Zona Oeste - SP',
      rating: 3.9,
      orders: 54,
      status: PartnerStatus.suspenso,
    ),
  ];

  List<Partner> get filteredPartners {
    final query = searchText.trim().toLowerCase();

    return partners.where((partner) {
      final matchesStatus =
          selectedFilter == null || partner.status == selectedFilter;

      final matchesSearch =
          query.isEmpty ||
          partner.name.toLowerCase().contains(query) ||
          partner.cnpj.toLowerCase().contains(query) ||
          partner.region.toLowerCase().contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  int count(PartnerStatus status) {
    return partners.where((partner) => partner.status == status).length;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
            const SliverToBoxAdapter(child: _AdminHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 30, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestão de Parceiros',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Caçambas municipais credenciadas e parceiros',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 18),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip(
                            label: 'Todos (${partners.length})',
                            status: null,
                          ),
                          const SizedBox(width: 8),
                          _filterChip(
                            label: 'Ativos (${count(PartnerStatus.ativo)})',
                            status: PartnerStatus.ativo,
                          ),
                          const SizedBox(width: 8),
                          _filterChip(
                            label:
                                'Pendentes (${count(PartnerStatus.pendente)})',
                            status: PartnerStatus.pendente,
                          ),
                          const SizedBox(width: 8),
                          _filterChip(
                            label:
                                'Suspensos (${count(PartnerStatus.suspenso)})',
                            status: PartnerStatus.suspenso,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: (value) {
                              setState(() => searchText = value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Buscar por CNPJ, empresa ou região...',
                              filled: true,
                              fillColor: AppColors.lightGray,
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 17,
                              ),
                              suffixIcon: searchText.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: _clearSearch,
                                      icon: const Icon(Icons.close),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => setState(() {}),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.search, size: 27),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (filteredPartners.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Nenhum parceiro encontrado.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                sliver: SliverList.separated(
                  itemCount: filteredPartners.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final partner = filteredPartners[index];

                    return _PartnerCard(
                      partner: partner,
                      onTap: () => _showPartnerOptions(partner),
                      onApprove: () => _approvePartner(partner),
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

  Widget _filterChip({required String label, required PartnerStatus? status}) {
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
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) {
        setState(() => selectedFilter = status);
      },
    );
  }

  void _clearSearch() {
    searchController.clear();

    setState(() => searchText = '');
  }

  void _approvePartner(Partner partner) {
    setState(() {
      partner.status = PartnerStatus.ativo;
      selectedFilter = PartnerStatus.ativo;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${partner.name} foi aprovado.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  void _showPartnerOptions(Partner partner) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.lightGray,
                    child: Icon(Icons.local_shipping_outlined),
                  ),
                  title: Text(
                    partner.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(partner.cnpj),
                ),
                const Divider(),
                if (partner.status == PartnerStatus.pendente)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.green,
                    ),
                    title: const Text('Aprovar cadastro'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _approvePartner(partner);
                    },
                  ),
                if (partner.status == PartnerStatus.ativo)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.block, color: Colors.red),
                    title: const Text('Suspender parceiro'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _changeStatus(partner, PartnerStatus.suspenso);
                    },
                  ),
                if (partner.status == PartnerStatus.suspenso)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.green,
                    ),
                    title: const Text('Reativar parceiro'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _changeStatus(partner, PartnerStatus.ativo);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _changeStatus(Partner partner, PartnerStatus status) {
    setState(() {
      partner.status = status;
      selectedFilter = status;
    });
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

class _PartnerCard extends StatelessWidget {
  final Partner partner;
  final VoidCallback onTap;
  final VoidCallback onApprove;

  const _PartnerCard({
    required this.partner,
    required this.onTap,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7ECE3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: Color(0xFF789052),
                      size: 31,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'CNPJ: ${partner.cnpj}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          partner.region,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: partner.status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.border),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    partner.rating == null
                        ? '★ Novo'
                        : '★ ${partner.rating!.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Avaliação',
                    style: TextStyle(color: Colors.black38, fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    '${partner.orders} pedidos',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              if (partner.status == PartnerStatus.pendente) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 43,
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Aprovar Cadastro',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PartnerStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color foreground;
    late final Color background;

    switch (status) {
      case PartnerStatus.ativo:
        label = 'Ativo';
        foreground = AppColors.green;
        background = const Color(0xFFE5F6E7);
      case PartnerStatus.pendente:
        label = 'Pendente';
        foreground = const Color(0xFF8A6500);
        background = AppColors.yellow;
      case PartnerStatus.suspenso:
        label = 'Suspenso';
        foreground = Colors.red;
        background = const Color(0xFFFFE8E8);
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
          color: foreground,
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
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        // A navegação será implementada na componentização.
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
