import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/aluguel.dart';
import '../../../../core/models/avaliacao.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/models/extensao.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/cacamba_image.dart';
import '../../../pedidos/data/pedidos_repository.dart';
import '../../../pedidos/presentation/compartilhar_pdf.dart';
import '../../../pedidos/presentation/widgets/contrato_extensao_cards.dart';
import '../../data/fornecedor_repository.dart';
import '../fornecedor_providers.dart';
import '../widgets/extensao_fornecedor_card.dart';
import '../widgets/pedido_fornecedor.dart';

import '../../../../core/widgets/app_bottom_navigation.dart';

class DetalhesPedidoPage extends ConsumerStatefulWidget {
  final String aluguelId;

  const DetalhesPedidoPage({super.key, required this.aluguelId});

  @override
  ConsumerState<DetalhesPedidoPage> createState() => _DetalhesPedidoPageState();
}

class _DetalhesPedidoPageState extends ConsumerState<DetalhesPedidoPage> {
  bool _atualizando = false;
  bool _respondendo = false;
  bool _baixandoContrato = false;

  @override
  Widget build(BuildContext context) {
    final provider = detalhePedidoFornecedorProvider(widget.aluguelId);

    return Scaffold(
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _DetailsHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 70),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Detalhes do Pedido',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Informações completas de entrega e pagamento',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  AsyncValueView(
                    value: ref.watch(provider),
                    onRetry: () => ref.invalidate(provider),
                    data: _buildPedido,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SupplierBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildPedido(Aluguel pedido) {
    final proximo = pedido.statusAluguel?.proximo;
    final telefone = pedido.consumidor?.telefone;
    final avaliacao = pedido.avaliacao;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusCard(pedido: pedido),

        const SizedBox(height: 28),
        const _SectionTitle('Informações do Cliente'),
        const SizedBox(height: 12),
        _CustomerCard(pedido: pedido),

        const SizedBox(height: 28),
        const _SectionTitle('Serviço & Pagamento'),
        const SizedBox(height: 12),
        _PaymentCard(pedido: pedido),

        if (pedido.contratoDisponivel) ...[
          const SizedBox(height: 28),
          ContratoCard(
            baixando: _baixandoContrato,
            onBaixar: () => _baixarContrato(pedido),
          ),
        ],

        if (pedido.extensao?.atual case final extensao?) ...[
          const SizedBox(height: 28),
          const _SectionTitle('Extensão do Aluguel'),
          const SizedBox(height: 12),
          ExtensaoFornecedorCard(
            extensao: extensao,
            ocupado: _respondendo,
            onResponder: (aceitar) => _responderExtensao(extensao, aceitar),
          ),
        ],

        if (avaliacao != null) ...[
          const SizedBox(height: 28),
          const _SectionTitle('Avaliação do Cliente'),
          const SizedBox(height: 12),
          _ReviewCard(avaliacao: avaliacao),
        ],

        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: proximo == null || _atualizando
                ? null
                : () => _avancarStatus(proximo),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.green.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _atualizando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    proximo == null
                        ? 'Pedido Finalizado'
                        : textoAvancarStatus(proximo),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),

        if (telefone != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () => _copiarTelefone(telefone),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Copiar Telefone do Cliente',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _avancarStatus(StatusAluguel proximo) async {
    if (!await confirmarAvancoStatus(context, proximo) || !mounted) return;

    setState(() => _atualizando = true);
    try {
      await avancarStatusPedido(context, ref, widget.aluguelId, proximo);
    } finally {
      if (mounted) setState(() => _atualizando = false);
    }
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

  Future<void> _responderExtensao(Extensao extensao, bool aceitar) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(aceitar ? 'Aceitar extensão?' : 'Recusar extensão?'),
        content: Text(
          aceitar
              ? 'O cliente receberá um e-mail e terá 24 horas para pagar '
                    '+${formatDias(extensao.diasAdicionais)} '
                    '(${formatMoney(extensao.valor)}).'
              : 'O cliente será avisado por e-mail e o aluguel segue com o '
                    'prazo original.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            key: const Key('extensao_confirmar'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              aceitar ? 'Aceitar' : 'Recusar',
              style: TextStyle(color: aceitar ? AppColors.green : Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;

    setState(() => _respondendo = true);

    try {
      await ref
          .read(fornecedorRepositoryProvider)
          .responderExtensao(widget.aluguelId, extensao.id, aceitar: aceitar);
      if (!mounted) return;

      ref.invalidate(detalhePedidoFornecedorProvider(widget.aluguelId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aceitar
                ? 'Extensão aceita. O cliente tem 24 horas para pagar.'
                : 'Extensão recusada.',
          ),
          backgroundColor: AppColors.green,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      showApiError(context, error);
      ref.invalidate(detalhePedidoFornecedorProvider(widget.aluguelId));
    } finally {
      if (mounted) setState(() => _respondendo = false);
    }
  }

  Future<void> _copiarTelefone(String telefone) async {
    await Clipboard.setData(ClipboardData(text: telefone));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Telefone copiado: ${formatPhone(telefone)}')),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(child: AppLogo()),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () => _goBack(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text(
              'Voltar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _goBack(BuildContext context) {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(AppRoutes.supplierOrders);
  }
}

class _StatusCard extends StatelessWidget {
  final Aluguel pedido;

  const _StatusCard({required this.pedido});

  /// Usa as etapas da API; sem elas, monta a partir do status atual.
  List<EtapaAluguel> get _etapas {
    if (pedido.etapas.isNotEmpty) return pedido.etapas;

    final atual = pedido.statusAluguel;
    final indiceAtual = atual == null
        ? -1
        : StatusAluguel.values.indexOf(atual);
    final finalizado = atual == StatusAluguel.finalizado;

    return [
      for (final (index, status) in StatusAluguel.values.indexed)
        EtapaAluguel(
          status: status,
          titulo: status.label,
          concluida: index < indiceAtual || finalizado,
          atual: index == indiceAtual && !finalizado,
          pendente: index > indiceAtual,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final etapas = _etapas;
    final codigo = pedido.codigo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            codigo == null
                ? 'Status da Locação'
                : 'Status da Locação: #$codigo',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          for (final (index, etapa) in etapas.indexed)
            _TimelineItem(
              title: etapa.titulo,
              subtitle: etapa.concluida
                  ? '✓ Concluída'
                  : etapa.atual
                  ? 'Etapa atual'
                  : 'Pendente',
              completed: etapa.concluida || etapa.atual,
              showLine: index < etapas.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool completed;
  final bool showLine;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.completed,
    this.showLine = true,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed
                        ? AppColors.green
                        : const Color(0xFFE8E8E8),
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(width: 2, color: const Color(0xFFE1E1E1)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: completed ? Colors.black : Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Aluguel pedido;

  const _CustomerCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final consumidor = pedido.consumidor;
    final nome = consumidor?.nomeCompleto ?? pedido.consumidorNome ?? '-';
    final email = consumidor?.email;
    final cep = pedido.endereco?.cep ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nome: $nome',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Text(
            'Telefone: ${formatPhone(consumidor?.telefone)}',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          if (email != null) ...[
            const SizedBox(height: 14),
            Text(
              'E-mail: $email',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Endereço: ${formatEnderecoPedido(pedido.endereco)}',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          if (cep.length == 8) ...[
            const SizedBox(height: 14),
            Text(
              'CEP: ${cep.substring(0, 5)}-${cep.substring(5)}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Aluguel pedido;

  const _PaymentCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final subtotal = pedido.subtotalItens;
    final taxaEntrega = pedido.taxaEntrega;
    final pago = pedido.statusPagamento == StatusPagamento.pago;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (final item in pedido.itens) ...[
            _ItemRow(item: item),
            const SizedBox(height: 14),
          ],
          if (pedido.itens.isNotEmpty) ...[
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
          ],
          _InformationRow(
            label: 'Data do Pedido:',
            value: formatDate(pedido.dataPedido),
          ),
          const SizedBox(height: 14),
          _InformationRow(
            label: 'Início da Locação:',
            value: formatDate(pedido.dataInicio),
          ),
          const SizedBox(height: 14),
          _InformationRow(
            label: 'Período Contratado:',
            value: formatDias(pedido.diasAluguel),
          ),
          if (subtotal != null) ...[
            const SizedBox(height: 14),
            _InformationRow(
              label: 'Subtotal das Caçambas:',
              value: formatMoney(subtotal),
            ),
          ],
          if (taxaEntrega != null) ...[
            const SizedBox(height: 14),
            _InformationRow(
              label: 'Taxa de Entrega:',
              value: formatMoney(taxaEntrega),
            ),
          ],
          const SizedBox(height: 14),
          _InformationRow(
            label: 'Pagamento:',
            value: pedido.statusPagamento?.label ?? '-',
            valueColor: pago ? AppColors.green : const Color(0xFF9A6D00),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          _InformationRow(
            label: 'Valor Total:',
            value: formatMoney(pedido.precoFinal),
            valueColor: AppColors.green,
            highlighted: true,
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56,
            height: 56,
            child: CacambaImage(
              fotoUrl: cacamba?.fotoUrl,
              tamanhoM3: cacamba?.tamanhoM3 ?? 5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.quantidade}x ${cacamba?.nome ?? 'Caçamba'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (cacamba != null) ...[
                const SizedBox(height: 3),
                Text(
                  '${formatVolume(cacamba.tamanhoM3)} • ${cacamba.tipoResiduo}',
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                '${formatDias(item.diasAluguel)} × '
                '${formatMoney(item.precoDiaria)}/dia',
                style: const TextStyle(color: Colors.black54, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatMoney(item.subtotal),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Avaliacao avaliacao;

  const _ReviewCard({required this.avaliacao});

  @override
  Widget build(BuildContext context) {
    final nota = avaliacao.nota.clamp(0, 5);
    final comentario = avaliacao.comentario;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${'★' * nota}${'☆' * (5 - nota)}  $nota/5',
            style: const TextStyle(
              color: Color(0xFF9A6D00),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (comentario != null && comentario.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comentario,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
          if (avaliacao.dataAvaliacao != null) ...[
            const SizedBox(height: 10),
            Text(
              'Avaliado em ${formatDate(avaliacao.dataAvaliacao)}',
              style: const TextStyle(color: Colors.black54, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool highlighted;

  const _InformationRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: highlighted ? Colors.black : Colors.black54,
              fontSize: highlighted ? 15 : 13,
              fontWeight: highlighted ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            color: valueColor ?? Colors.black,
            fontSize: highlighted ? 20 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    );
  }
}

/*
REMOVENDO POIS O TRECHO ABAIXO FOI SUBSTITUIDO POR:
{
bottomNavigationBar: const SupplierBottomNavigation(
  currentIndex: 2,
),
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2,
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
*/
