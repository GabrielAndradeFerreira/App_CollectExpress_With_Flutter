import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';

class CadastroFornecedorPage extends StatefulWidget {
  final String email;
  final String password;

  const CadastroFornecedorPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<CadastroFornecedorPage> createState() =>
      _CadastroFornecedorPageState();
}

class _CadastroFornecedorPageState extends State<CadastroFornecedorPage> {
  final _formKey = GlobalKey<FormState>();

  final _companyController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _cpfController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cepController = TextEditingController();
  final _addressController = TextEditingController();
  final _numberController = TextEditingController();
  final _regionController = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  String selectedCategory = 'Remoção de Entulhos';

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController(text: widget.password);
  }

  @override
  void dispose() {
    _companyController.dispose();
    _cnpjController.dispose();
    _responsibleController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cepController.dispose();
    _addressController.dispose();
    _numberController.dispose();
    _regionController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
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
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 90),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cadastro Fornecedor',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Preencha os dados da empresa',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildField(
                        label: 'Nome da Empresa',
                        controller: _companyController,
                        hint: 'Razão social ou Nome fantasia',
                        validator: _requiredValidator,
                      ),
                      _buildField(
                        label: 'CNPJ',
                        controller: _cnpjController,
                        hint: '00.000.000/0001-00',
                        keyboardType: TextInputType.number,
                        inputFormatters: _digitsOnly(14),
                        validator: _validateCnpj,
                      ),
                      _buildField(
                        label: 'Nome Completo do Responsável',
                        controller: _responsibleController,
                        hint: 'Responsável pela conta',
                        validator: _validateFullName,
                      ),
                      _buildField(
                        label: 'CPF do Responsável',
                        controller: _cpfController,
                        hint: '000.000.000-00',
                        keyboardType: TextInputType.number,
                        inputFormatters: _digitsOnly(11),
                        validator: _validateCpf,
                      ),
                      _buildField(
                        label: 'E-mail',
                        controller: _emailController,
                        hint: 'empresa@dominio.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      _buildField(
                        label: 'Confirmar E-mail',
                        controller: _confirmEmailController,
                        hint: 'Confirme o e-mail da empresa',
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmailConfirmation,
                      ),
                      _buildField(
                        label: 'Senha',
                        controller: _passwordController,
                        hint: 'Senha de acesso',
                        obscureText: obscurePassword,
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
                        validator: _validatePassword,
                      ),
                      _buildField(
                        label: 'Confirmar Senha',
                        controller: _confirmPasswordController,
                        hint: 'Confirme sua senha',
                        obscureText: obscureConfirmPassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword =
                                  !obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: _validatePasswordConfirmation,
                      ),
                      _buildField(
                        label: 'CEP',
                        controller: _cepController,
                        hint: '00000-000',
                        keyboardType: TextInputType.number,
                        inputFormatters: _digitsOnly(8),
                        validator: _validateCep,
                        onChanged: _searchAddressByCep,
                      ),
                      _buildField(
                        label: 'Endereço',
                        controller: _addressController,
                        hint: 'Endereço comercial',
                        validator: _requiredValidator,
                      ),
                      _buildField(
                        label: 'Número',
                        controller: _numberController,
                        hint: 'Nº',
                        keyboardType: TextInputType.number,
                        validator: _requiredValidator,
                      ),
                      _buildField(
                        label: 'Região de Atendimento',
                        controller: _regionController,
                        hint: 'Ex: Zona Sul, Zona Oeste',
                        validator: _requiredValidator,
                      ),
                      _buildField(
                        label: 'Telefone Contato 1',
                        controller: _phone1Controller,
                        hint: '(11) 99999-9999',
                        keyboardType: TextInputType.phone,
                        inputFormatters: _digitsOnly(11),
                        validator: _validatePhone,
                      ),
                      _buildField(
                        label: 'Telefone Contato 2',
                        controller: _phone2Controller,
                        hint: '(11) 99999-9999 (Opcional)',
                        keyboardType: TextInputType.phone,
                        inputFormatters: _digitsOnly(11),
                        validator: _validateOptionalPhone,
                      ),
                      const _FieldLabel('Categoria de Serviço'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        isExpanded: true,
                        decoration: _inputDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'Remoção de Entulhos',
                            child: Text('Remoção de Entulhos'),
                          ),
                          DropdownMenuItem(
                            value: 'Locação de Caçambas',
                            child: Text('Locação de Caçambas'),
                          ),
                          DropdownMenuItem(
                            value: 'Podas e Jardinagem',
                            child: Text('Podas e Jardinagem'),
                          ),
                          DropdownMenuItem(
                            value: 'Resíduos de Construção',
                            child: Text('Resíduos de Construção'),
                          ),
                          DropdownMenuItem(
                            value: 'Serviços Diversos',
                            child: Text('Serviços Diversos'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedCategory = value);
                          }
                        },
                      ),
                      const SizedBox(height: 38),
                      SizedBox(
                        width: double.infinity,
                        height: 57,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF2F8334),
                            disabledBackgroundColor:
                                AppColors.green.withValues(alpha: 0.55),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'CADASTRAR-SE',
                                  style: TextStyle(
                                    fontSize: 16,
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
      bottomNavigationBar: const _AuthBottomNavigation(),
    );
  }

  List<TextInputFormatter> _digitsOnly(int maxLength) {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.next,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            onChanged: onChanged,
            validator: validator,
            decoration: _inputDecoration(
              hintText: hint,
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black38),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: AppColors.green,
          width: 1.5,
        ),
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

  String? _validateFullName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Informe o nome do responsável';
    }

    if (!name.contains(' ')) {
      return 'Informe nome e sobrenome';
    }

    return null;
  }

  String? _validateCnpj(String? value) {
    final cnpj = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (cnpj.length != 14) {
      return 'Informe um CNPJ com 14 dígitos';
    }

    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) {
      return 'Informe um CNPJ válido';
    }

    return null;
  }

  String? _validateCpf(String? value) {
    final cpf = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (cpf.length != 11) {
      return 'Informe um CPF com 11 dígitos';
    }

    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'Informe um CPF válido';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe o e-mail';
    }

    final isValid = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);

    return isValid ? null : 'Informe um e-mail válido';
  }

  String? _validateEmailConfirmation(String? value) {
    final error = _validateEmail(value);

    if (error != null) return error;

    if (value!.trim().toLowerCase() !=
        _emailController.text.trim().toLowerCase()) {
      return 'Os e-mails não são iguais';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha';
    }

    if (value.length < 6) {
      return 'A senha deve possuir no mínimo 6 caracteres';
    }

    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a senha';
    }

    if (value != _passwordController.text) {
      return 'As senhas não são iguais';
    }

    return null;
  }

  String? _validateCep(String? value) {
    final cep = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    return cep.length == 8 ? null : 'Informe um CEP com 8 dígitos';
  }

  String? _validatePhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    return phone.length >= 10 ? null : 'Informe um telefone válido';
  }

  String? _validateOptionalPhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (phone.isNotEmpty && phone.length < 10) {
      return 'Informe um telefone válido';
    }

    return null;
  }

  void _searchAddressByCep(String value) {
    final cep = value.replaceAll(RegExp(r'\D'), '');

    if (cep.length == 8) {
      // A consulta do CEP será integrada posteriormente.
      FocusScope.of(context).nextFocus();
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    // Será substituído pela integração com a API.
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => isLoading = false);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: AppColors.green,
            size: 48,
          ),
          title: const Text('Cadastro enviado!'),
          content: const Text(
            'Os dados do fornecedor foram enviados para análise.',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
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
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: const AppLogo(),
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
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
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
        // Será implementado durante a componentização.
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
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}