import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

enum CollectionFilter { proximas, concluidas }

class ScheduledCollection {
  final String partnerName;
  final String material;
  final int quantityKg;
  final int day;
  final String period;
  final double estimatedValue;
  final bool completed;

  const ScheduledCollection({
    required this.partnerName,
    required this.material,
    required this.quantityKg,
    required this.day,
    required this.period,
    required this.estimatedValue,
    this.completed = false,
  });
}

class ColetasAgendadasPage extends StatefulWidget {
  final ScheduledCollection newCollection;

  const ColetasAgendadasPage({
    super.key,
    required this.newCollection,
  });

  @override
  State<ColetasAgendadasPage> createState() => _ColetasAgendadasPageState();
}

class _ColetasAgendadasPageState extends State<ColetasAgendadasPage> {
  CollectionFilter selectedFilter = CollectionFilter.proximas;

  late final List<ScheduledCollection> collections;

  @override
  void initState() {
    super.initState();

    collections = [
      widget.newCollection,
      const ScheduledCollection(
        partnerName: 'Recicla Verde',
        material: 'Garrafas PET',
        quantityKg: 30,
        day: 18,
        period: 'Tarde',
        estimatedValue: 34.50,
      ),
      const ScheduledCollection(
        partnerName: 'Metais & Plásticos Centro',
        material: 'Garrafas PET',
        quantityKg: 40,
        day: 2,
        period: 'Manhã',
        estimatedValue: 44,
        completed: true,
      ),
    ];
  }

  List<ScheduledCollection> get filteredCollections {
    final showCompleted =
        selectedFilter == CollectionFilter.concluidas;

    return collections
        .where((collection) => collection.completed == showCompleted)
        .toList();
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
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: _filterButton(
                        filter: CollectionFilter.proximas,
                        label: 'Próximas',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _filterButton(
                        filter: CollectionFilter.concluidas,
                        label: 'Concluídas',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (filteredCollections.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Nenhuma coleta encontrada.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 80),
                sliver: SliverList.separated(
                  itemCount: filteredCollections.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final collection = filteredCollections[index];

                    return _CollectionCard(
                      collection: collection,
                      onCancel: () => _cancelCollection(collection),
                      onContact: () => _contactPartner(collection),
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

  Widget _filterButton({
    required CollectionFilter filter,
    required String label,
  }) {
    final selected = selectedFilter == filter;

    final count = collections.where((collection) {
      return filter == CollectionFilter.concluidas
          ? collection.completed
          : !collection.completed;
    }).length;

    return ChoiceChip(
      label: Text('$label ($count)'),
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
        setState(() {
          selectedFilter = filter;
        });
      },
    );
  }

  Future<void> _cancelCollection(
    ScheduledCollection collection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar coleta'),
          content: Text(
            'Deseja cancelar a coleta agendada com '
            '${collection.partnerName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Voltar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Cancelar coleta',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      collections.remove(collection);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coleta cancelada.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _contactPartner(ScheduledCollection collection) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Abrindo contato com ${collection.partnerName}.',
        ),
        backgroundColor: AppColors.green,
      ),
    );
  }
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
      padding: const EdgeInsets.fromLTRB(18, 38, 18, 36),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coletas agendadas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Acompanhe suas próximas coletas e consulte '
            'os agendamentos concluídos.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final ScheduledCollection collection;
  final VoidCallback onCancel;
  final VoidCallback onContact;

  const _CollectionCard({
    required this.collection,
    required this.onCancel,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        collection.completed ? Colors.grey : AppColors.green;

    return Container(
      padding: const EdgeInsets.all(18),
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
                  collection.partnerName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  collection.completed
                      ? 'Concluída'
                      : 'Agendada',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InformationRow(
            icon: Icons.recycling,
            label: 'Material',
            value: collection.material,
          ),
          const SizedBox(height: 12),
          _InformationRow(
            icon: Icons.scale_outlined,
            label: 'Quantidade estimada',
            value: '${collection.quantityKg} kg',
          ),
          const SizedBox(height: 12),
          _InformationRow(
            icon: Icons.calendar_month_outlined,
            label: 'Data da coleta',
            value: '${collection.day} de outubro de 2024',
          ),
          const SizedBox(height: 12),
          _InformationRow(
            icon: Icons.schedule,
            label: 'Período',
            value: collection.period,
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Valor estimado a receber',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                _formatMoney(collection.estimatedValue),
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (!collection.completed) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onContact,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Falar com Parceiro'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.green,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      onTap: (index) {
        // A navegação geral será implementada depois.
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.recycling_outlined),
          label: 'Materiais',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Coletas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}