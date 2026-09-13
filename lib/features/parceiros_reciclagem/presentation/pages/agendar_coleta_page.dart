import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

import 'coletas_agendadas_page.dart';

class AgendarColetaPage extends StatefulWidget {
  final String partnerName;
  final double pricePerKg;

  const AgendarColetaPage({
    super.key,
    required this.partnerName,
    required this.pricePerKg,
  });

  @override
  State<AgendarColetaPage> createState() => _AgendarColetaPageState();
}

class _AgendarColetaPageState extends State<AgendarColetaPage> {
  int quantityKg = 50;
  int selectedDay = 10;
  String selectedPeriod = 'Manhã';

  final List<int> availableDays = const [6, 7, 8, 9, 10, 11, 12];

  double get estimatedValue => quantityKg * widget.pricePerKg;

  String formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 50),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _CollectionSummary(
                    partnerName: widget.partnerName,
                    pricePerKg: widget.pricePerKg,
                  ),
                  const SizedBox(height: 22),
                  _buildQuantitySection(),
                  const SizedBox(height: 22),
                  _buildDateSection(),
                  const SizedBox(height: 22),
                  _buildPeriodSection(),
                  const SizedBox(height: 22),
                  const _AddressSection(),
                  const SizedBox(height: 22),
                  _buildEstimatedValue(),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _confirmSchedule,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text(
                        'Confirmar Agendamento',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavigation(),
    );
  }

  Widget _buildQuantitySection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quantidade Estimada',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: quantityKg > 10
                      ? () {
                          setState(() {
                            quantityKg -= 10;
                          });
                        }
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.lightGray,
                  ),
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Text(
                    '$quantityKg kg',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      quantityKg += 10;
                    });
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
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
          const Text(
            'Outubro 2024',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableDays.map((day) {
                final selected = selectedDay == day;

                return Padding(
                  padding: const EdgeInsets.only(right: 9),
                  child: Material(
                    color: selected ? AppColors.yellow : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedDay = day;
                        });
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: 52,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected
                                ? AppColors.yellow
                                : AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Out',
                              style: TextStyle(
                                color: selected
                                    ? Colors.black87
                                    : Colors.black54,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$day',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSection() {
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
          const Text(
            'Período de Entrega',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PeriodButton(
                  title: 'Manhã',
                  hours: '08:00 - 12:00',
                  selected: selectedPeriod == 'Manhã',
                  onTap: () {
                    setState(() {
                      selectedPeriod = 'Manhã';
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PeriodButton(
                  title: 'Tarde',
                  hours: '13:00 - 17:00',
                  selected: selectedPeriod == 'Tarde',
                  onTap: () {
                    setState(() {
                      selectedPeriod = 'Tarde';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatedValue() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Valor Estimado a Receber:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            formatMoney(estimatedValue),
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSchedule() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.event_available,
            color: AppColors.green,
            size: 42,
          ),
          title: const Text('Confirmar agendamento?'),
          content: Text(
            'Parceiro: ${widget.partnerName}\n'
            'Material: Garrafas PET\n'
            'Quantidade: $quantityKg kg\n'
            'Data: $selectedDay de outubro de 2024\n'
            'Período: $selectedPeriod\n'
            'Valor estimado: ${formatMoney(estimatedValue)}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final collection = ScheduledCollection(
      partnerName: widget.partnerName,
      material: 'Garrafas PET',
      quantityKg: quantityKg,
      day: selectedDay,
      period: selectedPeriod,
      estimatedValue: estimatedValue,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ColetasAgendadasPage(newCollection: collection),
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
      padding: const EdgeInsets.fromLTRB(18, 38, 18, 36),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agendar coleta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Confirme os dados do material, escolha o dia e horário, '
            'e finalize o agendamento com o parceiro selecionado.',
            style: TextStyle(color: Colors.white, fontSize: 16, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _CollectionSummary extends StatelessWidget {
  final String partnerName;
  final double pricePerKg;

  const _CollectionSummary({
    required this.partnerName,
    required this.pricePerKg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const _SummaryRow(label: 'Material:', value: 'Garrafas PET'),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Parceiro:', value: partnerName),
          const SizedBox(height: 14),
          _SummaryRow(
            label: 'Preço por kg:',
            value: '${_formatMoney(pricePerKg)}/kg',
            valueColor: AppColors.green,
          ),
        ],
      ),
    );
  }

  static String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String title;
  final String hours;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.title,
    required this.hours,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF4CF) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.yellow : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hours,
                style: const TextStyle(color: Colors.black54, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection();

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Endereço de Retirada',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(13),
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
                        'Seu Endereço Cadastrado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Av. Paulista, 1000 - Bela Vista, São Paulo - SP',
                        style: TextStyle(color: Colors.black54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        // Será implementado durante a componentização.
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
