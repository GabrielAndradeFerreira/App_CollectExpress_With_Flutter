import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import 'cadastro_cliente_page.dart';
import 'cadastro_fornecedor_page.dart';
import 'cadastro_parceiro_reciclagem_page.dart';

enum AccountType { cliente, fornecedor, parceiroReciclagem }

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AccountType? selectedAccountType;
  bool obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _PageHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 80),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cadastre-se',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Escolha seu tipo de conta',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                      const SizedBox(height: 26),

                      const _FieldLabel('Tipo de Conta'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AccountType>(
                        initialValue: selectedAccountType,
                        isExpanded: true,
                        hint: const Text(
                          'Selecione (Cliente, Fornecedor, Parceiro...)',
                          overflow: TextOverflow.ellipsis,
                        ),
                        decoration: _inputDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: AccountType.cliente,
                            child: Text('Cliente'),
                          ),
                          DropdownMenuItem(
                            value: AccountType.fornecedor,
                            child: Text('Fornecedor de Caçambas'),
                          ),
                          DropdownMenuItem(
                            value: AccountType.parceiroReciclagem,
                            child: Text('Parceiro de Reciclagem'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedAccountType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecione o tipo de conta';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),
                      const _FieldLabel('E-mail'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: _inputDecoration(
                          hintText: 'seu-email@dominio.com',
                        ),
                        validator: _validateEmail,
                      ),

                      const SizedBox(height: 18),
                      const _FieldLabel('Senha'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: obscurePassword,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: _inputDecoration(
                          hintText: 'Digite sua senha de acesso',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                      ),

                      const SizedBox(height: 36),
                      SizedBox(
                        width: double.infinity,
                        height: 57,
                        child: ElevatedButton(
                          onPressed: _continueRegistration,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF2F8334),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text(
                            'CADASTRAR-SE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Já tem uma conta? ',
                            style: TextStyle(color: Colors.black54),
                          ),
                          TextButton(
                            onPressed: _openLogin,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: const Color(0xFF267A2D),
                            ),
                            child: const Text(
                              'Faça login',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _AuthBottomNavigation(),
    );
  }

  InputDecoration _inputDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.green, width: 1.5),
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

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe seu e-mail';
    }

    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (!isValid) {
      return 'Informe um e-mail válido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe sua senha';
    }

    if (value.length < 6) {
      return 'A senha deve possuir pelo menos 6 caracteres';
    }

    return null;
  }

  void _continueRegistration() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final Widget destination;

    switch (selectedAccountType!) {
      case AccountType.cliente:
        destination = CadastroClientePage(email: email, password: password);

      case AccountType.fornecedor:
        destination = CadastroFornecedorPage(email: email, password: password);

      case AccountType.parceiroReciclagem:
        destination = CadastroParceiroReciclagemPage(
          email: email,
          password: password,
        );
    }

    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => destination));
  }

  void _openLogin() {
   Navigator.of(context).pushReplacementNamed('/login');
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const AppLogo(),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }
}

class _AuthBottomNavigation extends StatelessWidget {
  const _AuthBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 3,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF267A2D),
      unselectedItemColor: Colors.black54,
      onTap: (index) {
        // A navegação compartilhada será implementada posteriormente.
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
