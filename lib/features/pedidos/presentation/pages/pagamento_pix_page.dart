import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/pagamento_pix.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../data/pedidos_repository.dart';

const _corPix = Color(0xFF32BCAD);

/// Pagamento de um pedido, ou de uma extensão dele ([extensaoId]), por PIX.
///
/// Gera o PIX (ou reaproveita o pendente), mostra o QR Code e o copia e
/// cola e consulta a API a cada [intervaloConsulta] até o pagamento ser
/// confirmado. Quem abre a tela recarrega o pedido quando ela fecha.
class PagamentoPixPage extends ConsumerStatefulWidget {
  final String aluguelId;

  /// Quando informado, paga a extensão aceita pelo fornecedor em vez do
  /// pedido.
  final String? extensaoId;

  final Duration intervaloConsulta;

  const PagamentoPixPage({
    super.key,
    required this.aluguelId,
    this.extensaoId,
    this.intervaloConsulta = const Duration(seconds: 5),
  });

  @override
  ConsumerState<PagamentoPixPage> createState() => _PagamentoPixPageState();
}

class _PagamentoPixPageState extends ConsumerState<PagamentoPixPage> {
  PagamentoPix? _pix;
  Object? _erro;
  bool _gerando = false;
  bool _simulando = false;

  /// O pedido já estava pago quando a tela abriu.
  bool _jaPago = false;

  Timer? _timer;
  bool _consultando = false;

  bool get _pago => _jaPago || (_pix?.pago ?? false);

  PedidosRepository get _repositorio => ref.read(pedidosRepositoryProvider);

  Future<PagamentoPix> _gerarNaApi() {
    final extensaoId = widget.extensaoId;

    return extensaoId == null
        ? _repositorio.gerarPix(widget.aluguelId)
        : _repositorio.gerarPixExtensao(widget.aluguelId, extensaoId);
  }

  Future<PagamentoPix> _consultarNaApi() {
    final extensaoId = widget.extensaoId;

    return extensaoId == null
        ? _repositorio.consultarPix(widget.aluguelId)
        : _repositorio.consultarPixExtensao(widget.aluguelId, extensaoId);
  }

  Future<PagamentoPix> _simularNaApi() {
    final extensaoId = widget.extensaoId;

    return extensaoId == null
        ? _repositorio.simularPagamentoPix(widget.aluguelId)
        : _repositorio.simularPagamentoPixExtensao(
            widget.aluguelId,
            extensaoId,
          );
  }

  @override
  void initState() {
    super.initState();
    _gerar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _gerar() async {
    _timer?.cancel();
    setState(() {
      _gerando = true;
      _erro = null;
    });

    try {
      final pix = await _gerarNaApi();
      if (!mounted) return;

      setState(() => _pix = pix);
      _acompanhar();
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        if (error.code == 'ORDER_ALREADY_PAID' ||
            error.code == 'EXTENSION_ALREADY_PAID') {
          _jaPago = true;
        } else {
          _erro = error;
        }
      });
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  /// Consulta o pagamento periodicamente enquanto o PIX está pendente.
  void _acompanhar() {
    _timer?.cancel();
    if (!(_pix?.aguardando ?? false)) return;

    _timer = Timer.periodic(widget.intervaloConsulta, (_) => _consultar());
  }

  Future<void> _consultar() async {
    if (_consultando) return;
    _consultando = true;

    try {
      final pix = await _consultarNaApi();
      if (!mounted) return;

      setState(() => _pix = pix);
      if (!pix.aguardando) _timer?.cancel();
    } on ApiException {
      // Falha momentânea: tenta de novo na próxima consulta.
    } finally {
      _consultando = false;
    }
  }

  Future<void> _simular() async {
    setState(() => _simulando = true);

    try {
      final pix = await _simularNaApi();
      if (!mounted) return;

      setState(() => _pix = pix);
      if (!pix.aguardando) _timer?.cancel();
    } on ApiException catch (error) {
      if (mounted) showApiError(context, error);
    } finally {
      if (mounted) setState(() => _simulando = false);
    }
  }

  Future<void> _copiar(String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código PIX copiado.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pix = _pix;

    final Widget conteudo;
    if (_pago) {
      conteudo = _PagamentoConfirmado(
        onVoltar: () => Navigator.of(context).pop(true),
      );
    } else if (_gerando) {
      conteudo = const LoadingView();
    } else if (_erro != null || pix == null) {
      conteudo = ErrorView(
        error: _erro ?? const ApiException('Não foi possível gerar o PIX.'),
        onRetry: _gerar,
      );
    } else if (pix.encerrado) {
      conteudo = _PixEncerrado(onGerarNovo: _gerar);
    } else {
      conteudo = _PixAguardando(
        pix: pix,
        simulando: _simulando,
        onCopiar: () => _copiar(pix.copiaECola),
        onSimular: _simular,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _PageHeader(
                onVoltar: () => Navigator.of(context).pop(_pago),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 60),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    widget.extensaoId == null
                        ? 'Pagamento por Pix'
                        : 'Pagamento da extensão',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pague pelo app do seu banco; a confirmação é automática',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  conteudo,
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final VoidCallback onVoltar;

  const _PageHeader({required this.onVoltar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 18, 18, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Voltar',
            onPressed: onVoltar,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 4),
          const Expanded(child: AppLogo()),
        ],
      ),
    );
  }
}

class _PixAguardando extends StatelessWidget {
  final PagamentoPix pix;
  final bool simulando;
  final VoidCallback onCopiar;
  final VoidCallback onSimular;

