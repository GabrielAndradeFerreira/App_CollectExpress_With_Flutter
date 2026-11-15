import 'package:flutter/material.dart';

import '../../../../core/models/reciclagem.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

/// Estrutura das telas de reciclagem: logo e menu no topo, conteúdo e a
/// barra de abas da área de reciclagem.
class ReciclagemScaffold extends StatelessWidget {
  const ReciclagemScaffold({
    super.key,
    required this.aba,
    required this.child,
    this.floatingActionButton,
  });

  final AbaReciclagem aba;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawerScrimColor: const Color(0xD9000000),
      endDrawer: const AppMenuDrawer(),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: RecyclingBottomNavigation(aba: aba),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const CabecalhoReciclagem(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Logo e botão do menu lateral.
class CabecalhoReciclagem extends StatelessWidget {
  const CabecalhoReciclagem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Builder(
        builder: (scaffoldContext) {
          return Row(
            children: [
              const Expanded(child: AppLogo()),
              IconButton(
                tooltip: 'Abrir menu',
                onPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightGray,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.menu_rounded),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Cartão branco com borda, o bloco básico das telas de reciclagem.
class CartaoReciclagem extends StatelessWidget {
  const CartaoReciclagem({
    super.key,
    required this.child,
    this.borda = AppColors.border,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color borda;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borda),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

/// Título de uma tela (fora do cabeçalho do app).
class TituloDaTela extends StatelessWidget {
  const TituloDaTela(this.titulo, {super.key, this.subtitulo});

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitulo!,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

/// Etiqueta colorida com a situação (ex.: Agendada).
class SeloDeStatus extends StatelessWidget {
  const SeloDeStatus(this.texto, {super.key, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

Color corDoStatusColeta(StatusColeta status) {
  return switch (status) {
    StatusColeta.agendada => const Color(0xFF1E6FD9),
    StatusColeta.concluida => const Color(0xFF2F8334),
    StatusColeta.cancelada => Colors.red.shade700,
  };
}

Color corDoStatusOferta(StatusOferta status) {
  return switch (status) {
    StatusOferta.aberta => const Color(0xFF2F8334),
    StatusOferta.agendada => const Color(0xFF1E6FD9),
    StatusOferta.concluida => const Color(0xFF2F8334),
    StatusOferta.cancelada => Colors.red.shade700,
    StatusOferta.expirada => Colors.black54,
  };
}

/// Materiais como etiquetas pequenas.
class EtiquetasDeMateriais extends StatelessWidget {
  const EtiquetasDeMateriais(this.nomes, {super.key});

  final List<String> nomes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final nome in nomes)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6E8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              nome,
              style: const TextStyle(
                color: Color(0xFF2F8334),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

/// Linha "rótulo: valor" para os detalhes.
class LinhaDeDetalhe extends StatelessWidget {
  const LinhaDeDetalhe(
    this.rotulo,
    this.valor, {
    super.key,
    this.largura = 118,
  });

  final String rotulo;
  final String valor;
  final double largura;

  @override
  Widget build(BuildContext context) {
    if (valor.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: largura,
            child: Text(
              rotulo,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// `25/10/2026 às 14:30 até 18:00` (ou com as duas datas, se mudar o dia).
String formatJanela(DateTime? inicio, DateTime? fim) {
  if (inicio == null || fim == null) return '-';

  final a = inicio.toLocal();
  final b = fim.toLocal();
  final mesmoDia = a.year == b.year && a.month == b.month && a.day == b.day;

  if (!mesmoDia) return '${formatDateTime(a)} até ${formatDateTime(b)}';

  final hora = b.hour.toString().padLeft(2, '0');
  final minuto = b.minute.toString().padLeft(2, '0');

  return '${formatDateTime(a)} até $hora:$minuto';
}

/// Estado vazio com ícone e texto.
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({super.key, required this.texto, this.icone, this.acao});

  final String texto;
  final IconData? icone;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone ?? Icons.inbox_outlined,
              size: 48,
              color: Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            if (acao != null) ...[const SizedBox(height: 16), acao!],
          ],
        ),
      ),
    );
  }
}

/// Botão verde largo, o botão principal das telas.
class BotaoPrincipal extends StatelessWidget {
  const BotaoPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.carregando = false,
    this.icone,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool carregando;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final rotulo = carregando
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Text(
            texto,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          );

    final estilo = ElevatedButton.styleFrom(
      elevation: 0,
      minimumSize: const Size(48, 52),
      backgroundColor: const Color(0xFF2F8334),
      disabledBackgroundColor: AppColors.green.withValues(alpha: 0.55),
      foregroundColor: Colors.white,
      disabledForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    );

    return SizedBox(
      width: double.infinity,
      child: icone == null || carregando
          ? ElevatedButton(
              onPressed: carregando ? null : onPressed,
              style: estilo,
              child: rotulo,
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              style: estilo,
              icon: Icon(icone),
              label: rotulo,
            ),
    );
  }
}
