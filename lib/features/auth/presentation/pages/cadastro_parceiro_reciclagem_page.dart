import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/models/reciclagem.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../reciclagem/presentation/reciclagem_providers.dart';
import '../../data/auth_repository.dart';
import '../validacao_senha.dart';

/// Cadastro do parceiro de reciclagem. A conta fica PENDENTE até um
/// administrador aprovar.
class CadastroParceiroReciclagemPage extends ConsumerStatefulWidget {
  final String email;
  final String password;

  const CadastroParceiroReciclagemPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  ConsumerState<CadastroParceiroReciclagemPage> createState() =>
      _CadastroParceiroReciclagemPageState();
}

class _CadastroParceiroReciclagemPageState
    extends ConsumerState<CadastroParceiroReciclagemPage> {
  final _formKey = GlobalKey<FormState>();

  final _companyController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _addressController = TextEditingController();
  final _capacityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  final Set<String> _materiais = {};
  bool _tentouEnviar = false;

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
    _responsibleController.dispose();
    _addressController.dispose();
    _capacityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

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
          Semantics(
            header: true,
            child: const Text(
              'Cadastro Parceiro de Reciclagem',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Preencha os dados da empresa. A equipe analisa o cadastro antes '
            'de liberar o acesso.',
            style: TextStyle(color: Colors.black54, fontSize: 15),
          ),
          const SizedBox(height: 28),

          _buildField(
            label: 'Nome da Empresa',
            controller: _companyController,
            hint: 'Nome que aparece para quem entrega o material',
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
            label: 'Responsável',
            controller: _responsibleController,
            hint: 'Nome completo de quem responde pela empresa',
            validator: _comErroDaApi('responsavel_nome', _validateResponsible),
          ),
          _buildField(
            label: 'Endereço da empresa',
            controller: _addressController,
            hint: 'Rua, número, bairro, cidade - UF',
            validator: _comErroDaApi('endereco_coleta', _validateAddress),
          ),
          _buildField(
            label: 'Telefone',
            controller: _phoneController,
            hint: '(11) 99999-9999',
            keyboardType: TextInputType.phone,
            inputFormatters: _digitsOnly(11),
            validator: _comErroDaApi('telefone', _validatePhone),
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
                setState(() => _obscurePassword = !_obscurePassword);
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
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            validator: _validatePasswordConfirmation,
          ),

          const SizedBox(height: 6),
          const Text(
            'O que você coleta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Você só verá sinalizações desses materiais.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 14),
          _buildMateriais(),
          const SizedBox(height: 18),
          _buildField(
            label: 'Capacidade diária de coleta (opcional)',
            controller: _capacityController,
            hint: 'Em kg, por exemplo 500',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffixText: 'kg',
            validator: _comErroDaApi('capacidade_diaria_kg', _validateCapacity),
          ),

          const SizedBox(height: 10),
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

  Widget _buildMateriais() {
    final catalogo = ref.watch(materiaisReciclaveisProvider);

    return catalogo.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(materiaisReciclaveisProvider),
      ),
      data: (materiais) {
        final erro =
            _errosApi['materiais_ids'] ??
            (_tentouEnviar && _materiais.isEmpty
                ? 'Escolha ao menos um tipo de material.'
                : null);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final material in materiais)
                  FilterChip(
                    label: Text(material.nome),
                    selected: _materiais.contains(material.id),
                    selectedColor: const Color(0xFFD7EFD3),
                    checkmarkColor: const Color(0xFF2F8334),
                    onSelected: (marcado) {
                      setState(() {
                        if (marcado) {
                          _materiais.add(material.id);
                        } else {
                          _materiais.remove(material.id);
                        }
                      });
                    },
                  ),
              ],
            ),
            if (erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  erro,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
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
    String? suffixText,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.next,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            validator: validator,
            decoration: _inputDecoration(
              hintText: hint,
              suffixIcon: suffixIcon,
              suffixText: suffixText,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black38),
      suffixText: suffixText,
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

    if (name.isEmpty) return 'Informe o nome da empresa';
    if (name.length < 3) return 'O nome deve ter pelo menos 3 letras';

    return null;
  }

  String? _validateCnpj(String? value) {
    final cnpj = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (cnpj.length != 14) return 'Informe um CNPJ com 14 dígitos';
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) {
      return 'Informe um CNPJ válido';
    }

    return null;
  }

  String? _validateResponsible(String? value) {
    final name = value?.trim() ?? '';

    return name.length < 3 ? 'Informe o nome do responsável' : null;
  }

  String? _validateAddress(String? value) {
    final address = value?.trim() ?? '';

    if (address.length < 5) return 'Informe o endereço da empresa';
    if (address.length > 255) return 'Use no máximo 255 caracteres';

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return 'Informe o e-mail';

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
    if (value == null || value.isEmpty) return 'Confirme a senha';

    if (value != _passwordController.text) return 'As senhas não são iguais';

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    return phone.length >= 10 ? null : 'Informe um telefone válido';
  }

  String? _validateCapacity(String? value) {
    final texto = value?.trim() ?? '';

    if (texto.isEmpty) return null;

    final kg = _parseDecimal(texto);

    if (kg == null || kg <= 0 || kg > 10000000) {
      return 'Informe uma capacidade válida em kg';
    }

    return null;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errosApi = const {};
      _tentouEnviar = true;
    });

    final formularioValido = _formKey.currentState!.validate();

    if (!formularioValido || _materiais.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .registrar(
            nomeCompleto: _companyController.text.trim(),
            email: _emailController.text.trim(),
            senha: _passwordController.text,
            tipoPerfil: TipoPerfil.parceiro,
            documento: _cnpjController.text,
            telefone: _phoneController.text,
            dadosParceiro: DadosCadastroParceiro(
              responsavelNome: _responsibleController.text,
              enderecoColeta: _addressController.text,
              materiaisIds: _materiais.toList(),
              capacidadeDiariaKg: _capacityController.text.trim().isEmpty
                  ? null
                  : _parseDecimal(_capacityController.text),
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
            'Os dados da empresa foram enviados para análise. Você poderá '
            'entrar no app assim que um administrador aprovar o cadastro. '
            'Avisaremos por e-mail.',
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
