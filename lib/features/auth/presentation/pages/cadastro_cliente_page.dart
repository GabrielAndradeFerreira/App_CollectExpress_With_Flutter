import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';

class CadastroClientePage extends StatefulWidget {
  final String email;
  final String password;

  const CadastroClientePage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<CadastroClientePage> createState() => _CadastroClientePageState();
}

class _CadastroClientePageState extends State<CadastroClientePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cepController = TextEditingController();
  final _addressController = TextEditingController();
  final _numberController = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController(text: widget.password);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cepController.dispose();
    _addressController.dispose();
    _numberController.dispose();
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
                        'Cadastro Cliente',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Preencha seus dados pessoais',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 26),

                      _buildField(
                        label: 'Nome Completo',
                        controller: _nameController,
                        hint: 'Nome e sobrenome',
                        textInputAction: TextInputAction.next,
                        validator: _validateName,
                      ),
                      _buildField(
                        label: 'CPF',
                        controller: _cpfController,
                        hint: '000.000.000-00',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: _validateCpf,
                      ),
                      _buildField(
                        label: 'E-mail',
                        controller: _emailController,
                        hint: 'seu-email@dominio.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _validateEmail,
                      ),
                      _buildField(
                        label: 'Confirmar E-mail',
                        controller: _confirmEmailController,
                        hint: 'Confirme seu endereço de e-mail',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _validateEmailConfirmation,
                      ),
                      _buildField(
                        label: 'Senha',
                        controller: _passwordController,
                        hint: 'No mínimo 6 caracteres',
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      _buildField(
                        label: 'Confirmar Senha',
                        controller: _confirmPasswordController,
                        hint: 'Digite a senha novamente',
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.next,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
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
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        validator: _validateCep,
                        onChanged: _searchAddressByCep,
                      ),
                      _buildField(
                        label: 'Endereço',
                        controller: _addressController,
                        hint: 'Rua, Avenida, Logradouro',
                        textInputAction: TextInputAction.next,
                        validator: _requiredValidator,
                      ),
                      _buildField(
                        label: 'Número',
                        controller: _numberController,
                        hint: 'Número da residência',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: _requiredValidator,
                      ),
                      _buildField(
                        label: 'Telefone Contato 1',
                        controller: _phone1Controller,
                        hint: '(11) 99999-9999',
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: _validatePhone,
                      ),
                      _buildField(
                        label: 'Telefone Contato 2',
                        controller: _phone2Controller,
                        hint: '(11) 99999-9999 (Opcional)',
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: _validateOptionalPhone,
                      ),

                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 57,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
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
                          child: _isLoading
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
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
            ),
          ),
        ],
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório';
    }

    return null;
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Informe seu nome completo';
    }

    if (!name.contains(' ')) {
      return 'Informe nome e sobrenome';
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
      return 'Informe seu e-mail';
    }

    final valid = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);

    if (!valid) {
      return 'Informe um e-mail válido';
    }

    return null;
  }

  String? _validateEmailConfirmation(String? value) {
    final validation = _validateEmail(value);

    if (validation != null) {
      return validation;
    }

    if (value!.trim().toLowerCase() !=
        _emailController.text.trim().toLowerCase()) {
      return 'Os e-mails não são iguais';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe sua senha';
    }

    if (value.length < 6) {
      return 'A senha deve possuir no mínimo 6 caracteres';
    }

    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme sua senha';
    }

    if (value != _passwordController.text) {
      return 'As senhas não são iguais';
    }

    return null;
  }

  String? _validateCep(String? value) {
    final cep = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (cep.length != 8) {
      return 'Informe um CEP com 8 dígitos';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (phone.length < 10) {
      return 'Informe um telefone válido';
    }

    return null;
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
      // A consulta de CEP será integrada posteriormente.
      FocusScope.of(context).nextFocus();
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Simulação temporária da chamada da API.
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _isLoading = false);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: AppColors.green,
            size: 48,
          ),
          title: const Text('Cadastro realizado!'),
          content: const Text(
            'Sua conta de cliente foi criada com sucesso.',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
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
        // Será implementado na componentização da navegação.
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