import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';

import '../../../pedidos/presentation/pages/resumo_pedido_page.dart';

class CacambaDetailsPage extends StatefulWidget {
  const CacambaDetailsPage({super.key});

  @override
  State<CacambaDetailsPage> createState() => _CacambaDetailsPageState();
}

class _CacambaDetailsPageState extends State<CacambaDetailsPage> {
  int quantity = 1;
  int selectedDays = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _DetailsHeader(onBack: () => Navigator.of(context).pop()),
              AspectRatio(
                aspectRatio: 1.75,
                child: Image.asset(
                  'assets/images/cacamba_5m_detalhe.jpg',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.image_outlined, size: 60),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ProductTitle(),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 14),
                    const Text(
                      'Especificações:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'A caçamba de 5m³ é ideal para reformas de médio porte, '
                      'remoção de terra, tijolos, concreto e azulejos. '
                      'Entrega rápida em até 24h úteis.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _WasteInfoCard(
                            title: 'PERMITIDO ✓',
                            description: 'Argamassa, Tijolos, Concreto, Madeiras, Azulejos.',
                            foregroundColor: AppColors.green,
                            backgroundColor: Color(0xFFF2F8EE),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _WasteInfoCard(
                            title: 'PROIBIDO ✕',
                            description:
                                'Lixo hospitalar, Químicos, Solventes, Pneus.',
                            foregroundColor: Colors.red,
                            backgroundColor: Color(0xFFFFF1F1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildQuantityField()),
                        const SizedBox(width: 10),
                        Expanded(child: _buildDaysField()),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: _addToCart,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text(
                          'Adicionar ao Carrinho',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 180),
                  ],
                ),
              ),
              const _SustainabilityFooter(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _DetailsBottomNavigation(),
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantidade:',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: quantity > 1
                    ? () => setState(() => quantity--)
                    : null,
                icon: const Icon(Icons.remove),
                color: AppColors.green,
              ),
              Expanded(
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => quantity++),
                icon: const Icon(Icons.add),
                color: AppColors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaysField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tempo de permanência:',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: selectedDays,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.lightGray,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 1, child: Text('1 Dia')),
            DropdownMenuItem(value: 3, child: Text('3 Dias')),
            DropdownMenuItem(value: 5, child: Text('5 Dias')),
            DropdownMenuItem(value: 7, child: Text('7 Dias')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => selectedDays = value);
            }
          },
        ),
      ],
    );
  }

  void _addToCart() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ResumoPedidoPage()));
  }
}

class _DetailsHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _DetailsHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 105,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 18,
            child: TextButton.icon(
              onPressed: onBack,
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              icon: const Icon(Icons.arrow_back),
              label: const Text(
                'Voltar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Transform.scale(scale: 0.72, child: AppLogo()),
        ],
      ),
    );
  }
}

class _ProductTitle extends StatelessWidget {
  const _ProductTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Caçamba 5m³ - Entulho',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Text(
                'MAIS ALUGADA',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'R\$ 350,00',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 29,
                fontWeight: FontWeight.w800,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 6, bottom: 5),
              child: Text(
                '/ período de 3 dias',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WasteInfoCard extends StatelessWidget {
  final String title;
  final String description;
  final Color foregroundColor;
  final Color backgroundColor;

  const _WasteInfoCard({
    required this.title,
    required this.description,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
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

class _DetailsBottomNavigation extends StatelessWidget {
  const _DetailsBottomNavigation();

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