  const _PixAguardando({
    required this.pix,
    required this.simulando,
    required this.onCopiar,
    required this.onSimular,
  });

  @override
  Widget build(BuildContext context) {
    final qrCode = pix.qrCodeBytes;
    final expiraEm = pix.expiraEm?.toLocal();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Text(
                'Valor a pagar',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                formatMoney(pix.valor),
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              if (qrCode != null)
                Image.memory(
                  qrCode,
                  width: 220,
                  height: 220,
                  gaplessPlayback: true,
                  semanticLabel: 'QR Code do PIX',
                )
              else
                const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Use o código copia e cola abaixo.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  pix.copiaECola,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onCopiar,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _corPix,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text(
                    'Copiar código Pix',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (expiraEm != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Válido até ${formatDate(expiraEm)} às '
                  '${expiraEm.hour.toString().padLeft(2, '0')}:'
                  '${expiraEm.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.green,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Aguardando o pagamento...',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _Passo(
          numero: 1,
          texto: 'Abra o app do seu banco e escolha pagar com Pix.',
        ),
        const _Passo(
          numero: 2,
          texto: 'Leia o QR Code ou cole o código copiado.',
        ),
        const _Passo(
          numero: 3,
          texto: 'Confirme o pagamento. Esta tela atualiza sozinha.',
        ),
        if (pix.devMode) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Modo de teste: nenhum valor é cobrado. Use o botão abaixo '
                  'para simular o pagamento.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: simulando ? null : onSimular,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB86E00),
                    side: const BorderSide(color: Color(0xFFB86E00)),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: simulando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Simular pagamento',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Passo extends StatelessWidget {
  final int numero;
  final String texto;

  const _Passo({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.sustainability,
            child: Text(
              '$numero',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PagamentoConfirmado extends StatelessWidget {
  final VoidCallback onVoltar;

  const _PagamentoConfirmado({required this.onVoltar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.green,
            child: Icon(Icons.check, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 18),
          const Text(
            'Pagamento confirmado!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'O pedido está pago. Acompanhe a entrega na tela do pedido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onVoltar,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'Voltar ao pedido',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PixEncerrado extends StatelessWidget {
  final VoidCallback onGerarNovo;

  const _PixEncerrado({required this.onGerarNovo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const Icon(Icons.timer_off_outlined, size: 54, color: Colors.black38),
          const SizedBox(height: 14),
          const Text(
            'Este PIX expirou.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gere um novo código para pagar o pedido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onGerarNovo,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _corPix,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'Gerar novo PIX',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
