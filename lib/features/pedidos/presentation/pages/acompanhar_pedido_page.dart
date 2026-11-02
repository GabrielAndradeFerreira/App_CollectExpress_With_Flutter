import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/aluguel.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/models/extensao.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/cacamba_image.dart';
import '../../../auth/data/sessao_provider.dart';
import '../../data/pedidos_repository.dart';
import '../compartilhar_pdf.dart';
import '../pedidos_format.dart';
import '../widgets/contrato_extensao_cards.dart';
import 'pagamento_pix_page.dart';

/// Detalhe de um pedido: itens, endereço, contatos, avaliação e etapas.
final pedidoDetalheProvider = FutureProvider.autoDispose
    .family<Aluguel, String>((ref, aluguelId) {
      // Recarrega quando alguém entra ou sai da conta.
      ref.watch(sessaoProvider.select((sessao) => sessao.value?.id));
      return ref.watch(pedidosRepositoryProvider).detalhe(aluguelId);
    });

class AcompanharPedidoPage extends ConsumerStatefulWidget {
  final String aluguelId;

  const AcompanharPedidoPage({super.key, required this.aluguelId});

  @override
  ConsumerState<AcompanharPedidoPage> createState() =>
      _AcompanharPedidoPageState();
}

class _AcompanharPedidoPageState extends ConsumerState<AcompanharPedidoPage> {
  bool _baixandoContrato = false;
  bool _estendendo = false;

