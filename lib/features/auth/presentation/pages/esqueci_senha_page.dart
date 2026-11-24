import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/recuperacao_senha.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../data/auth_repository.dart';
import '../validacao_senha.dart';

/// "Esqueci minha senha", em dois passos: o e-mail recebe um código de 6
/// dígitos, e o código com a senha nova troca a senha.
///
/// Recebe em `arguments` o e-mail já digitado no login. Ao terminar, volta
/// para o login devolvendo o e-mail, que o login preenche.
class EsqueciSenhaPage extends ConsumerStatefulWidget {
  const EsqueciSenhaPage({super.key});

  @override
  ConsumerState<EsqueciSenhaPage> createState() => _EsqueciSenhaPageState();
}

class _EsqueciSenhaPageState extends ConsumerState<EsqueciSenhaPage> {
  final _formEmailKey = GlobalKey<FormState>();
  final _formSenhaKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();

  /// Preenchido depois que a API aceita o e-mail (segundo passo).
  PedidoRecuperacaoSenha? _pedido;

  bool _carregando = false;
  bool _ocultarSenha = true;
  bool _leuArgumentos = false;
  Map<String, String> _errosApi = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_leuArgumentos) return;
    _leuArgumentos = true;

    final email = ModalRoute.of(context)?.settings.arguments;
    if (email is String) _emailController.text = email.trim();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _senhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pedido = _pedido;

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
                child: pedido == null ? _passoEmail() : _passoNovaSenha(pedido),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passoEmail() {
    return Form(
      key: _formEmailKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Titulo('Esqueci minha senha'),
          const SizedBox(height: 10),
          const _Explicacao(
            'Digite o e-mail da sua conta. Vamos enviar um código de 6 '
            'dígitos para você criar uma senha nova.',
          ),
          const SizedBox(height: 28),
          const _FieldLabel('E-mail'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _enviarCodigo(),
            decoration: _inputDecoration(hintText: 'seu-email@dominio.com'),
            validator: _comErroDaApi('identifier', _validarEmail),
          ),
          const SizedBox(height: 36),
          _BotaoPrincipal(
            texto: 'ENVIAR CÓDIGO',
            carregando: _carregando,
            onPressed: _enviarCodigo,
          ),
          const SizedBox(height: 14),
          Center(
            child: _BotaoTexto(
              texto: 'Voltar para o login',
              onPressed: _carregando ? null : () => _voltarAoLogin(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passoNovaSenha(PedidoRecuperacaoSenha pedido) {
    final destino = pedido.destinoMascarado ?? _emailController.text.trim();
    final codigoDeTeste = pedido.codigoDeTeste;

    return Form(
      key: _formSenhaKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Titulo('Crie uma senha nova'),
          const SizedBox(height: 10),
          _Explicacao(
            'Se houver uma conta com $destino, enviamos para esse e-mail um '
            'código de 6 dígitos. Ele vale por 15 minutos.',
          ),
          if (codigoDeTeste != null) ...[
            const SizedBox(height: 16),
            _AvisoCodigoDeTeste(
              codigo: codigoDeTeste,
              onUsar: () =>
                  setState(() => _codigoController.text = codigoDeTeste),
            ),
          ],
          const SizedBox(height: 28),
          const _FieldLabel('Código'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _codigoController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: _inputDecoration(hintText: '000000'),
            validator: _comErroDaApi('code', _validarCodigo),
          ),
          const SizedBox(height: 18),
          const _FieldLabel('Nova senha'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _senhaController,
            obscureText: _ocultarSenha,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: _inputDecoration(
              hintText: 'Mínimo de 8 caracteres',
              suffixIcon: IconButton(
                tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
                icon: Icon(
                  _ocultarSenha
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: _comErroDaApi('nova_senha', validarSenhaCadastro),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use 8 caracteres ou mais, com letra maiúscula, minúscula e '
            'número.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 18),
          const _FieldLabel('Confirme a nova senha'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmacaoController,
            obscureText: _ocultarSenha,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _redefinirSenha(),
            decoration: _inputDecoration(hintText: 'Repita a senha nova'),
            validator: (value) => value == _senhaController.text
                ? null
                : 'As senhas não conferem',
          ),
          const SizedBox(height: 36),
          _BotaoPrincipal(
            texto: 'REDEFINIR SENHA',
            carregando: _carregando,
            onPressed: _redefinirSenha,
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            children: [
              _BotaoTexto(
                texto: 'Reenviar código',
                onPressed: _carregando
                    ? null
                    : () => _enviarCodigo(reenvio: true),
              ),
              _BotaoTexto(
                texto: 'Usar outro e-mail',
                onPressed: _carregando ? null : _usarOutroEmail,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Primeiro passo, e também o "Reenviar código" do segundo.
  Future<void> _enviarCodigo({bool reenvio = false}) async {
    FocusScope.of(context).unfocus();
    setState(() => _errosApi = const {});

    if (!reenvio && !_formEmailKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final pedido = await ref
          .read(authRepositoryProvider)
          .solicitarRecuperacaoSenha(_emailController.text);

      if (!mounted) return;

      setState(() {
        _pedido = pedido;
        _codigoController.clear();
      });

      if (reenvio) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enviamos um código novo. O anterior não vale mais.'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;

      _mostrarErro(error, error.fields, _formEmailKey);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _redefinirSenha() async {
    FocusScope.of(context).unfocus();
    setState(() => _errosApi = const {});

    if (!_formSenhaKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .redefinirSenha(
            requestId: _pedido!.requestId,
            codigo: _codigoController.text,
            novaSenha: _senhaController.text,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha alterada! Entre com a senha nova.'),
          backgroundColor: AppColors.green,
        ),
      );
      _voltarAoLogin(email: _emailController.text.trim());
    } on ApiException catch (error) {
      if (!mounted) return;

      _mostrarErro(error, {
        ...error.fields,
        // Código errado, vencido ou já usado aparece no campo do código.
        if (error.code == 'INVALID_RECOVERY_CODE') 'code': error.message,
        if (error.code == 'WEAK_PASSWORD') 'nova_senha': error.message,
      }, _formSenhaKey);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// Erro de um campo aparece no próprio campo; os demais (limite de
  /// tentativas, API fora do ar) num aviso embaixo.
  void _mostrarErro(
    ApiException error,
    Map<String, String> porCampo,
    GlobalKey<FormState> form,
  ) {
    setState(() => _errosApi = porCampo);
    form.currentState?.validate();

    if (porCampo.isEmpty) showApiError(context, error);
  }

  void _usarOutroEmail() {
    setState(() {
      _pedido = null;
      _errosApi = const {};
      _codigoController.clear();
      _senhaController.clear();
      _confirmacaoController.clear();
    });
  }

  /// Volta para o login (devolvendo o [email], se houver). Aberta direto,
  /// sem tela atrás, abre o login.
  void _voltarAoLogin({String? email}) {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop(email);
    } else {
      navigator.pushReplacementNamed(AppRoutes.login);
    }
  }

  /// Mostra primeiro o erro que a API devolveu para [campo], se houver.
  String? Function(String?) _comErroDaApi(
    String campo,
    String? Function(String?) validator,
  ) {
    return (value) => _errosApi[campo] ?? validator(value);
  }

  String? _validarEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe seu e-mail';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Informe um e-mail válido';
    }

    return null;
  }

  String? _validarCodigo(String? value) {
    final codigo = value?.trim() ?? '';

    if (codigo.isEmpty) {
      return 'Informe o código que você recebeu';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(codigo)) {
      return 'O código tem 6 números';
    }

    return null;
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black38),
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
}

/// Sem e-mail configurado na API (ambiente de testes), o código vem na
/// resposta e aparece aqui, como o "Simular pagamento" do PIX.
class _AvisoCodigoDeTeste extends StatelessWidget {
  const _AvisoCodigoDeTeste({required this.codigo, required this.onUsar});

  final String codigo;
  final VoidCallback onUsar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Modo de teste: a API não está enviando e-mails. '
            'Seu código é $codigo.',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onUsar,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB86E00),
              side: const BorderSide(color: Color(0xFFB86E00)),
              minimumSize: const Size.fromHeight(46),
            ),
            child: const Text(
              'Usar este código',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoPrincipal extends StatelessWidget {
  const _BotaoPrincipal({
    required this.texto,
    required this.carregando,
    required this.onPressed,
  });

  final String texto;
  final bool carregando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 57,
      child: ElevatedButton(
        onPressed: carregando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF2F8334),
          disabledBackgroundColor: AppColors.green.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: carregando
            ? const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _BotaoTexto extends StatelessWidget {
  const _BotaoTexto({required this.texto, required this.onPressed});

  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF267A2D)),
      child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w800)),
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
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const AppLogo(),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
    );
  }
}

class _Explicacao extends StatelessWidget {
  const _Explicacao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(color: Colors.black54, fontSize: 15, height: 1.4),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }
}
