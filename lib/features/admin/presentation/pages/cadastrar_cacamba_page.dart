import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../domain/models/admin_cacamba.dart';

class CadastrarCacambaPage extends StatefulWidget {
  const CadastrarCacambaPage({super.key});

  @override
  State<CadastrarCacambaPage> createState() => _CadastrarCacambaPageState();
}

class _CadastrarCacambaPageState extends State<CadastrarCacambaPage> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController(text: '350,00');

  String wasteType = 'Entulho (Alvenaria, terra, concreto)';
  String selectedVolume = '5m³';
  String deliveryDeadline = 'Em até 24 horas';

  final Set<String> selectedRegions = {'Zona Sul', 'Zona Oeste'};

  final regions = const [
    'Zona Sul',
    'Zona Norte',
    'Zona Leste',
    'Zona Oeste',
    'Centro',
  ];

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  //------------------------------------------------------------------
  String _shortWasteName(String value) {
    if (value.startsWith('Entulho')) {
      return 'Entulho';
    }

    if (value.startsWith('Podas')) {
      return 'Poda';
    }

    return 'Reciclável';
  }

  String _imageForVolume(String volume) {
    switch (volume) {
      case '3m³':
        return 'assets/images/cacamba_3m.jpg';
      case '7m³':
        return 'assets/images/cacamba_7m.jpg';
      default:
        return 'assets/images/cacamba_5m.jpg';
    }
  }
  //------------------------------------------------------------------

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
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 80),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cadastrar Nova Caçamba',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Insira as especificações para listar no app',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 30),

                      const _FieldLabel('Tipo de Resíduo'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: wasteType,
                        decoration: _inputDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'Entulho (Alvenaria, terra, concreto)',
                            child: Text('Entulho (Alvenaria, terra, concreto)'),
                          ),
                          DropdownMenuItem(
                            value: 'Podas e jardinagem',
                            child: Text('Podas e jardinagem'),
                          ),
                          DropdownMenuItem(
                            value: 'Materiais recicláveis',
                            child: Text('Materiais recicláveis'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => wasteType = value);
                          }
                        },
                      ),

                      const SizedBox(height: 20),
                      const _FieldLabel('Capacidade / Volume'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _volumeButton('3m³'),
                          const SizedBox(width: 10),
                          _volumeButton('5m³'),
                          const SizedBox(width: 10),
                          _volumeButton('7m³'),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const _FieldLabel('Preço por Locação (5 dias)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration(
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 16, right: 8),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                'R\$',
                                style: TextStyle(
                                  color: Color(0xFF76A24A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o preço da locação';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),
                      const _FieldLabel('Regiões Atendidas'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: regions.map(_regionChip).toList(),
                      ),

                      const SizedBox(height: 20),
                      const _FieldLabel('Prazo de Entrega'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: deliveryDeadline,
                        decoration: _inputDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'Em até 24 horas',
                            child: Text('Em até 24 horas'),
                          ),
                          DropdownMenuItem(
                            value: 'Em até 48 horas',
                            child: Text('Em até 48 horas'),
                          ),
                          DropdownMenuItem(
                            value: 'Em até 72 horas',
                            child: Text('Em até 72 horas'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => deliveryDeadline = value);
                          }
                        },
                      ),

                      const SizedBox(height: 20),
                      const _FieldLabel('Fotos do Equipamento'),
                      const SizedBox(height: 8),
                      _PhotoUpload(onTap: _selectPhotos),

                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _publish,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text(
                            'Publicar Caçamba',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _AdminBottomNavigation(),
    );
  }

  Widget _volumeButton(String volume) {
    final selected = selectedVolume == volume;

    return Expanded(
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: () => setState(() => selectedVolume = volume),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: selected ? AppColors.green : AppColors.lightGray,
            foregroundColor: selected ? Colors.white : Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Text(
            volume,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _regionChip(String region) {
    final selected = selectedRegions.contains(region);

    return FilterChip(
      label: Text(region),
      selected: selected,
      showCheckmark: false,
      selectedColor: const Color(0xFFEAF6E8),
      backgroundColor: AppColors.lightGray,
      side: selected
          ? const BorderSide(color: AppColors.green)
          : BorderSide.none,
      labelStyle: TextStyle(
        color: selected ? AppColors.green : Colors.black54,
        fontSize: 12,
      ),
      onSelected: (isSelected) {
        setState(() {
          if (isSelected) {
            selectedRegions.add(region);
          } else {
            selectedRegions.remove(region);
          }
        });
      },
    );
  }

  InputDecoration _inputDecoration({Widget? prefixIcon}) {
    return InputDecoration(
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.green),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  void _selectPhotos() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('O seletor de imagens será integrado posteriormente.'),
      ),
    );
  }

  void _publish() {
    if (!_formKey.currentState!.validate()) return;

    if (selectedRegions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ao menos uma região atendida.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final normalizedPrice = _priceController.text
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');

    final price = double.tryParse(normalizedPrice);

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um preço válido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cacamba = AdminCacamba(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Caçamba $selectedVolume - ${_shortWasteName(wasteType)}',
      region: selectedRegions.first,
      price: price,
      period: '5 dias',
      imagePath: _imageForVolume(selectedVolume),
      status: AdminCacambaStatus.disponivel,
    );

    Navigator.of(context).pop(cacamba);
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

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }
}

class _PhotoUpload extends StatelessWidget {
  final VoidCallback onTap;

  const _PhotoUpload({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: double.infinity,
          height: 135,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFF76A24A),
                size: 30,
              ),
              SizedBox(height: 8),
              Text(
                'Adicionar Fotos da Caçamba',
                style: TextStyle(
                  color: Color(0xFF76A24A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Formatos aceitos: JPG, PNG • Máx: 5MB',
                style: TextStyle(color: Colors.black54, fontSize: 10),
              ),
            ],
          ),
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
