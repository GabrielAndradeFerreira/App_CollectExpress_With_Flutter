import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

class PerfilLojaPage extends StatefulWidget {
  const PerfilLojaPage({super.key});

  @override
  State<PerfilLojaPage> createState() => _PerfilLojaPageState();
}

class _PerfilLojaPageState extends State<PerfilLojaPage> {
  final _formKey = GlobalKey<FormState>();

  final _addressController = TextEditingController(
    text: 'Av. do Estado, 4500 - Mooca, São Paulo - SP',
  );

  final _phoneController = TextEditingController(text: '(11) 99999-9999');

  final _emailController = TextEditingController(
    text: 'contato@spexpress.com.br',
  );

  final _businessHoursController = TextEditingController(
    text: 'Segunda a Sábado - 08:00 às 18:00',
  );

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _businessHoursController.dispose();
    super.dispose();
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 80),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Perfil da Minha Loja',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Configure os detalhes da sua empresa no marketplace',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 36),
                      _StoreIdentity(onChangeLogo: _changeLogo),
                      const SizedBox(height: 36),
                      const _FieldLabel('Razão Social / CNPJ'),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue:
                            'São Paulo Express Locação LTDA • '
                            '12.345.678/0001-90',
                        readOnly: true,
                        decoration: _inputDecoration(
                          fillColor: AppColors.lightGray,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('Endereço Operacional'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        decoration: _inputDecoration(),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('Telefone de Contato'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('E-mail de Suporte'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(),
                        validator: _emailValidator,
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('Horário de Funcionamento'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _businessHoursController,
                        decoration: _inputDecoration(),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Dados Bancários para Repasse',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _BankDetailsCard(),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text(
                            'Salvar Alterações',
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

  InputDecoration _inputDecoration({Color fillColor = Colors.white}) {
    return InputDecoration(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o e-mail';
    }

    final validEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(value.trim());

    if (!validEmail) {
      return 'Informe um e-mail válido';
    }

    return null;
  }

  void _changeLogo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('O seletor de imagem será integrado posteriormente.'),
      ),
    );
  }

  void _save() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dados da loja atualizados com sucesso!'),
        backgroundColor: AppColors.green,
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

class _StoreIdentity extends StatelessWidget {
  final VoidCallback onChangeLogo;

  const _StoreIdentity({required this.onChangeLogo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.deepOrange, width: 2),
          ),
          child: const Icon(
            Icons.local_shipping_outlined,
            color: AppColors.green,
            size: 38,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Caçambas São Paulo Express',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              TextButton(
                onPressed: onChangeLogo,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFF76A24A),
                ),
                child: const Text(
                  'Alterar Logo da Loja',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
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

class _BankDetailsCard extends StatelessWidget {
  const _BankDetailsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          _BankRow(label: 'Banco:', value: 'Banco do Brasil (001)'),
          SizedBox(height: 14),
          _BankRow(label: 'Agência / Conta:', value: '1234-5 / 98765-4'),
          SizedBox(height: 14),
          _BankRow(
            label: 'Chave Pix (CNPJ):',
            value: '12.345.678/0001-90',
            valueColor: AppColors.green,
          ),
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BankRow({required this.label, required this.value, this.valueColor});

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
          textAlign: TextAlign.end,
          style: TextStyle(
            color: valueColor ?? Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 3,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      onTap: (index) {
        // A navegação principal será implementada posteriormente.
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
