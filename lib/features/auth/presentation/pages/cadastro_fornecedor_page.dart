import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/models/usuario.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../data/auth_repository.dart';
import '../validacao_senha.dart';

class CadastroFornecedorPage extends ConsumerStatefulWidget {
  final String email;
  final String password;

  const CadastroFornecedorPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  ConsumerState<CadastroFornecedorPage> createState() =>
      _CadastroFornecedorPageState();
}

class _CadastroFornecedorPageState
    extends ConsumerState<CadastroFornecedorPage> {
  final _formKey = GlobalKey<FormState>();

  final _companyController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  final _openingController = TextEditingController();
  final _closingController = TextEditingController();
  final _feeController = TextEditingController();

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  /// Erros de validação devolvidos pela API, por campo.
  Map<String, String> _errosApi = const {};

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
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();

    _openingController.dispose();
    _closingController.dispose();
    _feeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _PageHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 30, 18, 90),
                sliver: SliverToBoxAdapter(child: _buildForm()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
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
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 28),

          _buildField(
            label: 'Nome da Empresa',
            controller: _companyController,
            hint: 'Nome que aparece para os clientes',
            validator: _comErroDaApi('nome_completo', _validateCompany),
          ),
          _buildField(
            label: 'CNPJ',
            controller: _cnpjController,
            hint: '00.000.000/0001-00',
            keyboardType: TextInputType.number,
            inputFormatters: _digitsOnly(14),
            validator: _comErroDaApi('documento', _validateCnpj),
          ),
          _buildField(
            label: 'E-mail',
            controller: _emailController,
            hint: 'empresa@dominio.com',
            keyboardType: TextInputType.emailAddress,
            validator: _comErroDaApi('email', _validateEmail),
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
            hint: 'Mínimo 8 caracteres, com maiúscula, minúscula e número',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
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
            validator: _comErroDaApi('senha', validarSenhaCadastro),
          ),
          _buildField(
            label: 'Confirmar Senha',
            controller: _confirmPasswordController,
            hint: 'Confirme sua senha',
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              tooltip: _obscureConfirmPassword
                  ? 'Mostrar senha'
                  : 'Ocultar senha',
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
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
            label: 'Telefone',
            controller: _phoneController,
            hint: '(11) 99999-9999',
            keyboardType: TextInputType.phone,
            inputFormatters: _digitsOnly(11),
            validator: _comErroDaApi('telefone', _validatePhone),
          ),

          const SizedBox(height: 6),
          const Text(
            'Atendimento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aparece para os clientes no catálogo e no pedido',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildField(
                  label: 'Abre às',
                  controller: _openingController,
                  hint: '07:00',
                  readOnly: true,
                  onTap: () => _pickTime(_openingController),
                  suffixIcon: const Icon(Icons.schedule),
                  validator: _comErroDaApi('horario_inicio', _validateTime),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  label: 'Fecha às',
                  controller: _closingController,
                  hint: '18:00',
                  readOnly: true,
                  onTap: () => _pickTime(_closingController),
                  suffixIcon: const Icon(Icons.schedule),
                  validator: _comErroDaApi('horario_fim', _validateClosing),
                ),
              ),
            ],
          ),
          _buildField(
            label: 'Taxa de Entrega',
            controller: _feeController,
            hint: '0,00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText: 'R\$ ',
            validator: _comErroDaApi('taxa_entrega', _validateFee),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 57,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF2F8334),
                disabledBackgroundColor: AppColors.green.withValues(
                  alpha: 0.55,
                ),
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
    );
  }

  List<TextInputFormatter> _digitsOnly(int maxLength) {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  /// Mostra primeiro o erro que a API devolveu para [campo], se houver.
  String? Function(String?) _comErroDaApi(
    String campo,
    String? Function(String?) validator,
  ) {
    return (value) => _errosApi[campo] ?? validator(value);
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    String? prefixText,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
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
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.next,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            validator: validator,
            decoration: _inputDecoration(
              hintText: hint,
              suffixIcon: suffixIcon,
              prefixText: prefixText,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? suffixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black38),
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      errorMaxLines: 2,
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

  Future<void> _pickTime(TextEditingController controller) async {
    final current = _parseTime(controller.text);
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (picked == null || !mounted) return;

    setState(() {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  TimeOfDay? _parseTime(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;

    return TimeOfDay(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  /// Aceita "1.234,56", "1234,56" e "1234.56".
  double? _parseDecimal(String value) {
    var text = value.trim();
    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(text);
  }

  String? _validateCompany(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Informe o nome da empresa';
    }

    if (name.length < 3) {
      return 'O nome deve ter pelo menos 3 letras';
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

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe o e-mail';
    }

    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

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

  String? _validatePasswordConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a senha';
    }

    if (value != _passwordController.text) {
      return 'As senhas não são iguais';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    return phone.length >= 10 ? null : 'Informe um telefone válido';
  }

  String? _validateTime(String? value) {
    return _parseTime(value ?? '') == null ? 'Escolha o horário' : null;
  }

  String? _validateClosing(String? value) {
    final error = _validateTime(value);
    if (error != null) return error;

    final opening = _parseTime(_openingController.text);
    final closing = _parseTime(value!)!;

    int minutes(TimeOfDay time) => time.hour * 60 + time.minute;

    if (opening != null && minutes(closing) <= minutes(opening)) {
      return 'Deve ser depois da abertura';
    }

    return null;
  }

  String? _validateFee(String? value) {
    final fee = _parseDecimal(value ?? '');

    if (fee == null) {
      return 'Informe a taxa de entrega';
    }

    if (fee < 0.01 || fee > 99999.99) {
      return 'A taxa deve estar entre R\$ 0,01 e R\$ 99.999,99';
    }

    return null;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    setState(() => _errosApi = const {});

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .registrar(
            nomeCompleto: _companyController.text.trim(),
            email: _emailController.text.trim(),
            senha: _passwordController.text,
            tipoPerfil: TipoPerfil.cacambeiro,
            documento: _cnpjController.text,
            telefone: _phoneController.text,
            detalhesCacambeiro: DetalhesCacambeiro(
              horarioInicio: _openingController.text,
              horarioFim: _closingController.text,
              taxaEntrega: _parseDecimal(_feeController.text)!,
            ),
          );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (error is ApiException) _errosApi = error.fields;
      });
      _formKey.currentState!.validate();
      showApiError(context, error);
      return;
    }

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
          title: const Text('Cadastro enviado!'),
          content: const Text(
            'Os dados do fornecedor foram enviados para análise. Você poderá '
            'entrar no app assim que um administrador aprovar o cadastro.',
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

    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
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