  Future<void> _atualizar() async {
    final provider = pedidoDetalheProvider(widget.aluguelId);

    try {
      ref.invalidate(provider);
      await ref.read(provider.future);
    } catch (_) {
      // O erro aparece na própria tela.
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Status do pedido atualizado.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedido = ref.watch(pedidoDetalheProvider(widget.aluguelId));

    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _atualizar,
          color: AppColors.green,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _PageHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 60),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      'Acompanhar Pedido',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Acompanhe cada etapa da sua locação',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    AsyncValueView(
                      value: pedido,
                      onRetry: () => ref.invalidate(
                        pedidoDetalheProvider(widget.aluguelId),
                      ),
                      data: (dados) =>
                          _buildPedido(dados, atualizando: pedido.isLoading),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomerBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildPedido(Aluguel pedido, {required bool atualizando}) {
    final codigo = pedido.codigo;
    final fornecedor = pedido.cacambeiro;
    final telefone = fornecedor?.telefone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OrderHeaderCard(
          pedido: pedido,
          isRefreshing: atualizando,
          onCopy: codigo == null
              ? null
              : () => _copiar(codigo, 'Código do pedido copiado.'),
          onRefresh: _atualizar,
        ),
        if (pedido.statusPagamento == StatusPagamento.pendente) ...[
          const SizedBox(height: 20),
          _PagamentoPendenteCard(valor: pedido.precoFinal, onPagar: _pagar),
        ],
        if (pedido.contratoDisponivel) ...[
          const SizedBox(height: 20),
          ContratoCard(
            baixando: _baixandoContrato,
            onBaixar: () => _baixarContrato(pedido),
          ),
        ],
        if (ExtensaoCard.deveAparecer(pedido)) ...[
          const SizedBox(height: 20),
          ExtensaoCard(
            resumo: pedido.extensao!,
            ocupado: _estendendo,
            onEstender: () => _estender(pedido.extensao!),
            onPagar: _pagarExtensao,
          ),
        ],
        const SizedBox(height: 20),
        _OrderProgressCard(etapas: _etapasDo(pedido)),
        const SizedBox(height: 20),
        _DeliveryDetailsCard(pedido: pedido),
        const SizedBox(height: 20),
        _DumpsterCard(pedido: pedido),
        if (fornecedor != null) ...[
          const SizedBox(height: 20),
          _SupplierCard(
            contato: fornecedor,
            onCopyPhone: telefone == null
                ? null
                : () => _copiar(telefone, 'Telefone do fornecedor copiado.'),
          ),
        ],
        if (pedido.statusAluguel == StatusAluguel.finalizado) ...[
          const SizedBox(height: 20),
          _AvaliacaoCard(pedido: pedido),
        ],
      ],
    );
  }

  Future<void> _pagar() async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => PagamentoPixPage(aluguelId: widget.aluguelId),
      ),
    );
    if (!mounted) return;

    ref.invalidate(pedidoDetalheProvider(widget.aluguelId));
  }

  Future<void> _baixarContrato(Aluguel pedido) async {
    setState(() => _baixandoContrato = true);

    try {
      final bytes = await ref
          .read(pedidosRepositoryProvider)
          .baixarContrato(widget.aluguelId);

      await ref.read(compartilharPdfProvider)(
        bytes,
        'contrato-${pedido.codigo ?? widget.aluguelId}.pdf',
      );
    } on ApiException catch (error) {
      if (mounted) showApiError(context, error);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o contrato.')),
        );
      }
    } finally {
      if (mounted) setState(() => _baixandoContrato = false);
    }
  }

  Future<void> _estender(ResumoExtensao resumo) async {
    final dias = await mostrarEscolhaDeDias(context, resumo);
    if (dias == null || !mounted) return;

    setState(() => _estendendo = true);

    try {
      await ref
          .read(pedidosRepositoryProvider)
          .solicitarExtensao(widget.aluguelId, dias);
      if (!mounted) return;

      ref.invalidate(pedidoDetalheProvider(widget.aluguelId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pedido enviado ao fornecedor. Você receberá a resposta por '
            'e-mail.',
          ),
          backgroundColor: AppColors.green,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      showApiError(context, error);
      // O pedido pode ter mudado (ex.: já havia outra extensão em aberto).
      ref.invalidate(pedidoDetalheProvider(widget.aluguelId));
    } finally {
      if (mounted) setState(() => _estendendo = false);
    }
  }

  Future<void> _pagarExtensao(String extensaoId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => PagamentoPixPage(
          aluguelId: widget.aluguelId,
          extensaoId: extensaoId,
        ),
      ),
    );
    if (!mounted) return;

    ref.invalidate(pedidoDetalheProvider(widget.aluguelId));
  }

  /// As etapas vêm da API; sem elas, monta a partir do status atual.
  List<EtapaAluguel> _etapasDo(Aluguel pedido) {
    if (pedido.etapas.isNotEmpty) return pedido.etapas;

    final status = pedido.statusAluguel ?? StatusAluguel.aguardandoEntrega;
    final finalizado = status == StatusAluguel.finalizado;

    return [
      for (final etapa in StatusAluguel.values)
        EtapaAluguel(
          status: etapa,
          titulo: etapa.label,
          concluida:
              etapa.index < status.index || (finalizado && etapa == status),
          atual: etapa == status && !finalizado,
          pendente: etapa.index > status.index,
        ),
    ];
  }

  Future<void> _copiar(String texto, String mensagem) async {
    await Clipboard.setData(ClipboardData(text: texto));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: AppColors.green),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(child: AppLogo()),
          Builder(
            builder: (scaffoldContext) {
              return IconButton(
                tooltip: 'Abrir menu',
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

class _OrderHeaderCard extends StatelessWidget {
  final Aluguel pedido;
  final bool isRefreshing;
  final VoidCallback? onCopy;
  final VoidCallback onRefresh;

  const _OrderHeaderCard({
    required this.pedido,
    required this.isRefreshing,
    required this.onCopy,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final finalizado = pedido.statusAluguel == StatusAluguel.finalizado;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.sustainability,
        border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.green,
            child: Icon(
              finalizado ? Icons.check : Icons.local_shipping_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finalizado ? 'Pedido finalizado' : 'Pedido em andamento',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pedido.codigo ?? 'Feito em ${formatDate(pedido.dataPedido)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: 'Copiar código',
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined),
            ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.green,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _PagamentoPendenteCard extends StatelessWidget {
  final double valor;
  final VoidCallback onPagar;

  const _PagamentoPendenteCard({required this.valor, required this.onPagar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pagamento pendente',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Pague ${formatMoney(valor)} por Pix. A confirmação aparece '
            'aqui automaticamente.',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onPagar,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF32BCAD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.pix),
              label: const Text(
                'Pagar com Pix',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderProgressCard extends StatelessWidget {
  final List<EtapaAluguel> etapas;

  const _OrderProgressCard({required this.etapas});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status da Locação',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < etapas.length; i++)
            _TrackingStep(
              icon: _iconeDa(etapas[i].status),
              title: etapas[i].titulo,
              subtitle: _descricaoDa(etapas[i].status),
              state: etapas[i].atual
                  ? _TrackingState.current
                  : etapas[i].concluida
                  ? _TrackingState.completed
                  : _TrackingState.pending,
              showLine: i < etapas.length - 1,
            ),
        ],
      ),
    );
  }

  static IconData _iconeDa(StatusAluguel? status) => switch (status) {
    StatusAluguel.aguardandoEntrega => Icons.local_shipping_outlined,
    StatusAluguel.emUso => Icons.delete_outline,
    StatusAluguel.aguardandoRetirada => Icons.recycling_outlined,
    StatusAluguel.finalizado => Icons.flag_outlined,
    null => Icons.circle_outlined,
  };

  static String _descricaoDa(StatusAluguel? status) => switch (status) {
    StatusAluguel.aguardandoEntrega =>
      'O fornecedor levará a caçamba ao endereço na data de início',
    StatusAluguel.emUso => 'A caçamba está no endereço, em uso',
    StatusAluguel.aguardandoRetirada =>
      'O fornecedor fará a retirada da caçamba',
    StatusAluguel.finalizado => 'Locação concluída',
    null => '',
  };
}

enum _TrackingState { completed, current, pending }

class _TrackingStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final _TrackingState state;
  final bool showLine;

  const _TrackingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.state,
    this.showLine = true,
  });

  @override
  Widget build(BuildContext context) {
    final completed = state == _TrackingState.completed;
    final current = state == _TrackingState.current;

    final color = completed || current ? AppColors.green : Colors.grey.shade400;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: current
                      ? AppColors.green
                      : completed
                      ? AppColors.green.withValues(alpha: 0.15)
                      : Colors.grey.shade200,
                  child: Icon(
                    completed ? Icons.check : icon,
                    color: current ? Colors.white : color,
                    size: 19,
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: completed ? AppColors.green : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? 24 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: state == _TrackingState.pending
                                ? Colors.black54
                                : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (current)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'AGORA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryDetailsCard extends StatelessWidget {
  final Aluguel pedido;

  const _DeliveryDetailsCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final endereco = pedido.endereco;

    return _SectionCard(
      title: 'Detalhes da Entrega',
      children: [
        _InformationRow(
          icon: Icons.calendar_month_outlined,
          label: 'Data de início',
          value: formatDate(pedido.dataInicio),
        ),
        const SizedBox(height: 14),
        _InformationRow(
          icon: Icons.schedule,
          label: 'Período de locação',
          value: formatDias(pedido.diasAluguel),
        ),
        if (pedido.dataPedido != null) ...[
          const SizedBox(height: 14),
          _InformationRow(
            icon: Icons.receipt_long_outlined,
            label: 'Pedido feito em',
            value: formatDate(pedido.dataPedido),
          ),
        ],
        if (endereco != null) ...[
          const SizedBox(height: 14),
          _InformationRow(
            icon: Icons.location_on_outlined,
            label: 'Endereço',
            value: '${endereco.ruaENumero}\n${endereco.regiaoECep}',
          ),
        ],
      ],
    );
  }
}

class _DumpsterCard extends StatelessWidget {
  final Aluguel pedido;

  const _DumpsterCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final taxaEntrega = pedido.taxaEntrega;

    return _SectionCard(
      title: 'Serviço Contratado',
      children: [
        for (final item in pedido.itens) ...[
          _ItemRow(item: item),
          const SizedBox(height: 14),
        ],
        if (pedido.itens.isNotEmpty) ...[
          const Divider(color: AppColors.border),
          const SizedBox(height: 14),
        ],
        if (pedido.subtotalItens != null) ...[
          _InformationRow(
            icon: Icons.receipt_outlined,
            label: 'Subtotal',
            value: formatMoney(pedido.subtotalItens!),
          ),
          const SizedBox(height: 14),
        ],
        if (taxaEntrega != null) ...[
          _InformationRow(
            icon: Icons.local_shipping_outlined,
            label: 'Taxa de entrega',
            value: taxaEntrega == 0 ? 'Grátis' : formatMoney(taxaEntrega),
          ),
          const SizedBox(height: 14),
        ],
        _InformationRow(
          icon: Icons.payments_outlined,
          label: 'Valor total',
          value: formatMoney(pedido.precoFinal),
        ),
        const SizedBox(height: 14),
        _InformationRow(
          icon: Icons.credit_card_outlined,
          label: 'Pagamento',
          value: pedido.statusPagamento?.label ?? '-',
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ItemAluguel item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final cacamba = item.cacamba;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: SizedBox(
            width: 92,
            height: 78,
            child: CacambaImage(
              fotoUrl: cacamba?.fotoUrl,
              tamanhoM3: cacamba?.tamanhoM3 ?? 0,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cacamba?.nome ?? 'Caçamba',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Quantidade: ${item.quantidade} • '
                'Período: ${formatDias(item.diasAluguel)}',
                style: const TextStyle(color: Colors.black54, fontSize: 11),
              ),
              const SizedBox(height: 7),
              Text(
                formatMoney(item.subtotal),
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final ContatoPedido contato;
  final VoidCallback? onCopyPhone;

  const _SupplierCard({required this.contato, required this.onCopyPhone});

  @override
  Widget build(BuildContext context) {
    final email = contato.email;
    final temHorario =
        contato.horarioInicio != null && contato.horarioFim != null;

    return _SectionCard(
      title: 'Fornecedor',
      children: [
        _InformationRow(
          icon: Icons.storefront_outlined,
          label: 'Nome',
          value: contato.nomeCompleto,
        ),
        if (contato.telefone != null) ...[
          const SizedBox(height: 14),
          _InformationRow(
            icon: Icons.phone_outlined,
            label: 'Telefone',
            value: formatPhone(contato.telefone),
          ),
        ],
        if (email != null) ...[
          const SizedBox(height: 14),
          _InformationRow(
            icon: Icons.email_outlined,
            label: 'E-mail',
            value: email,
          ),
        ],
        if (temHorario) ...[
          const SizedBox(height: 14),
          _InformationRow(
            icon: Icons.schedule,
            label: 'Atendimento',
            value:
                '${formatHour(contato.horarioInicio)} às '
                '${formatHour(contato.horarioFim)}',
          ),
        ],
        if (onCopyPhone != null) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: onCopyPhone,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF20C765),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.copy_outlined),
              label: const Text(
                'Copiar telefone do fornecedor',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AvaliacaoCard extends ConsumerStatefulWidget {
  final Aluguel pedido;

  const _AvaliacaoCard({required this.pedido});

  @override
  ConsumerState<_AvaliacaoCard> createState() => _AvaliacaoCardState();
}

class _AvaliacaoCardState extends ConsumerState<_AvaliacaoCard> {
  final _comentarioController = TextEditingController();

  int _nota = 0;
  bool _enviando = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avaliacao = widget.pedido.avaliacao;

    if (avaliacao != null) {
      final comentario = avaliacao.comentario;

      return _SectionCard(
        title: 'Sua Avaliação',
        children: [
          _Estrelas(nota: avaliacao.nota),
          if (comentario != null && comentario.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comentario,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ],
      );
    }

    return _SectionCard(
      title: 'Avalie a Locação',
      children: [
        const Text(
          'Como foi o serviço do fornecedor?',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _Estrelas(
          nota: _nota,
          onChanged: _enviando ? null : (nota) => setState(() => _nota = nota),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _comentarioController,
          enabled: !_enviando,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Comentário (opcional)',
            hintStyle: const TextStyle(color: Colors.black38),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: AppColors.green, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _nota == 0 || _enviando ? null : _enviarAvaliacao,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.green,
              disabledBackgroundColor: AppColors.green.withValues(alpha: 0.55),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: _enviando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Enviar avaliação',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _enviarAvaliacao() async {
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);

    try {
      await ref
          .read(pedidosRepositoryProvider)
          .avaliar(
            aluguelId: widget.pedido.id,
            nota: _nota,
            comentario: _comentarioController.text,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obrigado pela avaliação!'),
          backgroundColor: AppColors.green,
        ),
      );
      ref.invalidate(pedidoDetalheProvider(widget.pedido.id));
    } on ApiException catch (error) {
      if (mounted) showApiError(context, error);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }
}

class _Estrelas extends StatelessWidget {
  final int nota;
  final ValueChanged<int>? onChanged;

  const _Estrelas({required this.nota, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var estrela = 1; estrela <= 5; estrela++)
          onChanged == null
              ? Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _icone(estrela),
                )
              : IconButton(
                  tooltip: '$estrela de 5',
                  onPressed: () => onChanged!(estrela),
                  visualDensity: VisualDensity.compact,
                  icon: _icone(estrela),
                ),
      ],
    );
  }

  Widget _icone(int estrela) {
    return Icon(
      estrela <= nota ? Icons.star_rounded : Icons.star_outline_rounded,
      color: AppColors.yellow,
      size: 30,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.green, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
